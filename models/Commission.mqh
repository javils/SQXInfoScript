//+------------------------------------------------------------------+
//|                                                  Commissions.mqh |
//|                                            Javier Luque Sanabria |
//|                                                                  |
//+------------------------------------------------------------------+
#include "CommissionType.mqh"

#property copyright "Javier Luque Sanabria"


class Commission {
public:
    string            symbol;
    double            value;
    string            currency;
    CommissionType    type;
};
//+------------------------------------------------------------------+
