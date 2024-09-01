//+------------------------------------------------------------------+
//|                                                    SQXInfoScript |
//|                            Copyright 2024, Javier Luque Sanabria |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs


#include "SQXInfoCalculator.mqh"
#include "UTCTimeCalculator.mqh"
#include "SQXInstrumentXMLGenerator.mqh"


input bool generateXMLFile = true;  // Generate an .xml file.

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart() {
    SQXInfoCalculator sqxInfoCalculator;
    SQXData sqxData;
    sqxInfoCalculator.Calculate(sqxData);
    ShowSQXData(sqxData);

    if (generateXMLFile) {
        SQXInstrumentXMLGenerator xmlGenerator;
        if (xmlGenerator.Generate(sqxData)) {
            Alert(StringFormat("Instrument %s exported into MQL5/Files folder.\n\nTo find this folder click in File > Open Data Folder in your Metatrader 5 and open the MQL5 folder.\nInside this folder you can see a file named %s that you can import into you SQX  Data Manager.", sqxData.symbol, StringFormat("InstrumentInfo_%s.xml", sqxData.symbol)));
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowSQXData(SQXData &sqxData) {
    UTCTimeCalculator utcTimeCalculator;

    string commissionInfo;
    if (sqxData.commissionType != CommissionType::Undef) {
        commissionInfo = "\nCOMMISSION INFO\n" +
                         StringFormat("Commission: %.5f %s\n", sqxData.commissionValue, GetCommissionTypeString(sqxData.commissionType));
    }

    string data = "\nSQX INFO\n" +
                  StringFormat("Symbol: %s\n", _Symbol) +
                  StringFormat("Broker Time: %s\n", utcTimeCalculator.GetUTCServerTimeString()) +
                  StringFormat("PC Time: %s\n", utcTimeCalculator.GetUTCPCTimeString()) +
                  StringFormat("Point value: %.2f USD\n", sqxData.pointValue) +
                  StringFormat("Pip/Tick step: %.5f\n", sqxData.pipTickStep) +
                  StringFormat("Order size step: %.2f\n", sqxData.orderSizeStep) +
                  StringFormat("Pip/Tick size: %.5f\n", sqxData.pipTickSize) +
                  "\nSPREAD INFO\n" +
                  StringFormat("Current Spread: %.2f points\n", sqxData.currentSpread) +
                  commissionInfo +
                  "\nSWAP INFO\n" +
                  StringFormat("Swap Long: %.2f USD\n", sqxData.swapLong) +
                  StringFormat("Swap Short: %.2f USD\n", sqxData.swapShort) +
                  StringFormat("Triple Swap Day: %s\n", sqxData.tripleSwapDay);
    Comment(data);
    Print(data);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetCommissionTypeString(CommissionType commissionType) {
    return commissionType == CommissionType::Percentage ? "%" : "USD";
}
//+------------------------------------------------------------------+
