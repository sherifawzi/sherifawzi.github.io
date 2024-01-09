
   //===========================================================================================================
   //=====                                          INCLUDES                                               =====
   //===========================================================================================================

   #include <newFunctions.mqh>

   #define SNR_BOTVER      "Bot Version: 23.12.27"

   #property copyright     SNR_COPYRIGHT
   #property link          SNR_WEBSITE
   #property description   SNR_LIBVER
   #property description   SNR_BOTVER

   //===========================================================================================================
   //=====                                            ENUMS                                                =====
   //===========================================================================================================

////   enum IchiType { sNoIchi = 0 , sBoth = 1 , sFirst = 2 , sSecond = 3 , sNone = 4 } ;

   //===========================================================================================================
   //=====                                           INPUTS                                                =====
   //===========================================================================================================

   input group "Main Settings:"

   string            myMagic                 = "SNR"        ; // EA Magic Number
   string            myMagicSuffix           = ""           ; // EA Magic Suffix
   input int         iMaxAllowedDD           = 20           ; // Quit test beyond this DD [0=Disabled]
   input int         iMaxAllowedDays         = 0            ; // Quit test if no trades for X Days [0=Disabled]
   input bool        iUseSL                  = false        ; // Use SL
   enumRiskLevel     RiskLevel               = Highest      ; // Risk appetite
   double            myMaxCapitalPerc        = 0            ; // Max capital percent to use [0=Disabled]
   double            myMaxLotPerK            = 0            ; // Max lot per 1K to use [0=Disabled]
   bool              myBeaconMode            = false        ; // Beacon mode activated
////   input string      mySettings              = ""           ;
////   string            mySunsetDate            = ""           ; // EA Sunset Date [empty=Disabled]

   input group "Variables to test:"

   input int         iTPMultiple             = 0            ; // Variable 1-1-3
////   input int         iSMAPeriod              = 20           ; // Variable 20-10-50
////   input int         iSMATrend               = 1            ; // Variable 1-1-3
   input int         iRSIPeriod              = 3            ; // Variable 3-1-5
   input int         iRSITrend               = 1            ; // Variable 1-1-3
////   input int         iADXPeriod              = 3            ; // Variable 3-1-5
////   input int         iADXTrend               = 1            ; // Variable 1-1-3
////   input int         iADXTarget              = 25           ; // Variable 25-5-45

////   input bool        iUseEquBal              = false        ; // Variable T/F
////   input bool        iUseSession             = false        ; // Variable T/F
////   input bool        iUseDaily               = false        ; // Variable T/F

////   input bool        iuseSMA                 = false        ; // Variable T/F
////   input bool        iuseEMA                 = false        ; // Variable T/F
////   input bool        iuseSMMA                = false        ; // Variable T/F
////   input bool        iuseDEMA                = false        ; // Variable T/F
////   input bool        iuseTEMA                = false        ; // Variable T/F
////   input bool        iuseSAR                 = false        ; // Variable T/F
////   input bool        iuseFrama               = false        ; // Variable T/F
////   input bool        iuseVidya               = false        ; // Variable T/F
////   input bool        iuseAMA                 = false        ; // Variable T/F

   input bool        iuseRSI                 = false        ; // Variable T/F
   input bool        iuseChaikin             = false        ; // Variable T/F
   input bool        iuseCCI                 = false        ; // Variable T/F
   input bool        iuseDemarker            = false        ; // Variable T/F
   input bool        iuseForce               = false        ; // Variable T/F
   input bool        iuseMomentum            = false        ; // Variable T/F
   input bool        iuseWPR                 = false        ; // Variable T/F
   input bool        iuseRVI                 = false        ; // Variable T/F
   input bool        iuseMFI                 = false        ; // Variable T/F
   input bool        iuseAO                  = false        ; // Variable T/F
   input bool        iuseTrix                = false        ; // Variable T/F
////   input bool        iuseADX                 = false        ; // Variable T/F
////   input bool        iuseADXW                = false        ; // Variable T/F

////   input int         iUseIchi                = 0            ; // Variable 0-1-4

////   input bool        iUseCloseBiggest        = false        ; // Variable T/F
   input bool        iUseRSIClose            = false        ; // Variable T/F

   //===========================================================================================================
   //=====                                          VARIABLES                                              =====
   //===========================================================================================================

   double            iGlobalLotSize          = 1            ; // Global Lot Size
////   int               iDelayHour              = 8            ; // Monday delayed start and Friday early finish [0=Disabled]

////   bool              iReverseSignal          = false        ; // Reverse Signal
////   bool              iUseYesterdayHL         = false        ; // Use yesterdays HL
////   bool              iOpenReverseTradeAlso   = false        ; // Open reverse trade at half targets
////   bool              iOneTradePerDirection   = false        ; // Only one trade per direction
////   bool              iUseBarChartOpinion     = false        ; // Use BarChart opinion
   enumTradeCount    iUseMultiTrade          = Single_Trade ; // Split trade
   bool              isMinTradeMode          = false        ;
////   bool              iEndOfDayCloser         = false        ;
   int               MinutesSinceLastTrade   = 0            ;
   bool              OK2OnTrade              = false        ;

   int TPMultiple , SMAPeriod , SMATrend , RSIPeriod , RSITrend , ADXPeriod , ADXTrend , ADXTarget , UseIchi ;
////   bool UseEquBal , UseSession , UseDaily , useSMA , useEMA , useSMMA , useDEMA , useTEMA , useSAR , useFrama ;
   bool useVidya , useAMA , useRSI , useChaikin , useCCI , useDemarker , useForce , useMomentum , useWPR ;
   bool useRVI , useMFI , useAO , useTrix , useADX , useADXW , UseCloseBiggest , UseRSIClose ;
   bool UseSNREntry = false ;

   double ATR_C=0 , myTPV=0 , myTPV2=0 , mySLV=0 , myLotSLV=0 ;
   enumTradeType sCurr_AllowedTrade = glb_AllowedTrade ;
   double StartBalanceForKill ;

   //===========================================================================================================
   //=====                                       INITIALIZATION                                            =====
   //===========================================================================================================

   void OnInit () {
      goOnInit ( __FILE__ ) ;
      // if ( glb_DebugMode ) { goDebug ( "OnInit" ) ; }
      // -------------------- Expiry date check
////      goLocalFile_Write ( "Tester started" , myMagicSuffix ) ;
      // -------------------- Config String symbol and broker check
////      if ( !goCheck_ConfigString ( mySettings ) ) { ExpertRemove () ; return ; }
      // --------------------
      glb_FC = 2 ;
      glb_BD = 5 ;
      glb_Magic = myMagic ;
////      glb_SunsetDate = mySunsetDate ;
      glb_BroadID = glb_Magic ;
      glb_MaxCapitalPerc = myMaxCapitalPerc ;
      glb_MaxLotPerK = myMaxLotPerK ;
      glb_BeaconMode = myBeaconMode ;
      glb_LotSize = iGlobalLotSize ;
      glb_MinTradeMode = isMinTradeMode ;
      glb_SilentMode = true ;
////      goDraw_ControlPanel () ;
////      string mySettings2Use = UT ( mySettings ) ;
      StartBalanceForKill = sBal () ;
////      if ( UT ( mySettings2Use ) == "" ) {
         TPMultiple = iTPMultiple ; TPMultiple = 0 ;
////         SMAPeriod = iSMAPeriod ;
////         SMATrend = iSMATrend ;
         RSIPeriod = iRSIPeriod ;
         RSITrend = iRSITrend ;
////         ADXPeriod = iADXPeriod ;
////         ADXTrend = iADXTrend ;
////         ADXTarget = iADXTarget ;
////         UseEquBal = iUseEquBal ;
////         UseSession = iUseSession ;
////         UseDaily = iUseDaily ;
////         useSMA = iuseSMA ;
////         useEMA = iuseEMA ;
////         useSMMA = iuseSMMA ;
////         useDEMA = iuseDEMA ;
////         useTEMA = iuseTEMA ;
////         useSAR = iuseSAR ;
////         useFrama = iuseFrama ;
////         useVidya = iuseVidya ;
////         useAMA = iuseAMA ;
         useRSI = iuseRSI ;
         useChaikin = iuseChaikin ;
         useCCI = iuseCCI ;
         useDemarker = iuseDemarker ;
         useForce = iuseForce ;
         useMomentum = iuseMomentum ;
         useWPR = iuseWPR ;
         useRVI = iuseRVI ;
         useMFI = iuseMFI ;
         useAO = iuseAO ;
         useTrix = iuseTrix ;
////         useADX = iuseADX ;
////         useADXW = iuseADXW ;
////         UseIchi = iUseIchi ;
////         UseCloseBiggest = iUseCloseBiggest ;
         UseRSIClose = iUseRSIClose ; }
////      } else {
////         string safSplit[] ;
////         StringSplit ( mySettings2Use , StringGetCharacter ( "|" , 0 ) , safSplit ) ;
////         TPMultiple = (int) safSplit[0] ;
////         SMAPeriod = (int) safSplit[1] ;
////         // -------------------- Start of TR4 Variant here
////         if ( UT ( safSplit[1] ) == "TR4" ) { UseSNREntry = true ; }
////         // -------------------- End of TR4 Variant here
////         SMATrend = (int) safSplit[2] ;
////         RSIPeriod = (int) safSplit[3] ;
////         RSITrend = (int) safSplit[4] ;
////         ADXPeriod = (int) safSplit[5] ;
////         ADXTrend = (int) safSplit[6] ;
////         ADXTarget = (int) safSplit[7] ;
////         if ( ( UT ( safSplit [ 8 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { UseEquBal = true ; } else { UseEquBal = false ; }
////         if ( ( UT ( safSplit [ 9 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { UseSession = true ; } else { UseSession = false ; }
////         if ( ( UT ( safSplit [ 10 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { UseDaily = true ; } else { UseDaily = false ; }
////         if ( ( UT ( safSplit [ 11 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useSMA = true ; } else { useSMA = false ; }
////         if ( ( UT ( safSplit [ 12 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useEMA = true ; } else { useEMA = false ; }
////         if ( ( UT ( safSplit [ 13 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useSMMA = true ; } else { useSMMA = false ; }
////         if ( ( UT ( safSplit [ 14 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useDEMA = true ; } else { useDEMA = false ; }
////         if ( ( UT ( safSplit [ 15 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useTEMA = true ; } else { useTEMA = false ; }
////         if ( ( UT ( safSplit [ 16 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useSAR = true ; } else { useSAR = false ; }
////         if ( ( UT ( safSplit [ 17 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useFrama = true ; } else { useFrama = false ; }
////         if ( ( UT ( safSplit [ 18 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useVidya = true ; } else { useVidya = false ; }
////         if ( ( UT ( safSplit [ 19 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useAMA = true ; } else { useAMA = false ; }
////         if ( UT ( safSplit [ 20 ] ) == "TRUE" ) { useRSI = true ; } else { useRSI = false ; }
////         if ( UT ( safSplit [ 21 ] ) == "TRUE" ) { useChaikin = true ; } else { useChaikin = false ; }
////         if ( UT ( safSplit [ 22 ] ) == "TRUE" ) { useCCI = true ; } else { useCCI = false ; }
////         if ( UT ( safSplit [ 23 ] ) == "TRUE" ) { useDemarker = true ; } else { useDemarker = false ; }
////         if ( UT ( safSplit [ 24 ] ) == "TRUE" ) { useForce = true ; } else { useForce = false ; }
////         if ( UT ( safSplit [ 25 ] ) == "TRUE" ) { useMomentum = true ; } else { useMomentum = false ; }
////         if ( UT ( safSplit [ 26 ] ) == "TRUE" ) { useWPR = true ; } else { useWPR = false ; }
////         if ( UT ( safSplit [ 27 ] ) == "TRUE" ) { useRVI = true ; } else { useRVI = false ; }
////         if ( UT ( safSplit [ 28 ] ) == "TRUE" ) { useMFI = true ; } else { useMFI = false ; }
////         if ( UT ( safSplit [ 29 ] ) == "TRUE" ) { useAO = true ; } else { useAO = false ; }
////         if ( UT ( safSplit [ 30 ] ) == "TRUE" ) { useTrix = true ; } else { useTrix = false ; }
////         if ( ( UT ( safSplit [ 31 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useADX = true ; } else { useADX = false ; }
////         if ( ( UT ( safSplit [ 32 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useADXW = true ; } else { useADXW = false ; }
////         if ( UseSNREntry == false ) { UseIchi = (int) safSplit[33] ; }
////         if ( ( UT ( safSplit [ 34 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { UseCloseBiggest = true ; } else { UseCloseBiggest = false ; }
////         if ( UT ( safSplit [ 35 ] ) == "TRUE" ) { UseRSIClose = true ; } else { UseRSIClose = false ; }}
////      goAutoDeploy_Check ( myMagicSuffix , mySettings ) ;
////      string safStatusPointer = "" ;
////      if ( StringFind ( UT ( glb_Magic ) , "TEST" , 0 ) < 0 ) {
////         safStatusPointer = glb_EAS + myMagicSuffix + "|" + mySettings ; }
////      goBroadcast_OPS ( goTele_PrepMsg ( "TESTER" , "STARTED" , safStatusPointer , SNR_LIBVER , SNR_BOTVER ) ) ; }

   //===========================================================================================================
   //=====                                         BUTTON FUNCTION                                         =====
   //===========================================================================================================

////   void OnChartEvent ( const int id , const long &lparam , const double &dparam , const string &sparam ) {
////      // if ( glb_DebugMode ) { goDebug ( "OnChartEvent" ) ; }
////      if ( id == CHARTEVENT_OBJECT_CLICK ) {
////         goDraw_ButtonPress ( sparam , "DOWN" ) ;
////         if ( sparam == "CloseAll" ) { goClose_AllOrders () ; goClose_AllPositions () ; }
////         if ( sparam == "CloseMostProfit" ) { goClose_BiggestProfitPosition () ; }
////         if ( sparam == "ClosePositive" ) { goClose_PositivePositions ( 0.01 ) ; }
////         if ( sparam == "BuyButton" ) { BuyButton () ; }
////         if ( sparam == "SellButton" ) { SellButton () ; }
////         if ( sparam == "SetSL" ) { goTrail_AfterBE_SLV ( ATR_C , 0.1 ) ; }
////         if ( sparam == "SetSLNow" ) { goTrail_Immediately_SLV ( ATR_C ) ; }
////         if ( sparam == "ForceBE" ) { goTrail_OnlyBE ( 2 * sPoint() ) ; }
////         if ( sparam == "KillButton" ) {
////            string TextToKill = ObjectGetString ( 0 , "CommentToClose" , OBJPROP_TEXT ) ;
////            if ( StringLen ( TextToKill ) < 10 ) {
////               Comment ( "Kill string is too short, it must be at least 10 characters long" ) ; return ; }
////            goClose_PositionWithComment ( TextToKill ) ; }
////         if ( sparam == "PauseButton" ) {
////            if ( glb_AllowedTrade == No_Trade ) {
////               glb_AllowedTrade = sCurr_AllowedTrade ;
////               Comment ( "TRADING IS ON" ) ;
////            } else {
////               glb_AllowedTrade = No_Trade ;
////               Comment ( "TRADING IS OFF" ) ; }}
////         goDraw_ButtonPress ( sparam , "UP" ) ; }}

   //===========================================================================================================
   //=====                                       ENTRY FUNCTION                                            =====
   //===========================================================================================================

   void OnTick () {
      // if ( glb_DebugMode ) { goDebug ( "OnTick" ) ; }
      if ( !IsNewCandle() ) { return ; }
      OK2OnTrade = false ;
      MinutesSinceLastTrade += 1 ;
////      if ( iEndOfDayCloser == true ) {
////         if ( IsNewDay() == true ) { goClose_EndOfPeriodChecks ( "1" , 1 ) ; }}
      goKillAccount_Check ( iMaxAllowedDD , iMaxAllowedDays , StartBalanceForKill , MinutesSinceLastTrade ) ;
      goCheckEntry () ;
      if ( glb_BeaconMode == false ) { if ( PositionsTotal() > 0 ) { goCheckExit () ; }}
      OK2OnTrade = true ; }
////      if ( !IsNewHour() ) { return ; }
////      goSunsetRobot ( glb_EAS + myMagicSuffix + "|" + mySettings ) ;
////      goAutoDeploy_Check ( myMagicSuffix , mySettings ) ; }

   void goCheckEntry() {
      // if ( glb_DebugMode ) { goDebug ( "goCheckEntry" ) ; }
      string mySig = "" ;
      if ( ind_ATR ( 14 ) == false ) { return ; }
      ATR_C = B0 [ glb_FC ] ;
      // -------------------- TR4XL Main Indicator
      mySig += goSignal_EntrySNR() ;
      // -------------------- Non indicator filters
////      if ( ( iDelayHour > 0 ) && ( UseSNREntry == false ) ) {
////         if ( goDelayMondayStart ( iDelayHour ) == "X" ) { return ; }
////         if ( goEndFridayEarly ( ( 24 - iDelayHour - 2 ) ) == "X" ) { return ; }}
////      if ( ( IsDay_NoTradeDay () ) && ( UseSNREntry == false ) ) { return ; }
////      if ( ( ( sAsk() - sBid() ) > ATR_C * 0.5 ) && ( UseSNREntry == false ) ) { return ; }
////      if ( UseEquBal == true ) { if ( sEqu() < sBal() ) { return ; }}
      mySig += goCalc_TradeRange ( "1" , 120 , 90 ) ; if ( !GCS ( mySig ) ) { return ; }
////      if ( UseSession == true ) { mySig += IsSession_Auto () ; if ( !GCS ( mySig ) ) { return ; }}
////      if ( UseDaily == true ) { mySig += goCheck_Daily200MA ( "EMA" , glb_EAS , 0 ) ; if ( !GCS ( mySig ) ) { return ; }}
      // -------------------- Trends
////      if ( useSMA == true ) { mySig += goSignal_Trend ( "1" , "SMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
////      if ( useEMA == true ) { mySig +=  goSignal_Trend ( "1" , "EMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
////      if ( useSMMA == true ) { mySig += goSignal_Trend ( "1" , "SMMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
////      if ( useDEMA == true ) { mySig += goSignal_Trend ( "1" , "DEMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
////      if ( useTEMA == true ) { mySig += goSignal_Trend ( "1" , "TEMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
////      if ( useSAR == true ) { mySig += goSignal_Trend ( "1" , "SAR" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
////      if ( useFrama == true ) { mySig += goSignal_Trend ( "1" , "FRAMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
////      if ( useVidya == true ) { mySig += goSignal_Trend ( "1" , "VIDYA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
////      if ( useAMA == true ) { mySig += goSignal_Trend ( "1" , "AMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
      // -------------------- Oscis
      string RSIMethod = "1" ;
      if ( useRSI == true ) { mySig += goSignal_Oscillator ( RSIMethod , "RSI" , RSIPeriod , RSITrend , 50 , 50 , 85 , 15 ) ; if ( !GCS ( mySig ) ) { return ; }} // ----- ( 30 , 50 , 70 ) -----
      if ( useChaikin == true ) { mySig += goSignal_Oscillator ( RSIMethod , "CHAIKIN" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( mySig ) ) { return ; }} // ----- ( x , 0 , x ) -----
      if ( useCCI == true ) { mySig += goSignal_Oscillator ( RSIMethod , "CCI" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( mySig ) ) { return ; }} // ----- ( 100 , 0 , -100 ) -----
      if ( useDemarker == true ) { mySig += goSignal_Oscillator ( RSIMethod , "DEMARKER" , RSIPeriod , RSITrend , 0.5 , 0.5 , 0.85 , 0.15 ) ; if ( !GCS ( mySig ) ) { return ; }} // ----- ( 0.3 , 0.5 , 0.7 ) -----
      if ( useForce == true ) { mySig += goSignal_Oscillator ( RSIMethod , "FORCE" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( mySig ) ) { return ; } } // ----- ( x , 0 , x ) -----
      if ( useMomentum == true ) { mySig += goSignal_Oscillator ( RSIMethod , "MOMENTUM" , RSIPeriod , RSITrend , 100 , 100 , 0 , 0 ) ; if ( !GCS ( mySig ) ) { return ; }} // ----- ( x , 100 , x ) -----
      if ( useWPR == true ) { mySig += goSignal_Oscillator ( RSIMethod , "WPR" , RSIPeriod , RSITrend , -50 , -50 , 0 , 0 ) ; if ( !GCS ( mySig ) ) { return ; }} // ----- ( -80 , -50 , -20 ) -----
      if ( useRVI == true ) { mySig += goSignal_Oscillator ( RSIMethod , "RVI" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( mySig ) ) { return ; }} // ----- ( x , 0 , x ) -----
      if ( useMFI == true ) { mySig += goSignal_Oscillator ( RSIMethod , "MFI" , RSIPeriod , RSITrend , 50 , 50 , 85 , 15 ) ; if ( !GCS ( mySig ) ) { return ; }} // ----- ( 20 , 50 , 80 ) -----
      if ( useAO == true ) { mySig += goSignal_Oscillator ( RSIMethod , "AO" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( mySig ) ) { return ; }} // ----- ( x , 0 , x ) -----
      if ( useTrix == true ) { mySig += goSignal_Oscillator ( RSIMethod , "TRIX" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( mySig ) ) { return ; }} // ----- ( x , 0 , x ) -----
////      string ADXMethod = "1" ;
////      if ( useADX == true ) { mySig += goSignal_ADX ( ADXMethod , "ADX" , ADXPeriod , ADXTrend , ADXTarget , 0 ) ; if ( !GCS ( mySig ) ) { return ; }}
////      if ( useADXW == true ) { mySig += goSignal_ADX ( ADXMethod , "ADXW" , ADXPeriod , ADXTrend , ADXTarget , 0 ) ; if ( !GCS ( mySig ) ) { return ; }}
      // -------------------- Ichimoku
////      if ( UseIchi > 0 ) {
////         if ( UseIchi == 1 ) { mySig += goSignal_Ichimoku( "12345678" ) ; if ( !GCS ( mySig ) ) { return ; }}
////         if ( UseIchi == 2 ) { mySig += goSignal_Ichimoku( "1234578" ) ; if ( !GCS ( mySig ) ) { return ; }}
////         if ( UseIchi == 3 ) { mySig += goSignal_Ichimoku( "1245678" ) ; if ( !GCS ( mySig ) ) { return ; }}
////         if ( UseIchi == 4 ) { mySig += goSignal_Ichimoku( "124578" ) ; if ( !GCS ( mySig ) ) { return ; }}}
      // -------------------- Other here
////      if ( iUseYesterdayHL == true ) { mySig += goCheck_Position2Yesterday () ; if ( !GCS ( mySig ) ) { return ; }}
////      if ( iUseBarChartOpinion == true ) {
////         // mySig += goCheck_BarChartOpinion ( EASymbol ) ; if ( !GCS ( mySig ) ) { return ; }}
////         mySig += goSignal_MyOpinion () ; if ( !GCS ( mySig ) ) { return ; }}
      // -------------------- Trade here
      mySig = goCleanSignal ( mySig ) ;
////      if ( iReverseSignal == true ) { mySig = goReverseSignal ( mySig ) ; }
      // -------------------- BUY HERE
      if ( mySig == "B" ) {
         MinutesSinceLastTrade = 0 ;
////         if ( UseCloseBiggest == true ) { goClose_BiggestProfitPosition () ; }
////         if ( iOneTradePerDirection == true ) { if ( goCount_NoSLBuyPositions() > 0 ) { return ; }}
////         if ( sBid() > glb_PI[1].close ) { BuyButton () ; }}
         if ( glb_PI[1].close > glb_PI[2].close ) { BuyButton () ; }}
      // -------------------- SELL HERE
      else if ( mySig == "S" ) {
         MinutesSinceLastTrade = 0 ;
////         if ( UseCloseBiggest == true ) { goClose_BiggestProfitPosition () ; }
////         if ( iOneTradePerDirection == true ) { if ( goCount_NoSLSellPositions() > 0 ) { return ; }}
////         if ( sAsk() < glb_PI[1].close ) { SellButton () ; }}}
         if ( glb_PI[1].close < glb_PI[2].close ) { SellButton () ; }}}

   //===========================================================================================================
   //=====                                       TRADE FUNCTIONS                                           =====
   //===========================================================================================================

   void goCheckExit () {
      // if ( glb_DebugMode ) { goDebug ( "goCheckExit" ) ; }
      // goTrail_AfterBE_SLV ( ATR_C ) ;
      Trail_After_XATR ( 14 , 2 , 1 ) ;
      // goTrail_AfterBE_SLV_Multi ( 1 ) ;
      // goTrail_OnlyBE ( ATR_C ) ;
      if ( UseRSIClose == true ) { goClose_OnRSI ( "2" , 0.1 , 50 ) ; }}

   void BuyButton () {
      // if ( glb_DebugMode ) { goDebug ( "BuyButton" ) ; }
      goCalcStops () ; if ( glb_AllowedTrade == No_Trade ) { return ; }
      int NoOfTrades = 1 ; //// if ( iUseMultiTrade == 1 ) { NoOfTrades = 3 ; } else if ( iUseMultiTrade == 2 ) { NoOfTrades = 10 ; }
      string safComment = glb_Magic + "|B/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + glb_EAS ;
      // if ( myMagicSuffix != "" ) { safComment += ( "/" + myMagicSuffix ) ; }
      sBuy ( iUseMultiTrade , NoOfTrades , mySLV , myTPV , ( 2 * myLotSLV ) , 0.5 , -1 , "B" , 0 , safComment ) ; }
      // goAutoDeploy_LogBuyTrade ( ATR_C , safComment , myMagicSuffix ) ;
////      if ( iOpenReverseTradeAlso ) { sSell ( iUseMultiTrade , NoOfTrades , mySLV , myTPV2 , ( 4 * myLotSLV ) , 0.5 ) ; }}

   void SellButton () {
      // if ( glb_DebugMode ) { goDebug ( "SellButton" ) ; }
      goCalcStops () ; if ( glb_AllowedTrade == No_Trade ) { return ; }
      int NoOfTrades = 1 ; //// if ( iUseMultiTrade == 1 ) { NoOfTrades = 3 ; } else if ( iUseMultiTrade == 2 ) { NoOfTrades = 10 ; }
      string safComment = glb_Magic + "|S/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + glb_EAS ;
      // if ( myMagicSuffix != "" ) { safComment += ( "/" + myMagicSuffix ) ; }
      sSell ( iUseMultiTrade , NoOfTrades , mySLV , myTPV , ( 2 * myLotSLV ) , 0.5 , -1 , "S" , 0 , safComment ) ; }
      // goAutoDeploy_LogSellTrade ( ATR_C , safComment , myMagicSuffix ) ;
////      if ( iOpenReverseTradeAlso ) { sBuy ( iUseMultiTrade , NoOfTrades , mySLV , myTPV2 , ( 4 * myLotSLV ) , 0.5 ) ; }}

   void goCalcStops () {
      // if ( glb_DebugMode ) { goDebug ( "goCalcStops" ) ; }
      if ( RiskLevel == LYDR3 ) {
         myLotSLV = goCalc_LastYearDayRange() * 0.5 ;
      } else {
         string myRiskString = goTranslate_RiskLevel ( RiskLevel ) ;
         int myDiv = 1 ; if ( RiskLevel == Lowest ) { myDiv = 50 ; }
         else if ( RiskLevel == Lower ) { myDiv = 20 ; }
         else if ( RiskLevel == Low ) { myDiv = 3 ; }
         myLotSLV = goCalc_PercentSLV ( "" , myRiskString , myDiv ) ; }
      if ( iUseSL == true ) { mySLV = myLotSLV ; }
      // if ( TPMultiple > 0 ) { myTPV = ATR_C * TPMultiple ; } else { myTPV = ATR_C ; }}
      if ( TPMultiple > 0 ) { myTPV = ATR_C * TPMultiple ; } else { myTPV = 0 ; }}
////      if ( myTPV == 0 ) { myTPV2 = ATR_C / 2 ; } else { myTPV2 = MathMin ( ( myTPV / 2 ) , ( ATR_C / 2 ) ) ; }}

   void OnTrade () {
      // if ( glb_DebugMode ) { goDebug ( "OnTrade" ) ; }
      if ( OK2OnTrade == false ) { return ; }
      // goTrail_AfterBE_SLV ( ATR_C ) ;
      Trail_After_XATR ( 14 , 2 , 1 ) ; }

   void OnTesterInit () {
      string safHeader = "Pass,Result,Profit,Expected Payoff,Profit Factor,Recovery Factor,Sharpe Ratio,Custom,Equity DD %,Trades" ;
      goTester_FileWrite ( sTestFN() , safHeader , "n" ) ; }

   double OnTester () { return 0 ; }

   void OnTesterDeinit () { ; }