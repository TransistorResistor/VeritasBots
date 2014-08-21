#property copyright "TimC                     "
#property link      "http://www.forexonlinetradingsystems.info/simple-systems/moving-average-crossover-with-rsi"

extern int magicNumber = 45654;
extern double lots = 1;
extern int MAPeriod = 20;
extern int MAfastPeriod = 5;
extern double StopLossSD = 2.5;
extern double takeProfit = 200;
extern double MinRange = 50;
extern double thresh = 0;
extern int StopPeriod = 20;
extern bool TrailStop = true;
extern int TrailingStep=0;
extern bool CloseOnMA_Cross = false;
extern bool RequireInsideBar = true;


int slippage = 3;
int ticket;
int counter;
bool openOrder;
bool buySignal;
bool sellSignal;
bool CloseBuySignal;
bool CloseSellSignal;
double TP = 0;
double stopLoss;
double TrailingStop;


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
   if (!TrailStop) TrailingStop = 0;
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
   
   generateSignals();
   
   //check for open orders
   for(counter=0;counter<OrdersTotal();counter++)   
   {
      OrderSelect(counter, SELECT_BY_POS, MODE_TRADES);     
      if (OrderMagicNumber() == magicNumber)
      {
         openOrder = true;
         
         //check for closing signals
         if ((OrderType() == OP_BUY && sellSignal) || (CloseBuySignal && CloseOnMA_Cross))
         {
            closeBuyTrade();
            openOrder = false;
         }
         else if ((OrderType() == OP_SELL && buySignal) || (CloseSellSignal && CloseOnMA_Cross))
         {
            closeSellTrade();
            openOrder = false;
         }
      }
   }
   
            
   //There are no open orders. check for signals.
   if (!openOrder)
   {
      if (buySignal)
         placeBuy();
      else if (sellSignal)
         placeSell();
   }
   if (TrailStop) TrailingStop = stopLoss;
   
   if(TrailingStop>0)MoveTrailingStop();
   return(0);
}
//+------------------------------------------------------------------+
//| place BUY trade                                                  |
//+------------------------------------------------------------------+
void placeBuy()
{   

   if (takeProfit > 0) TP = NormalizeDouble(Bid + Point*takeProfit,Digits());
   GenerateBuyStopLoss();   
      RefreshRates();    
   ticket=OrderSend(Symbol(),OP_BUY,lots,Ask,slippage, NormalizeDouble(Bid - Point*stopLoss,Digits()) , TP,"buy",magicNumber,0,Green);  
   if(ticket<0)
   {
      Print("BUY failed with error #",GetLastError()," at ",Ask, " SL ", NormalizeDouble(Bid - Point*stopLoss,Digits())," TP ", NormalizeDouble(TP,Digits()) );
      return;  
   }
}
//+------------------------------------------------------------------+
//| place SELL trade                                                 |
//+------------------------------------------------------------------+
void placeSell()
{
          
   if (takeProfit > 0) TP = NormalizeDouble(Bid - Point*takeProfit,Digits());
   GenerateSellStopLoss();   
   RefreshRates(); 
   ticket=OrderSend(Symbol(),OP_SELL,lots,Bid,slippage,NormalizeDouble(Ask + Point*stopLoss,Digits) ,TP,"sell",magicNumber,0,Red);  
   if(ticket<0)
   {
      Print("SELL failed with error #",GetLastError()," SL ",NormalizeDouble(Bid + Point*stopLoss,Digits), " TP ", NormalizeDouble(TP, Digits));
      return;
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
   double MaPrevious1;
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
   double Prev_MA_Delta;
   double FastMa1;
   double FastMa2;
   double FastMa3;
   double MaPrevious2;
   bool straddle = false;
      
   buySignal = false;
   sellSignal = false;
   CloseBuySignal = false;
   CloseSellSignal = false;
   straddle = true;
   
   FastMa1 = iMA(NULL,0,MAfastPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   FastMa2 = iMA(NULL,0,MAfastPeriod,0,MODE_EMA,PRICE_CLOSE,2);
   FastMa3 = iMA(NULL,0,MAfastPeriod,0,MODE_EMA,PRICE_CLOSE,3);
   
   MaPrevious1=iMA(NULL,0,MAPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   MaPrevious2 = iMA(NULL,0,MAPeriod,0,MODE_EMA,PRICE_CLOSE,2);
   
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
   
   MA_Delta = FastMa1-FastMa2;
   Prev_MA_Delta =  FastMa2-FastMa3;
   
   
   if (RequireInsideBar == False) {
   InsideBar = true;
   }
   if (PLow > PLow2 && PHigh < PHigh2) {
   InsideBar = true;
   }
   
   if (PLow < FastMa1 && PHigh > FastMa1) {
   straddle = false;
   }
   
   //Prev candle above MA and break above previous high
   if (PLow > MaPrevious1 && CLow > MaPrevious1 && CClose>(PHigh + thresh*Point) && InsideBar && straddle)
   {
      buySignal = true;
   }
   //fast MA crosses below slow MA.
   else if (PHigh < MaPrevious1 && CHigh < MaPrevious1 && CClose < (PLow - thresh*Point) && InsideBar && straddle)
   {
      
      sellSignal = true;
   }
      //Price moves below MA or the price moves below the low of the last (neagtive) bar
   else if ((CClose < MaPrevious1 && PClose > MaPrevious1) || (CClose < PLow && POpen > PClose) || MA_Delta < 0)
   {
      
      CloseBuySignal = true;
   }
        //Price moves above ma, or price moves above the high of the last positive bar
   else if ( (CClose > MaPrevious1 && PClose < MaPrevious1)  || (CClose > PHigh && POpen < PClose) || MA_Delta > 0)
   {
      CloseSellSignal = true;
   }
   if ((PHigh -PLow)/Point < MinRange && (PHigh2 - PLow2)/Point < MinRange && (buySignal || sellSignal)) {
      Comment("Trade passed up - range too small");
      buySignal = false;
      sellSignal = false;
   }
   
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
   }
}
void GenerateBuyStopLoss()
{
int HighBar = iHighest(NULL,0,MODE_HIGH,StopPeriod,0);
int LowBar = iLowest(NULL,0,MODE_HIGH,StopPeriod,0);
double HighPeriod = High[HighBar];
double LowPeriod = Low[LowBar];

stopLoss = (iClose(NULL,NULL,0)-LowPeriod) / Point;
double StopLevel = MarketInfo(Symbol(),MODE_STOPLEVEL);

if (stopLoss <StopLevel){
stopLoss = StopLevel*2;
Print("Order s/l set at min : ",StopLevel, " not ", stopLoss) ;
   }
}


void GenerateSellStopLoss()
{
int HighBar = iHighest(NULL,0,MODE_HIGH,StopPeriod,0);
int LowBar = iLowest(NULL,0,MODE_HIGH,StopPeriod,0);
double HighPeriod = High[HighBar];
double LowPeriod = Low[LowBar];

stopLoss = (HighPeriod - iClose(NULL,NULL,0)) / Point;
double StopLevel = MarketInfo(Symbol(),MODE_STOPLEVEL);

if (stopLoss <StopLevel){
stopLoss = StopLevel*1.5;
Print("Order s/l set at min : ",StopLevel, " not ", stopLoss) ;
}
} 