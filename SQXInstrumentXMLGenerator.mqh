//+------------------------------------------------------------------+
//|                                    SQXInstrumentXMLGenerator.mqh |
//|                                            Javier Luque Sanabria |
//|                                                                  |
//+------------------------------------------------------------------+
#include "models/SQXData.mqh"

#property copyright "Javier Luque Sanabria"


class SQXInstrumentXMLGenerator {
private:
    string           GetCommissionInfo(SQXData &sqxData);
public:
                     SQXInstrumentXMLGenerator();
                    ~SQXInstrumentXMLGenerator();

    bool             Generate(SQXData &sqxData);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SQXInstrumentXMLGenerator::SQXInstrumentXMLGenerator() {
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SQXInstrumentXMLGenerator::~SQXInstrumentXMLGenerator() {
}
//+------------------------------------------------------------------+
bool SQXInstrumentXMLGenerator::Generate(SQXData &sqxData) {
    string fileName = StringFormat("InstrumentInfo_%s.xml", sqxData.symbol);
    int handle = FileOpen(fileName, FILE_WRITE | FILE_BIN | FILE_TXT);

    if(handle == INVALID_HANDLE) {
        PrintFormat("Error opening %s.", fileName);
        return false;
    }

    string instrumentInfo =
        "<InstrumentInfo " +
        "instrument=\"" + sqxData.symbol + "\" " +
        "description=\"\" " +
        "tickSize=\"" + DoubleToString(sqxData.pipTickSize, _Digits) + "\" " +
        "tickStep=\"" + DoubleToString(sqxData.pipTickStep, _Digits) + "\" " +
        "tickValueInMoney=\"0.0\" " +
        "dateFrom=\"0\" " +
        "dateTo=\"0\" " +
        "rows=\"0\" " +
        "totalDays=\"0\" " +
        "defaultSpread=\"" + DoubleToString(sqxData.percentile90Spread, _Digits) + "\" " +
        "defaultSlippage=\"0.0\" " +
        "decimals=\"1\" " +
        "commissions=\"" + GetCommissionInfo(sqxData) + "\" " +
        "pointValue=\"" + DoubleToString(sqxData.pointValue, 2) + "\" " +
        "dataType=\"6\" " +
        "recognizedFromOrders=\"false\" " +
        "alias=\"" + sqxData.symbol + "\" " +
        "exchange=\"\" " +
        "country=\"\" " +
        "sector=\"\" " +
        "swap=\"&lt;Swap use=&quot;true&quot; type=&quot;money&quot; long=&quot;" +
        DoubleToString(sqxData.swapLong, 2) + "&quot; short=&quot;" +
        DoubleToString(sqxData.swapShort, 2) + "&quot; tripleSwapOn=&quot;" + sqxData.tripleSwapDay + "&quot;/&gt;\" " +
        "orderSizeMultiplier=\"1.0\" " +
        "orderSizeStep=\"" + DoubleToString(sqxData.orderSizeStep, 2) +
        "\"/>";

    FileWriteString(handle, "<Instruments>");
    FileWriteString(handle, instrumentInfo);
    FileWriteString(handle, "</Instruments>");
    FileClose(handle);

    return true;

}

string SQXInstrumentXMLGenerator::GetCommissionInfo(SQXData &sqxData) {

    string commissionInfo;
    if (sqxData.commissionType == CommissionType::Size) {
        commissionInfo = "&lt;Method type=&quot;SizeBased&quot; use=&quot;true&quot;&gt;&lt;Params&gt;&lt;Param key=&quot;Commission&quot; className=&quot;SizeBased&quot;&gt;" +
                         DoubleToString(sqxData.commissionValue, 2) + "&lt;/Param&gt;&lt;/Params&gt;&lt;/Method&gt;";
    } else if (sqxData.commissionType == CommissionType::Percentage) {
        commissionInfo = "&lt;Method type=&quot;PercentageBased&quot; use=&quot;true&quot;&gt;&lt;Params&gt;&lt;Param key=&quot;CommissionPct&quot; className=&quot;PercentageBased&quot;&gt;" +
                         DoubleToString(sqxData.commissionValue, 2) + "&lt;/Param&gt;&lt;/Params&gt;&lt;/Method&gt;";
    }

    return commissionInfo;
}
//+------------------------------------------------------------------+
