//+------------------------------------------------------------------+
//|                                                   StatsFuncs.mqh |
//|                                            Javier Luque Sanabria |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Javier Luque Sanabria"


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Percentile(int &data[], double percentile) {
    int n = ArraySize(data);
    if(n == 0)
        return 0.0;
// Calculate the rank of the percentile
    double rank = (percentile / 100.0) * (n - 1);
    int lowerIndex = (int)MathFloor(rank);
    int upperIndex = (int)MathCeil(rank);
// Interpolation
    if(upperIndex >= n)
        upperIndex = n - 1;
    double weight = rank - lowerIndex;
    return data[lowerIndex] * (1.0 - weight) + data[upperIndex] * weight;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateMode(int &data[]) {
    int n = ArraySize(data);
    if(n == 0)
        return 0.0;
// Use a map to count frequencies of each spread value
    double mode = data[0];
    int maxCount = 0;
    int count = 1;
// Iterate over the sorted array to find the mode
    for(int i = 1; i < n; i++) {
        if(data[i] == data[i - 1]) {
            count++;
            if(count > maxCount) {
                maxCount = count;
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
double GetCrossRate(string currencyProfit, string currencyAccount) {
    if(currencyProfit == currencyAccount) {
        return 1.0;
    }
    string symbol = currencyProfit + currencyAccount;
    if(CheckMarketWatch(symbol)) {
        double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        if(bid != 0.0)
            return bid;
    }
// Try the inverse symbol
    symbol = currencyAccount + currencyProfit;
    if(CheckMarketWatch(symbol)) {
        double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        if(ask != 0.0)
            return 1 / ask;
    }
    Print(__FUNCTION__, ": Error, cannot get cross rate for ", currencyProfit + currencyAccount);
    return 0.0;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckMarketWatch(string symbol) {
    ResetLastError();
// check if symbol is selected in the MarketWatch
    if(!SymbolInfoInteger(symbol, SYMBOL_SELECT)) {
#ifdef _MQL5_
        if(GetLastError() == ERR_MARKET_UNKNOWN_SYMBOL) {
            return false;
        }
#else 
        if(GetLastError() == ERR_UNKNOWN_SYMBOL) {
            return false;
        }
#endif
        if(!SymbolSelect(symbol, true)) {
            return false;
        }
        Sleep(100);
    }
    return true;
}
//+------------------------------------------------------------------+
