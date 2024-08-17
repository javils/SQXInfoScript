//+------------------------------------------------------------------+
//|                                     SQXCommissionsCalculator.mqh |
//|                                            Javier Luque Sanabria |
//|                                                                  |
//+------------------------------------------------------------------+

#include "models/Commission.mqh"

#property copyright "Javier Luque Sanabria"

interface SQXCommissionsCalculator {
    bool Calculate(string symbol, Commission &commission);
};
//+------------------------------------------------------------------+
