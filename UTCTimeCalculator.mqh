//+--------------------------------------------------------------------------------+
//|                                                          UTCTimeCalculator.mqh |
//|                                                          Javier Luque Sanabria |
//|Thanks to                                                                       |
//|https://www.mql5.com/en/code/viewcode/48650/298137/brokerdaylightschedule.mq5   |                            |
//+--------------------------------------------------------------------------------+
#property copyright "Javier Luque Sanabria"

class UTCTimeCalculator {
private:
    int              TimeYear(const datetime t);
    int              TimeMonth(const datetime t);
    int              TimeHour(const datetime t);
    datetime         GetNthSunday(int iYear, int iMonth, int Nth);
    int              GetSecsInAWeek();
    datetime         GetBar(datetime dstTime);
public:
    string           GetUTCPCTimeString();
    string           GetUTCServerTimeString();

};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string UTCTimeCalculator::GetUTCPCTimeString() {
    datetime localTime = TimeLocal();
    bool isLocalSummerTime = TimeDaylightSavings() != 0;
    int localTimeOffset = (int)(localTime - TimeGMT()) / 3600;
    localTimeOffset -= isLocalSummerTime ? 1 : 0;

    if (localTimeOffset >= 0) {
        return StringFormat("%s (UTC+%d)", TimeToString(localTime, TIME_SECONDS), localTimeOffset);
    } else {
        return StringFormat("%s (UTC-%d)", TimeToString(localTime, TIME_SECONDS), localTimeOffset);
    }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string UTCTimeCalculator::GetUTCServerTimeString() {
#ifdef __MQL5__
    datetime brokerTime = TimeTradeServer();
#else
    datetime brokerTime = TimeCurrent();
#endif 
    int brokerTimeOffset = (int)(brokerTime - TimeGMT()) / 3600;

    datetime lastbar = iTime(_Symbol, PERIOD_H1, 0);
    int year = TimeYear(lastbar);
    int month = TimeMonth(lastbar);
    datetime dstSwitchAU = GetNthSunday(year, 4, 1); // the first Sunday of April for the AU switch
    datetime dstSwitchUK = GetNthSunday(year, 3, 5); // the last Sunday of March for the UK switch
    datetime dstSwitchUS = GetNthSunday(year, 3, 2); // the second Sunday of March for the US switch

    if(lastbar < dstSwitchAU + GetSecsInAWeek()) {
        year--;
        dstSwitchAU = GetNthSunday(year, 10, 1); // the first Sunday of October for the AU switch
        dstSwitchUK = GetNthSunday(year, 10, 5); // the last Sunday of October for the UK switch
        dstSwitchUS = GetNthSunday(year, 11, 1); // the first Sunday of November for the US switch
    }

    datetime lastBarWeek = GetBar(dstSwitchAU + GetSecsInAWeek());
    datetime lastBarPrevWeek = GetBar(dstSwitchAU);

    if(TimeHour(lastBarWeek) != TimeHour(lastBarPrevWeek)) {
        if (month >= 10 || month < 4) {
            brokerTimeOffset -= 1;
        }
    }

    lastBarWeek = GetBar(dstSwitchUK + GetSecsInAWeek());
    lastBarPrevWeek = GetBar(dstSwitchUK);

    if(TimeHour(lastBarWeek) != TimeHour(lastBarPrevWeek)) {
        if (month > 3 && month < 10) {
            brokerTimeOffset -= 1;
        }
    }

    lastBarWeek = GetBar(dstSwitchUS + GetSecsInAWeek());
    lastBarPrevWeek = GetBar(dstSwitchUS);

    if(TimeHour(lastBarWeek) == TimeHour(lastBarPrevWeek)) {
        if (month >= 3 && month <= 10) {
            brokerTimeOffset -= 1;
        }
    }
    
    if (brokerTimeOffset >= 0) {
        return StringFormat("%s (UTC+%d)", TimeToString(brokerTime, TIME_SECONDS), brokerTimeOffset);
    } else {
        return StringFormat("%s (UTC-%d)", TimeToString(brokerTime, TIME_SECONDS), brokerTimeOffset);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int UTCTimeCalculator::TimeYear(const datetime t) {
    MqlDateTime st;
    TimeToStruct(t, st);
    return(st.year);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int UTCTimeCalculator::TimeMonth(const datetime t) {
    MqlDateTime st;
    TimeToStruct(t, st);
    return(st.mon);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int UTCTimeCalculator::TimeHour(const datetime t) {
    MqlDateTime st;
    TimeToStruct(t, st);
    return(st.hour);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime UTCTimeCalculator::GetNthSunday(int year, int month, int nth) {
    MqlDateTime st;
    st.year = year;
    st.mon = month;
    st.day = 1;
    datetime dt = StructToTime(st); // get date of first of month
    if(nth < 1)
        return 0;
    if(nth > 5)
        nth = 5;
    TimeToStruct(dt, st);
    int sundayDOM = (7 - st.day_of_week) % 7; // 1st Sunday Day of Month
    dt += (sundayDOM + 7 * (nth - 1)) * 86400;
    TimeToStruct(dt, st);
    if(st.mon != month)
        dt -= 7 * 86400;
    return dt;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime UTCTimeCalculator::GetBar(datetime dstTime) {
    return iTime(_Symbol, PERIOD_H1, iBarShift(_Symbol, PERIOD_H1, dstTime, false));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int UTCTimeCalculator::GetSecsInAWeek() {
    return 7 * 24 * 60 * 60;
}
//+------------------------------------------------------------------+
