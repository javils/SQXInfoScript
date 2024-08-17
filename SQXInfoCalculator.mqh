//+------------------------------------------------------------------+
//|                                            SQXInfoCalculator.mqh |
//|                                            Javier Luque Sanabria |
//|                                                                  |
//+------------------------------------------------------------------+
#include "JSON.mqh"
#include "StatsFuncs.mqh"
#include "models/SQXData.mqh"
#include "models/Commission.mqh"

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

    void             GetCommissions(string symbol, Commission &commission);
    void             parseCommissions(CJAVal &darwinexInfo, Commission &commissions[]);
public:

    void             calculate(SQXData& sqxData);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SQXInfoCalculator::calculate(SQXData &sqxData) {
    Commission commisions[];
    int spreads[];
    int bars = iBars(_Symbol, PERIOD_M1);
    int numSpreads = CopySpread(_Symbol, PERIOD_M1, 0, bars, spreads);
// Ensure we have enough ticks
    if(numSpreads < 1) {
        Print("No tick data available for the specified period.");
        return;
    }
// Output results
    Comment(StringFormat("Symbol: %s", _Symbol));
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
    GetCommissions(_Symbol, darwinexCommission);
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
    ENUM_SYMBOL_CALC_MODE calcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
    int tickWeight = 1;
    if(calcMode == SYMBOL_CALC_MODE_FOREX || calcMode == SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE) {
        tickWeight = 10;
    }
    return tickWeight;
}


//+------------------------------------------------------------------+

#define URL "https://www.darwinex.com/graphics/spreads?dx_platform=DX"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SQXInfoCalculator::GetCommissions(string symbol, Commission &commission) {
    Commission commissions[];
    char data[];
    char result[];
    string resultHeaders;
    if(WebRequest("GET", URL, NULL, 10, data, result, resultHeaders) < 0) {
        commission.type = CommissionType::Undef;
        Print("Can't get the comissions from Darwinex. Be sure you've added \"https://www.darwinex.com\" url into Tools > Options > Experts Advisors > Allow WebRequest for listed URL and marked as enabled.");
        return;
    }
    string response = CharArrayToString(result);
    CJAVal darwinexInfo;
    darwinexInfo.Deserialize(response);
    parseCommissions(darwinexInfo["indices"], commissions);
    parseCommissions(darwinexInfo["commodities"], commissions);
    parseCommissions(darwinexInfo["forex"], commissions);
    parseCommissions(darwinexInfo["stocks"], commissions);
    parseCommissions(darwinexInfo["crypto"], commissions);
    parseCommissions(darwinexInfo["etf"], commissions);
    for(int i = 0; i < ArraySize(commissions); i++) {
        if(commissions[i].symbol == symbol) {
            commission = commissions[i];
            return ;
        }
    }
    commission.type = CommissionType::Undef;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SQXInfoCalculator::parseCommissions(CJAVal &darwinexInfo, Commission &commissions[]) {
    for(int i = 0; i < darwinexInfo.Size(); i++) {
        Commission commission;
        commission.symbol = darwinexInfo[i]["asset"].ToStr();
        commission.value = darwinexInfo[i]["commission"].ToDbl();
        commission.currency = darwinexInfo[i]["type"].ToStr() == "CFD_FX" ? StringSubstr(darwinexInfo[i]["asset"].ToStr(), 0, 3) : darwinexInfo[i]["currency"].ToStr();
        commission.type = darwinexInfo[i]["type"].ToStr() == "CFD_COMM" ? CommissionType::Percentage : CommissionType::Size;
        int size = ArraySize(commissions);
        ArrayResize(commissions, size + 1, size + 1);
        commissions[size] = commission;
    }
}
//+------------------------------------------------------------------+
