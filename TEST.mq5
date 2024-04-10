
   //===========================================================================================================
   //=====                                          INCLUDES                                               =====
   //===========================================================================================================

   #include <newFunctions.mqh>

   #define SNR_BOTVER      "Bot Version: 24.04.10"

   #property copyright     SNR_COPYRIGHT
   #property link          SNR_WEBSITE
   #property description   SNR_LIBVER
   #property description   SNR_BOTVER

   //===========================================================================================================
   //=====                                            ENUMS                                                =====
   //===========================================================================================================

   enum IchiType { sNoIchi = 0 , sBoth = 1 , sFirst = 2 , sSecond = 3 , sNone = 4 } ;

   //===========================================================================================================
   //=====                                           INPUTS                                                =====
   //===========================================================================================================

   input group "Beacon Settings:"

   input string      robo_Magic        = "TEST"          ; // EA Magic Number
   input string      robo_MagicSuffix  = ""              ; // EA Magic Suffix
   input string      robo_Settings     = ""              ; // EA Config String
   input string      robo_SunsetDate   = ""              ; // EA Sunset Date [empty=Disabled]
   enumRiskLevel     robo_RiskLevel    = High            ; // Risk appetite

   input group "Tester Settings:"

   input int         inp_MaxDD            = 5            ; // Quit test beyond this DD [0=Disabled]
   input int         inp_MaxDays          = 0            ; // Quit test if no trades for X Days [0=Disabled]
   input bool        inp_SL               = false        ; // Use SL

   input group "Variables to test:"

   input int         inp_TPMultiple       = 0            ; // TP Multiple [1-1-3]
   input int         inp_SMAPeriod        = 20           ; // MA Period [20-10-50]
   input int         inp_SMATrend         = 1            ; // MA Trend [1-1-3]
   input int         inp_RSIPeriod        = 3            ; // Osci Period [3-1-5]
   input int         inp_RSITrend         = 1            ; // Osci Trend [1-1-3]
   input int         inp_ADXPeriod        = 3            ; // ADX Period [3-1-5]
   input int         inp_ADXTrend         = 1            ; // ADX Trend [1-1-3]
   input int         inp_ADXTarget        = 25           ; // ADX Target [25-5-45]
   input bool        inp_EquBal           = false        ; // EquBal [T/F]
   input bool        inp_Session          = false        ; // Session [T/F]
   input bool        inp_Daily            = false        ; // Daily [T/F]
   input bool        inp_SMA              = false        ; // SMA [T/F]
   input bool        inp_EMA              = false        ; // EMA [T/F]
   input bool        inp_SMMA             = false        ; // SMMA [T/F]
   input bool        inp_DEMA             = false        ; // DEMA [T/F]
   input bool        inp_TEMA             = false        ; // TEMA [T/F]
   input bool        inp_SAR              = false        ; // SAR [T/F]
   input bool        inp_Frama            = false        ; // Frama [T/F]
   input bool        inp_Vidya            = false        ; // Vidya [T/F]
   input bool        inp_AMA              = false        ; // AMA [T/F]
   input bool        inp_RSI              = false        ; // RSI [T/F]
   input bool        inp_Chaikin          = false        ; // Chaikin [T/F]
   input bool        inp_CCI              = false        ; // CCI [T/F]
   input bool        inp_Demarker         = false        ; // Demarker [T/F]
   input bool        inp_Force            = false        ; // Force [T/F]
   input bool        inp_Momentum         = false        ; // Momentum [T/F]
   input bool        inp_WPR              = false        ; // WPR [T/F]
   input bool        inp_RVI              = false        ; // RVI [T/F]
   input bool        inp_MFI              = false        ; // MFI [T/F]
   input bool        inp_AO               = false        ; // AO [T/F]
   input bool        inp_Trix             = false        ; // Trix [T/F]
   input bool        inp_ADX              = false        ; // ADX [T/F]
   input bool        inp_ADXW             = false        ; // ADXW [T/F]
   input int         inp_Ichi             = 0            ; // Ichi [0-1-4]
   input bool        inp_CloseBiggest     = false        ; // Close Biggest [T/F]
   input bool        inp_RSIClose         = false        ; // RSI Close [T/F]
   input bool        inp_Swapie           = false        ; // Swapie [T/F]
   input bool        inp_Trend_200M1      = false        ; // MA 200 M1 [T/F]
   input bool        inp_Trend_10M1       = false        ; // MA 10 M1 [T/F]
   input bool        inp_Trend_200H1      = false        ; // MA 200 H1 [T/F]
   input bool        inp_Trend_10H1       = false        ; // MA 10 H1 [T/F]
   input bool        inp_Trend_200D1      = false        ; // MA 200 D1 [T/F]
   input bool        inp_Trend_10D1       = false        ; // MA 10 D1 [T/F]
   input bool        inp_Osci_23M1        = false        ; // Osci 2/3 M1 [T/F]
   input bool        inp_Osci_23H1        = false        ; // Osci 2/3 H1 [T/F]
   input bool        inp_Osci_23D1        = false        ; // Osci 2/3 D1 [T/F]

   //===========================================================================================================
   //=====                                          VARIABLES                                              =====
   //===========================================================================================================

   double robo_ATR=0 , robo_TPV=0 , robo_SLV=0 , robo_LotSLV=0 ;
   int TPMultiple=0 , SMAPeriod=0 , SMATrend=0 , RSIPeriod=0 , RSITrend=0 ;
   int ADXPeriod=0 , ADXTrend=0 , ADXTarget=0 , useIchi=0 , robo_DelayHours=8 ;
   bool useEquBal=false , useSession=false , useDaily=false , useSMA=false , useEMA=false , useSMMA=false , useDEMA=false ;
   bool useTEMA=false , useSAR=false , useFrama=false , useVidya=false , useAMA=false , useRSI=false , useChaikin=false ;
   bool useCCI=false , useDemarker=false , useForce=false , useMomentum=false , useWPR=false , useRVI=false , useMFI=false ;
   bool useAO=false , useTrix=false , useADX=false , useADXW=false , useCloseBiggest=false , useRSIClose=false ;
   bool useSL=false , robo_OK2OnTrade=false , robo_T3=false , robo_T4=false , robo_T5=false ;
   bool useSwapie=false , useTrend_200M1=false , useTrend_10M1=false , useTrend_200H1=false , useTrend_10H1=false ;
   bool useTrend_200D1=false , useTrend_10D1=false , useOsci_23M1=false , useOsci_23H1=false , useOsci_23D1=false ;

   //===========================================================================================================
   //=====                                       INITIALIZATION                                            =====
   //===========================================================================================================

   void OnInit () {
      goOnInit ( __FILE__ ) ;
      // -------------------- Set global variables
      glb_BeaconMode = false ;
      glb_LotSize = 1 ;
      glb_Magic = robo_Magic ;
      glb_SunsetDate = robo_SunsetDate ;
      // -------------------- If there is a config string, setup as BEACON else as OPTIMIZER
      if ( StringLen ( robo_Settings ) > 0 ) { goSetupAs_Beacon() ; } else { goSetupAs_Tester() ; }}

   void goSetupAs_Tester() {
      // -------------------- Set risk level to highest
      robo_RiskLevel = High ;
      // -------------------- Setup tester type
      if ( robo_Magic == "TR3" ) { robo_T3 = true ; goTester_T3() ; }
      if ( robo_Magic == "TR4" ) { robo_T4 = true ; goTester_T4() ; }
      if ( robo_Magic == "TR5" ) { robo_T5 = true ; goTester_T5() ; }
     // -------------------- Optimization mode ONLY actions
      if ( MQLInfoInteger ( MQL_OPTIMIZATION ) ) {
         // -------------------- Remove if passed allowed run time
         if ( !goTester_CheckElapseTime () ) { ExpertRemove() ; return ; }}}

   void goSetupAs_Beacon() {
      // -------------------- Set risk level to highest
      robo_RiskLevel = High ;
      // -------------------- Decide on TR type
      if ( StringFind ( robo_Settings , "TR4" , 0 ) >= 0 )      { robo_T4 = true ; goBeacon_T4() ; }
      else if ( StringFind ( robo_Settings , "TR5" , 0 ) >= 0 ) { robo_T5 = true ; goBeacon_T5() ; }
      else                                                      { robo_T3 = true ; goBeacon_T3() ; }
      // -------------------- Config String symbol and broker check
      if ( !goCheck_ConfigString ( robo_Settings ) ) { ExpertRemove() ; return ; }
      // -------------------- Beacon mode ONLY actions
      if ( glb_BeaconMode ) {
         // -------------------- Set broadcast ID
         glb_BroadID = glb_Magic ;
         // -------------------- Log start
         goLocalFile_Write ( "Beacon started" , robo_MagicSuffix ) ;
         // -------------------- Check if already deployed
         goAutoDeploy_Check ( robo_MagicSuffix , robo_Settings ) ;
         // -------------------- Set i am alive addon
         string safStatusPointer = goFind_BotType ( robo_Settings ) ;
         if ( StringFind ( UT ( glb_Magic ) , "TEST" , 0 ) < 0 ) {
            safStatusPointer = glb_EAS + robo_MagicSuffix + "|" + robo_Settings ; }
         // -------------------- Broadcast start
         goBroadcast_IAMALIVE ( "BEACON" , SNR_BOTVER , safStatusPointer ) ; }}

   //===========================================================================================================
   //=====                                         MAIN FUNCTIONS                                          =====
   //===========================================================================================================

   void OnTick () {
      // -------------------- Abort checks
      if ( !IsNewCandle() ) { return ; }
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- Increment time since last trade
      glb_MinutesSinceTrade += 1 ;
      // -------------------- Main entry and exit funcs
      robo_OK2OnTrade = false ;
         goCheckEntry () ;
         goCheckExit () ;
      robo_OK2OnTrade = true ;
      // -------------------- OPTIMIZATION mode ONLY actions
      if ( MQLInfoInteger ( MQL_OPTIMIZATION ) ) {
         goKillAccount_Check ( inp_MaxDD , inp_MaxDays , glb_StartBalance , glb_MinutesSinceTrade ) ; }
      // -------------------- Hour check for sunset and autodeploy for BEACON
      if ( glb_BeaconMode ) {
         if ( !IsNewHour() ) { return ; }
         goSunsetRobot ( glb_EAS + robo_MagicSuffix + "|" + robo_Settings ) ;
         goAutoDeploy_Check ( robo_MagicSuffix , robo_Settings ) ; }}

   void OnTrade () {
      // -------------------- Check abort condition
      if ( !robo_OK2OnTrade ) { return ; }
      // -------------------- Trigger trails
      goCheckExit () ; }

   //===========================================================================================================
   //=====                                         TRADE FUNCTIONS                                         =====
   //===========================================================================================================

   void goCheckEntry() {
      // -------------------- Variables
      string mySig = "" ;
      // -------------------- Set ATR
      if ( !ind_ATR ( 14 ) ) { return ; }
      robo_ATR = B0 [ glb_FC ] ;
      // -------------------- Entry Conditions
      if      ( robo_T3 ) { mySig += goEntry_T3() ; }
      else if ( robo_T4 ) { mySig += goEntry_T4() ; }
      else if ( robo_T5 ) { mySig += goEntry_T5() ; }
      // -------------------- Clean signal
      mySig = goCleanSignal ( mySig ) ;
      // -------------------- Buy trade
      if ( mySig == "B" ) { goExecute_Buy() ;
         if ( useCloseBiggest ) { goClose_BiggestProfitPosition () ; }}
      // -------------------- Sell trade
      else if ( mySig == "S" ) { goExecute_Sell() ;
         if ( useCloseBiggest ) { goClose_BiggestProfitPosition () ; }}}

   void goCheckExit () {
      // -------------------- If no trades open then abort
      if ( PositionsTotal() < 1 ) { return ; }
      // -------------------- Exit conditions
      if      ( robo_T3 ) { goTrail_T3() ; }
      else if ( robo_T4 ) { goTrail_T4() ; }
      else if ( robo_T5 ) { goTrail_T5() ; }}

   void goExecute_Buy () {
      // -------------------- Set comment
      string safComment = glb_Magic + "|B/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + glb_EAS ;
      if ( robo_MagicSuffix != "" ) { safComment += ( "/" + robo_MagicSuffix ) ; }
      // -------------------- Calc trade stops and execute
      goCalcStops () ; sBuy ( robo_SLV , robo_TPV , ( 2 * robo_LotSLV ) , -1 , safComment ) ;
      // -------------------- Add trade to log and check autodeploy criteria
      if ( glb_BeaconMode ) { goAutoDeploy_LogBuyTrade (robo_ATR , safComment , robo_MagicSuffix ) ; }}

   void goExecute_Sell () {
      // -------------------- Set comment
      string safComment = glb_Magic + "|S/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + glb_EAS ;
      if ( robo_MagicSuffix != "" ) { safComment += ( "/" + robo_MagicSuffix ) ; }
      // -------------------- Calc trade stops and execute
      goCalcStops () ; sSell ( robo_SLV , robo_TPV , ( 2 * robo_LotSLV ) , -1 , safComment ) ;
      // -------------------- Add trade to log and check autodeploy criteria
      if ( glb_BeaconMode ) { goAutoDeploy_LogSellTrade (robo_ATR , safComment , robo_MagicSuffix ) ; }}

   void goCalcStops () {
      // -------------------- This is for lowest risk level
      if ( robo_RiskLevel == LYDR3 ) {
         robo_LotSLV = goCalc_LastYearDayRange() * 0.5 ; }
      // -------------------- Other risk levels
      else {
         // -------------------- Set divider value
         int myDiv = 1 ;
         if ( robo_RiskLevel == Lowest ) { myDiv = 50 ; }
         else if ( robo_RiskLevel == Lower ) { myDiv = 20 ; }
         else if ( robo_RiskLevel == Low ) { myDiv = 3 ; }
         // -------------------- Translate risk level
         string myRiskString = goTranslate_RiskLevel ( robo_RiskLevel ) ;
         robo_LotSLV = goCalc_PercentSLV ( "" , myRiskString , myDiv ) ; }
      // -------------------- Set SL if activated
      if ( useSL ) { robo_SLV = robo_LotSLV ; }
      // -------------------- TP for TR3
      if ( robo_T3 ) { if ( TPMultiple > 0 ) { robo_TPV = robo_ATR * TPMultiple ; } else { robo_TPV = robo_ATR ; }}
      // -------------------- TP for TR4
      else if ( robo_T4 ) { robo_TPV = 0 ; }
      // -------------------- TP for TR5
      else if ( robo_T5 ) { robo_TPV = 0 ; }}

   // =============================================================================================================================================
   // ============================================================== TR3 Conditions ===============================================================
   // =============================================================================================================================================

   void goTester_T3() {
      useSL             = inp_SL ;
      TPMultiple        = inp_TPMultiple ;
      SMAPeriod         = inp_SMAPeriod ;
      SMATrend          = inp_SMATrend ;
      RSIPeriod         = inp_RSIPeriod ;
      RSITrend          = inp_RSITrend ;
      ADXPeriod         = inp_ADXPeriod ;
      ADXTrend          = inp_ADXTrend ;
      ADXTarget         = inp_ADXTarget ;
      useEquBal         = inp_EquBal ;
      useSession        = inp_Session ;
      useDaily          = inp_Daily ;
      useSMA            = inp_SMA ;
      useEMA            = inp_EMA ;
      useSMMA           = inp_SMMA ;
      useDEMA           = inp_DEMA ;
      useTEMA           = inp_TEMA ;
      useSAR            = inp_SAR ;
      useFrama          = inp_Frama ;
      useVidya          = inp_Vidya ;
      useAMA            = inp_AMA ;
      useRSI            = inp_RSI ;
      useChaikin        = inp_Chaikin ;
      useCCI            = inp_CCI ;
      useDemarker       = inp_Demarker ;
      useForce          = inp_Force ;
      useMomentum       = inp_Momentum ;
      useWPR            = inp_WPR ;
      useRVI            = inp_RVI ;
      useMFI            = inp_MFI ;
      useAO             = inp_AO ;
      useTrix           = inp_Trix ;
      useADX            = inp_ADX ;
      useADXW           = inp_ADXW ;
      useIchi           = inp_Ichi ;
      useCloseBiggest   = inp_CloseBiggest ;
      useRSIClose       = inp_RSIClose ; }

   void goBeacon_T3() {
      // -------------------- Split config string into parts and check its correct
      string safSplit[] ; StringSplit ( UT ( robo_Settings ) , StringGetCharacter ( "|" , 0 ) , safSplit ) ;
      // -------------------- Check config string bits number
      if ( ArraySize ( safSplit ) < 42 ) {
         goPrint ( "Incorrect Config String" ) ;
         ExpertRemove() ; return ; }
      // -------------------- Decode config string here
      TPMultiple  = (int) safSplit [ 0 ] ;
      SMAPeriod   = (int) safSplit [ 1 ] ;
      SMATrend    = (int) safSplit [ 2 ] ;
      RSIPeriod   = (int) safSplit [ 3 ] ;
      RSITrend    = (int) safSplit [ 4 ] ;
      ADXPeriod   = (int) safSplit [ 5 ] ;
      ADXTrend    = (int) safSplit [ 6 ] ;
      ADXTarget   = (int) safSplit [ 7 ] ;
      useIchi     = (int) safSplit [ 33 ] ;
      if ( safSplit [ 8 ]  == "TRUE" ) { useEquBal       = true ; }
      if ( safSplit [ 9 ]  == "TRUE" ) { useSession      = true ; }
      if ( safSplit [ 10 ] == "TRUE" ) { useDaily        = true ; }
      if ( safSplit [ 11 ] == "TRUE" ) { useSMA          = true ; }
      if ( safSplit [ 12 ] == "TRUE" ) { useEMA          = true ; }
      if ( safSplit [ 13 ] == "TRUE" ) { useSMMA         = true ; }
      if ( safSplit [ 14 ] == "TRUE" ) { useDEMA         = true ; }
      if ( safSplit [ 15 ] == "TRUE" ) { useTEMA         = true ; }
      if ( safSplit [ 16 ] == "TRUE" ) { useSAR          = true ; }
      if ( safSplit [ 17 ] == "TRUE" ) { useFrama        = true ; }
      if ( safSplit [ 18 ] == "TRUE" ) { useVidya        = true ; }
      if ( safSplit [ 19 ] == "TRUE" ) { useAMA          = true ; }
      if ( safSplit [ 20 ] == "TRUE" ) { useRSI          = true ; }
      if ( safSplit [ 21 ] == "TRUE" ) { useChaikin      = true ; }
      if ( safSplit [ 22 ] == "TRUE" ) { useCCI          = true ; }
      if ( safSplit [ 23 ] == "TRUE" ) { useDemarker     = true ; }
      if ( safSplit [ 24 ] == "TRUE" ) { useForce        = true ; }
      if ( safSplit [ 25 ] == "TRUE" ) { useMomentum     = true ; }
      if ( safSplit [ 26 ] == "TRUE" ) { useWPR          = true ; }
      if ( safSplit [ 27 ] == "TRUE" ) { useRVI          = true ; }
      if ( safSplit [ 28 ] == "TRUE" ) { useMFI          = true ; }
      if ( safSplit [ 29 ] == "TRUE" ) { useAO           = true ; }
      if ( safSplit [ 30 ] == "TRUE" ) { useTrix         = true ; }
      if ( safSplit [ 31 ] == "TRUE" ) { useADX          = true ; }
      if ( safSplit [ 32 ] == "TRUE" ) { useADXW         = true ; }
      if ( safSplit [ 34 ] == "TRUE" ) { useCloseBiggest = true ; }
      if ( safSplit [ 35 ] == "TRUE" ) { useRSIClose     = true ; }
      // -------------------- Check if SL is on
      if ( StringFind ( safSplit [ 41 ] , "_SL" , 0 ) > 1 ) {
         useSL = true ;
         goPrint ( "SL Activated for this beacon" ) ;
         Comment ( "SL Activated for this beacon" ) ; }}

   string goEntry_T3() {
      string res = "" ;
      // -------------------- Spread / ATR check
      if ( ( sAsk() - sBid() ) > robo_ATR * 0.5 ) { return "X" ; }
      // -------------------- Non indicator filters
      if ( goDelayMondayStart ( robo_DelayHours ) == "X" ) { return "X" ; }
      if ( goEndFridayEarly ( ( 24 - 2 - robo_DelayHours ) ) == "X" ) { return "X" ; }
      if ( IsDay_NoTradeDay () ){ return "X" ; }
      if ( useEquBal ) { if ( sEqu() < sBal() ) { return "X" ; }}
      if ( useSession ) { res += IsSession_Auto () ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useDaily ) { res += goCheck_Daily200MA ( "EMA" , glb_EAS , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      // -------------------- trade range
      res += goCalc_TradeRange ( "1" , 120 , 90 ) ; if ( !GCS ( res ) ) { return "X" ; }
      // -------------------- Trends
      if ( useSMA )        { res += goSignal_Trend ( "1" , "SMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useEMA )        { res += goSignal_Trend ( "1" , "EMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useSMMA )       { res += goSignal_Trend ( "1" , "SMMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useDEMA )       { res += goSignal_Trend ( "1" , "DEMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useTEMA )       { res += goSignal_Trend ( "1" , "TEMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useSAR )        { res += goSignal_Trend ( "1" , "SAR" , SMAPeriod , SMATrend ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useFrama )      { res += goSignal_Trend ( "1" , "FRAMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useVidya )      { res += goSignal_Trend ( "1" , "VIDYA" , SMAPeriod , SMATrend ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useAMA )        { res += goSignal_Trend ( "1" , "AMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( res ) ) { return "X" ; }}
      // -------------------- Oscis
      if ( useRSI )        { res += goSignal_Oscillator ( "1" , "RSI" , RSIPeriod , RSITrend , 50 , 50 , 85 , 15 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useChaikin )    { res += goSignal_Oscillator ( "1" , "CHAIKIN" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useCCI )        { res += goSignal_Oscillator ( "1" , "CCI" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useDemarker )   { res += goSignal_Oscillator ( "1" , "DEMARKER" , RSIPeriod , RSITrend , 0.5 , 0.5 , 0.85 , 0.15 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useForce )      { res += goSignal_Oscillator ( "1" , "FORCE" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; } }
      if ( useMomentum )   { res += goSignal_Oscillator ( "1" , "MOMENTUM" , RSIPeriod , RSITrend , 100 , 100 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useWPR )        { res += goSignal_Oscillator ( "1" , "WPR" , RSIPeriod , RSITrend , -50 , -50 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useRVI )        { res += goSignal_Oscillator ( "1" , "RVI" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useMFI )        { res += goSignal_Oscillator ( "1" , "MFI" , RSIPeriod , RSITrend , 50 , 50 , 85 , 15 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useAO )         { res += goSignal_Oscillator ( "1" , "AO" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useTrix )       { res += goSignal_Oscillator ( "1" , "TRIX" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      // -------------------- Power
      if ( useADX )        { res += goSignal_ADX ( "1" , "ADX" , ADXPeriod , ADXTrend , ADXTarget , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useADXW )       { res += goSignal_ADX ( "1" , "ADXW" , ADXPeriod , ADXTrend , ADXTarget , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      // -------------------- Ichimoku
      if ( useIchi > 0 ) {
         if ( useIchi == 1 )      { res += goSignal_Ichimoku( "12345678" ) ; }
         else if ( useIchi == 2 ) { res += goSignal_Ichimoku( "1234578"  ) ; }
         else if ( useIchi == 3 ) { res += goSignal_Ichimoku( "1245678"  ) ; }
         else if ( useIchi == 4 ) { res += goSignal_Ichimoku( "124578"   ) ; }
         if ( !GCS ( res ) ) { return "X" ; }}
      return ( res ) ; }

   void goTrail_T3() {
      goTrail_AfterBE_SLV ( robo_ATR ) ;
      if ( useRSIClose ) { goClose_OnRSI ( "2" , 0.1 , 50 ) ; }}

   string goHeader_T3() {
      string safHeader  = "Pass,Result,Profit,Expected Payoff,Profit Factor,Recovery Factor,Sharpe Ratio,Profit per DD,Equity DD %,Trades," ;
      safHeader         += "TP Multiple,MA Period,MA Trend,Osci Period,Osci Trend,ADX Period,ADX Trend,ADX Target,EquBal,Session,Daily,SMA,EMA,SMMA," ;
      safHeader         += "DEMA,TEMA,SAR,Frama,Vidya,AMA,RSI,Chaikin,CCI,Demarker,Force,Momentum,WPR,RVI,MFI,AO,Trix,ADX,ADXW,Ichi,Close Biggest,RSIClose," ;
      safHeader         += "Config String" ;
      return safHeader ; }

   void goNextCurr_T3() {
      goTester_WriteNextTestConfigFile ( goTester_GetNextSymbol() , "TESTER" , ( "n" + robo_Magic + ".set" ) , "AI" ) ; }

   string goResult_T3() {
      string result = "" ;
      // -------------------- Add Bot settings
      result =  (string) inp_TPMultiple + "," ;
      result += (string) inp_SMAPeriod + "," ;
      result += (string) inp_SMATrend + "," ;
      result += (string) inp_RSIPeriod + "," ;
      result += (string) inp_RSITrend + "," ;
      result += (string) inp_ADXPeriod + "," ;
      result += (string) inp_ADXTrend + "," ;
      result += (string) inp_ADXTarget + "," ;
      result += (string) inp_EquBal + "," ;
      result += (string) inp_Session + "," ;
      result += (string) inp_Daily + "," ;
      result += (string) inp_SMA + "," ;
      result += (string) inp_EMA + "," ;
      result += (string) inp_SMMA + "," ;
      result += (string) inp_DEMA + "," ;
      result += (string) inp_TEMA + "," ;
      result += (string) inp_SAR + "," ;
      result += (string) inp_Frama + "," ;
      result += (string) inp_Vidya + "," ;
      result += (string) inp_AMA + "," ;
      result += (string) inp_RSI + "," ;
      result += (string) inp_Chaikin + "," ;
      result += (string) inp_CCI + "," ;
      result += (string) inp_Demarker + "," ;
      result += (string) inp_Force + "," ;
      result += (string) inp_Momentum + "," ;
      result += (string) inp_WPR + "," ;
      result += (string) inp_RVI + "," ;
      result += (string) inp_MFI + "," ;
      result += (string) inp_AO + "," ;
      result += (string) inp_Trix + "," ;
      result += (string) inp_ADX + "," ;
      result += (string) inp_ADXW + "," ;
      result += (string) inp_Ichi + "," ;
      result += (string) inp_CloseBiggest + "," ;
      result += (string) inp_RSIClose + "," ;
      // -------------------- Construct Config String
      result += (string) inp_TPMultiple + "|" ;
      result += (string) inp_SMAPeriod + "|" ;
      result += (string) inp_SMATrend + "|" ;
      result += (string) inp_RSIPeriod + "|" ;
      result += (string) inp_RSITrend + "|" ;
      result += (string) inp_ADXPeriod + "|" ;
      result += (string) inp_ADXTrend + "|" ;
      result += (string) inp_ADXTarget + "|" ;
      result += (string) inp_EquBal + "|" ;
      result += (string) inp_Session + "|" ;
      result += (string) inp_Daily + "|" ;
      result += (string) inp_SMA + "|" ;
      result += (string) inp_EMA + "|" ;
      result += (string) inp_SMMA + "|" ;
      result += (string) inp_DEMA + "|" ;
      result += (string) inp_TEMA + "|" ;
      result += (string) inp_SAR + "|" ;
      result += (string) inp_Frama + "|" ;
      result += (string) inp_Vidya + "|" ;
      result += (string) inp_AMA + "|" ;
      result += (string) inp_RSI + "|" ;
      result += (string) inp_Chaikin + "|" ;
      result += (string) inp_CCI + "|" ;
      result += (string) inp_Demarker + "|" ;
      result += (string) inp_Force + "|" ;
      result += (string) inp_Momentum + "|" ;
      result += (string) inp_WPR + "|" ;
      result += (string) inp_RVI + "|" ;
      result += (string) inp_MFI + "|" ;
      result += (string) inp_AO + "|" ;
      result += (string) inp_Trix + "|" ;
      result += (string) inp_ADX + "|" ;
      result += (string) inp_ADXW + "|" ;
      result += (string) inp_Ichi + "|" ;
      result += (string) inp_CloseBiggest + "|" ;
      result += (string) inp_RSIClose + "|" ;
      return result ; }

   // =============================================================================================================================================
   // ============================================================== TR4 Conditions ===============================================================
   // =============================================================================================================================================

   void goTester_T4() {
      useSL       = inp_SL ;
      RSIPeriod   = inp_RSIPeriod ;
      RSITrend    = inp_RSITrend ;
      useRSI      = inp_RSI ;
      useChaikin  = inp_Chaikin ;
      useCCI      = inp_CCI ;
      useDemarker = inp_Demarker ;
      useForce    = inp_Force ;
      useMomentum = inp_Momentum ;
      useWPR      = inp_WPR ;
      useRVI      = inp_RVI ;
      useMFI      = inp_MFI ;
      useAO       = inp_AO ;
      useTrix     = inp_Trix ;
      useRSIClose = inp_RSIClose ; }

   void goBeacon_T4() {
      // -------------------- Split config string into parts and check its correct
      string safSplit[] ; StringSplit ( UT ( robo_Settings ) , StringGetCharacter ( "|" , 0 ) , safSplit ) ;
      // -------------------- Check config string bits number
      if ( ArraySize ( safSplit ) < 36 ) {
         goPrint ( "Incorrect Config String" ) ;
         ExpertRemove() ; return ; }
      // -------------------- Decode config string here
      TPMultiple  = 0 ;
      RSIPeriod   = (int) safSplit [ 3 ] ;
      RSITrend    = (int) safSplit [ 4 ] ;
      if ( safSplit [ 20 ] == "TRUE" ) { useRSI          = true ; }
      if ( safSplit [ 21 ] == "TRUE" ) { useChaikin      = true ; }
      if ( safSplit [ 22 ] == "TRUE" ) { useCCI          = true ; }
      if ( safSplit [ 23 ] == "TRUE" ) { useDemarker     = true ; }
      if ( safSplit [ 24 ] == "TRUE" ) { useForce        = true ; }
      if ( safSplit [ 25 ] == "TRUE" ) { useMomentum     = true ; }
      if ( safSplit [ 26 ] == "TRUE" ) { useWPR          = true ; }
      if ( safSplit [ 27 ] == "TRUE" ) { useRVI          = true ; }
      if ( safSplit [ 28 ] == "TRUE" ) { useMFI          = true ; }
      if ( safSplit [ 29 ] == "TRUE" ) { useAO           = true ; }
      if ( safSplit [ 30 ] == "TRUE" ) { useTrix         = true ; }
      if ( safSplit [ 35 ] == "TRUE" ) { useRSIClose     = true ; }}

   string goEntry_T4() {
      string res = "" ;
      // -------------------- trade range
      res += goSignal_EntrySNR() ; if ( !GCS ( res ) ) { return "X" ; }
      res += goCalc_TradeRange ( "1" , 120 , 90 ) ; if ( !GCS ( res ) ) { return "X" ; }
      // -------------------- Oscis
      if ( useRSI )        { res += goSignal_Oscillator ( "1" , "RSI" , RSIPeriod , RSITrend , 50 , 50 , 85 , 15 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useChaikin )    { res += goSignal_Oscillator ( "1" , "CHAIKIN" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useCCI )        { res += goSignal_Oscillator ( "1" , "CCI" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useDemarker )   { res += goSignal_Oscillator ( "1" , "DEMARKER" , RSIPeriod , RSITrend , 0.5 , 0.5 , 0.85 , 0.15 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useForce )      { res += goSignal_Oscillator ( "1" , "FORCE" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; } }
      if ( useMomentum )   { res += goSignal_Oscillator ( "1" , "MOMENTUM" , RSIPeriod , RSITrend , 100 , 100 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useWPR )        { res += goSignal_Oscillator ( "1" , "WPR" , RSIPeriod , RSITrend , -50 , -50 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useRVI )        { res += goSignal_Oscillator ( "1" , "RVI" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useMFI )        { res += goSignal_Oscillator ( "1" , "MFI" , RSIPeriod , RSITrend , 50 , 50 , 85 , 15 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useAO )         { res += goSignal_Oscillator ( "1" , "AO" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useTrix )       { res += goSignal_Oscillator ( "1" , "TRIX" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      return ( res ) ; }

   void goTrail_T4() {
      Trail_After_XATR ( 14 , 2 , 1 ) ;
      if ( useRSIClose ) { goClose_OnRSI ( "2" , 0.1 , 50 ) ; }}

   string goHeader_T4() {
      string safHeader  = "Pass,Result,Profit,Expected Payoff,Profit Factor,Recovery Factor,Sharpe Ratio,Profit per DD,Equity DD %,Trades," ;
      safHeader         += "Osci Period,Osci Trend,RSI,Chaikin,CCI,Demarker,Force,Momentum,WPR,RVI,MFI,AO,Trix,RSI Close,Config String" ;
      return safHeader ; }

   void goNextCurr_T4() {
      goTester_WriteNextTestConfigFile ( goTester_GetNextSymbol() , "TESTER" , ( "n" + robo_Magic + ".set" ) , "ALL" ) ; }

   string goResult_T4() {
      string result = "" ;
      // -------------------- Add Bot settings
      result =  (string) inp_RSIPeriod + "," ;
      result += (string) inp_RSITrend + "," ;
      result += (string) inp_RSI + "," ;
      result += (string) inp_Chaikin + "," ;
      result += (string) inp_CCI + "," ;
      result += (string) inp_Demarker + "," ;
      result += (string) inp_Force + "," ;
      result += (string) inp_Momentum + "," ;
      result += (string) inp_WPR + "," ;
      result += (string) inp_RVI + "," ;
      result += (string) inp_MFI + "," ;
      result += (string) inp_AO + "," ;
      result += (string) inp_Trix + "," ;
      result += (string) inp_RSIClose + "," ;
      // -------------------- Construct Config String
      result += "TR4|TR4|TR4|" ;
      result += (string) inp_RSIPeriod + "|" ;
      result += (string) inp_RSITrend + "|" ;
      result += "TR4|TR4|TR4|TR4|TR4|TR4|TR4|TR4|TR4|TR4|TR4|TR4|TR4|TR4|TR4|" ;
      result += (string) inp_RSI + "|" ;
      result += (string) inp_Chaikin + "|" ;
      result += (string) inp_CCI + "|" ;
      result += (string) inp_Demarker + "|" ;
      result += (string) inp_Force + "|" ;
      result += (string) inp_Momentum + "|" ;
      result += (string) inp_WPR + "|" ;
      result += (string) inp_RVI + "|" ;
      result += (string) inp_MFI + "|" ;
      result += (string) inp_AO + "|" ;
      result += (string) inp_Trix + "|" ;
      result += "TR4|TR4|TR4|TR4|" ;
      result += (string) inp_RSIClose + "|" ;
      return result ; }

   // =============================================================================================================================================
   // ============================================================== TR5 Conditions ===============================================================
   // =============================================================================================================================================

   void goTester_T5() {
      useSL          = inp_SL ;
      RSITrend       = inp_RSITrend ;
      RSIPeriod      = inp_RSIPeriod ;
      ADXTarget      = inp_ADXTarget ;
      ADXTrend       = inp_ADXTrend ;
      ADXPeriod      = inp_ADXPeriod ;
      useSwapie      = inp_Swapie ;
      useTrend_200M1 = inp_Trend_200M1 ;
      useTrend_10M1  = inp_Trend_10M1 ;
      useTrend_200H1 = inp_Trend_200H1 ;
      useTrend_10H1  = inp_Trend_10H1 ;
      useTrend_200D1 = inp_Trend_200D1 ;
      useTrend_10D1  = inp_Trend_10D1 ;
      useOsci_23M1   = inp_Osci_23M1 ;
      useOsci_23H1   = inp_Osci_23H1 ;
      useOsci_23D1   = inp_Osci_23D1 ;
      useRSI         = inp_RSI ;
      useChaikin     = inp_Chaikin ;
      useCCI         = inp_CCI ;
      useDemarker    = inp_Demarker ;
      useForce       = inp_Force ;
      useMomentum    = inp_Momentum ;
      useWPR         = inp_WPR ;
      useRVI         = inp_RVI ;
      useMFI         = inp_MFI ;
      useAO          = inp_AO ;
      useTrix        = inp_Trix ;
      useADX         = inp_ADX ;
      useADXW        = inp_ADXW ; }

   void goBeacon_T5() {
      // -------------------- Split config string into parts and check its correct
      string safSplit[] ; StringSplit ( UT ( robo_Settings ) , StringGetCharacter ( "|" , 0 ) , safSplit ) ;
      // -------------------- Check config string bits number
      if ( ArraySize ( safSplit ) < 32 ) {
         goPrint ( "Incorrect Config String" ) ;
         ExpertRemove() ; return ; }
      // -------------------- Decode config string here
      RSITrend    = (int) safSplit [ 14 ] ;
      RSIPeriod   = (int) safSplit [ 15 ] ;
      ADXTarget   = (int) safSplit [ 16 ] ;
      ADXTrend    = (int) safSplit [ 17 ] ;
      ADXPeriod   = (int) safSplit [ 18 ] ;
      if ( safSplit [ 4 ] == "TRUE" )  { useSwapie       = true ; }
      if ( safSplit [ 5 ] == "TRUE" )  { useTrend_200M1  = true ; }
      if ( safSplit [ 6 ] == "TRUE" )  { useTrend_10M1   = true ; }
      if ( safSplit [ 7 ] == "TRUE" )  { useTrend_200H1  = true ; }
      if ( safSplit [ 8 ] == "TRUE" )  { useTrend_10H1   = true ; }
      if ( safSplit [ 9 ] == "TRUE" )  { useTrend_200D1  = true ; }
      if ( safSplit [ 10 ] == "TRUE" ) { useTrend_10D1   = true ; }
      if ( safSplit [ 11 ] == "TRUE" ) { useOsci_23M1    = true ; }
      if ( safSplit [ 12 ] == "TRUE" ) { useOsci_23H1    = true ; }
      if ( safSplit [ 13 ] == "TRUE" ) { useOsci_23D1    = true ; }
      if ( safSplit [ 19 ] == "TRUE" ) { useRSI          = true ; }
      if ( safSplit [ 20 ] == "TRUE" ) { useChaikin      = true ; }
      if ( safSplit [ 21 ] == "TRUE" ) { useCCI          = true ; }
      if ( safSplit [ 22 ] == "TRUE" ) { useDemarker     = true ; }
      if ( safSplit [ 23 ] == "TRUE" ) { useForce        = true ; }
      if ( safSplit [ 24 ] == "TRUE" ) { useMomentum     = true ; }
      if ( safSplit [ 25 ] == "TRUE" ) { useWPR          = true ; }
      if ( safSplit [ 26 ] == "TRUE" ) { useRVI          = true ; }
      if ( safSplit [ 27 ] == "TRUE" ) { useMFI          = true ; }
      if ( safSplit [ 28 ] == "TRUE" ) { useAO           = true ; }
      if ( safSplit [ 29 ] == "TRUE" ) { useTrix         = true ; }
      if ( safSplit [ 30 ] == "TRUE" ) { useADX          = true ; }
      if ( safSplit [ 31 ] == "TRUE" ) { useADXW         = true ; }}

   string goEntry_T5() {
      string res = "" ;
      // -------------------- Spread / ATR check
      if ( ( sAsk() - sBid() ) > robo_ATR * 0.5 ) { return "X" ; }
      // -------------------- Non indicator filters
      if ( goDelayMondayStart ( robo_DelayHours ) == "X" ) { return "X" ; }
      if ( goEndFridayEarly ( ( 24 - 2 - robo_DelayHours ) ) == "X" ) { return "X" ; }
      if ( IsDay_NoTradeDay () ) { return "X" ; }
      // -------------------- Other entries
      if ( useSwapie )        { res += goSignal_SWAP () ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useTrend_200M1 )   { res += goSignalTF_TREND ( PERIOD_M1 , 200 , "EMA" , "1" ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useTrend_10M1 )    { res += goSignalTF_TREND ( PERIOD_M1 , 10 , "EMA" , "2" ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useTrend_200H1 )   { res += goSignalTF_TREND ( PERIOD_H1 , 200 , "EMA" , "1" ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useTrend_10H1 )    { res += goSignalTF_TREND ( PERIOD_H1 , 10 , "EMA" , "2" ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useTrend_200D1 )   { res += goSignalTF_TREND ( PERIOD_D1 , 200 , "EMA" , "1" ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useTrend_10D1 )    { res += goSignalTF_TREND ( PERIOD_D1 , 10 , "EMA" , "2" ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useOsci_23M1 )     { res += goSignal_RSI_2_3 ( PERIOD_M1 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useOsci_23H1 )     { res += goSignal_RSI_2_3 ( PERIOD_H1 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useOsci_23D1 )     { res += goSignal_RSI_2_3 ( PERIOD_D1 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      // -------------------- Oscis
      if ( useRSI )           { res += goSignal_Oscillator ( "1" , "RSI" , RSIPeriod , RSITrend , 50 , 50 , 85 , 15 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useChaikin )       { res += goSignal_Oscillator ( "1" , "CHAIKIN" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useCCI )           { res += goSignal_Oscillator ( "1" , "CCI" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useDemarker )      { res += goSignal_Oscillator ( "1" , "DEMARKER" , RSIPeriod , RSITrend , 0.5 , 0.5 , 0.85 , 0.15 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useForce )         { res += goSignal_Oscillator ( "1" , "FORCE" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useMomentum )      { res += goSignal_Oscillator ( "1" , "MOMENTUM" , RSIPeriod , RSITrend , 100 , 100 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useWPR )           { res += goSignal_Oscillator ( "1" , "WPR" , RSIPeriod , RSITrend , -50 , -50 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useRVI )           { res += goSignal_Oscillator ( "1" , "RVI" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useMFI )           { res += goSignal_Oscillator ( "1" , "MFI" , RSIPeriod , RSITrend , 50 , 50 , 85 , 15 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useAO )            { res += goSignal_Oscillator ( "1" , "AO" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useTrix )          { res += goSignal_Oscillator ( "1" , "TRIX" , RSIPeriod , RSITrend , 0 , 0 , 0 , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      // -------------------- Power
      if ( useADX )           { res += goSignal_ADX ( "1" , "ADX" , ADXPeriod , ADXTrend , ADXTarget , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      if ( useADXW )          { res += goSignal_ADX ( "1" , "ADXW" , ADXPeriod , ADXTrend , ADXTarget , 0 ) ; if ( !GCS ( res ) ) { return "X" ; }}
      return ( res ) ; }

   void goTrail_T5() {
      Trail_After_XATR ( 14 , 3 , 2 ) ; }

   string goHeader_T5() {
      string safHeader  = "Pass,Result,Profit,Expected Payoff,Profit Factor,Recovery Factor,Sharpe Ratio,Profit per DD,Equity DD %,Trades," ;
      safHeader         += "Magic,Max DD,Max Days,Max Trades," ;
      safHeader         += "Config String" ;
      return safHeader ; }

   void goNextCurr_T5() {
      goTester_WriteNextTestConfigFile ( goTester_GetNextSymbol() , "TESTER" , ( "n" + robo_Magic + ".set" ) , "AI" ) ; }

   string goResult_T5() {
      string result = "" ;
      // -------------------- Add Bot settings
      result  = (string) robo_Magic + "," ;
      result += (string) inp_MaxDD + "," ;
      result += (string) inp_MaxDays + "," ;
      result += (string) robo_Magic + "," ;
      result += (string) inp_Swapie + "," ;
      result += (string) inp_Trend_200M1 + "," ;
      result += (string) inp_Trend_10M1 + "," ;
      result += (string) inp_Trend_200H1 + "," ;
      result += (string) inp_Trend_10H1 + "," ;
      result += (string) inp_Trend_200D1 + "," ;
      result += (string) inp_Trend_10D1 + "," ;
      result += (string) inp_Osci_23M1 + "," ;
      result += (string) inp_Osci_23H1 + "," ;
      result += (string) inp_Osci_23D1 + "," ;
      result += (string) inp_RSITrend + "," ;
      result += (string) inp_RSIPeriod + "," ;
      result += (string) inp_ADXTarget + "," ;
      result += (string) inp_ADXTrend + "," ;
      result += (string) inp_ADXPeriod + "," ;
      result += (string) inp_RSI + "," ;
      result += (string) inp_Chaikin + "," ;
      result += (string) inp_CCI + "," ;
      result += (string) inp_Demarker + "," ;
      result += (string) inp_Force + "," ;
      result += (string) inp_Momentum + "," ;
      result += (string) inp_WPR + "," ;
      result += (string) inp_RVI + "," ;
      result += (string) inp_MFI + "," ;
      result += (string) inp_AO + "," ;
      result += (string) inp_Trix + "," ;
      result += (string) inp_ADX + "," ;
      result += (string) inp_ADXW + "," ;
      // -------------------- Construct Config String
      result += (string) robo_Magic + "|" ;
      result += (string) inp_MaxDD + "|" ;
      result += (string) inp_MaxDays + "|" ;
      result += (string) robo_Magic + "|" ;
      result += (string) inp_Swapie + "|" ;
      result += (string) inp_Trend_200M1 + "|" ;
      result += (string) inp_Trend_10M1 + "|" ;
      result += (string) inp_Trend_200H1 + "|" ;
      result += (string) inp_Trend_10H1 + "|" ;
      result += (string) inp_Trend_200D1 + "|" ;
      result += (string) inp_Trend_10D1 + "|" ;
      result += (string) inp_Osci_23M1 + "|" ;
      result += (string) inp_Osci_23H1 + "|" ;
      result += (string) inp_Osci_23D1 + "|" ;
      result += (string) inp_RSITrend + "|" ;
      result += (string) inp_RSIPeriod + "|" ;
      result += (string) inp_ADXTarget + "|" ;
      result += (string) inp_ADXTrend + "|" ;
      result += (string) inp_ADXPeriod + "|" ;
      result += (string) inp_RSI + "|" ;
      result += (string) inp_Chaikin + "|" ;
      result += (string) inp_CCI + "|" ;
      result += (string) inp_Demarker + "|" ;
      result += (string) inp_Force + "|" ;
      result += (string) inp_Momentum + "|" ;
      result += (string) inp_WPR + "|" ;
      result += (string) inp_RVI + "|" ;
      result += (string) inp_MFI + "|" ;
      result += (string) inp_AO + "|" ;
      result += (string) inp_Trix + "|" ;
      result += (string) inp_ADX + "|" ;
      result += (string) inp_ADXW + "|" ;
      return result ; }

   //===========================================================================================================
   //=====                                       ON TESTER FUNCTIONS                                       =====
   //===========================================================================================================

   void OnTesterInit () {
      // -------------------- Construct and write report header
      string safHeader = "" ;
      if ( robo_Magic == "TR3" )      { safHeader = goHeader_T3() ; }
      else if ( robo_Magic == "TR4" ) { safHeader = goHeader_T4() ; }
      else if ( robo_Magic == "TR5" ) { safHeader = goHeader_T5() ; }
      // -------------------- Do init checks and writes here
      string safSLAddon = "" ;
      if ( inp_SL ) { safSLAddon = "_SL" ; }
      if ( inp_MaxDays > 0 ) { safSLAddon += "_" + string ( inp_MaxDays ) + "d" ; }
      goTester_OnInIt ( safHeader , __FILE__ , safSLAddon , robo_Magic ) ; }

   void OnTesterDeinit () {
      // -------------------- x
      string safSLAddon = "" ; if ( inp_SL ) { safSLAddon = "_SL" ; }
      goTester_DeOnInIt ( __FILE__ , safSLAddon , inp_MaxDD , "" , robo_Magic ) ;
      // -------------------- x
      if ( robo_Magic == "TR3" )       { goNextCurr_T3() ; }
      else if ( robo_Magic == "TR4" )  { goNextCurr_T4() ; }
      else if ( robo_Magic == "TR5" )  { goNextCurr_T5() ; }
      // -------------------- x
      goTester_WriteScreenShotCode () ;
      Sleep ( 10000 ) ; goTester_FileWrite ( "restart.me" , "restart" , "n" ) ; }

   double OnTester () {
      // -------------------- Variables
      string result = "" ;
      static string safFileName ;
      // -------------------- Test Stats
      double tProfit = ND2 ( TesterStatistics ( STAT_PROFIT ) ) ;
         if ( tProfit <= 0 ) { return 0 ; }
      double tDrawDown = ND2 ( MathMax ( TesterStatistics ( STAT_EQUITYDD_PERCENT ) , TesterStatistics ( STAT_EQUITY_DDREL_PERCENT ) ) ) ;
         if ( tDrawDown > inp_MaxDD ) { return 0 ; }
      double tRecoveryFactor = ND2 ( TesterStatistics ( STAT_RECOVERY_FACTOR ) ) ;
         if ( tRecoveryFactor < 1 ) { return 0 ; }
      double tSharpieRatio = ND2 ( TesterStatistics ( STAT_SHARPE_RATIO ) ) ;
         if ( tSharpieRatio < 2 ) { return 0 ; }
      int tTrades = int ( TesterStatistics ( STAT_TRADES ) ) ;
         if ( tTrades < 30 ) { return 0 ; }
      double tProfitFactor = ND2 ( TesterStatistics ( STAT_PROFIT_FACTOR ) ) ;
      double tResult = ND2 ( TesterStatistics ( STAT_INITIAL_DEPOSIT ) + tProfit ) ;
      double tExpectedPayoff = ND2 ( TesterStatistics ( STAT_EXPECTED_PAYOFF ) ) ;
      // -------------------- Construct filename
      if ( StringLen ( safFileName ) < 1 ) { safFileName = sTestFN() ; }
      // -------------------- Calculations here
      double tProfitPerDD = ND2 ( tProfit / tDrawDown ) ;
      // -------------------- Construct Return string
      result += (string) robo_Magic + "," + (string) tResult + "," + (string) tProfit + "," + (string) tExpectedPayoff + "," + (string) tProfitFactor + "," ;
      result += (string) tRecoveryFactor + "," + (string) tSharpieRatio + "," + (string) tProfitPerDD + "," + (string) tDrawDown + "," ;
      result += (string) tTrades + "," ;
      // -------------------- Go add bot specific resuls
      if      ( robo_Magic == "TR3" ) { result += goResult_T3() ; }
      else if ( robo_Magic == "TR4" ) { result += goResult_T4() ; }
      else if ( robo_Magic == "TR5" ) { result += goResult_T5() ; }
      // -------------------- End of Config String settings area
      result += (string) tTrades + "|" ;
      result += (string) tDrawDown + "|" ;
      result += (string) tRecoveryFactor + "|" ;
      result += (string) tSharpieRatio + "|" ;
      result += goTranslate_Broker() + "|" ;
      result += safFileName + "_" + StringSubstr ( goGetDateTime() , 0 , 6 ) + "_" + string ( inp_MaxDD ) + "_" ;
      if ( inp_SL == true ) { result += "SL_" ; }
      // string safBotName = goCleanFileName ( __FILE__ ) ;
      // result += safBotName + "|" ;
      result += robo_Magic + "|" ;
      // -------------------- Save to local temp file
      goTester_FileWrite ( safFileName , result ) ;
      return ( tProfitPerDD ) ; }