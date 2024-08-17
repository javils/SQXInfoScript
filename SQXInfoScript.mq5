//+------------------------------------------------------------------+
//|                                                    SQXInfoScript |
//|                            Copyright 2024, Javier Luque Sanabria |
//+------------------------------------------------------------------+
#property strict


#include "SQXInfoCalculator.mqh"


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart() {
    SQXInfoCalculator sqxInfoCalculator;
    SQXData sqxData;
    sqxInfoCalculator.calculate(sqxData);
    ShowSQXData(sqxData);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowSQXData(SQXData &sqxData) {
    string commissionInfo;
    if (sqxData.commissionType != CommissionType::Undef) {
        commissionInfo = "\nCOMMISSION INFO\n" +
                         StringFormat("Commission: %.5f %s\n", sqxData.commissionValue, GetCommissionTypeString(sqxData.commissionType));
    }
    string data = "\nSQX INFO\n" +
                  StringFormat("Point value: %.2f USD\n", sqxData.pointValue) +
                  StringFormat("Pip/Tick step: %.5f\n", sqxData.pipTickStep) +
                  StringFormat("Order size step: %.2f\n", sqxData.orderSizeStep) +
                  StringFormat("Pip/Tick size: %.5f\n", sqxData.pipTickSize) +
                  "\nSPREAD INFO\n" +
                  StringFormat("Current Spread: %.2f points\n", sqxData.currentSpread) +
                  StringFormat("Average Spread: %.2f points\n", sqxData.averageSpread) +
                  StringFormat("Percentile 50: %.2f points\n", sqxData.percentile50Spread) +
                  StringFormat("Percentile 75: %.2f points\n", sqxData.percentile75Spread) +
                  StringFormat("Percentile 90: %.2f points\n", sqxData.percentile90Spread) +
                  StringFormat("Percentile 99: %.2f points\n", sqxData.percentile99Spread) +
                  StringFormat("Mode Spread: %.2f points\n", sqxData.modeSpread) +
                  StringFormat("Maximum Spread: %.2f points\n", sqxData.maximumSpread) +
                  StringFormat("Minimum Spread: %.2f points\n", sqxData.minimumSpread) +
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
