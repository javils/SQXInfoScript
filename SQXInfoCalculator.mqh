//+------------------------------------------------------------------+
//|                                            SQXInfoCalculator.mqh |
//|                                            Javier Luque Sanabria |
//|                                                                  |
//+------------------------------------------------------------------+
#include "StatsFuncs.mqh"
#include "models/SQXData.mqh"
#include "models/Commission.mqh"
#include "DarwinexCommissionsCalculator.mqh"

#property copyright "Javier Luque Sanabria"


class SQXInfoCalculator {
private:
    void             GetSQXInfo(SQXData &sqxData, int &spreads[]);
    void             GetSwapsInfo(SQXData &sqxData);
    void             GetCommissionsInfo(SQXData &sqxData);

    double           GetPointValue();
    double           GetPipTickSize();
    double           GetPipTickStep();
    double           GetOrderSizeStep();
    int              GetTickWeight();
    
    SQXCommissionsCalculator *sqxCommissionsCalculator;
public:
    SQXInfoCalculator() { sqxCommissionsCalculator = new DarwinexCommissionsCalculator(); };
    ~SQXInfoCalculator() { delete sqxCommissionsCalculator; };
    
    void             Calculate(SQXData& sqxData);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SQXInfoCalculator::Calculate(SQXData &sqxData) {
    Commission commisions[];
    int spreads[];
    int bars = iBars(_Symbol, PERIOD_M1);
    int numSpreads = CopySpread(_Symbol, PERIOD_M1, 0, bars, spreads);
    
    if(numSpreads < 1) {
        Print("No tick data available for the specified period.");
        return;
    }
    GetSQXInfo(sqxData, spreads);
    GetCommissionsInfo(sqxData);
    GetSwapsInfo(sqxData);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SQXInfoCalculator::GetSQXInfo(SQXData &sqxData, int &spreads[]) {
    double totalSpread = 0.0;
    double maxSpread = 0.0;
    double minSpread = DBL_MAX;
    int numSpreads = ArraySize(spreads);
    for(int i = 0; i < numSpreads; i++) {
        int spread = spreads[i];
        totalSpread += spread;
        if(spread > maxSpread)
            maxSpread = spread;
        if(spread < minSpread)
            minSpread = spread;
    }
    ArraySort(spreads);
    double tickWeight = GetTickWeight();
    sqxData.symbol = _Symbol;
    sqxData.pointValue = GetPointValue();
    sqxData.pipTickStep = GetPipTickStep();
    sqxData.orderSizeStep = GetOrderSizeStep();
    sqxData.pipTickSize = GetPipTickSize();
    sqxData.currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) / tickWeight;
    sqxData.maximumSpread = maxSpread / tickWeight;
    sqxData.minimumSpread = minSpread / tickWeight;
    sqxData.averageSpread = (totalSpread / numSpreads) / tickWeight;
    sqxData.percentile50Spread = Percentile(spreads, 50) / tickWeight;
    sqxData.percentile75Spread = Percentile(spreads, 75) / tickWeight;
    sqxData.percentile90Spread = Percentile(spreads, 90) / tickWeight;
    sqxData.percentile99Spread = Percentile(spreads, 99) / tickWeight;
    sqxData.modeSpread = CalculateMode(spreads) / tickWeight;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SQXInfoCalculator::GetSwapsInfo(SQXData &sqxData) {
    sqxData.swapLong = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_LONG);
    sqxData.swapShort = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_SHORT);
    sqxData.tripleSwapDay = EnumToString((ENUM_DAY_OF_WEEK)SymbolInfoInteger(_Symbol, SYMBOL_SWAP_ROLLOVER3DAYS));
    if(StringCompare(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD") != 0) {
        sqxData.swapLong *= GetCrossRate(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD");
        sqxData.swapShort *= GetCrossRate(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD");
        if(StringCompare(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "JPY") == 0) {
            sqxData.swapLong *= 100;
            sqxData.swapShort *= 100;
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SQXInfoCalculator::GetCommissionsInfo(SQXData &sqxData) {
    Commission darwinexCommission;
    sqxCommissionsCalculator.Calculate(_Symbol, darwinexCommission);
    sqxData.commissionValue = darwinexCommission.value * 2;
    sqxData.commissionType = darwinexCommission.type;
    if(darwinexCommission.type == CommissionType::Size && StringCompare(darwinexCommission.currency, "USD") != 0) {
        sqxData.commissionValue *= GetCrossRate(darwinexCommission.currency, "USD");
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SQXInfoCalculator::GetPointValue() {
    double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    if(StringCompare(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD") != 0) {
        pointValue *= GetCrossRate(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD");
    }
    return pointValue;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SQXInfoCalculator::GetPipTickSize() {
    return GetTickWeight() * _Point;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SQXInfoCalculator::GetPipTickStep() {
    return _Point;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SQXInfoCalculator::GetOrderSizeStep() {
    return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int SQXInfoCalculator::GetTickWeight() {
#ifdef _MQL5_
    ENUM_SYMBOL_CALC_MODE calcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
    int tickWeight = 1;
    if(calcMode == SYMBOL_CALC_MODE_FOREX || calcMode == SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE) {
        tickWeight = 10;
    }
    return tickWeight;
#else
    long calcMode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
    int tickWeight = 1;
    if(calcMode == 0) {
        tickWeight = 10;
    }
    return tickWeight;
#endif
}
