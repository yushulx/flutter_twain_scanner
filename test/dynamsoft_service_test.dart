import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:flutter_twain_scanner/flutter_twain_scanner.dart';

const host = 'http://127.0.0.1:18625';

http.Response _json(Object body, {int status = 200}) => http.Response(
      json.encode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  group('DynamsoftService', () {
    test('getServerInfo decodes the version response', () async {
      final service = DynamsoftService(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url,
            Uri.parse('$host/api/server/version'),
          );
          return _json({
            'version': '20240719',
            'compatible': true,
            'moduleVersions': {
              'core': ['18.5.5.0416', '19.4.0.0410'],
            },
          });
        }),
      );

      final info = await service.getServerInfo(host);
      expect(info['version'], '20240719');
      expect(info['compatible'], isTrue);
    });

    test('getDevices appends the scanner type filter', () async {
      final service = DynamsoftService(
        client: MockClient((request) async {
          expect(
            request.url,
            Uri.parse('$host/api/device/scanners?type=${ScannerType.ica}'),
          );
          return _json([
            {'name': 'Virtual Scanner', 'type': 128, 'device': '{}'},
          ]);
        }),
      );

      final devices = await service.getDevices(host, ScannerType.ica);
      expect(devices, hasLength(1));
      expect(devices.first['name'], 'Virtual Scanner');
    });

    test('getDevices returns all scanners without a filter', () async {
      final service = DynamsoftService(
        client: MockClient((request) async {
          expect(request.url.queryParameters, isEmpty);
          return _json([
            {'name': 'Scanner A', 'type': 16, 'device': '{}'},
            {'name': 'Scanner B', 'type': 32, 'device': '{}'},
          ]);
        }),
      );

      final devices = await service.getDevices(host);
      expect(devices, hasLength(2));
    });

    test('createJob sends the license in the DWT-PRODUCT-KEY header', () async {
      final service = DynamsoftService(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url,
            Uri.parse('$host/api/device/scanners/jobs'),
          );
          expect(request.headers['DWT-PRODUCT-KEY'], 'test-license');
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body.containsKey('license'), isFalse);
          expect(body['device'], 'device-json');
          return _json({
            'jobuid': 'job-1',
            'status': JobStatus.pending,
          }, status: 201);
        }),
      );

      final job = await service.createJob(host, {
        'license': 'test-license',
        'device': 'device-json',
        'config': {'Resolution': 200},
      });

      expect(job['jobuid'], 'job-1');
      expect(job['status'], JobStatus.pending);
    });

    test('createJob throws on an invalid license', () async {
      final service = DynamsoftService(
        client: MockClient((request) async => _json({
              'code': -2800,
              'message': 'The current product key is empty or invalid.',
              'statusCode': 403,
            }, status: 403)),
      );

      await expectLater(
        service.createJob(host, {'license': 'invalid', 'device': '{}'}),
        throwsA(
          isA<DynamsoftServiceException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', contains('product key')),
        ),
      );
    });

    test('checkJob, updateJob and deleteJob hit the job endpoint', () async {
      final calls = <String>[];
      final service = DynamsoftService(
        client: MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          switch (request.method) {
            case 'GET':
              return _json({'status': JobStatus.running, 'code': '0'});
            case 'PATCH':
              expect(json.decode(request.body), {'status': JobStatus.canceled});
              return _json({'status': JobStatus.canceled});
            case 'DELETE':
              return http.Response('', 204);
          }
          return http.Response('error', 405);
        }),
      );

      final status = await service.checkJob(host, 'job-1');
      expect(status['status'], JobStatus.running);

      final updated = await service.updateJob(
        host,
        'job-1',
        {'status': JobStatus.canceled},
      );
      expect(updated['status'], JobStatus.canceled);

      expect(await service.deleteJob(host, 'job-1'), isTrue);
      expect(
        calls,
        containsAll([
          'GET /api/device/scanners/jobs/job-1',
          'PATCH /api/device/scanners/jobs/job-1',
          'DELETE /api/device/scanners/jobs/job-1',
        ]),
      );
    });

    test('getImageInfo returns an empty list when the job is done', () async {
      var calls = 0;
      final service = DynamsoftService(
        client: MockClient((request) async {
          calls++;
          if (calls == 1) {
            return _json([
              {
                'imageuid': 'page-1',
                'url': '$host/api/device/scanners/jobs/job-1/next-page'
                    '?page=page-1',
              },
            ]);
          }
          return http.Response('', 204);
        }),
      );

      final firstPage = await service.getImageInfo(host, 'job-1');
      expect(firstPage, hasLength(1));
      expect(firstPage.first['imageuid'], 'page-1');

      final done = await service.getImageInfo(host, 'job-1');
      expect(done, isEmpty);
    });

    test('getImageInfo normalizes a single-object response to a list',
        () async {
      final service = DynamsoftService(
        client: MockClient((request) async => _json({
              'imageuid': 'page-1',
              'url': '$host/api/device/scanners/jobs/job-1/next-page'
                  '?page=page-1',
            })),
      );

      final pages = await service.getImageInfo(host, 'job-1');
      expect(pages, hasLength(1));
      expect(pages.first['imageuid'], 'page-1');
    });

    test('getNextPage returns null when the job has no more pages', () async {
      final service = DynamsoftService(
        client: MockClient((request) async => http.Response('', 204)),
      );

      expect(await service.getNextPage(host, 'job-1'), isNull);
    });

    test('getImageStreams polls until the job is done', () async {
      const png = [1, 2, 3, 4];
      var calls = 0;
      final service = DynamsoftService(
        client: MockClient((request) async {
          calls++;
          if (calls <= 2) return http.Response.bytes(png, 200);
          return http.Response('', 204);
        }),
      );

      final streams = await service.getImageStreams(host, 'job-1');
      expect(streams, hasLength(2));
      expect(streams.first, Uint8List.fromList(png));
    });

    test('getPageStream requests the page index and image type', () async {
      final service = DynamsoftService(
        client: MockClient((request) async {
          expect(
            request.url.queryParameters,
            {'type': 'image/jpeg', 'page': '2'},
          );
          return http.Response.bytes([5, 6, 7], 200);
        }),
      );

      final stream = await service.getPageStream(
        host,
        'job-1',
        page: 2,
        type: 'image/jpeg',
      );
      expect(stream, Uint8List.fromList([5, 6, 7]));
    });

    test('getScannerSettings passes the showui parameter', () async {
      final service = DynamsoftService(
        client: MockClient((request) async {
          expect(
            request.url.path,
            '/api/device/scanners/jobs/job-1/scanner/settings',
          );
          expect(request.url.queryParameters['showui'], 'false');
          return _json({'settings': 'base64-settings'});
        }),
      );

      final settings =
          await service.getScannerSettings(host, 'job-1', showui: false);
      expect(settings['settings'], 'base64-settings');
    });

    test('createDocument, getDocumentInfo and deleteDocument round trip',
        () async {
      final service = DynamsoftService(
        client: MockClient((request) async {
          switch (request.method) {
            case 'POST':
              expect(json.decode(request.body), {'password': 'secret'});
              return _json({'uid': 'doc-1', 'pages': []}, status: 201);
            case 'GET':
              expect(request.headers['DWT-DOC-PASSWORD'], 'secret');
              return _json({
                'uid': 'doc-1',
                'pages': [
                  {'uid': 'page-1'},
                ],
              });
            case 'DELETE':
              return http.Response('', 204);
          }
          return http.Response('error', 405);
        }),
      );

      final doc = await service.createDocument(host, {'password': 'secret'});
      expect(doc['uid'], 'doc-1');

      final info =
          await service.getDocumentInfo(host, 'doc-1', password: 'secret');
      expect((info['pages'] as List), hasLength(1));

      expect(await service.deleteDocument(host, 'doc-1'), isTrue);
    });

    test('insertPage sends the source URL and the password header', () async {
      final service = DynamsoftService(
        client: MockClient((request) async {
          expect(request.headers['DWT-DOC-PASSWORD'], 'secret');
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['source'], contains('/next-page?page='));
          expect(body.containsKey('password'), isFalse);
          return _json({'uid': 'doc-1', 'pages': []});
        }),
      );

      final doc = await service.insertPage(host, 'doc-1', {
        'password': 'secret',
        'source': '$host/api/device/scanners/jobs/job-1/next-page?page=p1',
      });
      expect(doc['uid'], 'doc-1');
    });

    test('deletePage accepts a page UID or index', () async {
      final paths = <String>[];
      final service = DynamsoftService(
        client: MockClient((request) async {
          paths.add(request.url.path);
          return http.Response('', 204);
        }),
      );

      expect(await service.deletePage(host, 'doc-1', '0'), isTrue);
      expect(await service.deletePage(host, 'doc-1', 'page-1'), isTrue);
      expect(
        paths,
        containsAll([
          '/api/storage/documents/doc-1/pages/0',
          '/api/storage/documents/doc-1/pages/page-1',
        ]),
      );
    });

    test('getDocumentStream throws with the service error message', () async {
      final service = DynamsoftService(
        client: MockClient((request) async => _json({
              'code': -1040,
              'message': 'The provided UID is invalid.',
              'statusCode': 404,
            }, status: 404)),
      );

      await expectLater(
        service.getDocumentStream(host, 'missing'),
        throwsA(
          isA<DynamsoftServiceException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having(
                  (e) => e.message, 'message', 'The provided UID is invalid.'),
        ),
      );
    });

    test('connection failures are wrapped in DynamsoftServiceException',
        () async {
      final service = DynamsoftService(
        client: MockClient((request) async => throw http.ClientException('x')),
      );

      await expectLater(
        service.getServerInfo(host),
        throwsA(isA<DynamsoftServiceException>()),
      );
    });
  });
}
