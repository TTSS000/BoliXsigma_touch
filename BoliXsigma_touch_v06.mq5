//+------------------------------------------------------------------+
//|                                        BoliXsigma_toutch_v06.mq5 |
//|                                                          TTSS000 |
//|                                      https://twitter.com/ttss000 |
//+------------------------------------------------------------------+
#property copyright "TTSS000"
#property link      "https://twitter.com/ttss000"
#property version   "06" //2022/5/27
#include <MT4Orders.mqh>


//---- indicator parameters
input double input_lots = 0.1;
input int ma_bars = 200;
input int BobaPeriod= 20;
input double BobaDeviations= 2.8;
input bool Use_Sound=true;
input string memo_from_minute="0or55gayoi";
input int from_minute=0;
input int to_minute=59;
input double pinbar_ratio=0.25;
input int jisa_winter=7;
//input int trade_hour_from=9;
//input int trade_hour_to=0;
input double rsi_upper_thresh=70;
input double rsi_lower_thresh=30;
// ----
input int slip_point=5;
//input int      HourStart=0;
//input int      HourEnd=24;
input int      NumHolizontal=10;
//input double   TPSL_Ratio=2.0;
//----- trail -----
input string memo_trail="0tpsl,1trail_points,2atr,3ratio";
input int trailtype=0;
input double TrailingStopPoint  =30;
input double TrailingStopRatio = 0.0003;
input double TrailingStop_StartRatio = 0.00075;

//----- ATR -----
input string atr_memo="";
input int ATR_bars=14;
input double ATR_sl_factor=2;
input double ATR_tp_factor=10;
input double ATR_trail_start_factor=1.2;
input double ATR_trail_sl_factor=0.6;

//----- tp -----
input string memo_tp="0=middleline,1=price_ratio,2=atr";
input int tp_type=1;
input double tp_ratio=0.01;

//----- sl -----
input string memo_sl="0=middleline,1=price_ratio,2=atr";
input int sl_type=1;
input double sl_ratio=0.0017;
//input string memo_sl2="0point,1ratio,2atr not implemented";
//input int sltype=1;

//----- d'Alembert -----
input string memo_d_Alembert="";
input bool bUse_d_Alembert=true;
input double d_Alembert_1st_risk=2.0;
input double d_Alembert_risk_diff=0.2;


input bool bUseSL=true;
input double   riskpercent=2.0;
input int      input_magic=202204219;

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
MqlTradeResult  result;

string strEAname="BoliXsigma_touch";

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
double ATRbuf[];
//double loK[];

int h_BB;
int h_MA_L;
int h_MA_S;
int h_ATR;

int h_iC;

double order_price;

ulong last_ticket=0;
ulong prev_ticket=0;


double riskpercent_d_Alembert = d_Alembert_1st_risk;
double riskpercent_d_Alembert_max = 0;

struct WinLoseHist {
  datetime           dt;
  ulong              ticket_num;
  int                WinPlus_Even0_LoseMinus;
};

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
  h_ATR=iATR(NULL, PERIOD_CURRENT, ATR_bars);

  ArraySetAsSeries(BBUpperBuffer, true);
  ArraySetAsSeries(BBLowerBuffer, true);
  ArraySetAsSeries(MABufLongTerm, true);
  ArraySetAsSeries(MABufShortTerm, true);
  ArraySetAsSeries(ATRbuf, true);
//ArraySetAsSeries(loK, true);

  long modes = SymbolInfoInteger(Symbol(), SYMBOL_FILLING_MODE);
  if ((modes & SYMBOL_FILLING_FOK) != 0) {
    Print("SYMBOL_FILLING_FOK FOK ポリシーに対応しています");
  }
  if ((modes & SYMBOL_FILLING_IOC) != 0) {
    Print("SYMBOL_FILLING_IOC IOC ポリシーに対応しています");
  }

// 成行注文時には RETURN ポリシーは無条件で指定可能とされているため、
// RETURN ポリシーに対応しているかを調べるビットフラグは用意されていないようです。
  Print("SYMBOL_FILLING_RETURN ポリシーに対応しています（嘘かも）");

  //Print("ATR_sl_factor="+ATR_sl_factor);
  string data_folder_str = TerminalInfoString(TERMINAL_DATA_PATH);
  Print ("DataFolder="+data_folder_str);

//---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- destroy timer
  Print("riskpercent_d_Alembert_max="+  riskpercent_d_Alembert_max);
  EventKillTimer();
  string data_folder_str = TerminalInfoString(TERMINAL_DATA_PATH);
  Print ("DataFolder="+data_folder_str);

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
  //double order_price;

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
  CopyBuffer(h_ATR,0,0,2,ATRbuf);

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

  if(bUse_d_Alembert) lots = input_lots * riskpercent_d_Alembert;
// buy new condition
  if(iLongCount==0) {
    if(band1 < iClose(NULL, PERIOD_CURRENT, 0)
        && rsi_upper_thresh < rsi_current
        && from_minute<=TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))
        && TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))<=to_minute
        && ma200 < iClose(NULL, PERIOD_CURRENT, 0)
        //&& ma200_1 < ma200
         ) {
      buy_flag=true;
      order_price = band1;
      //Print("ATRbuf1="+ATRbuf[1]);
    }
    if(iClose(NULL, PERIOD_CURRENT, 0) < band2
        && rsi_lower_thresh < rsi_current
        && from_minute<=TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))
        && TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))<=to_minute
        && ma200 < iClose(NULL, PERIOD_CURRENT, 0)
        //&& ma200_1 < ma200
         ) {
      buy_flag=true;
      order_price = band2;
      //Print("ATRbuf1="+ATRbuf[1]);
    }
  }

// sell new condition
  if(iShortCount==0) {
    if(iClose(NULL, PERIOD_CURRENT, 0) < band2
        && rsi_current < rsi_lower_thresh
        && from_minute<=TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))
        && TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))<=to_minute
        && ma200 > iClose(NULL, PERIOD_CURRENT, 0)
        //&& ma200_1 > ma200
         ) {
      sell_flag=true;  // junbari
      order_price = band2;
      //Print("ATRbuf1="+ATRbuf[1]);
    }
    if(band1 < iClose(NULL, PERIOD_CURRENT, 0)
        && rsi_current < rsi_upper_thresh
        && from_minute<=TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))
        && TimeMinute(iTime(NULL,PERIOD_CURRENT, 0))<=to_minute
        && ma200 > iClose(NULL, PERIOD_CURRENT, 0)
        //&& ma200_1 > ma200
         ) {
      sell_flag=true;  // gyaku bari
      order_price = band1;
      //Print("ATRbuf1="+ATRbuf[1]);
    }
  }
//lots=0.01;
  if(buy_flag) {
    dtLastLong = iTime(NULL,PERIOD_CURRENT, 0);
    CheckWinLoseHistorySort();
    MarketBuy();
    //if(OrderSend(NULL, OP_BUY, lots, order_price, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){
    //
    //}
  }

  if(sell_flag) {
    dtLastShort = iTime(NULL,PERIOD_CURRENT, 0);
    CheckWinLoseHistorySort();
    MarketSell();
//    if(OrderSend(NULL, OP_SELL, lots, order_price, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){
//          }
  }
  CheckPositions();
// check sell close
//  if(iClose(NULL, PERIOD_CURRENT, 1) < ma && ma < iClose(NULL, PERIOD_CURRENT, 0)){
//    //Print ("close condition0");
//
//  }
//  if(dtLastShort != iTime(NULL,PERIOD_CURRENT, 0)){
//    //Print ("close condition1");
//
//  }

  if(tp_type == 0 && sl_type==0) {
    if(0<iShortCount
        && iClose(NULL, PERIOD_CURRENT, 0) < ma
        && ma < iClose(NULL, PERIOD_CURRENT, 1)
        && dtLastShort != iTime(NULL,PERIOD_CURRENT, 0)) {
      //Print ("close Short 0");
      order_price = ma;
      CloseShort();
      dtLastShort = 0;
    } else if(0<iShortCount && iClose(NULL, PERIOD_CURRENT, 1) < ma && ma < iClose(NULL, PERIOD_CURRENT, 0) && dtLastShort != iTime(NULL,PERIOD_CURRENT, 0)) {
      //Print ("close Short 1");
      order_price = ma;
      CloseShort();
      dtLastShort = 0;
    }
    if(0<iLongCount &&  iClose(NULL, PERIOD_CURRENT, 0) < ma && ma < iClose(NULL, PERIOD_CURRENT, 1) && dtLastLong != iTime(NULL,PERIOD_CURRENT, 0)) {
      //Print ("close Long 0");
      order_price = ma;
      CloseLong();
      dtLastLong = 0;
    } else if(0<iLongCount &&  iClose(NULL, PERIOD_CURRENT, 1) < ma && ma < iClose(NULL, PERIOD_CURRENT, 0) && dtLastLong != iTime(NULL,PERIOD_CURRENT, 0)) {
      //Print ("close Long 1");
      order_price = ma;
      CloseLong();
      dtLastLong = 0;
    }
  } else {
    SetTPSL();
    if(trailtype==2) {
      CheckTrailATR();
    }
    if(trailtype==3) {
      CheckTrailRatio();
    }
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
  for(int i = orders_total -1 ; 0 <= i ; i--) {
    if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if(OrderType() == OP_BUY) {
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
  for(int i = orders_total -1 ; 0 <= i ; i--) {
    if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if(OrderType() == OP_SELL) {
        OrderClose(OrderTicket(), lots, order_price, slip_point, clrNONE);
      }
    }
  }
}
//+------------------------------------------------------------------+
int MarketBuy(void)
{

// if(OrderSend(NULL, OP_BUY, lots, order_price, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){
  ZeroMemory(request);
  ZeroMemory(result);

  switch(tp_type) {
  case 0:
    request.tp =0;
    break;
  case 1:
    request.tp =NormalizeDouble(order_price*(1+tp_ratio), Digits());
    break;
  case 2:
    request.tp =NormalizeDouble(order_price+ATRbuf[1]*ATR_tp_factor, Digits());
    break;
  default:
    break;
  }

  switch(sl_type) {
  case 0:
    request.sl =0;
    break;
  case 1:
    request.sl =NormalizeDouble(order_price*(1-sl_ratio), Digits());
    break;
  case 2:
    request.sl =NormalizeDouble(order_price-ATRbuf[1]*ATR_sl_factor, Digits());
    break;
  default:
    request.sl =0;
    break;
  }
  //Print("tpsl00,order_price,ATRbuf[1],ATR_tp_factor,ATR_sl_factor="+request.tp+" : "+request.sl+" : "+ order_price +" : "+ ATRbuf[1] +" : "+ATR_tp_factor+" : "+ATR_sl_factor);

  request.action   =TRADE_ACTION_DEAL;        // type of trade operation
//request.action   =TRADE_ACTION_PENDING;        // type of trade operation
//request.position =position_ticket;          // ticket of the position
  request.symbol   =Symbol();          // symbol
  request.volume   =lots;                   // volume of the position
  request.deviation=slip_point;                        // allowed deviation from the price
  request.magic    =input_magic;             // MagicNumber of the position
  request.price=order_price;
//request.price=MA_S_Line[1];
  request.type =ORDER_TYPE_BUY;
//request.type =ORDER_TYPE_SELL_LIMIT;
//request.sl =0;
//request.type_filling = ORDER_FILLING_RETURN;
  request.type_filling = ORDER_FILLING_FOK;
  request.type_filling = ORDER_FILLING_IOC;

  OrderSend(request,result);

  return 0;
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
int MarketSell(void)
{

// if(OrderSend(NULL, OP_BUY, lots, order_price, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){

  ZeroMemory(request);
  ZeroMemory(result);

  switch(tp_type) {
  case 0:
    request.tp =0;
    break;
  case 1:
    request.tp =NormalizeDouble(order_price*(1-tp_ratio), Digits());
    break;
  case 2:
    request.tp =NormalizeDouble(order_price-ATRbuf[1]*ATR_tp_factor, Digits());
    break;
  default:
    request.tp =0;
    break;
  }

  switch(sl_type) {
  case 0:
    request.sl =0;
    break;
  case 1:
    request.sl =NormalizeDouble(order_price*(1+sl_ratio), Digits());
    break;
  case 2:
    request.sl =NormalizeDouble(order_price+ATRbuf[1]*ATR_sl_factor, Digits());
    break;
  default:
    request.sl =0;
    break;
  }

  //Print("tpsl01,order_price,ATRbuf[1],ATR_tp_factor,ATR_sl_factor="+request.tp+" : "+request.sl+" : "+ order_price +" : "+ ATRbuf[1] +" : "+ATR_tp_factor+" : "+ATR_sl_factor);
  //Print("tpsl01,order_price,ATRbuf[1]="+request.tp+" : "+request.sl+" : "+order_price+" : "+ATRbuf[1]);

  request.action   =TRADE_ACTION_DEAL;        // type of trade operation
//request.action   =TRADE_ACTION_PENDING;        // type of trade operation
//request.position =position_ticket;          // ticket of the position
  request.symbol   =Symbol();          // symbol
  request.volume   =lots;                   // volume of the position
  request.deviation=slip_point;                        // allowed deviation from the price
  request.magic    =input_magic;             // MagicNumber of the position
  request.price=order_price;
//request.price=MA_S_Line[1];
  request.type =ORDER_TYPE_SELL;
//request.type =ORDER_TYPE_SELL_LIMIT;
//request.sl =0;
//request.type_filling = ORDER_FILLING_RETURN;
  request.type_filling = ORDER_FILLING_FOK;
  request.type_filling = ORDER_FILLING_IOC;

  OrderSend(request,result);

  return 0;
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
int CloseLongMQL5(void)
{

  int positions_total = PositionsTotal();
// if(OrderSend(NULL, OP_BUY, lots, order_price, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){
  for(int i = positions_total -1 ; 0 <= i ; i--) {
    ulong ticket = PositionGetTicket(i);
    int position_type = PositionGetInteger(POSITION_TYPE);

    if(position_type == POSITION_TYPE_SELL) {
      continue;
    }
    ZeroMemory(request);
    ZeroMemory(result);
    request.action   =TRADE_ACTION_DEAL;        // type of trade operation
    //request.action   =TRADE_ACTION_PENDING;        // type of trade operation
    //request.position =position_ticket;          // ticket of the position
    request.symbol   =Symbol();          // symbol
    request.volume   =lots;                   // volume of the position
    request.deviation=slip_point;                        // allowed deviation from the price
    request.magic    =input_magic;             // MagicNumber of the position
    request.price=order_price;
    //request.price=MA_S_Line[1];
    request.type =ORDER_TYPE_SELL;
    //request.type =ORDER_TYPE_SELL_LIMIT;
    request.sl =0;
    //request.type_filling = ORDER_FILLING_RETURN;
    //request.type_filling = ORDER_FILLING_FOK;
    request.type_filling = ORDER_FILLING_IOC;
    request.tp =0;

    OrderSend(request,result);
  }
//PositionSelectByTicket(ticket);


  return 0;
}
//+------------------------------------------------------------------+
int CloseShortMQL5(void)
{

  int positions_total = PositionsTotal();
// if(OrderSend(NULL, OP_BUY, lots, order_price, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){
  for(int i = positions_total -1 ; 0 <= i ; i--) {
    ulong ticket = PositionGetTicket(i);
    int position_type = PositionGetInteger(POSITION_TYPE);
    if(position_type == POSITION_TYPE_BUY) {
      continue;
    }
    ZeroMemory(request);
    ZeroMemory(result);
    request.action   =TRADE_ACTION_DEAL;        // type of trade operation
    //request.action   =TRADE_ACTION_PENDING;        // type of trade operation
    //request.position =position_ticket;          // ticket of the position
    request.symbol   =Symbol();          // symbol
    request.volume   =lots;                   // volume of the position
    request.deviation=slip_point;                        // allowed deviation from the price
    request.magic    =input_magic;             // MagicNumber of the position
    request.price=order_price;
    //request.price=MA_S_Line[1];
    request.type =ORDER_TYPE_BUY;
    //request.type =ORDER_TYPE_SELL_LIMIT;
    request.sl =0;
    //request.type_filling = ORDER_FILLING_RETURN;
    //request.type_filling = ORDER_FILLING_FOK;
    request.type_filling = ORDER_FILLING_IOC;
    request.tp =0;

    OrderSend(request,result);
  }
//PositionSelectByTicket(ticket);


  return 0;
}
//+------------------------------------------------------------------+
void SetTPSL(void)
{
  int total=PositionsTotal(); // number of open positions
//--- iterate over all open positions
  for(int i=total-1; 0 <= i; i--) {
    //--- parameters of the order
    ulong  position_ticket=PositionGetTicket(i);// ticket of the position
    PositionSelectByTicket(position_ticket);
    string position_symbol=PositionGetString(POSITION_SYMBOL); // symbol
    int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS); // number of decimal places
    ulong  magic_local=PositionGetInteger(POSITION_MAGIC); // MagicNumber of the position
    double volume=PositionGetDouble(POSITION_VOLUME);    // volume of the position
    double sl=PositionGetDouble(POSITION_SL);  // Stop Loss of the position
    double tp=PositionGetDouble(POSITION_TP);  // Take Profit of the position
    double op=PositionGetDouble(POSITION_PRICE_OPEN);  // Take Profit of the position
    ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // type of the position

    if(0==sl || 0==tp) {

      //if(position_symbol != Symbol() || magic != in_Magic){
      //  continue;
      //}
      ZeroMemory(request);
      ZeroMemory(result);

      request.action   =TRADE_ACTION_SLTP;        // type of trade operation
      request.position =position_ticket;          // ticket of the position
      request.symbol   =position_symbol;          // symbol
      request.volume   =volume;                   // volume of the position
      request.deviation=slip_point;
      request.magic    =magic_local;             // MagicNumber of the position
      request.price=op;

      if(type==POSITION_TYPE_BUY) {
        switch(tp_type) {
        case -1:
          request.tp =0;
          break;
        case 0:
          request.tp =0;
          break;
        case 1:
          request.tp =NormalizeDouble(op*(1+tp_ratio), Digits());
          break;
        case 2:
          request.tp =NormalizeDouble(op+ATRbuf[1]*ATR_tp_factor, Digits());
          break;
        default:
          break;
        }

        switch(sl_type) {
        case 0:
          request.sl =0;
          break;
        case 1:
          request.sl =NormalizeDouble(op*(1-sl_ratio), Digits());
          break;
        case 2:
          request.sl =NormalizeDouble(op-ATRbuf[1]*ATR_sl_factor, Digits());
          break;
        default:
          request.sl =0;
          break;
        }

        //--- modify order and exit
        request.type = ORDER_TYPE_SELL;
        //request.sl =NormalizeDouble(Bid-Bid*TrailingStopRatio, _Digits);
        //request.tp =tp;
      } else if(type==POSITION_TYPE_SELL) {
        switch(tp_type) {
        case -1:
          request.tp =0;
          break;
        case 0:
          request.tp =0;
          break;
        case 1:
          request.tp =NormalizeDouble(op*(1-tp_ratio), Digits());
          break;
        case 2:
          request.sl =NormalizeDouble(op+ATRbuf[1]*ATR_tp_factor, Digits());
          break;
        default:
          request.tp =0;
          break;
        }

        switch(sl_type) {
        case 0:
          request.sl =0;
          break;
        case 1:
          request.sl =NormalizeDouble(op*(1+sl_ratio), Digits());
          break;
        case 2:
          request.sl =NormalizeDouble(op+ATRbuf[1]*ATR_sl_factor, Digits());
          break;
        default:
          request.sl =0;
          break;
        }

        request.type =ORDER_TYPE_BUY;
      }

      //Print("set tpsl,op,atr1,ATR_sl_factor="+request.tp+" : "+request.sl+" : "+op+" : "+ATRbuf[1]+" : "+ATR_sl_factor);

      if(Point() < MathAbs(request.sl - sl) || Point() < MathAbs(request.tp - tp)) {
        if(!OrderSend(request,result)) {
          PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
          //--- information about the operation
          PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
        }
      }
    }
  }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CheckTrailRatio()
{

  iLongCount=0;
  iShortCount=0;

//bBuyPos=false;
//bSellPos=false;
  int total=PositionsTotal(); // number of open positions
//--- iterate over all open positions
  for(int i=total-1; 0 <= i; i--) {
    //--- parameters of the order
    ulong  position_ticket=PositionGetTicket(i);// ticket of the position
    PositionSelectByTicket(position_ticket);
    string position_symbol=PositionGetString(POSITION_SYMBOL); // symbol
    int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS); // number of decimal places
    ulong  magic=PositionGetInteger(POSITION_MAGIC); // MagicNumber of the position
    double volume=PositionGetDouble(POSITION_VOLUME);    // volume of the position
    double sl=PositionGetDouble(POSITION_SL);  // Stop Loss of the position
    double tp=PositionGetDouble(POSITION_TP);  // Take Profit of the position
    double op=PositionGetDouble(POSITION_PRICE_OPEN);  // Take Profit of the position
    ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // type of the position

    //if(position_symbol != Symbol() || magic != in_Magic){
    //  continue;
    //}

    if(0<TrailingStopPoint)      {
      ZeroMemory(request);
      ZeroMemory(result);
      double Bid=SymbolInfoDouble(position_symbol,SYMBOL_BID);
      double Ask=SymbolInfoDouble(position_symbol,SYMBOL_ASK);

      Bid = iClose(NULL, PERIOD_CURRENT, 0);
      Ask = iClose(NULL, PERIOD_CURRENT, 0);

      if(type==POSITION_TYPE_BUY)     {
        //Print ("trail buy check");
        if(op*TrailingStop_StartRatio < Bid-op) {
          //Print ("trail buy check2");
          if(sl < Bid-Bid*TrailingStopRatio)            {
            //Print ("trail buy check3");
            //--- modify order and exit
            request.action   =TRADE_ACTION_SLTP;        // type of trade operation
            request.position =position_ticket;          // ticket of the position
            request.symbol   =position_symbol;          // symbol
            request.volume   =volume;                   // volume of the position
            request.deviation=slip_point;
            request.magic    =magic;             // MagicNumber of the position
            request.price=op;
            request.type =ORDER_TYPE_SELL;
            request.sl = NormalizeDouble(Bid-Bid*TrailingStopRatio, _Digits);
            //Print ("0 sl, Bid-Bid*TrailingStopRatio="+sl+"  :  "+(Bid-Bid*TrailingStopRatio));
            request.tp = tp;
            if(Point() < MathAbs(request.sl - sl) || Point() < MathAbs(request.tp - tp)) {
              //Print ("1 sl, Bid-Bid*TrailingStopRatio="+sl+"  :  "+(Bid-Bid*TrailingStopRatio));
              if(!OrderSend(request,result)) {
                PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
                //--- information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
              }
            }
            iLongCount++;
            //bBuyPos=true;
          }
        }
      } else if(type==POSITION_TYPE_SELL) {
        //Print ("trail sell check");
        if(op-Ask>op*TrailingStop_StartRatio)         {
          //Print ("trail sell check2");
          if(sl>(Ask+Ask*TrailingStopRatio) || sl==0)            {
            //--- modify order and exit
            //Print ("trail sell check3");
            request.action   =TRADE_ACTION_SLTP;        // type of trade operation
            request.position =position_ticket;          // ticket of the position
            request.symbol   =position_symbol;          // symbol
            request.volume   =volume;                   // volume of the position
            request.deviation=slip_point;
            request.magic    =magic;             // MagicNumber of the position
            request.price=op;
            request.type = ORDER_TYPE_BUY;
            request.sl =NormalizeDouble(Ask+Ask*TrailingStopRatio, _Digits);
            request.tp =tp;
            if(Point() < MathAbs(request.sl - sl) || Point() < MathAbs(request.tp - tp)) {
              if(!OrderSend(request,result)) {
                PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
                //--- information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
              }
            }
            iShortCount++;
            //bSellPos=true;
          }
        }
      }
    }
  }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CheckTrailATR()
{

  iLongCount=0;
  iShortCount=0;

//bBuyPos=false;
//bSellPos=false;
  int total=PositionsTotal(); // number of open positions
//--- iterate over all open positions
  for(int i=total-1; 0 <= i; i--) {
    //--- parameters of the order
    ulong  position_ticket=PositionGetTicket(i);// ticket of the position
    PositionSelectByTicket(position_ticket);
    string position_symbol=PositionGetString(POSITION_SYMBOL); // symbol
    int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS); // number of decimal places
    ulong  magic=PositionGetInteger(POSITION_MAGIC); // MagicNumber of the position
    double volume=PositionGetDouble(POSITION_VOLUME);    // volume of the position
    double sl=PositionGetDouble(POSITION_SL);  // Stop Loss of the position
    double tp=PositionGetDouble(POSITION_TP);  // Take Profit of the position
    double op=PositionGetDouble(POSITION_PRICE_OPEN);  // Take Profit of the position
    ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // type of the position

    //if(position_symbol != Symbol() || magic != in_Magic){
    //  continue;
    //}

    if(0<ATR_trail_sl_factor)      {
      //Print("atr trail");
      ZeroMemory(request);
      ZeroMemory(result);
      double Bid=SymbolInfoDouble(position_symbol,SYMBOL_BID);
      double Ask=SymbolInfoDouble(position_symbol,SYMBOL_ASK);

      Bid = iClose(NULL, PERIOD_CURRENT, 0);
      Ask = iClose(NULL, PERIOD_CURRENT, 0);

      if(type==POSITION_TYPE_BUY)     {
        //Print ("trail buy check");
        //Print("atr trail 001");
        //Print("op, atr*factor,bid="+op+" : "+(ATRbuf[1]*ATR_trail_start_factor)+" : "+Bid  +" : "+  (ATRbuf[1]*ATR_trail_start_factor)  +" : "+  (Bid-op));

        if(ATRbuf[1]*ATR_trail_start_factor < Bid-op) {
          //Print ("trail buy check2");
          if(sl < Bid-ATRbuf[1]*ATR_trail_sl_factor)            {
            //Print ("trail buy check3");
            //--- modify order and exit
            request.action   =TRADE_ACTION_SLTP;        // type of trade operation
            request.position =position_ticket;          // ticket of the position
            request.symbol   =position_symbol;          // symbol
            request.volume   =volume;                   // volume of the position
            request.deviation=slip_point;
            request.magic    =magic;             // MagicNumber of the position
            request.price=op;
            request.type =ORDER_TYPE_SELL;
            request.sl = NormalizeDouble(Bid-ATRbuf[1]*ATR_trail_sl_factor, _Digits);
            //Print ("0 sl, Bid-Bid*TrailingStopRatio="+sl+"  :  "+(Bid-Bid*TrailingStopRatio));
            request.tp = tp;
            if(Point() < MathAbs(request.sl - sl) || Point() < MathAbs(request.tp - tp)) {
              //Print ("1 sl, Bid-Bid*TrailingStopRatio="+sl+"  :  "+(Bid-Bid*TrailingStopRatio));
              if(!OrderSend(request,result)) {
                PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
                //--- information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
              }
            }
            iLongCount++;
            //bBuyPos=true;
          }
        }
      } else if(type==POSITION_TYPE_SELL) {
        //Print ("trail sell check");
        //Print("atr trail 002");
        //Print("op, atr*factor,ask="+op+" : "+ATRbuf[1]*ATR_trail_start_factor+" : "+Ask   +" : "+  (op-ATRbuf[1]*ATR_trail_start_factor)  +" : "+  (op-Ask)    );

        if(op-Ask>ATRbuf[1]*ATR_trail_start_factor)         {
          //Print ("trail sell check2");
          if(sl>(Ask+ATRbuf[1]*ATR_trail_sl_factor) || sl==0)            {
            //--- modify order and exit
            //Print ("trail sell check3");
            request.action   =TRADE_ACTION_SLTP;        // type of trade operation
            request.position =position_ticket;          // ticket of the position
            request.symbol   =position_symbol;          // symbol
            request.volume   =volume;                   // volume of the position
            request.deviation=slip_point;
            request.magic    =magic;             // MagicNumber of the position
            request.price=op;
            request.type = ORDER_TYPE_BUY;
            request.sl =NormalizeDouble(Ask+ATRbuf[1]*ATR_trail_sl_factor, _Digits);
            request.tp =tp;
            if(Point() < MathAbs(request.sl - sl) || Point() < MathAbs(request.tp - tp)) {
              if(!OrderSend(request,result)) {
                PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
                //--- information about the operation
                PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
              }
            }
            iShortCount++;
            //bSellPos=true;
          }
        }
      }
    }
  }
}
//+------------------------------------------------------------------+
void CheckWinLoseHistorySort()
{
// [0]=date, [1]=ticket
  WinLoseHist WinLoseHistArray[];

// receive history for the last 180 days
  HistorySelect(iTime(NULL, PERIOD_CURRENT, 0)-3600*24*180, iTime(NULL, PERIOD_CURRENT, 0));
  int total_HistoryDeals = HistoryDealsTotal();
  //Print("total_HistoryDeals="+total_HistoryDeals);

  ArrayResize(WinLoseHistArray, total_HistoryDeals*sizeof(WinLoseHist));
  int contiguous_lose = 0;
  int last_result=0;
  
  for(int i_hist = total_HistoryDeals - 1 ; 0 <= i_hist ; i_hist--) {
    WinLoseHistArray[i_hist].ticket_num = HistoryDealGetTicket(i_hist);
    HistoryDealSelect(WinLoseHistArray[i_hist].ticket_num);
    WinLoseHistArray[i_hist].dt=(datetime)HistoryDealGetInteger(WinLoseHistArray[i_hist].ticket_num,DEAL_TIME);
    double d_profit = HistoryDealGetDouble(WinLoseHistArray[i_hist].ticket_num, DEAL_PROFIT);
    if(0<d_profit) {
      WinLoseHistArray[i_hist].WinPlus_Even0_LoseMinus = 1;
      if(last_result==0) {
        last_result=1;
        last_ticket=WinLoseHistArray[i_hist].ticket_num;
      }
      break;
    } else if(d_profit<0) {
      WinLoseHistArray[i_hist].WinPlus_Even0_LoseMinus = -1;
      contiguous_lose++;
      if(last_result==0) {
        last_result=-1;
        last_ticket=WinLoseHistArray[i_hist].ticket_num;
      }
    } else {
      WinLoseHistArray[i_hist].WinPlus_Even0_LoseMinus = 0;
    }
    //Print("WinLoseHistArray dt WL="+WinLoseHistArray[i_hist].dt+" : "+WinLoseHistArray[i_hist].WinPlus_Even0_LoseMinus);
  }
  //Print("lastticket, contiguous_lose,last_result="+last_ticket+" : "+contiguous_lose+" : "+last_result);
//input double d_Alembert_1st_risk=2.0;
//input double d_Alembert_risk_diff=0.2;
  //Print("contiguous_lose="+contiguous_lose);
  if(0<last_result && prev_ticket != last_ticket) {
    riskpercent_d_Alembert -= d_Alembert_risk_diff;
    prev_ticket = last_ticket;
  } else if(last_result<0 && prev_ticket != last_ticket) {
    riskpercent_d_Alembert += d_Alembert_risk_diff;
    prev_ticket = last_ticket;
  }
  //Print("riskpercent_d_Alembert0="+riskpercent_d_Alembert);
  if(riskpercent_d_Alembert < d_Alembert_1st_risk) riskpercent_d_Alembert = d_Alembert_1st_risk;
  //Print("riskpercent_d_Alembert1="+riskpercent_d_Alembert);
  if(riskpercent_d_Alembert_max < riskpercent_d_Alembert) riskpercent_d_Alembert_max = riskpercent_d_Alembert;
  //Print("riskpercent_d_Alembert_max="+  riskpercent_d_Alembert_max);

}
//+------------------------------------------------------------------+
