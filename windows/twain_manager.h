#ifndef TWAIN_MANAGER_H_
#define TWAIN_MANAGER_H_

#include <vector>
#include <iostream>
#include <map>

#include <flutter/standard_method_codec.h>

#include "main.h"
#include <signal.h>

#include "CommonTWAIN.h"
#include "TwainAppCMD.h"
#include "TwainApp_ui.h"

using namespace std;

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

class TwainManager
{
public:
    ~TwainManager()
    {
        gpTwainApplicationCMD->exit();
        delete gpTwainApplicationCMD;
        gpTwainApplicationCMD = 0;
    };

    TwainManager()
    {
        // Instantiate the TWAIN application CMD class
        HWND parentWindow = NULL;

#ifdef TWH_CMP_MSC
        parentWindow = GetConsoleWindow();
#endif
        gpTwainApplicationCMD = new TwainAppCMD(parentWindow);
    };

    // const char *GetVersion()
    // {
    //     return DDN_GetVersion();
    // }

    // void Init()
    // {
    //     normalizer = DDN_CreateInstance();
    //     imageResult = NULL;
    // }

    // int SetParameters(const char *params)
    // {
    //     int ret = 0;

    //     if (normalizer)
    //     {
    //         char errorMsgBuffer[512];
    //         ret = DDN_InitRuntimeSettingsFromString(normalizer, params, errorMsgBuffer, 512);
    //         if (ret != DM_OK)
    //         {
    //             cout << errorMsgBuffer << endl;
    //         }
    //     }

    //     return ret;
    // }

    // static int SetLicense(const char *license)
    // {
    //     char errorMsgBuffer[512];
    //     // Click https://www.dynamsoft.com/customer/license/trialLicense/?product=ddn to get a trial license.
    //     int ret = DC_InitLicense(license, errorMsgBuffer, 512);
    //     if (ret != DM_OK)
    //     {
    //         cout << errorMsgBuffer << endl;
    //     }
    //     return ret;
    // }

    // EncodableList Detect(const char *filename)
    // {
    //     EncodableList out;
    //     if (normalizer == NULL)
    //         return out;

    //     DetectedQuadResultArray *pResults = NULL;

    //     int ret = DDN_DetectQuadFromFile(normalizer, filename, "", &pResults);
    //     if (ret)
    //     {
    //         printf("Detection error: %s\n", DC_GetErrorString(ret));
    //     }

    //     if (pResults)
    //     {
    //         int count = pResults->resultsCount;

    //         for (int i = 0; i < count; i++)
    //         {
    //             EncodableMap map;

    //             DetectedQuadResult *quadResult = pResults->detectedQuadResults[i];
    //             int confidence = quadResult->confidenceAsDocumentBoundary;
    //             DM_Point *points = quadResult->location->points;
    //             int x1 = points[0].coordinate[0];
    //             int y1 = points[0].coordinate[1];
    //             int x2 = points[1].coordinate[0];
    //             int y2 = points[1].coordinate[1];
    //             int x3 = points[2].coordinate[0];
    //             int y3 = points[2].coordinate[1];
    //             int x4 = points[3].coordinate[0];
    //             int y4 = points[3].coordinate[1];

    //             map[EncodableValue("confidence")] = EncodableValue(confidence);
    //             map[EncodableValue("x1")] = EncodableValue(x1);
    //             map[EncodableValue("y1")] = EncodableValue(y1);
    //             map[EncodableValue("x2")] = EncodableValue(x2);
    //             map[EncodableValue("y2")] = EncodableValue(y2);
    //             map[EncodableValue("x3")] = EncodableValue(x3);
    //             map[EncodableValue("y3")] = EncodableValue(y3);
    //             map[EncodableValue("x4")] = EncodableValue(x4);
    //             map[EncodableValue("y4")] = EncodableValue(y4);
    //             out.push_back(map);
    //         }
    //     }

    //     if (pResults != NULL)
    //         DDN_FreeDetectedQuadResultArray(&pResults);

    //     return out;
    // }

    // EncodableMap Normalize(const char *filename, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4)
    // {
    //     FreeImage();
    //     EncodableMap map;

    //     Quadrilateral quad;
    //     quad.points[0].coordinate[0] = x1;
    //     quad.points[0].coordinate[1] = y1;
    //     quad.points[1].coordinate[0] = x2;
    //     quad.points[1].coordinate[1] = y2;
    //     quad.points[2].coordinate[0] = x3;
    //     quad.points[2].coordinate[1] = y3;
    //     quad.points[3].coordinate[0] = x4;
    //     quad.points[3].coordinate[1] = y4;

    //     int errorCode = DDN_NormalizeFile(normalizer, filename, "", &quad, &imageResult);
    //     if (errorCode != DM_OK)
    //         printf("%s\r\n", DC_GetErrorString(errorCode));

    //     if (imageResult)
    //     {
    //         ImageData *imageData = imageResult->image;
    //         int width = imageData->width;
    //         int height = imageData->height;
    //         int stride = imageData->stride;
    //         int format = (int)imageData->format;
    //         unsigned char *data = imageData->bytes;
    //         int orientation = imageData->orientation;
    //         int length = imageData->bytesLength;

    //         map[EncodableValue("width")] = EncodableValue(width);
    //         map[EncodableValue("height")] = EncodableValue(height);
    //         map[EncodableValue("stride")] = EncodableValue(stride);
    //         map[EncodableValue("format")] = EncodableValue(format);
    //         map[EncodableValue("orientation")] = EncodableValue(orientation);
    //         map[EncodableValue("length")] = EncodableValue(length);

    //         unsigned char *rgba = new unsigned char[width * height * 4];
    //         memset(rgba, 0, width * height * 4);
    //         if (format == IPF_RGB_888)
    //         {
    //             int dataIndex = 0;
    //             for (int i = 0; i < height; i++)
    //             {
    //                 for (int j = 0; j < width; j++)
    //                 {
    //                     int index = i * width + j;

    //                     rgba[index * 4] = data[dataIndex + 2];     // red
    //                     rgba[index * 4 + 1] = data[dataIndex + 1]; // green
    //                     rgba[index * 4 + 2] = data[dataIndex];     // blue
    //                     rgba[index * 4 + 3] = 255;                 // alpha
    //                     dataIndex += 3;
    //                 }
    //             }
    //         }
    //         else if (format == IPF_GRAYSCALED)
    //         {
    //             int dataIndex = 0;
    //             for (int i = 0; i < height; i++)
    //             {
    //                 for (int j = 0; j < width; j++)
    //                 {
    //                     int index = i * width + j;
    //                     rgba[index * 4] = data[dataIndex];
    //                     rgba[index * 4 + 1] = data[dataIndex];
    //                     rgba[index * 4 + 2] = data[dataIndex];
    //                     rgba[index * 4 + 3] = 255;
    //                     dataIndex += 1;
    //                 }
    //             }
    //         }
    //         else if (format == IPF_BINARY)
    //         {
    //             unsigned char *grayscale = new unsigned char[width * height];
    //             binary2grayscale(data, grayscale, width, height, stride, length);

    //             int dataIndex = 0;
    //             for (int i = 0; i < height; i++)
    //             {
    //                 for (int j = 0; j < width; j++)
    //                 {
    //                     int index = i * width + j;
    //                     rgba[index * 4] = grayscale[dataIndex];
    //                     rgba[index * 4 + 1] = grayscale[dataIndex];
    //                     rgba[index * 4 + 2] = grayscale[dataIndex];
    //                     rgba[index * 4 + 3] = 255;
    //                     dataIndex += 1;
    //                 }
    //             }

    //             free(grayscale);
    //         }

    //         std::vector<uint8_t> rawBytes(rgba, rgba + width * height * 4);
    //         map[EncodableValue("data")] = rawBytes;

    //         free(rgba);
    //     }

    //     return map;
    // }

    // void binary2grayscale(unsigned char *data, unsigned char *output, int width, int height, int stride, int length)
    // {
    //     int index = 0;

    //     int skip = stride * 8 - width;
    //     int shift = 0;
    //     int n = 1;

    //     for (int i = 0; i < length; ++i)
    //     {
    //         unsigned char b = data[i];
    //         int byteCount = 7;
    //         while (byteCount >= 0)
    //         {
    //             int tmp = (b & (1 << byteCount)) >> byteCount;

    //             if (shift < stride * 8 * n - skip)
    //             {
    //                 if (tmp == 1)
    //                     output[index] = 255;
    //                 else
    //                     output[index] = 0;
    //                 index += 1;
    //             }

    //             byteCount -= 1;
    //             shift += 1;
    //         }

    //         if (shift == stride * 8 * n)
    //         {
    //             n += 1;
    //         }
    //     }
    // }

    // EncodableValue GetParameters()
    // {
    //     if (normalizer == NULL)
    //         return EncodableValue("");

    //     char *content = NULL;
    //     DDN_OutputRuntimeSettingsToString(normalizer, "", &content);
    //     EncodableValue params = EncodableValue((const char *)content);
    //     if (content != NULL)
    //         DDN_FreeString(&content);
    //     return params;
    // }

    // int Save(const char *filename)
    // {
    //     if (imageResult == NULL)
    //         return -1;
    //     int ret = NormalizedImageResult_SaveToFile(imageResult, filename);
    //     if (ret != DM_OK)
    //         printf("NormalizedImageResult_SaveToFile: %s\r\n", DC_GetErrorString(ret));

    //     return ret;
    // }

    /////////////////////////////////////////////////////////////////////////////
    /**
     * Display exit message.
     * @param[in] _sig not used.
     */
    void onSigINT(int _sig)
    {
        UNUSEDARG(_sig);
        cout << "\nGoodbye!" << endl;
        exit(0);
    }

    //////////////////////////////////////////////////////////////////////////////
    /**
     * Negotiate a capabilities between the app and the DS
     * @param[in] _pCap the capabilities to negotiate
     */
    void negotiate_CAP(const pTW_CAPABILITY _pCap)
    {
        string input;

        // -Setting one cap could change another cap so always refresh the caps
        // before working with another one.
        // -Another method of doing this is to let the DS worry about the state
        // of the caps instead of keeping a copy in the app like I'm doing.
        gpTwainApplicationCMD->initCaps();

        for (;;)
        {
            if ((TWON_ENUMERATION == _pCap->ConType) ||
                (TWON_ONEVALUE == _pCap->ConType))
            {
                TW_MEMREF pVal = _DSM_LockMemory(_pCap->hContainer);

                // print the caps current value
                if (TWON_ENUMERATION == _pCap->ConType)
                {
                    print_ICAP(_pCap->Cap, (pTW_ENUMERATION)(pVal));
                }
                else // TWON_ONEVALUE
                {
                    print_ICAP(_pCap->Cap, (pTW_ONEVALUE)(pVal));
                }

                cout << "\nset cap# > ";
                cin >> input;
                cout << endl;

                if ("q" == input)
                {
                    _DSM_UnlockMemory(_pCap->hContainer);
                    break;
                }
                else
                {
                    int n = atoi(input.c_str());
                    TW_UINT16 valUInt16 = 0;
                    pTW_FIX32 pValFix32 = {0};
                    pTW_FRAME pValFrame = {0};

                    // print the caps current value
                    if (TWON_ENUMERATION == _pCap->ConType)
                    {
                        switch (((pTW_ENUMERATION)pVal)->ItemType)
                        {
                        case TWTY_UINT16:
                            valUInt16 = ((pTW_UINT16)(&((pTW_ENUMERATION)pVal)->ItemList))[n];
                            break;

                        case TWTY_FIX32:
                            pValFix32 = &((pTW_ENUMERATION_FIX32)pVal)->ItemList[n];
                            break;

                        case TWTY_FRAME:
                            pValFrame = &((pTW_ENUMERATION_FRAME)pVal)->ItemList[n];
                            break;
                        }

                        switch (_pCap->Cap)
                        {
                        case ICAP_PIXELTYPE:
                            gpTwainApplicationCMD->set_ICAP_PIXELTYPE(valUInt16);
                            break;

                        case ICAP_BITDEPTH:
                            gpTwainApplicationCMD->set_ICAP_BITDEPTH(valUInt16);
                            break;

                        case ICAP_UNITS:
                            gpTwainApplicationCMD->set_ICAP_UNITS(valUInt16);
                            break;

                        case ICAP_XFERMECH:
                            gpTwainApplicationCMD->set_ICAP_XFERMECH(valUInt16);
                            break;

                        case ICAP_XRESOLUTION:
                        case ICAP_YRESOLUTION:
                            gpTwainApplicationCMD->set_ICAP_RESOLUTION(_pCap->Cap, pValFix32);
                            break;

                        case ICAP_FRAMES:
                            gpTwainApplicationCMD->set_ICAP_FRAMES(pValFrame);
                            break;

                        default:
                            cerr << "Unsupported capability" << endl;
                            break;
                        }
                    }
                }
                _DSM_UnlockMemory(_pCap->hContainer);
            }
            else
            {
                cerr << "Unsupported capability" << endl;
                break;
            }
        }

        return;
    }

    //////////////////////////////////////////////////////////////////////////////
    /**
     * drives main capabilities menu.  Negotiate all capabilities
     */
    void negotiateCaps()
    {
        // If the app is not in state 4, don't even bother showing this menu.
        if (gpTwainApplicationCMD->m_DSMState < 4)
        {
            cerr << "\nNeed to open a source first\n"
                 << endl;
            return;
        }

        string input;

        // Loop forever until either SIGINT is heard or user types done to go back
        // to the main menu.
        for (;;)
        {
            printMainCaps();
            cout << "\n(h for help) > ";
            cin >> input;
            cout << endl;

            if ("q" == input)
            {
                break;
            }
            else if ("h" == input)
            {
                printMainCaps();
            }
            else if ("1" == input)
            {
                negotiate_CAP(&(gpTwainApplicationCMD->m_ICAP_XFERMECH));
            }
            else if ("2" == input)
            {
                negotiate_CAP(&(gpTwainApplicationCMD->m_ICAP_PIXELTYPE));
            }
            else if ("3" == input)
            {
                negotiate_CAP(&(gpTwainApplicationCMD->m_ICAP_BITDEPTH));
            }
            else if ("4" == input)
            {
                negotiate_CAP(&(gpTwainApplicationCMD->m_ICAP_XRESOLUTION));
            }
            else if ("5" == input)
            {
                negotiate_CAP(&(gpTwainApplicationCMD->m_ICAP_YRESOLUTION));
            }
            else if ("6" == input)
            {
                negotiate_CAP(&(gpTwainApplicationCMD->m_ICAP_FRAMES));
            }
            else if ("7" == input)
            {
                negotiate_CAP(&(gpTwainApplicationCMD->m_ICAP_UNITS));
            }
            else
            {
                printMainCaps();
            }
        }

        return;
    }

    //////////////////////////////////////////////////////////////////////////////
    /**
     * Enables the source. The source will let us know when it is ready to scan by
     * calling our registered callback function.
     */
    void EnableDS()
    {
        gpTwainApplicationCMD->m_DSMessage = 0;
#ifdef TWNDS_OS_LINUX

        int test;
        sem_getvalue(&(gpTwainApplicationCMD->m_TwainEvent), &test);
        while (test < 0)
        {
            sem_post(&(gpTwainApplicationCMD->m_TwainEvent)); // Event semaphore Handle
            sem_getvalue(&(gpTwainApplicationCMD->m_TwainEvent), &test);
        }
        while (test > 0)
        {
            sem_wait(&(gpTwainApplicationCMD->m_TwainEvent)); // event semaphore handle
            sem_getvalue(&(gpTwainApplicationCMD->m_TwainEvent), &test);
        }

#endif
        // -Enable the data source. This puts us in state 5 which means that we
        // have to wait for the data source to tell us to move to state 6 and
        // start the transfer.  Once in state 5, no more set ops can be done on the
        // caps, only get ops.
        // -The scan will not start until the source calls the callback function
        // that was registered earlier.
#ifdef TWNDS_OS_WIN
        if (!gpTwainApplicationCMD->enableDS(GetDesktopWindow(), FALSE))
#else
        if (!gpTwainApplicationCMD->enableDS(0, TRUE))
#endif
        {
            return;
        }

#ifdef TWNDS_OS_WIN
        // now we have to wait until we hear something back from the DS.
        while (!gpTwainApplicationCMD->m_DSMessage)
        {
            TW_EVENT twEvent = {0};

            // If we are using callbacks, there is nothing to do here except sleep
            // and wait for our callback from the DS.  If we are not using them,
            // then we have to poll the DSM.

            // Pumping messages is for Windows only
            MSG Msg;
            if (!GetMessage((LPMSG)&Msg, NULL, 0, 0))
            {
                break; // WM_QUIT
            }
            twEvent.pEvent = (TW_MEMREF)&Msg;

            twEvent.TWMessage = MSG_NULL;
            TW_UINT16 twRC = TWRC_NOTDSEVENT;
            twRC = _DSM_Entry(gpTwainApplicationCMD->getAppIdentity(),
                              gpTwainApplicationCMD->getDataSource(),
                              DG_CONTROL,
                              DAT_EVENT,
                              MSG_PROCESSEVENT,
                              (TW_MEMREF)&twEvent);

            if (!gUSE_CALLBACKS && twRC == TWRC_DSEVENT)
            {
                // check for message from Source
                switch (twEvent.TWMessage)
                {
                case MSG_XFERREADY:
                case MSG_CLOSEDSREQ:
                case MSG_CLOSEDSOK:
                case MSG_NULL:
                    gpTwainApplicationCMD->m_DSMessage = twEvent.TWMessage;
                    break;

                default:
                    cerr << "\nError - Unknown message in MSG_PROCESSEVENT loop\n"
                         << endl;
                    break;
                }
            }
            if (twRC != TWRC_DSEVENT)
            {
                TranslateMessage((LPMSG)&Msg);
                DispatchMessage((LPMSG)&Msg);
            }
        }
#elif defined(TWNDS_OS_LINUX)
        // Wait for the event be signaled
        sem_wait(&(gpTwainApplicationCMD->m_TwainEvent)); // event semaphore handle
                                                          // Indefinite wait
#endif

        // At this point the source has sent us a callback saying that it is ready to
        // transfer the image.

        if (gpTwainApplicationCMD->m_DSMessage == MSG_XFERREADY)
        {
            // move to state 6 as a result of the data source. We can start a scan now.
            gpTwainApplicationCMD->m_DSMState = 6;

            gpTwainApplicationCMD->startScan();
        }

        // Scan is done, disable the ds, thus moving us back to state 4 where we
        // can negotiate caps again.
        gpTwainApplicationCMD->disableDS();

        return;
    }

//////////////////////////////////////////////////////////////////////////////
/**
 * Callback funtion for DS.  This is a callback function that will be called by
 * the source when it is ready for the application to start a scan. This
 * callback needs to be registered with the DSM before it can be called.
 * It is important that the application returns right away after recieving this
 * message.  Set a flag and return.  Do not process the callback in this function.
 */
#ifdef TWH_CMP_MSC
    TW_UINT16 FAR PASCAL
#else
    FAR PASCAL TW_UINT16
#endif
    DSMCallback(pTW_IDENTITY _pOrigin,
                pTW_IDENTITY _pDest,
                TW_UINT32 _DG,
                TW_UINT16 _DAT,
                TW_UINT16 _MSG,
                TW_MEMREF _pData)
    {
        UNUSEDARG(_pDest);
        UNUSEDARG(_DG);
        UNUSEDARG(_DAT);
        UNUSEDARG(_pData);

        TW_UINT16 twrc = TWRC_SUCCESS;

        // we are only waiting for callbacks from our datasource, so validate
        // that the originator.
        if (0 == _pOrigin ||
            _pOrigin->Id != gpTwainApplicationCMD->getDataSource()->Id)
        {
            return TWRC_FAILURE;
        }
        switch (_MSG)
        {
        case MSG_XFERREADY:
        case MSG_CLOSEDSREQ:
        case MSG_CLOSEDSOK:
        case MSG_NULL:
            gpTwainApplicationCMD->m_DSMessage = _MSG;
            // now signal the event semaphore
#ifdef TWNDS_OS_LINUX
            {
                int test = 12345;
                sem_post(&(gpTwainApplicationCMD->m_TwainEvent)); // Event semaphore Handle
            }
#endif
            break;

        default:
            cerr << "Error - Unknown message in callback routine" << endl;
            twrc = TWRC_FAILURE;
            break;
        }

        return twrc;
    }

private:
    TwainAppCMD *gpTwainApplicationCMD;
    bool gUSE_CALLBACKS;
};

#endif