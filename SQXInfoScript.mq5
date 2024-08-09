//+------------------------------------------------------------------+
//|                                                    SQXInfoScript |
//|                            Copyright 2024, Javier Luque Sanabria |
//+------------------------------------------------------------------+
#property strict

#include "JSON.mqh"
#include <Generic\HashMap.mqh>



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
    int spreads_int [];
    int bars = iBars(_Symbol, PERIOD_M1);
    int num_spreads = CopySpread(_Symbol, PERIOD_M1, 0, bars, spreads_int);
// Ensure we have enough ticks
    if(num_spreads < 1) {
        Print("No tick data available for the specified period.");
        return;
    }
// Variables for calculating spread statistics
    double total_spread = 0.0;
    double max_spread = 0.0;
    double min_spread = DBL_MAX;
    double spread_array[];
    ArrayResize(spread_array, num_spreads, num_spreads);
// Iterate over the ticks and calculate spreads
    for(int i = 0; i < num_spreads; i++) {
        double spread = spreads_int[i];
        total_spread += spread;
        // Determine maximum and minimum spread
        if(spread > max_spread)
            max_spread = spread;
        if(spread < min_spread)
            min_spread = spread;
        // Add the spread to the array
        spread_array[ArraySize(spread_array) - 1 - i] = spread;
    }
    ArraySort(spread_array);
    double tickWeight = GetTickWeight();
    sqxData.symbol = _Symbol;
    sqxData.currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) / tickWeight;
    sqxData.maximumSpread = max_spread / tickWeight;
    sqxData.minimumSpread = min_spread / tickWeight;
    sqxData.averageSpread = (total_spread / num_spreads) / tickWeight;
    sqxData.percentile50Spread = Percentile(spread_array, 50) / tickWeight;
    sqxData.percentile75Spread = Percentile(spread_array, 75) / tickWeight;
    sqxData.percentile90Spread = Percentile(spread_array, 90) / tickWeight;
    sqxData.percentile99Spread = Percentile(spread_array, 99) / tickWeight;
    sqxData.modeSpread = CalculateMode(spread_array) / tickWeight;
// Output results
    Comment(StringFormat("Symbol: %s", _Symbol));
    GetSQXInfo(sqxData);
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
                  StringFormat("Point value: %.2f USD\n", GetPointValue()) +
                  StringFormat("Pip/Tick step: %.5f\n", GetPipTickStep()) +
                  StringFormat("Order size step: %.2f\n", GetOrderSizeStep()) +
                  StringFormat("Pip/Tick size: %.5f\n", GetPipTickSize()) +
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
void GetSQXInfo(SQXData &sqxData) {
    sqxData.pointValue = GetPointValue();
    sqxData.pipTickStep = GetPipTickStep();
    sqxData.orderSizeStep = GetOrderSizeStep();
    sqxData.pipTickSize = GetPipTickSize();
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
//|                                                                  |
//+------------------------------------------------------------------+
double Percentile(double &data[], double percentile) {
    int n = ArraySize(data);
    if(n == 0)
        return 0.0;
// Calculate the rank of the percentile
    double rank = (percentile / 100.0) * (n - 1);
    int lower_index = (int)MathFloor(rank);
    int upper_index = (int)MathCeil(rank);
// Interpolation
    if(upper_index >= n)
        upper_index = n - 1;
    double weight = rank - lower_index;
    return data[lower_index] * (1.0 - weight) + data[upper_index] * weight;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateMode(double &data[]) {
    int n = ArraySize(data);
    if(n == 0)
        return 0.0;
// Use a map to count frequencies of each spread value
    double mode = data[0];
    int max_count = 0;
    int count = 1;
// Iterate over the sorted array to find the mode
    for(int i = 1; i < n; i++) {
        if(data[i] == data[i - 1]) {
            count++;
            if(count > max_count) {
                max_count = count;
                mode = data[i];
            }
        } else {
            count = 1;
        }
    }
    return mode;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetCrossRate(string curr_prof, string curr_acc) {
    if(curr_prof == curr_acc) {
        return 1.0;
    }
    string symbol = curr_prof + curr_acc;
    if(CheckMarketWatch(symbol)) {
        double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        if(bid != 0.0)
            return bid;
    }
// Try the inverse symbol
    symbol = curr_acc + curr_prof;
    if(CheckMarketWatch(symbol)) {
        double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        if(ask != 0.0)
            return 1 / ask;
    }
    Print(__FUNCTION__, ": Error, cannot get cross rate for ", curr_prof + curr_acc);
    return 0.0;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckMarketWatch(string symbol) {
    ResetLastError();
// check if symbol is selected in the MarketWatch
    if(!SymbolInfoInteger(symbol, SYMBOL_SELECT)) {
        if(GetLastError() == ERR_MARKET_UNKNOWN_SYMBOL) {
            return false;
        }
        if(!SymbolSelect(symbol, true)) {
            return false;
        }
        Sleep(100);
    }
    return true;
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
