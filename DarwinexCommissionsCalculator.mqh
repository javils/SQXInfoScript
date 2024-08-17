//+------------------------------------------------------------------+
//|                                DarwinexCommissionsCalculator.mqh |
//|                                            Javier Luque Sanabria |
//|                                                                  |
//+------------------------------------------------------------------+
#include "JSON.mqh"
#include "SQXCommissionsCalculator.mqh"

#property copyright "Javier Luque Sanabria"


#define URL "https://www.darwinex.com/graphics/spreads?dx_platform=DX"

class DarwinexCommissionsCalculator : public SQXCommissionsCalculator {
private:
   void ParseCommissions(CJAVal &darwinexInfo, Commission &commissions[]);
public:
   virtual bool Calculate(string symbol, Commission &commission);   
};



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DarwinexCommissionsCalculator::Calculate(string symbol, Commission &commission) {
    Commission commissions[];
    char data[];
    char result[];
    string resultHeaders;
    if(WebRequest("GET", URL, NULL, 10, data, result, resultHeaders) < 0) {
        commission.type = CommissionType::Undef;
        Print("Can't get the comissions from Darwinex. Be sure you've added \"https://www.darwinex.com\" url into Tools > Options > Experts Advisors > Allow WebRequest for listed URL and marked as enabled.");
        return false;
    }
    string response = CharArrayToString(result);
    CJAVal darwinexInfo;
    darwinexInfo.Deserialize(response);
    ParseCommissions(darwinexInfo["indices"], commissions);
    ParseCommissions(darwinexInfo["commodities"], commissions);
    ParseCommissions(darwinexInfo["forex"], commissions);
    ParseCommissions(darwinexInfo["stocks"], commissions);
    ParseCommissions(darwinexInfo["crypto"], commissions);
    ParseCommissions(darwinexInfo["etf"], commissions);
    for(int i = 0; i < ArraySize(commissions); i++) {
        if(commissions[i].symbol == symbol) {
            commission = commissions[i];
            return true;
        }
    }
    commission.type = CommissionType::Undef;
    return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DarwinexCommissionsCalculator::ParseCommissions(CJAVal &darwinexInfo, Commission &commissions[]) {
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
