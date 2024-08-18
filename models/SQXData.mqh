//+------------------------------------------------------------------+
//|                                                      SQXData.mqh |
//|                                            Javier Luque Sanabria |
//|                                                                  |
//+------------------------------------------------------------------+
#include "CommissionType.mqh"

#property copyright "Javier Luque Sanabria"


struct SQXData {
    string            symbol;
    double            pointValue;
    double            pipTickStep;
    double            orderSizeStep;
    double            pipTickSize;

    double            currentSpread;
    double            averageSpread;
    double            percentile50Spread;
    double            percentile75Spread;
    double            percentile90Spread;
    double            percentile99Spread;
    double            modeSpread;
    double            maximumSpread;
    double            minimumSpread;

    double            commissionValue;
    CommissionType    commissionType;

    double            swapLong;
    double            swapShort;
    string            tripleSwapDay;
    
};
//+------------------------------------------------------------------+
