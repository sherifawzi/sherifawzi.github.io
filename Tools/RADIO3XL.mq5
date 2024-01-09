
   //===========================================================================================================
   //=====                                          INCLUDES                                               =====
   //===========================================================================================================

   #include <newFunctions.mqh>

   #define SNR_BOTVER      "Bot Version: 24.01.03"

   #property copyright     SNR_COPYRIGHT
   #property link          SNR_WEBSITE
   #property description   SNR_LIBVER
   #property description   SNR_BOTVER

   //===========================================================================================================
   //=====                                           INPUTS                                                =====
   //===========================================================================================================

   input group "Main Settings:"

   input string      iRobot2Follow           = "BB;TVM;8CAP;MB;VAN"      ;  // Robot to follow
   double      myMaxCapitalPerc        = 65                    ; // Max capital percent to use [0=Disabled]
   double      myMaxLotPerK            = 0.015                 ; // Max lot per 1K to use [0=Disabled]

   input group "Close Settings:"

   input bool        iEndOfDayCloser         = false                 ; // Close open trades at new day
   input int         DrawDrownTriggerPercent = 10                    ; // DD% Trigger [0=Disabled]
   input enumMaxDD   iMaxDDBehaviour         = Trade_Half_Half_Min   ; // Drawdown behaviour

   input group "MultiBank suffix handlers:"

   input bool        AddThreeDots            = false                 ; // Add MultiBank suffix to incoming signal
   input bool        RemoveThreeDots         = true                  ; // Remove MultiBank suffix from incoming signal

   //===========================================================================================================
   //=====                                          VARIABLES                                              =====
   //===========================================================================================================

   int               myTimeOutPeriod         = 3500                  ;
   bool              OK2OnTrade              = true                  ;
   enumTradeType     sCurr_AllowedTrade      = glb_AllowedTrade      ;
   string            Robot2Follow            = ""                    ;

   //===========================================================================================================
   //=====                                       INITIALIZATION                                            =====
   //===========================================================================================================

   void OnInit () {
      goOnInit ( __FILE__ ) ;
      // if ( glb_DebugMode ) { goDebug ( "OnInit" ) ; }
      goLocalFile_Write ( "Radio started" ) ;
      glb_MaxCapitalPerc   = myMaxCapitalPerc ;
      glb_MaxLotPerK       = myMaxLotPerK ;
      glb_MaxDDTrigger     = DrawDrownTriggerPercent ;
      glb_MaxDDBehaviour   = iMaxDDBehaviour ;
      glb_BeaconMode       = false ;
      Robot2Follow         = UT ( iRobot2Follow ) ;
      if ( Robot2Follow == "" ) { ExpertRemove() ; }
      glb_BroadID          = IntegerToString ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ;
         goBroadcast_OPS ( goTele_PrepMsg ( "RADIO" , "STARTED" , SNR_LIBVER , SNR_BOTVER ) ) ;
      glb_BroadID          =  "" ; } // Empty to stop sending back executed trade instructions

   //===========================================================================================================
   //=====                                       ENTRY FUNCTION                                            =====
   //===========================================================================================================

   void OnTick () {
      // if ( glb_DebugMode ) { goDebug ( "OnTick" ) ; }
      if ( !IsNewCandle() ) { return ; }
      OK2OnTrade = false ;
         if ( iEndOfDayCloser == true ) {
            if ( IsNewDay() == true ) { goClose_EndOfPeriodChecks ( "1" , 1 ) ; }}
         goCheckEntry () ;
         if ( PositionsTotal() > 0 ) { goCheckExit () ; }
      OK2OnTrade = true ;
      if ( IsNewDay() ) {
         int safDelay = sRandomNumber ( 1 , 120000 ) ;
         Sleep ( safDelay ) ;
         if ( goTrimmer_Check ( 2 , 2678400 ) == false ) {
            if ( goTrimmer_Check ( 1 , 1339200 ) == false ) {
               goTrimmer_Check ( 0.5 , 669600 ) ; }}
         goHistory_Send2Server() ; }}

   void goCheckEntry () {
      // if ( glb_DebugMode ) { goDebug ( "goCheckEntry" ) ; }
      // -------------------- Store global variables
      string sCurr_Symbol = glb_EAS ;
      double sCurr_GlobalLotSize = glb_LotSize ;
         // -------------------- Main work starts here
         Sleep ( myTimeOutPeriod ) ;
         string myMessages [] , safSplit [] ;
         goTele_GetMsgs ( Robot2Follow , myMessages ) ;
         if ( ArraySize ( myMessages ) < 1 ) { return ; }
         string ExecutedTradesThisMinute = "" ;
         for ( int i = 0 ; i < ArraySize ( myMessages ) ; i++ ) {
            StringSplit ( UT ( myMessages [ i ] ) , StringGetCharacter ( "|" , 0 ) , safSplit ) ;
            if ( ArraySize ( safSplit ) < 14 ) { continue ; }
            goPrint ( ">  >   >   >   Received: " + myMessages [ i ] ) ;
            // Start + BotName + DateTime + safType + 01 + 02 + 03 + symbol + 04 + 05 + 06 + 07 + 08 + 09 + 10 + Hash + End
            string msgRobotName     = safSplit [ 0 ] ;
            string msgDateTime      = safSplit [ 1 ] ;
            string msgType          = UT ( safSplit [ 2 ] ) ;
            string msgVal01         = safSplit [ 3 ] ;  // safTradeType
            string msgVal02         = safSplit [ 4 ] ;  // NoOfTrades
            string msgVal03         = safSplit [ 5 ] ;  // safSLV
            string msgSymbol        = safSplit [ 6 ] ;  // glb_EAS
            string msgVal04         = safSplit [ 7 ] ;  // safTPV
            string msgVal05         = safSplit [ 8 ] ;  // safPercCalcSLV
            string msgVal06         = safSplit [ 9 ] ;  // safStopsMultiple
            string msgVal07         = safSplit [ 10 ] ; // safLot
            string msgVal08         = safSplit [ 11 ] ; // safStart
            string msgVal09         = safSplit [ 12 ] ; // GlobalLotSize
            string msgVal10         = safSplit [ 13 ] ; // Comment
            // -------------------- Checks here
            if ( msgType == "" ) { continue ; }
            if ( msgSymbol == "" ) { continue ; } else { glb_EAS = msgSymbol ; }
            if ( RemoveThreeDots == true ) { StringReplace ( glb_EAS , "." , "" ) ; } // Remove ... from MB
            if ( AddThreeDots == true ) { glb_EAS = StringSubstr ( ( glb_EAS + "..." ) , 0 , 9 ) ; } // Add ... from MB
            // -------------------- Add symbol to data windows if not there
            goSymbol_AddToDataWindow ( glb_EAS ) ;
            // -------------------- Type here
            if ( msgType == "STOP" ) {
               glb_AllowedTrade = No_Trade ;
               goPrint ( "Trading Stopped" ) ; }
            else if ( msgType == "START" ) {
               glb_AllowedTrade = sCurr_AllowedTrade ;
               goPrint ( "Trading Resumed" ) ; }
            else if ( msgType == "TOP" ) {
               myTimeOutPeriod = MathMax ( 1000 , (int)msgVal01 ) ;
               goPrint ( "Timeout period changed to: " + string( myTimeOutPeriod ) ) ; }
            else if ( ( ( msgType == "B" ) || ( msgType == "S" ) ) && ( glb_AllowedTrade != No_Trade ) ) {
               if ( ArraySize ( safSplit ) < 15 ) { continue ; }
               // -------------------- Prepare trade variables
               enumTradeCount safTradeType   = (enumTradeCount) msgVal01 ;
               int NoOfTrades                = (int) msgVal02 ;
               double safSLV                 = (double) msgVal03 * sPoint() ;
               double safTPV                 = (double) msgVal04 * sPoint() ;
               double safPercCalcSLV         = (double) msgVal05 * sPoint() ;
               double safStopsMultiple       = (double) msgVal06 ;
               double safLot                 = (double) msgVal07 ;
               double safStart               = (double) msgVal08 ;
               glb_LotSize                   = (double) msgVal09 ;
               string safComment             = msgVal10 + "|" + safSplit [ 14 ] ;
               // -------------------- Buy Here
               if ( msgType == "B" ) {
                  if ( goCount_NoSLBuyPositions ( "1" ) > 0 ) {
                     goPrint ( "Skip trade due to open with No SL rule" ) ;
                  } else {
                     if ( StringFind ( ExecutedTradesThisMinute , ( glb_EAS + "|B" ) , 0 ) < 0 ) {
                        sBuy ( safTradeType , NoOfTrades , safSLV , safTPV , safPercCalcSLV , safStopsMultiple , safLot , msgType , safStart , safComment ) ;
                        ExecutedTradesThisMinute += ( glb_EAS + "|B" ) ; }}}
               // -------------------- Sell Here
               else if ( msgType == "S" ) {
                  if ( goCount_NoSLSellPositions ( "1" ) > 0 ) {
                     goPrint ( "Skip trade due to open with No SL rule" ) ;
                  } else {
                     if ( StringFind ( ExecutedTradesThisMinute , ( glb_EAS + "|S" ) , 0 ) < 0 ) {
                        sSell ( safTradeType , NoOfTrades , safSLV , safTPV , safPercCalcSLV , safStopsMultiple , safLot , msgType , safStart , safComment ) ;
                        ExecutedTradesThisMinute += ( glb_EAS + "|S" ) ; }}}}
            else if ( msgType == "CBPP" ) { goClose_BiggestProfitPosition () ; }
            else if ( msgType == "CBLP" ) { goClose_BiggestLossPosition () ; }
            else if ( msgType == "CAO" ) { goClose_AllOrders () ; }
            else if ( msgType == "CAP" ) { goClose_AllPositions () ; }
            else if ( msgType == "TRBE" ) { prvPosition_Trail ( (double) msgVal01 , (double) msgVal02 , (double) msgVal03 , msgVal04 , (int) msgVal05 ) ; }
            else if ( msgType == "TRSLV" ) { prvPosition_Trail ( (double) msgVal01 , (double) msgVal02 , (double) msgVal03 , msgVal04 , (int) msgVal05 ) ; }
            else if ( msgType == "CABP" ) { prvPosition_Closer ( msgVal01 , (double) msgVal02 , msgVal03 ) ; }
            else if ( msgType == "CASP" ) { prvPosition_Closer ( msgVal01 , (double) msgVal02 , msgVal03 ) ; }
            else if ( msgType == "CAPP" ) { prvPosition_Closer ( msgVal01 , (double) msgVal02 , msgVal03 ) ; }
            else if ( msgType == "COA" ) { prvOrder_Closer ( msgVal01 , (double) msgVal02 , msgVal03 ) ; }
            else if ( msgType == "COB" ) { prvOrder_Closer ( msgVal01 , (double) msgVal02 , msgVal03 ) ; }
            else if ( msgType == "CABO" ) { prvOrder_Closer ( msgVal01 , (double) msgVal02 , msgVal03 ) ; }
            else if ( msgType == "CASO" ) { prvOrder_Closer ( msgVal01 , (double) msgVal02 , msgVal03 ) ; }
            else if ( msgType == "TRSA" ) { goTrail_Stepped_TradeAmount ( (double) msgVal01 , (double) msgVal02 , (double) msgVal03 , msgVal04 ) ; }
            else if ( msgType == "KILL" ) { prvPosition_Closer ( msgVal01 , (double) msgVal02 , msgVal03 , msgVal04 ) ; }
            else if ( msgType == "ID" ) {
               Sleep ( int ( sRandomNumber ( 10 , 500 ) * 100 ) ) ;
               goBroadcast_ID ( string ( myTimeOutPeriod ) ) ; }
            else if ( msgType == "ROBOT" ) { Robot2Follow = msgVal01 ; goPrint ( Robot2Follow ) ; }
            else if ( msgType == "TRIM" ) { goTrimmer_Check ( double ( msgVal01 ) , int ( msgVal02 ) ) ; }
            glb_EAS = sCurr_Symbol ;
            glb_LotSize = sCurr_GlobalLotSize ; }
      // -------------------- Return global variables
      glb_EAS = sCurr_Symbol ;
      glb_LotSize = sCurr_GlobalLotSize ; }

   //===========================================================================================================
   //=====                                       TRADE FUNCTIONS                                           =====
   //===========================================================================================================

   void goCheckExit () {
      // if ( glb_DebugMode ) { goDebug ( "goCheckExit" ) ; }
      // goATR ( 14 ) ; double ATR_C = B0 [ FirstCandle ] ;
      // goTrail_OnlyBE ( ATR_C ) ;
      // goTrail_AfterBE_SLV ( ATR_C ) ;
      goTrail_AfterBE_SLV_Multi ( 1 ) ; }

   void OnTrade () {
      // if ( glb_DebugMode ) { goDebug ( "OnTrade" ) ; }
      if ( OK2OnTrade == false ) { return ; }
      goTrail_AfterBE_SLV_Multi ( 1 ) ; }