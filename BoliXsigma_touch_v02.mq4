//+------------------------------------------------------------------+
//|                                        BoliXsigma_toutch_v02.mq4 |
//|                                          Copyright 2022, ttss000 |
//|                                      https://twitter.com/ttss000 |
//+------------------------------------------------------------------+
// suppose M5 chart

#property copyright "Copyright 2022, ttss000"
#property link      "https://twitter.com/ttss000"
#property version   "02" //2022/5/23
#property strict
//--- input parameters

//---- indicator parameters
input double input_lots = 0.1;
input int ma_bars = 75;
extern int BobaPeriod= 20;
extern double BobaDeviations= 3;
extern bool Use_Sound=true;
extern int from_minute=55;
extern int to_minute=59;
extern double pinbar_ratio=0.25;
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
extern string aaa1 ="shikin kanri";
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

int i,j,slippage=3;
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

struct MqlTradeRequest {
  int action;
  string symbol;
  double volume;
  double price;
  double deviation;
  double sl;
  double tp;
  int magic;
  int type;
  int position;
  int order;
};

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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//--- create timer
  EventSetTimer(1);


//---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- destroy timer
  //int obj_total = ObjectsTotal(0, -1, -1);
  EventKillTimer();
  //for(int obj_i = obj_total ; 0<=obj_i ; i--){
  //  string obj_name = ObjectName(obj_i);
  //  if(OBJ_RECTANGLE==ObjectType(obj_name)){
    //  string name_head = StringSubstr(obj_name, 0, StringLen("test_vline"));
  //    if(0<=StringFind(obj_name, strEAname, 0)){
  //      ObjectDelete(0, obj_name);
  //    }
  //  }
  //}
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
  double band1, band2;
  double rsi_current;
  double ma, ma200, ma200_1;

  band1= iBands(NULL,PERIOD_CURRENT, BobaPeriod, BobaDeviations, 0, PRICE_CLOSE, MODE_UPPER, 0);
  ma = iMA(NULL, PERIOD_CURRENT, BobaPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
  ma200 = iMA(NULL, PERIOD_CURRENT, ma_bars, 0, MODE_SMA, PRICE_CLOSE, 0);
  ma200_1 = iMA(NULL, PERIOD_CURRENT, ma_bars, 0, MODE_SMA, PRICE_CLOSE, 1);
  band2= iBands(NULL,PERIOD_CURRENT, BobaPeriod, BobaDeviations, 0, PRICE_CLOSE, MODE_LOWER, 0);
  //rsi_current = iRSI(NULL, PERIOD_CURRENT, 14, PRICE_CLOSE, 0);
  rsi_current = 50;
  buy_flag=false;
  sell_flag=false;
  // buy new condition
  if(iLongCount==0){
    if(band1 < Close[0] && rsi_upper_thresh < rsi_current && from_minute<=TimeMinute(Time[0]) && TimeMinute(Time[0])<=to_minute && ma200 < Close[0] && ma200_1 < ma200 ) buy_flag=true;
    if(Close[0] < band2 && rsi_lower_thresh < rsi_current && from_minute<=TimeMinute(Time[0]) && TimeMinute(Time[0])<=to_minute && ma200 < Close[0] && ma200_1 < ma200 ) buy_flag=true;
  }     

  // sell new condition
  if(iShortCount==0){
    if(Close[0] < band2 && rsi_current < rsi_lower_thresh && from_minute<=TimeMinute(Time[0]) && TimeMinute(Time[0])<=to_minute && ma200 > Close[0] && ma200_1 > ma200 ) sell_flag=true;  // junbari
    if(band1 < Close[0] && rsi_current < rsi_upper_thresh && from_minute<=TimeMinute(Time[0]) && TimeMinute(Time[0])<=to_minute && ma200 > Close[0] && ma200_1 > ma200 ) sell_flag=true;  // gyaku bari
  }     
  lots=0.01;
  if(buy_flag){
    dtLastLong = Time[0];
    if(OrderSend(NULL, OP_BUY, lots, Ask, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){
      
    }
  }

  if(sell_flag){
    dtLastShort = Time[0];
    if(OrderSend(NULL, OP_SELL, lots, Bid, slip_point, 0, 0, NULL, magic, 0, clrNONE)<0){
      
    }
  }

  CheckPositions();
  // check sell close
  if(0<iShortCount && Close[0] < ma && ma < Close[1] && dtLastShort != Time[0]){
    CloseShort();
    dtLastShort = 0;  
  }else if(0<iShortCount && Close[1] < ma && ma < Close[0] && dtLastShort != Time[0]){
    CloseShort();  
    dtLastShort = 0;  
  }
  if(0<iLongCount &&  Close[0] < ma && ma < Close[1] && dtLastLong != Time[0]){
    CloseLong();
    dtLastLong = 0;  
  }else if(0<iLongCount &&  Close[1] < ma && ma < Close[0] && dtLastLong != Time[0]){
    CloseLong();
    dtLastLong = 0;  
  }
  CheckPositions();
}
//+------------------------------------------------------------------+
void CheckPositions(void)
{

  iLongCount=0;
  iShortCount=0;

  int orders_total = OrdersTotal();
  for(int i = orders_total -1 ; 0 <= i ; i--){
    if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
      if(OrderType() == OP_BUY){
        iLongCount++;
      }else if(OrderType() == OP_SELL){
        iShortCount++;
      }
    }
  }
}
//+------------------------------------------------------------------+
void CloseLong(void)
{
  int orders_total = OrdersTotal();
  for(int i = orders_total -1 ; 0 <= i ; i--){
    if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
      if(OrderType() == OP_BUY){
        OrderClose(OrderTicket(), lots, Bid, slip_point, clrNONE);
      }
    }
  }
}
//+------------------------------------------------------------------+
void CloseShort(void)
{
  int orders_total = OrdersTotal();
  for(int i = orders_total -1 ; 0 <= i ; i--){
    if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
      if(OrderType() == OP_SELL){
        OrderClose(OrderTicket(), lots, Ask, slip_point, clrNONE);
      }
    }
  }
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---
  //ForPastRoutine2();
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
//+------------------------------------------------------------------+
void ForPastRoutine2(void)
{
  //CheckPastCondition2();
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LinearRegressionValue(int Len,int shift)
{
  double SumBars = 0;
  double SumSqrBars = 0;
  double SumY = 0;
  double Sum1 = 0;
  double Sum2 = 0;
  double Slope = 0;
  SumBars = Len * (Len-1) * 0.5;
  SumSqrBars = (Len - 1) * Len * (2 * Len - 1)/6;
  for(int x=0; x<=Len-1; x++) {
    double HH = Low[x+shift];
    double LL = High[x+shift];
    for(int y=x; y<=(x+Len)-1; y++) {
      if(y+shift < Bars){
        HH = MathMax(HH, High[y+shift]);
        LL = MathMin(LL, Low[y+shift]);
      }else{
        HH = 0;
        LL = 0;
      }
    }
    Sum1 += x* (Close[x+shift]-((HH+LL)/2 + iMA(NULL,0,Len,0,MODE_EMA,PRICE_CLOSE,x+shift))/2);
    SumY += (Close[x+shift]-((HH+LL)/2 + iMA(NULL,0,Len,0,MODE_EMA,PRICE_CLOSE,x+shift))/2);
  }
  Sum2 = SumBars * SumY;
  double Num1 = Len * Sum1 - Sum2;
  double Num2 = SumBars * SumBars-Len * SumSqrBars;
  if(Num2 != 0.0) {
    Slope = Num1/Num2;
  } else {
    Slope = 0;
  }
  double Intercept = (SumY - Slope*SumBars) /Len;
//debugPrintln(Intercept+" : "+Slope);
  double LinearRegValue = Intercept+Slope * (Len - 1);
  return (LinearRegValue);
}
//+------------------------------------------------------------------+
bool NewBar()
{
  static datetime dt = 0;
  if(dt != Time[0]) {
    dt = Time[0];
    //Sleep(100); // wait for tick
    return(true);
  }
  return(false);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// >>---------<< サマータイム関数 >>--------------------------------------------------------------------<<
// copy right takulogu san
// http://fxbo.takulogu.com/mql4/backtest/summertime/
int Summerflag(int shift){ // TimeFlag と summer はグローバル関数
 int B=0;
 int CanM = (int)TimeMonth(iTime(NULL,0,shift)); //月取得
 int CanD = (int)TimeDay(iTime(NULL,0,shift)); //日取得
 int CanW = (int)TimeDayOfWeek(iTime(NULL,0,shift));//曜日取得
 if(TimeFlag!=CanD){ //>>日が変わった際に計算
  if(CanM>=3&&CanM<=11){ //------------------------------------------- 3月から11月範囲計算開始
   if(CanM==3){ //------------------------------------------- 3月の計算（月曜日が○日だったら夏時間）
    if(CanD<=8) { summer = false;}
    if(CanD==9) { if(CanW==1){summer = true;}else{summer = false;} }// 9日の月曜日が第3月曜日の最小日（第2日曜の最小が8日の為）
    if(CanD==10){ if(CanW<=2){summer = true;}else{summer = false;} }// 10日が火曜以下であれば,第3月曜日を迎えた週
    if(CanD==11){ if(CanW<=3){summer = true;}else{summer = false;} }// 11日が水曜以下であれば,第3月曜日を迎えた週
    if(CanD==12){ if(CanW<=4){summer = true;}else{summer = false;} }// 12日が木曜以下であれば,第3月曜日を迎えた週
    if(CanD>=13){ summer = true; } // 13日以降は上の条件のいずれかが必ず満たされる
   }
   if(CanM==11){ //------------------------------------------ 11月の計算（月曜日が○日だったら冬時間）
    if(CanD==1){ summer = true; }
    if(CanD==2){ if(CanW==1){summer = false;}else{summer = true;} }// 2日の月曜日が第2月曜日の最小日（第1日曜の最小が1日の為）
    if(CanD==3){ if(CanW<=2){summer = false;}else{summer = true;} }// 3日が火曜以下であれば,第2月曜日を迎えた週
    if(CanD==4){ if(CanW<=3){summer = false;}else{summer = true;} }// 4日が水曜以下であれば,第2月曜日を迎えた週
    if(CanD==5){ if(CanW<=4){summer = false;}else{summer = true;} }// 5日が木曜以下であれば,第2月曜日を迎えた週
    if(CanD==6){ if(CanW<=5){summer = false;}else{summer = true;} }// 6日が金曜以下であれば,第2月曜日を迎えた週
    if(CanD>=7){ summer = false; } // 7日以降が何曜日に来ても第2月曜日を迎えている(7日が日なら迎えていないが8日で迎える)
   }
  if(CanM!=3&&CanM!=11)summer = true;//　4月~10月は無条件で夏時間
  } //--------------------------------------------------------------- 3月から11月範囲計算終了
  else{summer = false;}//12月~2月は無条件で冬時間
  TimeFlag=CanD;
  } if(summer == true){B=0;}else{B=1;}
 return(B);
}
//+------------------------------------------------------------------+
void DeletePendingOrder(void)
{
  //int res;
  //ulong ticket;
  for(int i2 = OrdersTotal()-1 ; i2 >= 0 ; i2--){
    if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
      int type = OrderType();
      if(type == OP_BUY || type==OP_SELL || OrderSymbol() != Symbol() || OrderMagicNumber() != magic){
        continue;
      }

      request.order=OrderTicket();   // ticket of the position
      request.symbol=_Symbol;     // symbol 
      request.volume=OrderLots();
      request.magic=magic;         // MagicNumber of the position
      OrderDelete(request.order, clrNONE);
    }
  }
}
//+------------------------------------------------------------------+
// upk iCustom(NULL, 0, "bbsqueeze w Alert nmc", 2,
// lok iCustom(NULL, 0, "bbsqueeze w Alert nmc", 3,
void CheckLatestCondition2(void)
{
  //check squeeze
  bool bFoundSqueeze=false;
  bool bFoundNonSqueeze2=false;
  int SqueezeLen=0;
  int idx_start=-1, idx_end=-1;

  int shift_highest=0;
  int shift_lowest=0;
  if(iCustom(NULL, 0, "bbsqueeze w Alert nmc", 3, 1)==0){  // murasaki
    //Print ("loK[1]==0");
    for(int idx=2 ; idx<Bars ; idx++){
      // check length of squeeze
      if( !bFoundSqueeze && iCustom(NULL, 0, "bbsqueeze w Alert nmc", 2,idx)==0 ){
        bFoundSqueeze=true;
        idx_start=idx;
      }
      if(bFoundSqueeze && iCustom(NULL, 0, "bbsqueeze w Alert nmc", 3,idx)==0){
        bFoundNonSqueeze2=true;
        idx_end=idx-1;
      }
      if(bFoundSqueeze && !bFoundNonSqueeze2){
        SqueezeLen++;
      }
      if(bFoundSqueeze && bFoundNonSqueeze2){
        break;
      }
    }  // for
    //Print("SqueezeLen="+SqueezeLen);
    if(NumHolizontal<=SqueezeLen){
      // check short condition
      shift_lowest = iLowest(NULL, 0, MODE_LOW, idx_end-idx_start+1, idx_start);
      lowest = iLow(NULL, 0, shift_lowest);
      shift_highest = iHighest(NULL, 0, MODE_HIGH, idx_end-idx_start+1, idx_start);
      highest = iHigh(NULL, 0, shift_highest);
      if(iMA(NULL, 0, MA1_Bars, 0, MODE_SMA, PRICE_CLOSE, 1) > iMA(NULL, 0, MA1_Bars, 0, MODE_SMA, PRICE_CLOSE, 0)
        && iMA(NULL, 0, MA2_Bars, 0, MODE_SMA, PRICE_CLOSE, 1) > iMA(NULL, 0, MA2_Bars, 0, MODE_SMA, PRICE_CLOSE, 0)
        && Close[0] < iMA(NULL, 0, MA1_Bars, 0, MODE_SMA, PRICE_CLOSE, 0)
        && Close[0] < iMA(NULL, 0, MA2_Bars, 0, MODE_SMA, PRICE_CLOSE, 0)
          ){
        //Print("short cond 1");
        if(lowest < Close[0]){
          // if no short position, and if no short order placed, then place short order
          //Print("short cond 2");
          //Print("idx_start="+idx_start);
          //Print("dtLastShort="+dtLastShort);
          if(iTime(NULL, 0, idx_start) != dtLastShort){
            PlaceOrModifyShortOrder(lowest, highest);
            dtLastShort = iTime(NULL, 0, idx_start); 
          }
          
        }
      }
      // check long condition
      if(iMA(NULL, 0, MA1_Bars, 0, MODE_SMA, PRICE_CLOSE, 1) < iMA(NULL, 0, MA1_Bars, 0, MODE_SMA, PRICE_CLOSE, 0)
        && iMA(NULL, 0, MA2_Bars, 0, MODE_SMA, PRICE_CLOSE, 1) < iMA(NULL, 0, MA2_Bars, 0, MODE_SMA, PRICE_CLOSE, 0)
        && Close[0] > iMA(NULL, 0, MA1_Bars, 0, MODE_SMA, PRICE_CLOSE, 0)
        && Close[0] > iMA(NULL, 0, MA2_Bars, 0, MODE_SMA, PRICE_CLOSE, 0)
          ){
        //Print("long cond 1");
        if(highest > Close[0]){
          // if no long position, and if no long order placed, then place long order
          //Print("long cond 2");
          //Print("idx_start="+idx_start);
          //Print("dtLastLong="+dtLastLong);
          if(iTime(NULL, 0, idx_start) != dtLastLong){
            PlaceOrModifyLongOrder(lowest, highest);
            dtLastLong = iTime(NULL, 0, idx_start); 
          }
        }
      }
    }
  }else{
    //Print ("loK[1]== NOT 0");
    DeletePendingOrder();
  }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void PlaceOrModifyShortOrder(double lowest_local, double highest_local)
{
  bool bFoundShortPending=false;
  bool bFoundShortPos=false;
  double sl_local;

  int orders_total = OrdersTotal();

  bFoundShortPending=false;
  bFoundShortPos=false;

  iShortCount=0;
  double TP_BB_Price = iBands(NULL, 0, 20, TP_BB, 0, PRICE_CLOSE, MODE_LOWER, 0); 
  for (int order_idx = orders_total-1 ; 0<=order_idx ; order_idx--){
    OrderSelect(order_idx, SELECT_BY_POS, MODE_TRADES);
    if(OrderType() == OP_SELL){
      iShortCount++;
      bFoundShortPos = true;
      if(OrderTakeProfit() < TP_BB_Price){
        OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), TP_BB_Price, 0, clrNONE);
      }
    }
    if(OrderType() == OP_SELLSTOP){
      bFoundShortPending = true;
    }
  }
  //if((!bFoundShortPending) && (!bFoundShortPos)){
  if((!bFoundShortPending) && iShortCount <= iLongCount){
    //Print("short cond 3");
    double takeprofit = TP_BB_Price;
    if(TP_BB_Price<lowest_local-2*(highest_local-lowest_local)){
      takeprofit=lowest_local-2*(highest_local-lowest_local);
    }
    calc_lots(highest_local-lowest_local);
    //Print("lots="+lots);
    //lots=0.01;
    sl_local=0;
    if(bUseSL){
      sl_local=highest_local;
    }
    if( (lowest_local - takeprofit) / Point() < 30){takeprofit=lowest_local-30*Point();}
    if(OrderSend(NULL, OP_SELLSTOP, lots, lowest_local, 3, sl_local, takeprofit, NULL, magic, 0, clrNONE)<0){
      if(OrderSend(NULL, OP_SELLLIMIT, lots, lowest_local, 3, sl_local, takeprofit, NULL, magic, 0, clrNONE)<0){
      }
    }
  }
}
//+------------------------------------------------------------------+
void PlaceOrModifyLongOrder(double lowest_local, double highest_local)
{
  bool bFoundLongPending=false;
  bool bFoundLongPos=false;
  double sl_local;

  int orders_total = OrdersTotal();

  bFoundLongPending=false;
  bFoundLongPos=false;

  //Print ("orders_total="+orders_total);
  //Print ("bFoundLongPos before="+bFoundLongPos);
  iLongCount=0;
  double TP_BB_Price = iBands(NULL, 0, 20, TP_BB, 0, PRICE_CLOSE, MODE_UPPER, 0); 
  for (int order_idx = orders_total-1 ; 0<=order_idx ; order_idx--){
    OrderSelect(order_idx, SELECT_BY_POS, MODE_TRADES);
    if(OrderType() == OP_BUY){
      iLongCount++;
      bFoundLongPos = true;
      if(OrderTakeProfit() > TP_BB_Price){
        OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), TP_BB_Price, 0, clrNONE);
      }
    }
    if(OrderType() == OP_BUYSTOP){
      bFoundLongPending = true;
    }
  }
  //Print ("bFoundLongPending="+bFoundLongPending);
  //Print ("bFoundLongPos after="+bFoundLongPos);
  //if(bFoundLongPending==false && bFoundLongPos==false){
  if(bFoundLongPending==false &&  iLongCount <= iShortCount){
    //Print("long cond 3");
    double takeprofit = TP_BB_Price;
    if(TP_BB_Price>highest_local+2*(highest_local-lowest_local)){
      takeprofit=highest_local+2*(highest_local-lowest_local);
    }
    calc_lots(highest_local-lowest_local);
    //Print("lots="+lots);
    //lots=0.01;
    if( (takeprofit - highest_local) / Point() < 30){takeprofit=highest_local+30*Point();}
    //Print("highest_local="+highest_local);
    //Print("lowest_local="+lowest_local);
    //Print("takeprofit="+takeprofit);
    sl_local=0;
    if(bUseSL){
      sl_local=lowest_local;
    }
    
    if(OrderSend(NULL, OP_BUYSTOP, lots, highest_local, 3, sl_local, takeprofit, NULL, magic, 0, clrNONE)<0){
      if(OrderSend(NULL, OP_BUYLIMIT, lots, highest_local, 3, sl_local, takeprofit, NULL, magic, 0, clrNONE)<0){
        Print("OrderError");
      }
    }
  }
}
//+------------------------------------------------------------------+
void calc_lots(double price_diff)
{
  double Bid_bunshi=1;
  double Ask_bunshi=1;
  double Bid_bunbo=1;
  double Ask_bunbo=1;
  double risk_money=0;
  double money_diff;

  double contract_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE);
  double account_equity = AccountInfoDouble(ACCOUNT_EQUITY); 
  //double Bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
  //double Ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  if(acc_bunshi=="1"){
    Bid_bunshi=1;
    Ask_bunshi=1;
  }else{
    Bid_bunshi=SymbolInfoDouble(acc_bunshi,SYMBOL_BID);
    Ask_bunshi=SymbolInfoDouble(acc_bunshi,SYMBOL_ASK);
  }
  if(acc_bunbo=="1"){
    Bid_bunbo=1;
    Ask_bunbo=1;
  }else{
    Bid_bunbo=SymbolInfoDouble(acc_bunbo,SYMBOL_BID);
    Ask_bunbo=SymbolInfoDouble(acc_bunbo,SYMBOL_ASK);
  }

  //Print("acc_bunbo="+acc_bunbo);
  //Print("Bid_bunshi="+Bid_bunshi);
  //Print("Bid_bunbo="+Bid_bunbo);

  
  //if(acc_symbol==1){
  //  account_equity *= (Bid+Ask)/2; 
  //}
  if(Bid_bunbo+Ask_bunbo<=0){
    Bid_bunbo=iClose(acc_bunbo,PERIOD_D1,1);
    Ask_bunbo=iClose(acc_bunbo,PERIOD_D1,1);
  }
  //Print("Bid_bunshi2="+Bid_bunshi);
  //Print("Bid_bunbo2="+Bid_bunbo);


  if(Bid_bunbo+Ask_bunbo<=0){
    Bid_bunbo=1000000;
    Ask_bunbo=1000000;
    Bid_bunshi=0;
    Ask_bunshi=0;
  }
  //Print("account_equity 1="+account_equity);
  account_equity *= (Bid_bunshi+Ask_bunshi)/(Bid_bunbo+Ask_bunbo); 
  //Print("account_equity 2="+account_equity);
  //Print("price_diff="+price_diff);
  //Print("contract_size="+contract_size);
  risk_money=account_equity*riskpercent/100;
  money_diff=price_diff*contract_size;
  //Print("risk_money="+risk_money);
  if(0<money_diff){
    lots=NormalizeDouble(risk_money/money_diff, 2);
  }else{
    lots=0;
  }
}
//+------------------------------------------------------------------+
