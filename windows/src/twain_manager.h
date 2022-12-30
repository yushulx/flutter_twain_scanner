#ifndef TWAIN_MANAGER_H_
#define TWAIN_MANAGER_H_

#include <vector>
#include <iostream>
#include <map>

#include <flutter/standard_method_codec.h>

#include "TwainAppCMD.h"

using namespace std;

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

extern TwainAppCMD  *gpTwainApplicationCMD;
extern string EnableDS();

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

        gpTwainApplicationCMD->connectDSM();
    };

    EncodableList getDataSources() {
        EncodableList list;

        vector<string> dsNames = gpTwainApplicationCMD->printAvailableDataSources();

        for (int i = 0; i < dsNames.size(); i++) {
            list.push_back(EncodableValue(dsNames[i]));
        }
        return list;
    }

    EncodableValue scanDocument(TW_INT32 index) {
        gpTwainApplicationCMD->loadDS(index);
        string documentPath =  EnableDS();
        return EncodableValue(documentPath);
    }
};

#endif