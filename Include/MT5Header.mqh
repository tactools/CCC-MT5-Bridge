#include <Trade\SymbolInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <VirtuBots\GMMM_Trade.mqh>

CPositionInfo m_position; // trade position object
CTrade m_trade;           // trading object
CSymbolInfo m_symbol;     // symbol info object
COrderInfo m_order;



input bool AlertsMessage = true; // Display messages on alerts?
input bool AlertsSound = true;   // Play sound on alerts?
input bool AlertsEmail = false;  // Send email on alerts?
input bool AlertsNotify = false; // Send push notification on alerts?
input bool DEV_DEBUG = false;


string last_alert = "";



/*
Get orderbook
*/
string _MT5_OrderBook(string symbol){

  MqlBookInfo book[];
   //Returns a structure array MqlBookInfo containing records of the Depth of Market of a specified symbol.
   MarketBookGet(symbol, book);
   // check if the data exists
   if(ArraySize(book) == 0)
   {
      printf("Failed load market book price. Reason: " + (string)GetLastError());
      return("faile");
   }

   // what is the size of the book array?
   int size=ArraySize(book);
   
   //Print all the values
   string bestbids = "";
   string bestasks ="";
   
   for(int i=1; i<size; i++) // ensure that we start counting at 1, to prevent the array out of index
     {
       
           if(book[i].type == BOOK_TYPE_SELL){
            bestasks += "\n Price: "+DoubleToString(book[i].price, Digits()) +" "+DoubleToString(book[i].volume_real, Digits());
          }   
           if(book[i].type == BOOK_TYPE_BUY){
            bestbids += "\n Price: "+DoubleToString(book[i].price, Digits()) +" "+DoubleToString(book[i].volume_real, Digits());
          } 
     }
     
     // now that we have the index for the best Bid and Ask, we can do some logic
     
     // lets print only these values first (working)
     
      MarketBookRelease(symbol);
     
     return("Asks:"+ bestasks + "\nBids:" +bestbids);

}









int _MT5_Math_random(int digit_length)
{
   int random = MathRand(); // 32767
   string random_string = IntegerToString(random, 0, 0);
   string random_digit = StringSubstr(random_string, 0, digit_length);
   int random_int = StringToInteger(random_digit);

   return (random_int);
}

void _MT5_Alert_Median(string var_name, double market_price)
{

   // get median value
   double med = GlobalVariableGet(var_name);
   // we have a value (global found
   if (med != 0)
   {

      if (market_price > med && last_alert != "bull")
      {
         Alert(" Bullish ");
         last_alert = "bull";
      }
      if (market_price < med && last_alert != "bear")
      {
         Alert("Bearish");
         last_alert = "bear";
      }
   }
}

void _MT5_Alert_Send(string message, string header_email, string sound_file)
{

   if (AlertsMessage)
      Alert(message);
   if (AlertsEmail)
      SendMail(header_email, message);
   if (AlertsNotify)
      SendNotification(message);
   string dir = sound_file + ".wav";
   if (AlertsSound)
      PlaySound(dir);
}

string _MT5_Indicator_Name()
{
   string path = MQL5InfoString(MQL5_PROGRAM_PATH);
   string data = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Indicators\\";
   string name = StringSubstr(path, StringLen(data));
   return (name);
}

int _tfsPer[] = {PERIOD_M1, PERIOD_M2, PERIOD_M3, PERIOD_M4, PERIOD_M5, PERIOD_M6, PERIOD_M10, PERIOD_M12, PERIOD_M15, PERIOD_M20, PERIOD_M30, PERIOD_H1, PERIOD_H2, PERIOD_H3, PERIOD_H4, PERIOD_H6, PERIOD_H8, PERIOD_H12, PERIOD_D1, PERIOD_W1, PERIOD_MN1};
string _tfsStr[] = {"1 minute", "2 minutes", "3 minutes", "4 minutes", "5 minutes", "6 minutes", "10 minutes", "12 minutes", "15 minutes", "20 minutes", "30 minutes", "1 hour", "2 hours", "3 hours", "4 hours", "6 hours", "8 hours", "12 hours", "daily", "weekly", "monthly"};

// return the string which is equal to the chart time frame int enum values
string _MT5_TimeFrameToString(int chart_period)
{
   if (chart_period == PERIOD_CURRENT)
      chart_period = _Period;

   int i;
   for (i = 0; i < ArraySize(_tfsPer); i++)
   {
      if (chart_period == _tfsPer[i])
         break;
   }

   return (_tfsStr[i]);
}

// Take the High and take the low , subtract and divide by 2 , return
double _MT5_Indicator_Band_Width(double low, double high)
{
   double Distance_from_high_low = high - low;
   double median_value = Distance_from_high_low / 2;
   return (median_value);
}

// enter the symbol, enter criteria for the firing at what second
bool _MT5_Time_Search(string sym, int minutes, int seconds)
{

   // Current way of doing this to get the current value of time for the minute value
   int secondsFrom = (long)TimeCurrent();

   string hour_min = TimeToString(secondsFrom, TIME_MINUTES);

   string min = StringSubstr(hour_min, 3, 2);

   string hour_min_second = TimeToString(secondsFrom, TIME_SECONDS);

   string sec = StringSubstr(hour_min_second, 6, 2);

   if (min == minutes && sec == seconds)
   {
      Print("MT5 Time Search( " + sym + " criteria min  " + minutes + " seconds " + seconds + ") = min " + min + " seconds " + sec);
      return (true);
   }
   else
   {
      return (false);
   }
}

// insert buy or sell as a string and get back the position count ( must include the marketname, EA comments, direction""")
int _MT5_Positions_Count(string market_symbol, string order_comment, string buy_sell)
{

   int buy = 0;
   int sell = 0;
   uint total = PositionsTotal();
   //Loop for positions
   for (uint i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket))
      {
         string position_symbol = PositionGetString(POSITION_SYMBOL);

         if (position_symbol == market_symbol &&
             PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY &&
             PositionGetString(POSITION_COMMENT) == order_comment)
         {

            buy++;

            //  entry_buy =   PositionGetDouble(POSITION_PRICE_OPEN);
         }
         if (position_symbol == market_symbol &&
             PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL &&
             PositionGetString(POSITION_COMMENT) == order_comment

         )
         {

            sell++;

            //  entry_sell =   PositionGetDouble(POSITION_PRICE_OPEN);
         }
      }
   }

   if (buy_sell == "buy")
   {
      return (buy);
   }
   if (buy_sell == "sell")
   {
      return (sell);
   }
   return (0);
}

//Returns the name of the day of the week
string _MT5_Time_DayOfWeek(string market_symbol)
{
   MqlDateTime dt;
   string day = "";

   ENUM_TIMEFRAMES tf = PERIOD_M1; // mql format of timeframes

   datetime time = iTime(market_symbol, tf, 0); // get the timeseries data datetime format of a string

   TimeToStruct(time, dt);
   switch (dt.day_of_week)
   {
   case 0:
      day = EnumToString(SUNDAY);
      break;
   case 1:
      day = EnumToString(MONDAY);
      break;
   case 2:
      day = EnumToString(TUESDAY);
      break;
   case 3:
      day = EnumToString(WEDNESDAY);
      break;
   case 4:
      day = EnumToString(THURSDAY);
      break;
   case 5:
      day = EnumToString(FRIDAY);
      break;
   default:
      day = EnumToString(SATURDAY);
      break;
   }
   //---
   return day;
}

//Returns seconds since beginning of bar[]
int _MT5_Time_Seconds(string market_symbol)
{

   int secondsFrom = (long)TimeCurrent();

   string hour_min_second = TimeToString(secondsFrom, TIME_SECONDS);

   string second = StringSubstr(hour_min_second, 6, 2);

   // Print("seconds "+  second );
   return (second);
}

// Returns the minutes since hour[] open
int _MT5_Time_Minutes(string market_symbol)
{

   int secondsFrom = (long)TimeCurrent();

   string hour_min = TimeToString(secondsFrom, TIME_MINUTES);

   string min = StringSubstr(hour_min, 3, 2);

   // Print("seconds "+  second );
   return (min);
}

// parse telegram message and send back the symbol
string _MT5_Parse_The_User_Text(string text)
{

   string newSymbol = StringSubstr(text, 0, 1);
   string newSymbolTwo = "";
   string symName = "";

   if (newSymbol == "/")
   {
      // working , step two
      newSymbolTwo = StringSubstr(text, 1, 6);
      //  newSymbolTwo =  StringToUpper(newSymbolTwo);
      //  newSymbolTwo == EURUSD , ok
   }

   //   Print("FUNCTION Parse_The_User_Text() newSymbol  ",newSymbol );

   //  Print("FUNCTION Parse_The_User_Text() newSymbolTwo ",newSymbolTwo );
   // step 2,
   // loop all just like what I did with the Quotes Daily, I would have to flip through all possible values, what once it matches, this go into the function
   // -- make a symbol mapping basically,
   // put in the string
   for (int i = 0; i < SymbolsTotal(true); i++)
   {
      symName = SymbolName(i, false);

      if (symName == newSymbolTwo)
      {
         // Print("FUNCTION Parse_The_User_Text()|| SYMBOL MATCH ||  ",symName );
         // ok found the correct symbol, Now pass the value back
         return (symName);
      }
      else
      {
         // Print("FUNCTION Parse_The_User_Text()NO MATCH newSymbolTwo " + newSymbolTwo + "   sym " + symName );
      }
   }
   return ("ERROR");
}

// is Currency Swap +/- ( save as globalsVariables for other bots to use)
string _MT5_Return_Daily_Swap()
{

   double swap_long_m = 0;
   double swap_short_m = 0;
   double direction = -1;
   string bigstring = "";
   double ydayHigh = 0;
   double ydayLow = 0;

   double dayHigh = 0;
   double dayLow = 0;

   double dayO = 0;
   double dayC = 0;
   double ydayO = 0;
   double ydayC = 0;

   int errorCode = 0;

   for (int i = 0; i < SymbolsTotal(true); i++)
   {
      direction = -1; // reset
      string symName = SymbolName(i, false);
      string str = symName + " index: " + DoubleToString(i, 0);

      // get history for the daily
      if (GlobalVariableGet("Global_Bot_Swap_" + symName) != -1)
      {
         ydayHigh = iHigh(symName, PERIOD_D1, 1);
         ydayLow = iLow(symName, PERIOD_D1, 1);
         dayHigh = iHigh(symName, PERIOD_D1, 0);
         dayLow = iLow(symName, PERIOD_D1, 0);

         dayC = iClose(symName, PERIOD_D1, 0);
         dayO = iOpen(symName, PERIOD_D1, 0);

         ydayC = iClose(symName, PERIOD_D1, 1);
         ydayO = iOpen(symName, PERIOD_D1, 1);
         // get data
         errorCode = GetLastError();
         while (errorCode == 4073 || errorCode == 4066)
         {
            Sleep(300);
            ydayHigh = iHigh(symName, PERIOD_D1, 1);
            ydayLow = iLow(symName, PERIOD_D1, 1);
            dayHigh = iHigh(symName, PERIOD_D1, 0);
            dayLow = iLow(symName, PERIOD_D1, 0);
            dayC = iClose(symName, PERIOD_D1, 0);
            dayO = iOpen(symName, PERIOD_D1, 0);
            ydayC = iClose(symName, PERIOD_D1, 1);
            ydayO = iOpen(symName, PERIOD_D1, 1);
            errorCode = GetLastError();
         }

         double newPoint = SymbolInfoDouble(symName, SYMBOL_POINT) * 10;

         double pipsbar = 0;
         double pipsbarToday = 0;

         if (dayHigh != 0)
         {
            if (dayLow != 0)
            {
               if (ydayHigh != 0)
               {
                  if (ydayLow != 0)
                  {
                     Print(" " + symName + " high " + dayHigh + " highlast " + ydayHigh + " low " + dayLow + "  lowlast " + ydayLow + " POINT : " + newPoint);
                     pipsbarToday = (dayHigh - dayLow) / newPoint;
                     pipsbar = (ydayHigh - ydayLow) / newPoint;
                  }
               }
            }
         }

         string special_up = "↗️";
         string special_flat = " ➡️";
         string special_dn = "↘️";

         string resultingDay = "";
         string resultingYDay = "";

         if (dayO > dayC)
         {
            // bear
            resultingDay = special_dn;
         }
         else
         {
            resultingDay = special_up;
         }

         if (ydayO > ydayC)
         {
            // bear
            resultingYDay = special_dn;
         }
         else
         {
            resultingYDay = special_up;
         }

         bigstring += "/" + symName + " Daily Bar: " + DoubleToString(pipsbarToday, 1) + " pips " + resultingDay + "\n" + "Yesterday Bar: " + DoubleToString(pipsbar, 1) + " pips" + resultingYDay + "\n";
         Print("Daily Bar: " + pipsbar + " Symbol ", str);
      }
   }

   return (bigstring);
}

// is Currency Swap +/- ( save as globalsVariables for other bots to use)
string _MT5_Return_Daily_Other()
{

   double swap_long_m = 0;
   double swap_short_m = 0;
   double direction = -1;
   string bigstring = "";
   double ydayHigh = 0;
   double ydayLow = 0;

   double dayHigh = 0;
   double dayLow = 0;

   double dayO = 0;
   double dayC = 0;
   double ydayO = 0;
   double ydayC = 0;

   int errorCode = 0;

   for (int i = 0; i < SymbolsTotal(true); i++)
   {
      direction = -1; // reset
      string symName = SymbolName(i, false);
      string str = symName + " index: " + DoubleToString(i, 0);

      // get history for the daily
      if (GlobalVariableGet("Global_Bot_Swap_" + symName) != -1)
      {
      }
      else
      {
         ydayHigh = iHigh(symName, PERIOD_D1, 1);
         ydayLow = iLow(symName, PERIOD_D1, 1);
         dayHigh = iHigh(symName, PERIOD_D1, 0);
         dayLow = iLow(symName, PERIOD_D1, 0);

         dayC = iClose(symName, PERIOD_D1, 0);
         dayO = iOpen(symName, PERIOD_D1, 0);

         ydayC = iClose(symName, PERIOD_D1, 1);
         ydayO = iOpen(symName, PERIOD_D1, 1);
         // get data
         errorCode = GetLastError();
         while (errorCode == 4073 || errorCode == 4066)
         {
            Sleep(300);
            ydayHigh = iHigh(symName, PERIOD_D1, 1);
            ydayLow = iLow(symName, PERIOD_D1, 1);
            dayHigh = iHigh(symName, PERIOD_D1, 0);
            dayLow = iLow(symName, PERIOD_D1, 0);
            dayC = iClose(symName, PERIOD_D1, 0);
            dayO = iOpen(symName, PERIOD_D1, 0);
            ydayC = iClose(symName, PERIOD_D1, 1);
            ydayO = iOpen(symName, PERIOD_D1, 1);
            errorCode = GetLastError();
         }

         double newPoint = SymbolInfoDouble(symName, SYMBOL_POINT) * 10;
         double pipsbar = 0;
         double pipsbarToday = 0;

         if (dayHigh != 0)
         {
            if (dayLow != 0)
            {
               if (ydayHigh != 0)
               {
                  if (ydayLow != 0)
                  {
                     Print(" " + symName + " high " + dayHigh + " highlast " + ydayHigh + " low " + dayLow + "  lowlast " + ydayLow + " POINT : " + newPoint);
                     pipsbarToday = (dayHigh - dayLow) / newPoint;
                     pipsbar = (ydayHigh - ydayLow) / newPoint;
                  }
               }
            }
         }

         string special_up = "↗️";
         string special_flat = " ➡️";
         string special_dn = "↘️";

         string resultingDay = "";
         string resultingYDay = "";

         if (dayO > dayC)
         {
            // bear
            resultingDay = special_dn;
         }
         else
         {
            resultingDay = special_up;
         }

         if (ydayO > ydayC)
         {
            // bear
            resultingYDay = special_dn;
         }
         else
         {
            resultingYDay = special_up;
         }

         bigstring += "/" + symName + " Daily Bar: " + DoubleToString(pipsbarToday, 1) + " pips " + resultingDay + "\n" + "Yesterday Bar: " + DoubleToString(pipsbar, 1) + " pips" + resultingYDay + "\n";
         Print("Daily Bar: " + pipsbar + " Symbol ", str);
      }
   }

   return (bigstring);
}

//Search through all global varibales by name
string _MT5_GlobalVariable_search(string search)
{
   // total number of globals within the terminal
   int total = GlobalVariablesTotal();
   // loop over all the values
   for (int i = 0; i < total; i++)
   {

      // cycles through all the globals.

      if (StringFind(GlobalVariableName(i), search, 0) == 0)
      {

         //  Alert(GlobalVariableName(i)," = ",GlobalVariableGet(GlobalVariableName(i)));

         //   GlobalVariablesDeleteAll("gr1_");
      }
   }

   return ("");
}

//
int _MT5_Orders_Count_Buy(string sym)
{
   int count = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--) // returns the number of current orders
      if (m_order.SelectByIndex(i))
      { // selects the pending order by index for further access to its properties

         if (m_order.Symbol() == sym)
         {
            if ((m_order.OrderType() == ORDER_TYPE_BUY_LIMIT) || (m_order.OrderType() == ORDER_TYPE_BUY_STOP))

               count++;
         }
      }
   return (count);
}

//
int _MT5_Orders_Count_Sell(string sym)
{
   int count = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--) // returns the number of current orders
      if (m_order.SelectByIndex(i))
      { // selects the pending order by index for further access to its properties

         if (m_order.Symbol() == sym)

         {
            if ((m_order.OrderType() == ORDER_TYPE_SELL_LIMIT) || (m_order.OrderType() == ORDER_TYPE_SELL_STOP))
               count++;
         }
      }
   return (count);
}

// input: ticketnumber || symbolClose Position based on Ticket Number
int _MT5_Positions_Close(string sym)
{
   int count=0;
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == sym){
            
             long  ticket_number =  m_position.Ticket();
              count++;
              m_trade.PositionClose(ticket_number, 0);
         }

            
         
      }
   }
   return(count);
}


// input: ticketnumber || symbolClose Position based on Ticket Number
void _MT5_Position_Close(long ticket_number)
{
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (m_position.SelectByIndex(i))
      {

         if (m_position.Ticket() == ticket_number)
         {
            /*
                find the symbol 
                run the DeleteOrders Function
                then try to close the position
                
                There might be a situation where the position has no limit orders, 
                else,
                try to close the position anyways.
               */
            string what_market = m_position.Symbol();

            if (_MT5_Orders_Delete(what_market) > 0)
            {
               m_trade.PositionClose(ticket_number, 0);
            }
            else
            {
               m_trade.PositionClose(ticket_number, 0);
            }
         }
      }
   }
}





// input: string symbol || Delete Pending orders and return the number count
int _MT5_Orders_Delete(string sym)
{
   int count = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--) // returns the number of current orders
      if (m_order.SelectByIndex(i))
      { // selects the pending order by index for further access to its properties

         if (m_order.Symbol() == sym)
         {
            // delete all orders
            m_trade.OrderDelete(m_order.Ticket());
            count++;
         }
      }
   return (count);
}

//Return a json string for telegram "/Health" function
string _MT5_User_AccountBalance()
{
   string id_Server = AccountInfoString(ACCOUNT_SERVER);
   long id_Login = AccountInfoInteger(ACCOUNT_LOGIN);
   string id_Currency = AccountInfoString(ACCOUNT_CURRENCY);
   double id_Acc = AccountInfoDouble(ACCOUNT_PROFIT);
   double id_Bal = AccountInfoDouble(ACCOUNT_BALANCE);
   string msg = "";

   msg = "Profit/Loss: " + DoubleToString(id_Acc, 8) + " (" + id_Currency + ")" + " (" + DoubleToString((id_Acc / id_Bal) * 100, 1) + "% PNL)" + "\n" +
         "Balance: " + DoubleToString(id_Bal, 8) + "\n" +
         "Equity: " + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 8) + "\n" +
         "Free Margin: " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 8) + "\n" +
         "\n" +
         "Server: " + id_Server + "\n" +
         "Account: " + IntegerToString(id_Login) + "\n\n" +

         _MT5_Positions_Manager(id_Bal);

   return (msg);
}

// Telegram string to manage the positions
string _MT5_Positions_Manager(double balance)
{
   string msg = "";

   // how many positions do we have
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (m_position.SelectByIndex(i))
      {

         string sym = m_position.Symbol();
         double exposure = m_position.Volume() * m_position.PriceOpen();
         double exposure_percent = (exposure / balance) * 100;

         // Build the message string
         msg += "\n" + sym + " " + DoubleToString(m_position.PriceCurrent(), 8) + "\n" +
                "Entry: " + DoubleToString(m_position.PriceOpen(), 8) + "\n" +
                "Profit: " + DoubleToString(m_position.Profit(), 8) + "\n" +
                "Size: " + DoubleToString(m_position.Volume(), 1) + "\n" +
                "Exposure: " + DoubleToString(exposure, 8) + " (" + DoubleToString(exposure_percent, 1) + "%)" + "\n\n" +

                //  "Swap: " +  DoubleToString( m_position.Swap(),8)  +"\n"+ // not needed for Crypto

                "Action: /close" + IntegerToString(m_position.Ticket()) + "\n\n" +

                "Action: /delete" + sym + " (" + IntegerToString(_MT5_Orders_Count_Buy(sym)) + "|" + IntegerToString(_MT5_Orders_Count_Sell(sym)) + ")" + "\n\n" +

                //    "Action: /risk" + sym + "_" + DoubleToString(getRobotRiskPercentage(sym), 1) + "\n\n" +

                //    "Action: /positions" + sym + "_" + IntegerToString(getRobotHowManyPositions(sym), 0) + "\n\n" +

                //   "Action: /profit" + sym + "_" + DoubleToString(getRobotProfitPercentage(sym), 4) + "\n\n" +

                "";
      }
   }
   return (msg);
}

// telegram signal logic , working with logical ideas now

// Modify the stoploss on an open position
void _MT5_Positions_Modify(string sym, string what_side, double input_value_sl, double input_value_tp, string modify_type)
{
   // how many positions do we have
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (m_position.SelectByIndex(i))
      {
         if (m_position.Symbol() == sym && what_side == "buy")
         {

            if (m_position.TakeProfit() == 0 && m_position.StopLoss() == 0 && input_value_sl != 0 && input_value_tp != 0)
            {
               // position modify
               m_trade.PositionModify(m_position.Ticket(), input_value_sl, input_value_tp);
            }
            if (m_position.TakeProfit() == 0 && input_value_tp != 0)
            {
               // position modify
               m_trade.PositionModify(m_position.Ticket(), NULL, input_value_tp);
            }
            if (m_position.StopLoss() == 0 && input_value_sl != 0)
            {
               // position modify
               m_trade.PositionModify(m_position.Ticket(), input_value_sl, NULL);
            }else if(modify_type == "trail" && input_value_sl != 0){
               // position modify
               m_trade.PositionModify(m_position.Ticket(), input_value_sl, NULL);
            }
         }
         //==
         if (m_position.Symbol() == sym && what_side == "sell")
         {

            if (m_position.TakeProfit() == 0 && m_position.StopLoss() == 0 && input_value_sl != 0 && input_value_tp != 0)
            {
               // position modify
               m_trade.PositionModify(m_position.Ticket(), input_value_sl, input_value_tp);
            }
            if (m_position.TakeProfit() == 0 && input_value_tp != 0)
            {
               // position modify
               m_trade.PositionModify(m_position.Ticket(), NULL, input_value_tp);
            }
            if (m_position.StopLoss() == 0 && input_value_sl != 0)
            {
               // position modify
               m_trade.PositionModify(m_position.Ticket(), input_value_sl, NULL);
            }else if(modify_type =="trail" && input_value_sl != 0){
               // position modify
               m_trade.PositionModify(m_position.Ticket(), input_value_sl, NULL);
            }
         }
      }
   }
}

// Modify the stoploss on an open position
double _MT5_Positions_EntryPrice(string sym, string what_side)
{
   // how many positions do we have
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (m_position.SelectByIndex(i))
      {
         if (m_position.Symbol() == sym)
         {
            if (what_side == "buy")
            {
               return (m_position.PriceOpen());
            }
            else if (what_side == "sell")
            {
               return (m_position.PriceOpen());
            }
         }
      }
   }

   return (0);
}

//+----------------------------------------------------------------------+ 
//| Gets the number of bars that are displayed (visible) in chart window | 
//+----------------------------------------------------------------------+ 
int _MT5_Chart_VisibleBars(const long chart_ID=0) 
  { 
//--- prepare the variable to get the property value 
   long result=-1; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetInteger(chart_ID,CHART_VISIBLE_BARS,0,result)) 
     { 
      //--- display the error message in Experts journal 
      Print(__FUNCTION__+", Error Code = ",GetLastError()); 
     } 
//--- return the value of the chart property 
   return((int)result); 
  }
  
//+------------------------------------------------------------------+ 
//| Gets the width of chart (in pixels)                              | 
//+------------------------------------------------------------------+ 
int _MT5_Chart_WidthInPixels(const long chart_ID=0) 
  { 
//--- prepare the variable to get the property value 
   long result=-1; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetInteger(chart_ID,CHART_WIDTH_IN_PIXELS,0,result)) 
     { 
      //--- display the error message in Experts journal 
     // Print(__FUNCTION__+", Error Code = ",GetLastError()); 
      if(DEV_DEBUG)   Print(__FUNCTION__+", Error Code = ",GetLastError() +" chartid: " + chart_ID  + " | r " + result ); 
    
     } 
//--- return the value of the chart property 
   return((int)result); 
  }
  
//+------------------------------------------------------------------+ 
//| Gets the height of chart (in pixels)                             | 
//+------------------------------------------------------------------+ 
int _MT5_Chart_HeightInPixels(const long chart_ID=0) 
  { 
//--- prepare the variable to get the property value 
   long result=-1; 
//--- reset the error value 
   ResetLastError(); 
//--- receive the property value 
   if(!ChartGetInteger(chart_ID,CHART_HEIGHT_IN_PIXELS,result)) 
     { 
      //--- display the error message in Experts journal 
      if(DEV_DEBUG)  Print(__FUNCTION__+", Error Code = ",GetLastError()  +" chartid: " + chart_ID +  " | r " + result ); 
     } 
//--- return the value of the chart property 
   return((int)result); 
  } 
  
  
  
  
string _MT5_Candle_Direction(string symName){
  
  
      string message_pos_neg  ="";
   
       double  c1= iClose(symName, PERIOD_CURRENT, 0);
       double   o1 = iOpen(symName, PERIOD_CURRENT, 0);
         
         if( c1 > o1 ){ 
            message_pos_neg = "+ ";
         
         }else{
             message_pos_neg = "- ";
         }

     double     c2 = iClose(symName, PERIOD_CURRENT, 1);
     double     o2 = iOpen(symName, PERIOD_CURRENT, 1);
         if( c2 > o2){ 
            message_pos_neg += "+ ";
         
         }else{
             message_pos_neg += "- ";
         }
         
      double    c3 = iClose(symName, PERIOD_CURRENT, 2);
      double   o3 = iOpen(symName, PERIOD_CURRENT, 2);
            if( c3 >o3 ){ 
            message_pos_neg += "+ ";
         
         }else{
             message_pos_neg += "- ";
         }
         
      double    c4 = iClose(symName, PERIOD_CURRENT, 3);
      double   o4 = iOpen(symName, PERIOD_CURRENT, 3);
            if( c4 >o4 ){ 
            message_pos_neg += "+ ";
         
         }else{
             message_pos_neg += "- ";
         }
        
      double    c5= iClose(symName, PERIOD_CURRENT, 4);
      double    o5 = iOpen(symName, PERIOD_CURRENT, 4);
            if( c5 > o5 ){ 
            message_pos_neg += "+ ";
         
         }else{
             message_pos_neg += "- ";
         }
         
      double   c6 = iClose(symName, PERIOD_CURRENT, 5);
      double    o6 = iOpen(symName, PERIOD_CURRENT, 5);
            if( c6 > o6 ){ 
            message_pos_neg += "+ ";
         
         }else{
             message_pos_neg += "- ";
         }
         
      double   c7 = iClose(symName, PERIOD_CURRENT, 6);
     double    o7 = iOpen(symName, PERIOD_CURRENT, 6);
            if( c7> o7 ){ 
            message_pos_neg += "+ ";
         
         }else{
             message_pos_neg += "- ";
         }
   return(message_pos_neg);
   
}

// daily change
double DailyOpenPrice=0;
double DailyCurrentPrice=0;
double DailyRangePrice=0;
string DailySignal = "";


double _MT5_Candle_Daily_Change(string symName){
  
      DailySignal = "";//reset
      string message_pos_neg  ="";
      
   
       double  c1= iClose(symName, PERIOD_D1, 0);
       double   o1 = iOpen(symName, PERIOD_D1, 0);
       
       double  h1= iHigh(symName, PERIOD_D1, 0);
       double   l1 = iLow(symName, PERIOD_D1, 0);
       
       DailyRangePrice = h1 - l1;
       
       DailyOpenPrice = o1;
       DailyCurrentPrice = c1;
       
        double value_change;
         
         if( c1 > o1 ){ 
         // bullish ( usdt are on)
         value_change =  (c1 - o1 )/c1;
         DailySignal = "ON: /USDT OFF: /BTC /ETH";
         
         }
         
         if( c1 < o1 ){ 
         // bearish ( USDT pairs are off)
         value_change =  (o1 - c1 )/c1;
         value_change =  value_change*-1;
          DailySignal = "ON: /BTC /ETH OFF: /USDT";
         
         }
         
          if( c1 ==o1 ){ 
          value_change =0;
          DailySignal = "ON: /BTC /ETH OFF: /USDT";
          }
          
          value_change = value_change * 100;
         
         return( NormalizeDouble(value_change,2) );
}


string _MT5_Global_PatternName(){

     double value =  GlobalVariableGet("PatternName");
     
     if(value <=0) return("ERROR");
  
  
      if(value==1){
         return("BULLISH ENGULFING");
      }
      if(value==2){
         return("BEARISH ENGULFING");
      }
      if(value==3){
         return("BULLISH INSIDE BAR");
      }
      if(value==4){
         return("BEARISH INSIDE BAR");
      }

      return("NONE"); 
}



double _MT5_Price_Bid(string market){

 // To be used for getting recent/latest price quotes
               MqlTick Latest_Price;                      // Structure to get the latest prices
               SymbolInfoTick(market, Latest_Price); // Assign current prices to structure
            
               // The BID price.
             //  static double dBid_Price;
            
               // The ASK price.
               static double dAsk_Price;
            
            //   dBid_Price = Latest_Price.bid; // Current Bid price.
               dAsk_Price = Latest_Price.ask; // Current Ask price.
               
               return(dAsk_Price);
}





string _MT5_Position_Details(double commission)
{
   string msg = "";
   double pr = 0;
   double st_comm = 0;;
   double priceOpen=0;
   string grab_sym = "";
   string  msg2 = "";
   
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (m_position.SelectByIndex(i))
      {
         grab_sym = m_position.Symbol();
        
         priceOpen = m_position.PriceOpen();
         pr =  _MT5_Price_Bid(grab_sym);
         st_comm = pr*commission;
         
         
         //buy or sell order ((m_order.OrderType() == ORDER_TYPE_BUY_LIMIT)
         if(m_position.PositionType() == POSITION_TYPE_BUY){
            msg2 = "/ask_p"+DoubleToString(priceOpen+st_comm,2);
         }
          if(m_position.PositionType() == POSITION_TYPE_SELL){
            msg2 = "/bid_p"+DoubleToString(priceOpen-st_comm,2);
         }
         
         
         msg += "\n\n/Symbol "+grab_sym+
         
         "\nPrice: "+pr+
         "\nEntry Price: " + 
            DoubleToString(priceOpen,2) +
            
            "\nCommission: " + 
            DoubleToString(st_comm,2) +" (BE) " + msg2 +
         
         
         "\n/Volume: " +
            m_position.Volume() + 
            
            "\nStoploss: " + m_position.StopLoss();
            
         
      }
   }
   return(msg);
}










/*
   get the number value from the user text bid_p837583
   
   if bid_p or ask_p
*/

double _MT5_Parse_bidask_p(string text)
{
   //  "\"  \bid
   // take the dash out 
   string dash = StringSubstr(text, 0, 1);
   double num =0;
   string matched = "";


 //  if (dash  == "/")// working , step two
 //  {
      //bid_p or ask_p
      matched = StringSubstr(text, 1, 5);
      
      num=  StringToDouble( StringSubstr(text, 6) );
      
 //  }
   
   Print(" number " + num + " matched " + matched + " dash " +dash );
  return(num);
}


double _MT5_Parse_volume(string text)
{
   //  "\"  \bid
   // take the dash out 
   string dash = StringSubstr(text, 0, 1);
   double num =0;
   string matched = "";


 //  if (dash  == "/")// working , step two
 //  {
      //volume:_
      matched = StringSubstr(text, 1, 8);
      
      num=  StringToDouble( StringSubstr(text, 9) );
      
 //  }
   
   Print(" number " + num + " matched " + matched + " dash " +dash );
  return(num);
}























string _MT5_Parse_string_symbol(string text)
{
   //  "\"  \bid
   // take the dash out 
   string dash = StringSubstr(text, 0, 1);
   string sym  ="";
   string matched = "";


 //  if (dash  == "/")// working , step two
 //  {
      //symbol
      matched = StringSubstr(text, 1, 6);
      
      sym=  StringSubstr(text, 8);
      
 //  }
   
   Print(" sym -" + sym + "- matched -" + matched + "- dash " +dash );
  return(sym);
}