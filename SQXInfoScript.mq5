﻿//+------------------------------------------------------------------+
//|                                                    SQXInfoScript |
//|                            Copyright 2024, Javier Luque Sanabria |
//+------------------------------------------------------------------+
#property strict

#include "JSON.mqh"
#include "StatsFuncs.mqh"


enum CommissionType {
    Size,
    Percentage,
    Undef
};

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
//|                                                                  |
//+------------------------------------------------------------------+
class DarwinexCommissions {
public:
    string            symbol;
    double            value;
    string            currency;
    CommissionType    type;
};


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart() {
    SQXData sqxData;
    DarwinexCommissions darwinexCommisions[];
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
void GetSQXInfo(SQXData &sqxData, int &spreads[]) {
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
void GetSwapsInfo(SQXData &sqxData) {
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
void GetCommissionsInfo(SQXData &sqxData) {
    DarwinexCommissions darwinexCommission;
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
string GetCommissionTypeString(CommissionType commissionType) {
    return commissionType == CommissionType::Percentage ? "%" : "USD";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPointValue() {
    double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    if(StringCompare(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD") != 0) {
        pointValue *= GetCrossRate(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD");
    }
    return pointValue;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPipTickSize() {
    return GetTickWeight() * _Point;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPipTickStep() {
    return _Point;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetOrderSizeStep() {
    return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetTickWeight() {
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
void GetCommissions(string symbol, DarwinexCommissions &commission) {
    DarwinexCommissions commissions[];
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
void parseCommissions(CJAVal &darwinexInfo, DarwinexCommissions &commissions[]) {
    for(int i = 0; i < darwinexInfo.Size(); i++) {
        DarwinexCommissions commission;
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
