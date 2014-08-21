#property copyright "TimC                     "
extern int magicNumber = 45654;
extern double lots = 1;
extern int MAPeriod = 20;
extern int MAfastPeriod = 5;
extern double MaxMoveAgainstMA = 0;
extern double takeProfit = 100;
extern double MinRange = 0;
extern double thresh = 0;
extern int TrailingStop=0;
extern int TrailingStep=0;
extern bool exitOnBBands = true;
extern int StochK = 14;
extern int StochD = 3;
extern int StochSlow = 3;
extern int StochUpperThresh = 80; 
extern int StochLowerThresh = 20;
extern bool requireTrend = false;
extern bool requireCloseonMaXClose = false;

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
string closeString = "";


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
 
   int total;
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
         if ((OrderType() == OP_BUY && sellSignal)||(OrderType() == OP_BUY && exitOnBBands && CloseBuySignal))
         {
            if (sellSignal) {
            closeString = " Buy Signal (MA Crossing)";
            }
            else if ( exitOnBBands && CloseBuySignal)
            {
            closeString = "BBand intersection";
            }
            closeBuyTrade();
            openOrder = false;
         }
         else if ((OrderType() == OP_SELL && buySignal)||(OrderType() == OP_SELL && exitOnBBands && CloseSellSignal))
         {
            if (buySignal) {
            closeString = " Buy Signal (MA Crossing)";
            }
            else if ( exitOnBBands && CloseSellSignal)
            {
            closeString = " BBand intersection";
            }
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
   ticket=OrderSend(Symbol(),OP_BUY,lots,Ask,slippage, 0 , 0,"buy",magicNumber,0,Green);  

   if(ticket<0)
   {
      Print("BUY failed with error #",GetLastError()," at ",Ask );
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
   ticket=OrderSend(Symbol(),OP_SELL,lots,Bid,slippage,0 ,0,"sell",magicNumber,0,Red);  
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
      else{
      Print("CLOSED #", OrderTicket(), " ", closeString);
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
            else{
      Print("CLOSED #", OrderTicket(), " ", closeString);
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
   double stoch1, stoch2;
//   int i, StreakCount;
//   bool SlowStreak,FastStreak;
   
      
   buySignal = false;
   sellSignal = false;
   CloseBuySignal = false;
   CloseSellSignal = false;
   
   FastMa1 = iMA(NULL,0,MAfastPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   FastMa2 = iMA(NULL,0,MAfastPeriod,0,MODE_SMA,PRICE_CLOSE,2);
   FastMa3 = iMA(NULL,0,MAfastPeriod,0,MODE_SMA,PRICE_CLOSE,3);
   FastMa4 = iMA(NULL,0,MAfastPeriod,0,MODE_SMA,PRICE_CLOSE,4);

   MaPrevious1 = iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   MaPrevious2 = iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,2);
   MaPrevious3 = iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,3);
   MaPrevious4 = iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,4);
   
   Prev_MA_Delta1 = MaPrevious1 - MaPrevious2;
   Prev_MA_Delta2 = MaPrevious2 - MaPrevious3;
   Prev_MA_Delta3 = MaPrevious3 - MaPrevious4;
   
   bool uptrend = false;
   bool downtrend = false;

   Prev_FMA_Delta1 = FastMa1 - FastMa2;
   Prev_FMA_Delta2 = FastMa2 - FastMa3;
   Prev_FMA_Delta3 = FastMa3 - FastMa4;
   stoch1 = iStochastic(NULL,0,StochK,StochD,StochSlow,MODE_SMA,PRICE_CLOSE,0,1);
   stoch2 = iStochastic(NULL,0,StochK,StochD,StochSlow,MODE_SMA,PRICE_CLOSE,0,2);
   
   if (Prev_MA_Delta1 > 0 &&  Prev_MA_Delta2 > 0  && Prev_MA_Delta3 > 0)
      {uptrend= true;}
   else if (Prev_MA_Delta1 < 0 &&  Prev_MA_Delta2 < 0 && Prev_MA_Delta3 < 0)
      {downtrend= true;}
   if (!requireTrend)
   {uptrend= true;
   downtrend= true;}
   
   
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
   

   //SMA + FMA in uptrend, price above FMA and FMA above SMA
   if ( (stoch1 > StochUpperThresh && MaPrevious2 >= FastMa2) && (FastMa1 >= MaPrevious1) && uptrend)
   {
      buySignal = true;
   }
   //fast MA crosses below slow MA.
   else if (stoch1 < StochLowerThresh && MaPrevious2 <= FastMa2 && FastMa1 <= MaPrevious1 && downtrend)
   {
      sellSignal = true;
   }
   
      //Price moves below MA or the price moves below the low of the last (negative) bar
   else if ((stoch1 > 80 && stoch2 < 80)  || (MaPrevious2 < FastMa2 && FastMa1 < MaPrevious1 ))
   {
      CloseBuySignal = true;
   }
        //Price moves above ma, or price moves above the high of the last positive bar
   else if ( (stoch1 > 20 && stoch2 < 20 )|| (MaPrevious2 > FastMa2 && FastMa1 > MaPrevious1))
   {
      CloseSellSignal = true;
   }
   // cancel buy/sell signal if the movement in the last 2 bars has been very small
   if ((PHigh -PLow)/Point < MinRange && (PHigh2 - PLow2)/Point < MinRange && (buySignal || sellSignal)) {
      Print("Trade passed up - range too small");
      buySignal = false;
      sellSignal = false;
   }
   
   
   Comment("FMA1,SMA1, Condition : ", FastMa1 , " ",MaPrevious1,"\n", "FMA2, SMA2, Condition : ", FastMa2 , " ",MaPrevious2, "\n", "Buysig, CloseBuy : ", buySignal, " ", CloseBuySignal );   
   
}


void MoveTrailingStop()
{
   int cnt,total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<=OP_SELL&&OrderSymbol()==Symbol())
      {
         if(OrderType()==OP_BUY)
         {
            if(TrailingStop>0)  
            {                 
               if((NormalizeDouble(OrderStopLoss(),Digits)<NormalizeDouble(Bid-Point*(TrailingStop+TrailingStep),Digits))||(OrderStopLoss()==0))
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid-Point*TrailingStop,Digits),OrderTakeProfit(),0,Green);
                  //return(0);
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
   }
}

