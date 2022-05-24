//+------------------------------------------------------------------+
//|                                        BoliXsigma_toutch_v02.mq5 |
//|                                                          TTSS000 |
//|                                      https://twitter.com/ttss000 |
//+------------------------------------------------------------------+
#property copyright "TTSS000"
#property link      "https://twitter.com/ttss000"
#property version   "02" //2022/5/24
#include <MT4Orders.mqh>

//---- indicator parameters
input double input_lots = 0.1;
input int ma_bars = 200;
input int BobaPeriod= 20;
input double BobaDeviations= 2.8;
input bool Use_Sound=true;
input int from_minute=55;
input int to_minute=59;
input double pinbar_ratio=0.25;
input int jisa_winter=7;
input int trade_hour_from=9;
input int trade_hour_to=0;
input double rsi_upper_thresh=70;
input double rsi_lower_thresh=30;

input int slip_point=5;
input int      HourStart=0;
input int      HourEnd=24;
input int      NumHolizontal=10;
input double   TPSL_Ratio=2.0;
input bool bUseSL=true;
input double   riskpercent=2.0;
input int      magic=202204219;

input int       bolPrd=20;
input double    bolDev=2.0;
input int       keltPrd=20;
input double    keltFactor=1.5;
input int       momPrd=20;
input bool     AlertSqueezeStart=false;
input bool     AlertSqueezeEnd=false;
input int timediff_winter=7;
input int MA1_Bars=48;
input int MA2_Bars=288;
input double TP_BB=3.5;
input string aaa1 ="shikin kanri";
input string memo_acc_symbol0="ex,acc=JPY,sym=xxxJPY,bunshibunnbo=1";
input string memo_acc_symbol1="ex,acc=USD,sym=xxxUSD,bunshibunbo=1";
input string memo_acc_symbol2="ex,acc=JPY,sym=XXXUSD,bunshi=1,bunbo=USDJPY";  // convert to USD
input string memo_acc_symbol3="ex,acc=USD,sym=USDxxx,bunshi=USDxxx,bunbo=1";  // convert to xxx
input string memo_acc_symbol4="ex,acc=EUR,sym=XXXUSD,bunshi=EURUSD,bunbo=1";  // convert to USD
input string memo_acc_symbol5="ex,acc=USD,sym=XXXHKD,bunshi=1,bunbo=USDHKD";  // convert to USD
input string memo_acc_symbol6="ex,acc=JPY,sym=XXXHKD,bunshi=USDJPY,bunbo=USDHKD";  // convert to JPY
input string acc_bunshi="1";
input string acc_bunbo="1";


//---- buffers

//int i,j,slippage=3;
double breakpoint=0.0;
double ema=0.0;
int peakf=0;
int peaks=0;
int valleyf=0;
int valleys=0;
double ccis[61],ccif[61];
double delta=0;
double ugol=0;
int count_squeeze=0;
int count_squeeze_pre=0;

int TimeFlag=0;
bool summer = false;

//struct MqlTradeRequest {
//  int action;
//  string symbol;
//  double volume;
//  double price;
//  double deviation;
//  double sl;
//  double tp;
//  int magic;
//  int type;
//  int position;
//  int order;
//};

MqlTradeRequest request;

string strEAname="BB_BO";

double highest=0;
double lowest=0;

double lots=input_lots;

int indexLastLong=-1;
int indexLastShort=-1;

datetime dtLastLong=0;
datetime dtLastShort=0;
int iLongCount=0;
int iShortCount=0;
bool buy_flag=false;
bool sell_flag=false;

double BBUpperBuffer[];
double BBLowerBuffer[];
double MABufLongTerm[];
double MABufShortTerm[];
double upK[];
double loK[];

int h_BB;
int h_MA_L;
int h_MA_S;

int h_iC;

double order_price;

//+------------------------------------------------------------------+
datetime TimeMonth(datetime TargetTime)
{
  MqlDateTime tm;
  TimeToStruct(TargetTime,tm);
  return tm.mon;
}
//+------------------------------------------------------------------+
datetime TimeDay(datetime TargetTime)
{
  MqlDateTime tm;
  TimeToStruct(TargetTime,tm);
  return tm.day;
}
//+------------------------------------------------------------------+
datetime TimeMinute(datetime TargetTime)
{
  MqlDateTime tm;
  TimeToStruct(TargetTime,tm);
  return tm.min;
}
//+------------------------------------------------------------------+
datetime TimeHour(datetime TargetTime)
{
  MqlDateTime tm;
  TimeToStruct(TargetTime,tm);
  return tm.hour;
}
//+------------------------------------------------------------------+
datetime TimeDayOfWeek(datetime TargetTime)
{
  MqlDateTime tm;
  TimeToStruct(TargetTime,tm);
  return tm.day_of_week;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//--- create timer
  EventSetTimer(60);
  h_BB=iBands(NULL, PERIOD_CURRENT,BobaPeriod,0,BobaDeviations,PRICE_CLOSE);
  h_MA_L=iMA(NULL, PERIOD_CURRENT, ma_bars, 0, MODE_SMA, PRICE_CLOSE);
  h_MA_S=iMA(NULL, PERIOD_CURRENT, BobaPeriod, 0, MODE_SMA, PRICE_CLOSE);

  ArraySetAsSeries(BBUpperBuffer, true);
  ArraySetAsSeries(BBLowerBuffer, true);
  ArraySetAsSeries(MABufLongTerm, true);
  ArraySetAsSeries(MABufShortTerm, true);
  //ArraySetAsSeries(upK, true);
  //ArraySetAsSeries(loK, true);

//---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- destroy timer
  EventKillTimer();

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---

  double Bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
  double Ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);

  double band1, band2;
  double rsi_current;
  double ma, ma200, ma200_1;
  double order_price;

  //band1= iBands(NULL,PERIOD_CURRENT, BobaPeriod, BobaDeviations, 0, PRICE_CLOSE, MODE_UPPER, 0);
  //ma = iMA(NULL, PERIOD_CURRENT, BobaPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
  //ma200 = iMA(NULL, PERIOD_CURRENT, ma_bars, 0, MODE_SMA, PRICE_CLOSE, 0);
  //ma200_1 = iMA(NULL, PERIOD_CURRENT, ma_bars, 0, MODE_SMA, PRICE_CLOSE, 1);
  //band2= iBands(NULL,PERIOD_CURRENT, BobaPeriod, BobaDeviations, 0, PRICE_CLOSE, MODE_LOWER, 0);
  //rsi_current = iRSI(NULL, PERIOD_CURRENT, 14, PRICE_CLOSE, 0);
  CopyBuffer(h_BB,2,0,2,BBLowerBuffer);
  //double TP_BB_PriceS = BBLowerBuffer[0];

  CopyBuffer(h_BB,1,0,2,BBUpperBuffer);
  //double TP_BB_PriceL = BBUpperBuffer[0];
  CopyBuffer(h_MA_L,0,0,2,MABufLongTerm);
  CopyBuffer(h_MA_S,0,0,2,MABufShortTerm);

  //double takeprofitS = TP_BB_PriceS;
  //double takeprofitL = TP_BB_PriceL;

  band1= BBUpperBuffer[0];
  ma200 = MABufLongTerm[0];
  ma200_1 = MABufLongTerm[1];
  ma = MABufShortTerm[0];
  //ma = iMA(NULL, PERIOD_CURRENT, BobaPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
  //ma200 = iMA(NULL, PERIOD_CURRENT, ma_bars, 0, MODE_SMA, PRICE_CLOSE, 0);
  //ma200_1 = iMA(NULL, PERIOD_CURRENT, ma_bars, 0, MODE_SMA, PRICE_CLOSE, 1);
  //band2= iBands(NULL,PERIOD_CURRENT, BobaPeriod, BobaDeviations, 0, PRICE_CLOSE, MODE_LOWER, 0);
  band2= BBLowerBuffer[0];

  rsi_current = 50;
  buy_flag=false;
  sell_flag=false;

  // buy new condition
  if(iLongCount==0){
    if(band1 < iClose(NULL, PERIOD_CURRENT, 0) 
        && rsi_upper_thresh < rsi_current 
        && from_minute<=TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))
        && TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))<=to_minute 
        && ma200 < iClose(NULL, PERIOD_CURRENT, 0) 
        && ma200_1 < ma200 ){ buy_flag=true; order_price = band1;}
    if(iClose(NULL, PERIOD_CURRENT, 0) < band2 
        && rsi_lower_thresh < rsi_current 
        && from_minute<=TimeMinute(iTime(NULL,PERIOD_CURRENT, 0)) 
        && TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))<=to_minute 
        && ma200 < iClose(NULL, PERIOD_CURRENT, 0) 
        && ma200_1 < ma200 ){
         buy_flag=true;
          order_price = band2;
    }
  }     

  // sell new condition
  if(iShortCount==0){
    if(iClose(NULL, PERIOD_CURRENT, 0) < band2 
        && rsi_current < rsi_lower_thresh 
        && from_minute<=TimeMinute(iTime(NULL,PERIOD_CURRENT, 0)) 
        && TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))<=to_minute 
        && ma200 > iClose(NULL, PERIOD_CURRENT, 0) 
        && ma200_1 > ma200 ){
           sell_flag=true;  // junbari
           order_price = band2;
    }
    if(band1 < iClose(NULL, PERIOD_CURRENT, 0) 
        && rsi_current < rsi_upper_thresh 
        && from_minute<=TimeMinute(iTime(NULL,PERIOD_CURRENT, 0)) 
        && TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))<=to_minute 
        && ma200 > iClose(NULL, PERIOD_CURRENT, 0) 
        && ma200_1 > ma200 ){
          sell_flag=true;  // gyaku bari
          order_price = band1;
    }
  }     
  lots=0.01;
  if(buy_flag){
    dtLastLong = iTime(NULL,PERIOD_CURRENT, 0);
    if(OrderSend(NULL, OP_BUY, lots, order_price, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){
      
    }
  }

  if(sell_flag){
    dtLastShort = iTime(NULL,PERIOD_CURRENT, 0);
    if(OrderSend(NULL, OP_SELL, lots, order_price, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){
      
    }
  }
  CheckPositions();
  // check sell close
  if(iClose(NULL, PERIOD_CURRENT, 1) < ma && ma < iClose(NULL, PERIOD_CURRENT, 0)){
    //Print ("close condition0");
  
  }
  if(dtLastShort != iTime(NULL,PERIOD_CURRENT, 0)){
    //Print ("close condition1");
  
  }

  if(0<iShortCount
      && iClose(NULL, PERIOD_CURRENT, 0) < ma 
      && ma < iClose(NULL, PERIOD_CURRENT, 1)
      && dtLastShort != iTime(NULL,PERIOD_CURRENT, 0)){
    Print ("close Short 0");
    order_price = ma;
    CloseShort();
    dtLastShort = 0;  
  }else if(0<iShortCount && iClose(NULL, PERIOD_CURRENT, 1) < ma && ma < iClose(NULL, PERIOD_CURRENT, 0) && dtLastShort != iTime(NULL,PERIOD_CURRENT, 0)){
    Print ("close Short 1");
    order_price = ma;
    CloseShort();
    dtLastShort = 0;  
  }
  if(0<iLongCount &&  iClose(NULL, PERIOD_CURRENT, 0) < ma && ma < iClose(NULL, PERIOD_CURRENT, 1) && dtLastLong != iTime(NULL,PERIOD_CURRENT, 0)){
    Print ("close Long 0");
    order_price = ma;
    CloseLong();
    dtLastLong = 0;  
  }else if(0<iLongCount &&  iClose(NULL, PERIOD_CURRENT, 1) < ma && ma < iClose(NULL, PERIOD_CURRENT, 0) && dtLastLong != iTime(NULL,PERIOD_CURRENT, 0)){
    Print ("close Long 1");
    order_price = ma;
    CloseLong();
    dtLastLong = 0;  
  }
  CheckPositions();
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---

}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
{
//---

}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
//---

}
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
{
//---
  double ret=0.0;
//---

//---
  return(ret);
}
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit()
{
//---

}
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass()
{
//---

}
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
{
//---

}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//---

}
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
{
//---

}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CheckPositions(void)
{

  iLongCount=0;
  iShortCount=0;
  ulong ticket;

  int positions_total = PositionsTotal();
  for(int i = positions_total -1 ; 0 <= i ; i--) {
    if(ticket = PositionGetTicket(i)) {
      if(PositionSelectByTicket(ticket)) {
        int position_type = PositionGetInteger(POSITION_TYPE);
        if(position_type == POSITION_TYPE_BUY) {
          iLongCount++;
          //Print("iLongCount="+iLongCount);
        } else if(position_type == POSITION_TYPE_SELL) {
          iShortCount++;
          //Print("iShortCount="+iShortCount);
        }
      }
    }
  }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CloseLong(void)
{
  double Bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
  double Ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  int orders_total = OrdersTotal();
  for(int i = orders_total -1 ; 0 <= i ; i--){
    if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
      if(OrderType() == OP_BUY){
        OrderClose(OrderTicket(), lots, order_price, slip_point, clrNONE);
      }
    }
  }
}
//+------------------------------------------------------------------+
void CloseShort(void)
{
  double Bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
  double Ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);

  int orders_total = OrdersTotal();
  for(int i = orders_total -1 ; 0 <= i ; i--){
    if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
      if(OrderType() == OP_SELL){
        OrderClose(OrderTicket(), lots, order_price, slip_point, clrNONE);
      }
    }
  }
}
//+------------------------------------------------------------------+
