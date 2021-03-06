//+------------------------------------------------------------------+
//|                                              SafeProfitMaker.mq4 |
//|                                                   Rafał Zawadzki |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Rafał Zawadzki"
#property link      "https://www.mql5.com"
#property version   "0.01"
#property strict
//--- input parameters
//input int      changeStopPips=10;
//input int      valueToChange=3;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include "hash.mqh"
Hash *orderPriceTable=new Hash();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   checkOrderNumber();
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         double priceDiff=orderPriceTable.hGetDouble(IntegerToString(OrderTicket()));
         int diffPoints=priceDiff/Point;
         if(ruleMoveSLpips(i, diffPoints, 20, diffPoints/2)==true) { continue; }
         if(ruleMoveSLpips(i, diffPoints, 15, 5)==true) { continue; }
         if(ruleMoveSLpips(i, diffPoints, 10, 3)==true) { continue; }
        }

     }
  }

bool ruleMoveSLpips(int i, int diffPoints,int condition, int points)
  {
   bool go=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
   if(diffPoints>=condition)
     {
      if(OrderType()==OP_SELL)
        {
         bool mo=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(points)*Point,OrderTakeProfit(),OrderExpiration(),Red);
         return(true);
        }
      else if(OrderType()==OP_BUY)
        {
         bool mo=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(points)*Point,OrderTakeProfit(),OrderExpiration(),Red);
         return(true);
        }
     }
   return(false);
  }
   
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkOrderNumber()
  {
   bool flag=false;
   HashLoop *l;
   for(l=new HashLoop(orderPriceTable); l.hasNext(); l.next())
     {
      for(int i=0; i<OrdersTotal(); i++)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
           {
            if(OrderType()==OP_BUY || OrderType()==OP_SELL)
              {
               if(l.key()==IntegerToString(OrderTicket()))
                 {
                  if(OrderType()==OP_SELL && (OrderOpenPrice()-Ask)>l.valDouble())
                    {
                     orderPriceTable.hPutDouble(IntegerToString(OrderTicket()),OrderOpenPrice()-Ask);
                    }
                  else if(OrderType()==OP_BUY && (Bid-OrderOpenPrice())>l.valDouble())
                    {
                     orderPriceTable.hPutDouble(IntegerToString(OrderTicket()),Bid-OrderOpenPrice());
                    }
                  flag=true;
                  break;
                 }
              }
           }
        }
      if(!flag)
        {
         orderPriceTable.hDel(IntegerToString(OrderTicket()));
        }
     }

   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         // interesują nas tylko aktywne nie oczekujące zlecenia
         if(orderPriceTable.hGet(IntegerToString(OrderTicket()))==NULL)
           {
            if(OrderType()==OP_SELL)
              {
               orderPriceTable.hPutDouble(IntegerToString(OrderTicket()),OrderOpenPrice()-Ask);
              }
            else if(OrderType()==OP_BUY)
              {
               orderPriceTable.hPutDouble(IntegerToString(OrderTicket()),Bid-OrderOpenPrice());
              }
           }
        }
     }
  }