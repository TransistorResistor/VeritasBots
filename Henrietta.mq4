#property copyright "TimC                     "
extern int magicNumber = 45654;
extern double lots = 1;
extern int MAPeriod = 20;
extern double stopLoss = 100;
extern double takeProfit = 100;
extern double MinRange = 0;
extern double thresh = 0;
extern int TrailingStop=0;
extern int TrailingStep=0;
extern int SlowPeriodStreak=50;
extern double lockInLevel = 50;
extern double lockInTP = 0.5;
extern bool OnlyOnCross = true;


int slippage = 3;
int ticket;
int counter;
bool openOrder;
bool buySignal;
bool sellSignal;
bool CloseBuySignal;
bool CloseSellSignal;
double TP = 0;
datetime LastBarOpenAt;
bool isNewBar = true;
bool traded_this_bar = false;


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
   return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
   return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
   openOrder = false;
 
   int cnt,total;
   total = OrdersTotal();
   
   if (LastBarOpenAt != Time[0]) // reset bar trave variable on new bar
   {
   LastBarOpenAt = Time[0];
   traded_this_bar = False;
   }
   generateSignals();
   
   //check for open orders
   for(counter=0;counter<OrdersTotal();counter++)   
   {
      OrderSelect(counter, SELECT_BY_POS, MODE_TRADES);     
      if (OrderMagicNumber() == magicNumber)
      {
         openOrder = true;
         
         //check for closing signals
         if ((OrderType() == OP_BUY && sellSignal))
         {
            closeBuyTrade();
            openOrder = false;
         }
         else if ((OrderType() == OP_SELL && buySignal) )
         {
            closeSellTrade();
            openOrder = false;
         }
      }
   }
            
   //There are no open orders. check for signals.
   if (!openOrder)
   {
      if (buySignal && !traded_this_bar)
         placeBuy();
      else if (sellSignal && !traded_this_bar)
         placeSell();
   }
   
   if(TrailingStop>0)MoveTrailingStop();
   return(0);
}
//+------------------------------------------------------------------+
//| place BUY trade                                                  |
//+------------------------------------------------------------------+
void placeBuy()
{   

   if (takeProfit > 0) TP = NormalizeDouble(Bid + Point*takeProfit,Digits());    
      RefreshRates();    
   ticket=OrderSend(Symbol(),OP_BUY,lots,Ask,slippage, NormalizeDouble(Bid - Point*stopLoss,Digits()) , TP,"buy",magicNumber,0,Green);  

   if(ticket<0)
   {
      Print("BUY failed with error #",GetLastError()," at ",Ask, " ", NormalizeDouble(Bid - Point*stopLoss,Digits()));
      return;  
   }
   else{
      traded_this_bar = true;
      Print("BUY Order Ask",Ask, " Bid ", Bid);
   }
}
//+------------------------------------------------------------------+
//| place SELL trade                                                 |
//+------------------------------------------------------------------+
void placeSell()
{
          
   if (takeProfit > 0) TP = NormalizeDouble(Bid - Point*takeProfit,Digits());
   RefreshRates(); 
   ticket=OrderSend(Symbol(),OP_SELL,lots,Bid,slippage,NormalizeDouble(Bid + Point*stopLoss,Digits) ,TP,"sell",magicNumber,0,Red);  
   if(ticket<0)
   {
      Print("SELL failed with error #",GetLastError()," tp ",Bid, " ", NormalizeDouble(TP, Digits));
      return;
   }
      else
   {
      traded_this_bar = true;
      Print("Sell Order Ask", Ask, " Bid ", Bid);
   }
}
//+------------------------------------------------------------------+
//| calculate the trailing stop for a BUY trade
//+------------------------------------------------------------------+
void closeBuyTrade()
{
      RefreshRates();
      if (!OrderClose(OrderTicket(),OrderLots(),Bid,slippage,Green)) {
      Print("CLOSE failed with #", GetLastError());
      }     
     
}
//+------------------------------------------------------------------+
//| calculate the trailing stop for a SELL trade
//+------------------------------------------------------------------+
void closeSellTrade()
{
      RefreshRates();
      if (!OrderClose(OrderTicket(),OrderLots(),Ask,slippage,Red))   {
      Print("CLOSE failed with #", GetLastError());
      }
}
//+------------------------------------------------------------------+
//| generate a buy or sell signal upon MA cross over
//+------------------------------------------------------------------+
void generateSignals()
{
   double MaPrevious1, MaPrevious2, MaPrevious3, MaPrevious4;
   double PClose, PClose2;
   double PHigh, PHigh2;
   double PLow, PLow2;
   double POpen, POpen2;
   double CClose;
   double CHigh;
   double CLow;
   double COpen;
   bool InsideBar = false;
   double MA_Delta;
   double Prev_MA_Delta1,Prev_MA_Delta2, Prev_MA_Delta3;
   double Prev_FMA_Delta1,Prev_FMA_Delta2, Prev_FMA_Delta3;
   double FastMa1, FastMa2, FastMa3, FastMa4;
   int i, StreakCount;
   bool SlowStreak,FastStreak;
   
      
   buySignal = false;
   sellSignal = false;
   CloseBuySignal = false;
   CloseSellSignal = false;
   

   MaPrevious1 = iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   MaPrevious2 = iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,2);
   MaPrevious3 = iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,3);
   MaPrevious4 = iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,4);
   
   Prev_MA_Delta1 = MaPrevious1 - MaPrevious2;
   Prev_MA_Delta2 = MaPrevious2 - MaPrevious3;
   Prev_MA_Delta3 = MaPrevious3 - MaPrevious4;

   Prev_FMA_Delta1 = FastMa1 - FastMa2;
   Prev_FMA_Delta2 = FastMa2 - FastMa3;
   Prev_FMA_Delta3 = FastMa3 - FastMa4;

   PClose = iClose(NULL,0,1);
   PHigh = iHigh(NULL,0,1);
   POpen = iOpen(NULL,0,1);
   PLow = iLow(NULL,0,1);
   
   PClose2 = iClose(NULL,0,2);
   PHigh2 = iHigh(NULL,0,2);
   POpen2 = iOpen(NULL,0,2);
   PLow2 = iLow(NULL,0,2);
   
   CClose = iClose(NULL,0,0);
   CHigh = iHigh(NULL,0,0);
   COpen = iOpen(NULL,0,0);
   CLow = iLow(NULL,0,0);
   
/*   SlowStreak = True;
   if (Prev_MA_Delta1 < 0){
      for(i=1; i<=SlowPeriodStreak; i++){
         if (iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,i) > iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,i+1))
         {
         SlowStreak = False;
         }
      }
   }
   else if (Prev_MA_Delta1 > 0){
         for(i=1; i<=SlowPeriodStreak; i++){
         if (iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,i) < iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,i+1))
         {
            SlowStreak = False;
         }
      }
   }
   else {
    SlowStreak = False;
    Comment("SMA = 0");
   }
   
      FastStreak = True;
   if (Prev_MA_Delta1 < 0){
      for(i=1; i<=FastPeriodStreak; i++){
         if (iMA(NULL,0,MAfastPeriod,0,MODE_SMA,PRICE_CLOSE,i) > iMA(NULL,0,MAfastPeriod,0,MODE_SMA,PRICE_CLOSE,i+1))
         {
         FastStreak = False;
         }
      }
   }
   else if (Prev_MA_Delta1 > 0){
         for(i=1; i<=FastPeriodStreak; i++){
            if (iMA(NULL,0,MAfastPeriod,0,MODE_SMA,PRICE_CLOSE,i) < iMA(NULL,0,MAfastPeriod,0,MODE_SMA,PRICE_CLOSE,i+1))
            {
            FastStreak = False;
            }
         }
   }
   else {
    SlowStreak = False;

   }*/
   //SMA + FMA in uptrend, price above FMA and FMA above SMA
   
   if ((iClose(NULL,0,1) > MaPrevious1 && !OnlyOnCross) || (iClose(NULL,0,1) > MaPrevious1 && iClose(NULL,0,2) < MaPrevious1 && OnlyOnCross))
   {
      buySignal = true;
   }
   //fast MA crosses below slow MA.
   else if ((iClose(NULL,0,1) < MaPrevious1 && !OnlyOnCross) || (iClose(NULL,0,1) < MaPrevious1 && iClose(NULL,0,2) > MaPrevious1 && OnlyOnCross))
   {
      sellSignal = true;
   }
   
      //Price moves below MA or the price moves below the low of the last (negative) bar
   else if ((CClose < MaPrevious1 && PClose > MaPrevious1) || (CClose < PLow && POpen > PClose) || MA_Delta < 0)
   {
      CloseBuySignal = true;
   }
        //Price moves above ma, or price moves above the high of the last positive bar
   else if ( (CClose > MaPrevious1 && PClose < MaPrevious1)  || (CClose > PHigh && POpen < PClose) || MA_Delta > 0)
   {
      CloseSellSignal = true;
   }
   // cancel buy/sell signal if the movement in the last 2 bars has been very small
   if ((PHigh -PLow)/Point < MinRange && (PHigh2 - PLow2)/Point < MinRange && (buySignal || sellSignal)) {
      Print("Trade passed up - range too small");
      buySignal = false;
      sellSignal = false;
   }
   Comment("Streak Delta FMA = ", FastStreak ,"\n", 
   "Streak Delta SMA  = ", SlowStreak ,"\n", 
   "Close Below FMA  = ", iClose(NULL,0,1) < FastMa1 ,"\n",
   "FMA below SMA   = ", FastMa1 < MaPrevious1 ,"\n",
   "Downtrend             " , Prev_MA_Delta1 < 0, "\n"
    );
}


void MoveTrailingStop()
{
   int cnt,total=OrdersTotal();
   double prft;
   
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      
      if(OrderType()<=OP_SELL&&OrderSymbol()==Symbol() && OrderMagicNumber() == magicNumber && OrderProfit() < lockInLevel )
      {
         if(OrderType()==OP_BUY)
         {
            if(TrailingStop>0)  
            {                 
               if((NormalizeDouble(OrderStopLoss(),Digits)<NormalizeDouble(Bid-Point*(TrailingStop+TrailingStep),Digits))||(OrderStopLoss()==0))
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid-Point*TrailingStop,Digits),OrderTakeProfit(),0,Green);
                  return(0);
               }
            }
         }
         else 
         {
            if(TrailingStop>0)  
            {                 
               if((NormalizeDouble(OrderStopLoss(),Digits)>(NormalizeDouble(Ask+Point*(TrailingStop+TrailingStep),Digits)))||(OrderStopLoss()==0))
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Ask+Point*TrailingStop,Digits),OrderTakeProfit(),0,Red);
                  /*return(0)*/;
               }
            }
         }
      }
      
            if(OrderType()<=OP_SELL&&OrderSymbol()==Symbol()&&OrderMagicNumber() == magicNumber && OrderProfit() >= lockInLevel )
      {
         if(OrderType()==OP_BUY)
         {
            if(TrailingStop>0 && lockInLevel > 0)  
            {                 
               if((((OrderOpenPrice() - Bid)/Point < lockInLevel && OrderProfit() > 0) && ( OrderStopLoss() < Bid-Point*lockInLevel) )||OrderStopLoss()==0)
               {
                  Comment("Locking In buy at ", Ask+Point*lockInLevel*lockInTP);
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid-Point*lockInLevel*lockInTP,Digits),OrderTakeProfit(),0,Green);
                  return(0);
               }
            }
         }
         else 
         {
            if(TrailingStop > 0 && lockInLevel > 0)  
            {                 
               if((((Ask - OrderOpenPrice())/Point < lockInLevel && OrderProfit() > 0) && ( OrderStopLoss() > Ask+Point*lockInLevel))||(OrderStopLoss()==0))
               {
                  Comment("Locking In sell at ", Ask+Point*lockInLevel*lockInTP);
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Ask+Point*lockInLevel*lockInTP,Digits),OrderTakeProfit(),0,Red);
                  /*return(0)*/;
               }
            }
         }
      }
      
   }


}
