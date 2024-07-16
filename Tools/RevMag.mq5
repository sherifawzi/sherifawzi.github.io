
   //===========================================================================================================
   //=====                                          INCLUDES                                               =====
   //===========================================================================================================

   #include <newFunctions.mqh>

   #define SNR_BOTVER      "Bot Version: 24.07.16"

   #property copyright     SNR_COPYRIGHT
   #property link          SNR_WEBSITE
   #property description   SNR_LIBVER
   #property description   SNR_BOTVER

   //===========================================================================================================
   //=====                                            ENUMS                                                =====
   //===========================================================================================================

   enum TrailType { NoTrail=0 , AfterBESLV=1 , AfterXATR21=2 , AfterXATR32=3 } ;

   //===========================================================================================================
   //=====                                           INPUTS                                                =====
   //===========================================================================================================

   input group "Bot settings:"
   input int      robo_MaxDD              = 99 ;      // Test fail DD% [Tests Only]
   input string   robo_Settings           = "" ;      // EA Config String
   input string   robo_SunsetDate         = "" ;      // EA Sunset Date [empty=Disabled]

   input group "Hedger settings:"
   input int      inp_PeriodATR           = 1440 ;    // ATR period [14-62-1440]
   input int      inp_HedgeATRMultiple    = 1 ;       // Hedge distance in ATR multiples [1-1-5]
   input int      inp_MaxNoOfHedges       = 0 ;       // Max No Of hedges allowed [5-5-20]
   input double   inp_MinHedgeDistance    = 20 ;      // Minimum hedge distance in points [20-10-100]

   input group "Counter settings:"
   input bool     inp_OpenCounterTrade    = false ;   // Open counter trade at max hedge count [Y/N]
   input int      inp_CounterMaxHours     = 0 ;       // Max counter hours before close all [5-5-50]

   input group "Trade size settings:"
   input double   inp_StartLotSize        = 0.01 ;    // Start lot size
   input double   inp_LotSizeIncrement    = 0.01 ;    // Lost size increment per hedge [0-0.01-0.01]

   input group "Entry settings:"
   input int      inp_Trend_M1            = 0 ;       // EMA period on M1 [50-50-200]
   input int      inp_Trend_H1            = 0 ;       // EMA period on H1 [50-50-200]
   input int      inp_Trend_D1            = 0 ;       // EMA period on D1 [50-50-200]
   input bool     inp_UseSwapie           = false ;   // Trade in swap side only [Y/N]

   input group "Exit settings:"
   input double   inp_CloseAllProfit      = 1 ;       // Take profit and reset at this profit value [1-1-10]
   input bool     inp_CloseIfAllTriggered = false ;   // Close all at loss if all hedges triggered [Y/N]
   input int      inp_TrailType           = 0 ;       // Trail type [0-1-3]

   //===========================================================================================================
   //=====                                          VARIABLES                                              =====
   //===========================================================================================================

   double         robo_ATR                = 0 ;
   double         robo_StartBalance       = 0 ;
   bool           StartMode               = false ;
   bool           CounterMode             = false ;
   bool           TickLock                = false ;
   // double         OriginalOrderTP         = 0 ;
   string         robo_Magic              = "RevMag" ;

   int PeriodATR=0 , HedgeATRMultiple=0 , Trend_M1=0 , Trend_H1=0 , Trend_D1=0 , MaxNoOfHedges=0 ;
   int CounterMinutes=0 , CounterMaxHours=0 , useTrailType=0 ;
   double MinHedgeDistance=0 , StartLotSize=0 , LotSizeIncrement=0 , CloseAllProfit=0 , CounterPrice=0 ;
   bool CloseIfAllTriggered=false , UseSwapie=false , OpenCounterTrade=false ;

   //===========================================================================================================
   //=====                                       INITIALIZATION                                            =====
   //===========================================================================================================

   void OnInit () {
      goOnInit ( __FILE__ ) ;
      // -------------------- Bot Magic
      glb_Magic = robo_Magic ;
      // -------------------- Set balance to kill to
      robo_StartBalance = sBal() ;
      // -------------------- If there is a config string, setup as BEACON else as OPTIMIZER
      if ( StringLen ( robo_Settings ) > 0 ) { goSetupAs_Trader() ; } else { goSetupAs_Tester() ; }}

   void goSetupAs_Tester() {
      // -------------------- Setup tester type
      goTester_TA() ;
      // -------------------- Optimization mode ONLY actions
      if ( !glb_IsThisLive ) { if ( !goTester_CheckElapseTime () ) { ExpertRemove() ; return ; }}}

   void goSetupAs_Trader() {
      // -------------------- Decide on TR type
      goTrader_TA() ;
      // -------------------- Config String symbol and broker check
      if ( !goCheck_ConfigString ( robo_Settings ) ) { ExpertRemove() ; return ; }
      // -------------------- Broadcast start
      goBroadcast_IAMALIVE ( UT ( robo_Magic ) , SNR_BOTVER ) ; }

   //===========================================================================================================
   //=====                                       ENTRY FUNCTION                                            =====
   //===========================================================================================================

   void OnTick () {
      if ( TickLock ) { return ; }
      TickLock = true ;
         // -------------------- Main code here
         goExecuteCloseChecks() ;
         goExecuteTickCheck() ;
         // -------------------- x
         if ( useTrailType > 0 ) {
            if ( useTrailType == 1 )      { Trail_After_XATR ( 14 , 1 , 1 ) ; }
            else if ( useTrailType == 2 ) { Trail_After_XATR ( 14 , 2 , 1 ) ; }
            else if ( useTrailType == 3 ) { Trail_After_XATR ( 14 , 3 , 2 ) ; }}
         // -------------------- On ewn candle check
         if ( !IsNewCandle() ) { TickLock = false ; return ; }
         // -------------------- Increment CounterTrade minutes
          if ( CounterMode ) { CounterMinutes += 1 ; if ( CounterMinutes > ( CounterMaxHours * 60 ) ) { revmag_CloseAll() ; }}
         // -------------------- ReCalc ATR every minute
         if ( !ind_ATR ( PeriodATR ) ) { TickLock = false ; return ; }
         robo_ATR = B0 [ glb_FC ] ;
         // -------------------- Variables
         int safPos = revmag_PositionsTotal() ;
         // -------------------- After reset handler
         if ( ( safPos < 1 ) && ( StartMode == false ) ) {
            revmag_CloseAllOrdersByForce() ; Sleep ( 2000 ) ; goCreateFirstTrade () ; }
         // -------------------- OPTIMIZATION mode ONLY actions
         if ( !glb_IsThisLive ) {
            goKillAccount_Check ( robo_MaxDD , 0 , robo_StartBalance , 0 ) ; }
         // -------------------- Sunset handler
         if ( robo_SunsetDate != "" ) {
            goSunsetRobot ( robo_SunsetDate , string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) + "|" + robo_Settings ) ; }
      // -------------------- x
      TickLock = false ; }

   void goExecuteCloseChecks() {
      // -------------------- Reset if profit target reached
      if ( revmag_Profit() > CloseAllProfit ) { revmag_CloseAll () ; Sleep ( 3000 ) ; return ; }
      // -------------------- Variables
      int safPos = revmag_PositionsTotal() ;
      int safOrd = revmag_OrdersTotal() ;
      // -------------------- Close extra order after trigger first stop trade
      if ( StartMode == true ) {
         if ( safOrd > 0 ) { // And pending order still exists
            if ( safPos > 0 ) { // If one of the pending orders is triggered, close the other and exit start mode
               revmag_CloseAllOrdersByForce() ; Sleep ( 2000 ) ; StartMode = false ; return ; }
         // -------------------- return so as not to trigger the next orphan handler
         } return ; }
      // -------------------- If there is an orphan order close it
      if ( ( safPos < 1 ) && ( safOrd > 1 ) ) {
         revmag_CloseAllOrdersByForce() ; Sleep ( 2000 ) ; return ; }
      // -------------------- If original trade closed the close all
      static int LastPosCount = 0 ;
      if ( safPos < LastPosCount ) { revmag_CloseAll() ; LastPosCount = 0 ; Sleep ( 2000 ) ; return ; } else { LastPosCount = safPos ; }}

   void goExecuteTickCheck() {
      // -------------------- Variables
      int safPos = revmag_PositionsTotal() ;
      int safOrd = revmag_OrdersTotal() ;
      // -------------------- Handle hedging
      if ( ( safPos > 0 ) && ( safOrd < 1 ) ) {
         // -------------------- Check max hedge count restrictions
         if ( MaxNoOfHedges > 0 ) { if ( safPos > MaxNoOfHedges ) {
            // -------------------- If rule is to close all if max hedge reached then close
            if ( CloseIfAllTriggered ) { revmag_CloseAll() ; Sleep ( 3000 ) ; }
            // -------------------- If rule is to open counter, we do it here
            if ( OpenCounterTrade ) { if ( !CounterMode ) { goCreateCounterTrade () ; Sleep ( 3000 ) ; }}
            // -------------------- Finally return so as not to open a new hedge
            return ; }}
         // -------------------- If no restrictions then hedge
         goCreateHedge() ; }}

   void goCreateFirstTrade () {
      // -------------------- Trade filters
      if ( ( sAsk() - sBid() ) > robo_ATR * 0.5 ) { return ; }
      if ( goDelayMondayStart ( 8 ) == "X" ) { return ; }
      if ( goEndFridayEarly ( 14 ) == "X" ) { return ; }
      if ( IsDay_NoTradeDay () ) { return ; }
      // -------------------- ENTRY WITHOUT INDICATORS
      if ( ( Trend_M1 == 0 ) && ( Trend_H1 == 0 ) && ( Trend_D1 == 0 ) ) {
         // -------------------- Open 2 tradestops here
         if ( ( revmag_BuyStop() ) && ( revmag_SellStop() ) ) { StartMode = true ; return ; }
         // -------------------- If failed to open both trades then close all and try again later
         revmag_CloseAllOrdersByForce() ; return ; }
      // -------------------- ENTRY WITH INDICATORS
      else {
         string mySig = "" ;
         if ( Trend_M1 > 0 ) { mySig += goSignalTF_TREND ( PERIOD_M1 , Trend_M1 , "EMA" , "1" ) ; }
         if ( Trend_H1 > 0 ) { mySig += goSignalTF_TREND ( PERIOD_H1 , Trend_H1 , "EMA" , "1" ) ; }
         if ( Trend_D1 > 0 ) { mySig += goSignalTF_TREND ( PERIOD_D1 , Trend_D1 , "EMA" , "1" ) ; }
         // -------------------- Clean Signal
         mySig = goCleanSignal ( mySig ) ;
         // -------------------- Execute trade here
         if ( mySig == "B" ) { revmag_Buy () ; } else if ( mySig == "S" ) { revmag_Sell () ; }}}

   void goCreateHedge () {
      // -------------------- x
      double LastLot = 0 ;
      double LastPrice = 0 ;
      long posType = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( PositionGetString ( POSITION_SYMBOL ) != glb_EAS ) { continue ; }
         // -------------------- Find highest lot size so far
         double posLot = PositionGetDouble ( POSITION_VOLUME ) ;
         if ( posLot > LastLot ) { LastLot = posLot ; }
         // -------------------- x
         double posPrice = PositionGetDouble ( POSITION_PRICE_OPEN ) ;
         // -------------------- x
         // double posTP = PositionGetDouble ( POSITION_TP ) ;
         // if ( posTP > 0 ) { OriginalOrderTP = posTP ; }
         // -------------------- x
         posType = PositionGetInteger ( POSITION_TYPE ) ;
         // -------------------- Find last price to use as anchor for next hedge
         if ( posType == POSITION_TYPE_BUY ) {
            if ( LastPrice == 0 ) { LastPrice = 9999999 ; }
            if ( posPrice < LastPrice ) { LastPrice = posPrice ; }}
         else if ( posType == POSITION_TYPE_SELL ) {
            if ( posPrice > LastPrice ) { LastPrice = posPrice ; }}}
         // -------------------- Place the hedge here
         if ( posType == POSITION_TYPE_BUY ) { revmag_BuyLimit ( LastLot , LastPrice ) ; }
         else if ( posType == POSITION_TYPE_SELL ) { revmag_SellLimit ( LastLot , LastPrice ) ; }}

   void goCreateCounterTrade () {
      // -------------------- x
      if ( CounterMode ) { return ; }
      // -------------------- x
      double TotalLot = 0 ;
      long posType = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( PositionGetString ( POSITION_SYMBOL ) != glb_EAS ) { continue ; }
         // -------------------- x
         TotalLot += PositionGetDouble ( POSITION_VOLUME ) ;
         // -------------------- x
         posType = PositionGetInteger ( POSITION_TYPE ) ; }
         // -------------------- x
         if ( posType == POSITION_TYPE_BUY ) {
            if ( CounterPrice > 0 ) {
               // -------------------- dont open counter if price is not at its level
               if ( sBid() > CounterPrice ) { return ; }
               // -------------------- otherwise set counter price
               CounterPrice = sBid() ; }
            // -------------------- Counter trade here
            if ( revmag_Sell ( TotalLot , 0 , 0 ) == true ) {
               // -------------------- Reset counter variables
               CounterMode = true ;
               CounterMinutes = 0 ; }}
         // -------------------- x
         else if ( posType == POSITION_TYPE_SELL ) {
            if ( CounterPrice > 0 ) {
               // -------------------- dont open counter if price is not at its level
               if ( sAsk() < CounterPrice ) { return ; }
               // -------------------- otherwise set counter price
               CounterPrice = sAsk() ; }
            // -------------------- Counter trade here
            if ( revmag_Buy ( TotalLot , 0 , 0 ) == true ) {
               // -------------------- Reset counter variables
               CounterMode = true ;
               CounterMinutes = 0 ; }}}

   //===========================================================================================================
   //=====                                       TRADE FUNCTIONS                                           =====
   //===========================================================================================================

   void revmag_BuyLimit ( double LastLot , double LastPrice ) {
      double newLot = ND2 ( LastLot + LotSizeIncrement ) ;
      double safDist = HedgeATRMultiple * MathMax ( ( MinHedgeDistance * sPoint() ) , robo_ATR ) ;
      double newPrice = ND ( MathMin ( ( LastPrice - safDist ) , ( sAsk() - safDist ) ) ) ;
      trade.BuyLimit ( newLot , newPrice , glb_EAS , 0 , 0 , ORDER_TIME_GTC , 0 , robo_Magic ) ; Sleep ( 2000 ) ; }

   void revmag_SellLimit ( double LastLot , double LastPrice ) {
      double newLot = ND2 ( LastLot + LotSizeIncrement ) ;
      double safDist = HedgeATRMultiple * MathMax ( ( MinHedgeDistance * sPoint() ) , robo_ATR ) ;
      double newPrice = ND ( MathMax ( ( LastPrice + safDist ) , ( sBid() + safDist ) ) ) ;
      trade.SellLimit ( newLot , newPrice , glb_EAS , 0 , 0 , ORDER_TIME_GTC , 0 , robo_Magic ) ; Sleep ( 2000 ) ; }

   bool revmag_BuyStop () {
      double safPrice   = ND ( sAsk() + robo_ATR ) ;
      // double safTP      = ND ( safPrice + robo_ATR ) ;
      bool success = trade.BuyStop ( StartLotSize , safPrice , glb_EAS , 0 , 0 , ORDER_TIME_GTC , 0 , robo_Magic ) ;
      Sleep ( 2000 ) ;
      return ( success ) ; }

   bool revmag_SellStop () {
      double safPrice   = ND ( sBid() - robo_ATR ) ;
      // double safTP      = ND ( safPrice - robo_ATR ) ;
      bool success = trade.SellStop ( StartLotSize , safPrice , glb_EAS , 0 , 0 , ORDER_TIME_GTC , 0 , robo_Magic ) ;
      Sleep ( 2000 ) ;
      return ( success ) ; }

   bool revmag_Buy ( double safLot=0 , double safSLV=0 , double safTPV=0 ) {
      if ( UseSwapie ) { if ( SymbolInfoDouble ( glb_EAS , SYMBOL_SWAP_LONG ) < 0 ) { return false ; }}
      if ( safLot == 0 ) { safLot = StartLotSize ; }
      double safPrice = ND ( sAsk() ) ;
      // double safTP = 0 ; if ( safTPV > 0 ) { safTP = ND ( safPrice + safTPV ) ; } // OriginalOrderTP = safTP ; }
      // double safSL = 0 ; if ( safSLV > 0 ) { safSL = ND ( safPrice - safSLV ) ; }
      bool success = trade.Buy ( ND2 ( safLot ) , glb_EAS , safPrice , 0 , 0 , robo_Magic ) ;
      Sleep ( 2000 ) ;
      return ( success ) ; }

   bool revmag_Sell ( double safLot=0 , double safSLV=0 , double safTPV=0 ) {
      if ( UseSwapie ) { if ( SymbolInfoDouble ( glb_EAS , SYMBOL_SWAP_SHORT ) < 0 ) { return false ; }}
      if ( safLot == 0 ) { safLot = StartLotSize ; }
      double safPrice = ND ( sBid() ) ;
      // double safTP = 0 ; if ( safTPV > 0 ) { safTP = ND ( safPrice - safTPV ) ; } // OriginalOrderTP = safTP ; }
      // double safSL = 0 ; if ( safSLV > 0 ) { safSL = ND ( safPrice + safSLV ) ; }
      bool success = trade.Sell ( ND2 ( safLot ) , glb_EAS , safPrice , 0 , 0 , robo_Magic ) ;
      Sleep ( 2000 ) ;
      return ( success ) ; }

   void revmag_CloseAll () {
      TickLock = true ;
         revmag_CloseAllPositionsByForce ();
         revmag_CloseAllOrdersByForce();
         CounterMode = false ;
         CounterPrice = 0 ;
         CounterMinutes = 0 ;
         // OriginalOrderTP = 0 ;
         Sleep ( 2000 ) ;
         goPrint ( string ( goCalc_TotalTradedLots() ) ) ;
      TickLock = false ; }

   //===========================================================================================================
   //=====                                       ON TESTER FUNCTIONS                                       =====
   //===========================================================================================================

   void OnTesterInit () {
      // -------------------- Construct and write report header
      string safHeader  = "ID,Result,Profit,Payoff,PF,RF,SR,Lots,DD%,Trades,Config String" ;
      goTester_OnInIt ( safHeader , __FILE__ , "" , robo_Magic ) ; }

   void OnTesterDeinit () {
      goTester_DeOnInIt ( __FILE__ , "/nTESTS/" + robo_Magic + "/" , robo_MaxDD , "" , robo_Magic , robo_Magic , "AI" , "2023.06.01" ) ; }

   double OnTester () {
      double tTotTradedLots = ND2 ( goCalc_TotalTradedLots() ) ;
      string ConfigString = goResult_TA() ;
      return ( goTester_OnTester ( ConfigString , robo_MaxDD , tTotTradedLots , "" , "1250|0|0|500" ) ) ; }

   string goResult_TA() {
      string result = "" ;
      // -------------------- Construct Config String
      result =  (string) inp_PeriodATR + "|" ;
      result += (string) inp_HedgeATRMultiple + "|" ;
      result += (string) inp_MinHedgeDistance + "|" ;
      result += (string) inp_StartLotSize + "|" ;
      result += (string) inp_LotSizeIncrement + "|" ;
      result += (string) inp_CloseAllProfit + "|" ;
      result += (string) inp_Trend_M1 + "|" ;
      result += (string) inp_Trend_H1 + "|" ;
      result += (string) inp_Trend_D1 + "|" ;
      result += (string) inp_UseSwapie + "|" ;
      result += (string) inp_MaxNoOfHedges + "|" ;
      result += (string) inp_CloseIfAllTriggered + "|" ;
      result += (string) inp_OpenCounterTrade + "|" ;
      result += (string) inp_CounterMaxHours + "|" ;
      result += (string) inp_TrailType + "|" ;
      return result ; }

   void goTester_TA() {
      PeriodATR            = inp_PeriodATR ;
      HedgeATRMultiple     = inp_HedgeATRMultiple ;
      MinHedgeDistance     = inp_MinHedgeDistance ;
      StartLotSize         = inp_StartLotSize ;
      LotSizeIncrement     = inp_LotSizeIncrement ;
      CloseAllProfit       = inp_CloseAllProfit ;
      Trend_M1             = inp_Trend_M1 ;
      Trend_H1             = inp_Trend_H1 ;
      Trend_D1             = inp_Trend_D1 ;
      UseSwapie            = inp_UseSwapie ;
      MaxNoOfHedges        = inp_MaxNoOfHedges ;
      CloseIfAllTriggered  = inp_CloseIfAllTriggered ;
      OpenCounterTrade     = inp_OpenCounterTrade ;
      CounterMaxHours      = inp_CounterMaxHours ;
      useTrailType         = inp_TrailType ; }

   void goTrader_TA() {
      // -------------------- Split config string into parts and check its correct
      string safSplit[] ; StringSplit ( UT ( robo_Settings ) , StringGetCharacter ( "|" , 0 ) , safSplit ) ;
      // -------------------- Variables
      int x = 0 ; int y = ArraySize ( safSplit ) ;
      // -------------------- Decode config string here
      x += 1 ; if ( y >= x ) { PeriodATR           = (int) safSplit [ x-1 ] ; } // 00
      x += 1 ; if ( y >= x ) { HedgeATRMultiple    = (int) safSplit [ x-1 ] ; } // 01
      x += 1 ; if ( y >= x ) { MinHedgeDistance    = (double) safSplit [ x-1 ] ; } // 02
      x += 1 ; if ( y >= x ) { StartLotSize        = (double) safSplit [ x-1 ] ; } // 03
      x += 1 ; if ( y >= x ) { LotSizeIncrement    = (double) safSplit [ x-1 ] ; } // 04
      x += 1 ; if ( y >= x ) { CloseAllProfit      = (double) safSplit [ x-1 ] ; } // 05
      x += 1 ; if ( y >= x ) { Trend_M1            = (int) safSplit [ x-1 ] ; } // 06
      x += 1 ; if ( y >= x ) { Trend_H1            = (int) safSplit [ x-1 ] ; } // 07
      x += 1 ; if ( y >= x ) { Trend_D1            = (int) safSplit [ x-1 ] ; } // 08
      x += 1 ; if ( y >= x ) { if ( safSplit [ x-1 ] == "TRUE" ) { UseSwapie = true ; }} // 09
      x += 1 ; if ( y >= x ) { MaxNoOfHedges       = (int) safSplit [ x-1 ] ; } // 10
      x += 1 ; if ( y >= x ) { if ( safSplit [ x-1 ] == "TRUE" ) { CloseIfAllTriggered = true ; }} // 11
      x += 1 ; if ( y >= x ) { if ( safSplit [ x-1 ] == "TRUE" ) { OpenCounterTrade = true ; }} // 12
      x += 1 ; if ( y >= x ) { CounterMaxHours       = (int) safSplit [ x-1 ] ; } // 13
      x += 1 ; if ( y >= x ) { useTrailType         = (int) safSplit [ x-1 ] ; }} // 14

   //===========================================================================================================
   //=====                              TESTER VERSUS OPERATIONS OPTIMIZATION                              =====
   //===========================================================================================================

   int revmag_PositionsTotal() {
      if ( !glb_IsThisLive ) { return PositionsTotal() ; }
      return ( goCount_PositionsTotal ( glb_EAS ) ) ; }

   int revmag_OrdersTotal() {
      if ( !glb_IsThisLive ) { return OrdersTotal() ; }
      return ( goCount_OrdersTotal ( glb_EAS ) ) ; }

   void revmag_CloseAllPositionsByForce() {
      if ( !glb_IsThisLive ) { goClose_AllPositionsByForce() ; return ; }
      goClose_AllPositions ( glb_EAS ) ; }

   void revmag_CloseAllOrdersByForce() {
      if ( !glb_IsThisLive ) { goClose_AllOrdersByForce () ; return ; }
      goClose_AllOrders ( glb_EAS ) ; }

   double revmag_Profit() {
      if ( !glb_IsThisLive ) { return ( sEqu() - sBal() ) ; }
      return ( goCalc_SymbolProfit ( glb_EAS ) ) ; }