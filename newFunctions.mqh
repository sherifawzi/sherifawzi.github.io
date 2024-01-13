   #define SNR_COPYRIGHT   "Copyright 2023, F-SQUARE ApS"
   #define SNR_WEBSITE     "https://fsquare.dk"
   #define SNR_LIBVER      "Library Version: 24.01.13"

   #include <Trade\Trade.mqh>
   #include <Math\Stat\Math.mqh>
   CTrade trade ;

   //===========================================================================================================
   //=====                                             CODE                                                =====
   //===========================================================================================================

   // SNR Dist Link: https://www.dropbox.com/sh/qy8zg03x2t5xgtq/AAAyBcGUXnryeQ0kWkkv3aqya?dl=0
   // git config --global user.name "Sherif Fawzi"
   // git config --global user.email coding.fsquare@outlook.com
   // git init
   // git remote add origin https://github.com/sherifawzi/MQL-Framework.git
   // git pull origin master
   // git add newFunctions.mqh
   // git commit -m "Minor changes"
   // git push --set-upstream origin master
   // git push
   // username: sherifawzi

   //===========================================================================================================
   //=====                                            ENUMS                                                =====
   //===========================================================================================================

   enum enumTradeType   { No_Trade = 0 , Buy_and_Sell = 1 , Buy_Only = 2 , Sell_Only = 3 } ;
   enum enumStopType    { No_Stops = 0 , SL_and_TP = 1 , SL_Only = 2 , TP_Only = 3 } ;
   enum enumLogType     { No_Log = 0 , Journal = 1 , Excel = 2 } ;
   enum enumRiskLevel   { Auto , Highest , Higher , High , Medium , Low , Lower , Lowest , LYDR3 } ;
   enum enumTradeCount  { Single_Trade = 0 , Multi_Trade = 1 , Multi_Min_Trade = 2 } ;
   enum enumMaxDD       { Do_Noting = 0 , Stop_Trade = 1 , Trade_Minimum = 2 , Trade_Half_Half_Min = 3 } ;

   //===========================================================================================================
   //=====                                           INPUTS                                                =====
   //===========================================================================================================

   // input group "Main settings:"
      string glb_Magic                    = "SNR"           ; // EA Magic Number
      string glb_EAS                      = _Symbol         ; // EA Symbol
      ENUM_TIMEFRAMES glb_EAP             = _Period         ; // EA Period
      int glb_FC                          = 1               ; // Candle to use for calculations
      int glb_BD                          = 3               ; // Indicator buffer depth
      string glb_BroadID                  = ""              ; // EA Broadcast ID
      bool glb_Write2Server               = true            ; // Write to Server
      string glb_BaseCurr                 = "USD"           ; // Account base currency
      string glb_FileName                 = ""              ; // Main log file for the EA
      bool glb_SilentMode                 = false           ; // EA no outside communication
      bool glb_DebugMode                  = false           ; // Debug mode

   // input group "Trade size limiters:"
      double glb_LotSize                  = 0.01            ; // Lost size [0=Min/1K, 0.01=Min, [NUMBER]=Percent of Free Margin]
      double glb_MaxCapitalValue          = 0               ; // EA Max capital value to use [0=Disabled]
      double glb_MaxCapitalPerc           = 0               ; // EA Max capital percent to use [0=Disabled]
      double glb_MaxLotPerK               = 0               ; // EA Max capital trade size per 1K [0=Disabled]

   // input group "Trade and stops settings:"
      enumTradeType glb_AllowedTrade      = Buy_and_Sell    ; // Allowed trade types
      enumStopType glb_AllowedStops       = SL_and_TP       ; // Allowed trade stops
      bool glb_MinTradeMode               = false           ; // Place trades as sMin and broadcast normal lot size
      bool glb_BeaconMode                 = false           ; // Beacon mode activated

   // input group "Drawdown behaviour:"
      double glb_MaxDDTrigger             = 0               ; // Drawdown percent trigger [0=Disabled]
      enumMaxDD glb_MaxDDBehaviour        = Do_Noting       ; // Drawdown trigger behaviour

   // input group "Sunset settings:"
      int glb_SunsetDays                  = 0               ; // Days to EA sunset [0=Disabled]
      string glb_SunsetDate               = ""              ; // EA sunset date [Empty=Disabled]

   // input group "Robot specific settings:"

   //===========================================================================================================
   //=====                                          VARIABLES                                              =====
   //===========================================================================================================

   MqlRates    glb_PI [] ;
   double      B0 [] , B1 [] , B2 [] , B3 [] , B4 [] ;
   double      glb_UpperTradeLimit = 999999 ;
   double      glb_LowerTradeLimit = 0 ;
   datetime    glb_LastTradeTime ;
   string      glb_SymbolArray [] ;

   //===========================================================================================================
   //=====                                       CONST VARIABLES                                           =====
   //===========================================================================================================

   const string glb_MsgStart  = "XyXyXyZ|" ;
   const string glb_MsgEnd    = "|ZyXyXyX" ;
   const string glb_ServerIP  = "http://3.66.106.21/" ;
   string glb_ServerPath      = "/ERROR/" ;
   string glb_ServerPHP       = "saveeofy.php" ;
   string glb_ServerFileName  = "catchall.txt" ;

   //===========================================================================================================
   //=====                                     INDICATOR FUNCTIONS                                         =====
   //===========================================================================================================

   // ------------------------------ 01: Accelerator Oscillator
   bool ind_AC () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iAC ( glb_EAS , glb_EAP ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 02: Accumulation/Distribution
   bool ind_AD () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iAD ( glb_EAS , glb_EAP , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 03: Average Directional Movement Index
   bool ind_ADX ( int sPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      // 0 - MAIN LINE / 1 - PLUS DI LINE / 2 - MINUS DI LINE
      int F = iADX ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      if ( !CopyBuffer ( F , 2 , 0 , glb_BD , B2 ) ) { return false ; }
      return true ; }

   // ------------------------------ 04: Average Directional Movement Index by Welles Wilder
   bool ind_ADXW ( int sPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      // 0 - MAIN LINE / 1 - PLUS DI LINE / 2 - MINUS DI LINE
      int F = iADXWilder ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      if ( !CopyBuffer ( F , 2 , 0 , glb_BD , B2 ) ) { return false ; }
      return true ; }

   // ------------------------------ 05: Alligator
   bool ind_Alligator ( int jawPeriod=13 , int jawShift=8 , int teethPeriod=8 , int teethShift=5 , int lipsPeriod=5 , int lipsShift=3 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      // 0 - GATOR JAW LINE / 1 - GATOR TEETH LINE / 2 - GATOR LIPS LINE
      int F = iAlligator ( glb_EAS , glb_EAP , jawPeriod , jawShift , teethPeriod , teethShift , lipsPeriod , lipsShift , MODE_SMMA , PRICE_MEDIAN ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      if ( !CopyBuffer ( F , 2 , 0 , glb_BD , B2 ) ) { return false ; }
      return true ; }

   // ------------------------------ 06: Adaptive Moving Average
   bool ind_AMA ( int sPeriod=15 , int fastMA=2 , int slowMA=30 , int sShift=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iAMA ( glb_EAS , glb_EAP , sPeriod , fastMA , slowMA , sShift , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 07: Awesome Oscillator
   bool ind_AO () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iAO ( glb_EAS , glb_EAP ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 08: Average True Range
   bool ind_ATR ( int sPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iATR ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 09: Bears Power
   bool ind_Bears ( int sPeriod=13 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iBearsPower ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 10: Bollinger Bands
   bool ind_Band ( int sPeriod=20 , int sShift=0 , double sDeviation=2.0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      // 0 - BASE LINE / 1 - UPPER BAND / 2 - LOWER BAND
      int F = iBands ( glb_EAS , glb_EAP , sPeriod, sShift , sDeviation , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      if ( !CopyBuffer ( F , 2 , 0 , glb_BD , B2 ) ) { return false ; }
      return true ; }

   // ------------------------------ 11: Bulls Power
   bool ind_Bulls ( int sPeriod=13 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iBullsPower ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 12: Commodity Channel Index
   bool ind_CCI ( int sPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iCCI ( glb_EAS , glb_EAP , sPeriod , PRICE_TYPICAL ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 13: Chaikin Oscillator
   bool ind_Chaikin ( int fastMA=3 , int slowMA=10 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iChaikin ( glb_EAS , glb_EAP , fastMA , slowMA , MODE_EMA , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 14: Double Exponential Moving Average
   bool ind_DEMA ( int sPeriod=14 , int sShift=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iDEMA ( glb_EAS , glb_EAP , sPeriod , sShift , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 15: DeMarker
   bool ind_DeMarker ( int sPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iDeMarker ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 16: Envelopes
   bool ind_Envelopes ( int sPeriod=14 , int sShift=0 , double sDeviation=0.1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      // 0 - UPPER LINE / 1 - LOWER LINE
      int F = iEnvelopes ( glb_EAS , glb_EAP , sPeriod , sShift , MODE_SMA , PRICE_CLOSE , sDeviation ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      return true ; }

   // ------------------------------ 17: Force Index
   bool ind_Force ( int sPeriod=13 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iForce ( glb_EAS , glb_EAP , sPeriod , MODE_SMA , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 18: Fractals
   bool ind_Fractals () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      // 0 - UPPER LINE / 1 - LOWER LINE
      int F = iFractals ( glb_EAS , glb_EAP ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      return true ; }

   // ------------------------------ 19: Fractal Adaptive Moving Average
   bool ind_FrAMA ( int sPeriod=14 , int sShift=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iFrAMA ( glb_EAS , glb_EAP , sPeriod , sShift , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 20: Gator
   bool ind_Gator ( int jawPeriod=13 , int jawShift=8 , int teethPeriod=8 , int teethShift=5 , int lipsPeriod=5 , int lipsShift=3 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      // 0 - UPPER HISTOGRAM / 1 - color buffer of the upper histogram / 2 - LOWER HISTOGRAM / 3 - color buffer of the lower histogram
      int F = iGator ( glb_EAS , glb_EAP , jawPeriod , jawShift , teethPeriod , teethShift , lipsPeriod , lipsShift , MODE_SMMA , PRICE_MEDIAN ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      if ( !CopyBuffer ( F , 2 , 0 , glb_BD , B2 ) ) { return false ; }
      if ( !CopyBuffer ( F , 3 , 0 , glb_BD , B3 ) ) { return false ; }
      return true ; }

   // ------------------------------ 21: Ichimoku Kinko Hyo
   bool ind_Ichimoku ( int sTenkan=9 , int sKijun=26 , int sSenkou=52 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      // 0 - TENKANSEN LINE-RED / 1 - KIJUNSEN LINE-BLUE / 2 - SENKOUSPANA LINE-CLOUDA / 3 - SENKOUSPANB LINE-CLOUDB / 4 - CHIKOUSPAN LINE-SPAN
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sSenkou , ( sKijun * 2 ) ) + 2 ;
      int F = iIchimoku ( glb_EAS , glb_EAP , sTenkan , sKijun , sSenkou ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , ( glb_BD + glb_FC ) , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , ( glb_BD + glb_FC ) , B1 ) ) { return false ; }
      if ( !CopyBuffer ( F , 2 , -sKijun , ( glb_BD + glb_FC ) , B2 ) ) { return false ; }
      if ( !CopyBuffer ( F , 3 , -sKijun , ( glb_BD + glb_FC ) , B3 ) ) { return false ; }
      if ( !CopyBuffer ( F , 4 , sKijun , ( glb_BD + glb_FC ) , B4 ) ) { return false ; }
      glb_BD = sCurr_BufferDepth ;
      return true ; }

   // ------------------------------ 22: Market Facilitation Index
   bool ind_BWMFI () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iBWMFI ( glb_EAS , glb_EAP , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 23: Momentum
   bool ind_Momentum ( int sPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iMomentum ( glb_EAS , glb_EAP , sPeriod , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 24: Money Flow Index
   bool ind_MFI ( int sPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iMFI ( glb_EAS , glb_EAP , sPeriod , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 25: Moving Average
   bool ind_MA ( string sType , int sPeriod , int sShift=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = 0 ;
      if ( sType == "SMA" ) { F = iMA ( glb_EAS , glb_EAP , sPeriod , sShift , MODE_SMA , PRICE_CLOSE ) ; }
      if ( sType == "EMA" ) { F = iMA ( glb_EAS , glb_EAP , sPeriod , sShift , MODE_EMA , PRICE_CLOSE ) ; }
      if ( sType == "SMMA" ) { F = iMA ( glb_EAS , glb_EAP , sPeriod , sShift , MODE_SMMA , PRICE_CLOSE ) ; }
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 26: Moving Average of Oscillator
   bool ind_OsMA ( int fastMA=12 , int slowMA=26 , int sSignal=9 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iOsMA ( glb_EAS , glb_EAP , fastMA , slowMA , sSignal , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 27: Moving Averages Convergence/Divergence
   bool ind_MACD ( int fastMA=12 , int slowMA=26 , int sSignal=9 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      // 0 - MAIN LINE / 1 - SIGNAL LINE
      int F = iMACD ( glb_EAS , glb_EAP , fastMA , slowMA , sSignal , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      return true ; }

   // ------------------------------ 28: On Balance Volume
   bool ind_OBV () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iOBV ( glb_EAS , glb_EAP , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 29: Parabolic Stop and Reverse system
   bool ind_SAR ( double sStep=0.02 , int sMax=2 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iSAR ( glb_EAS , glb_EAP , sStep , sMax ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 30: Relative Strength Index
   bool ind_RSI ( int sPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iRSI ( glb_EAS , glb_EAP , sPeriod , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 31: Relative Vigor Index
   bool ind_RVI ( int sPeriod=10 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      // 0 - MAIN LINE / 1 - SIGNAL LINE
      int F = iRVI ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      return true ; }

   // ------------------------------ 32: Standard Deviation
   bool ind_StdDev ( int sPeriod=20 , int sShift=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iStdDev ( glb_EAS , glb_EAP , sPeriod , sShift , MODE_SMA , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 33: Stochastic Oscillator
   bool ind_Stochastic ( int sKPeriod=5 , int sDPeriod=3 , int sSlowing=3 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      // 0 - MAIN LINE / 1 - SIGNAL LINE
      int F = iStochastic ( glb_EAS , glb_EAP , sKPeriod , sDPeriod , sSlowing , MODE_SMA , STO_LOWHIGH ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      return true ; }

   // ------------------------------ 34: Triple Exponential Moving Average
   bool ind_TEMA ( int sPeriod=14 , int sShift=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iTEMA ( glb_EAS , glb_EAP , sPeriod , sShift , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 35: Triple Exponential Moving Averages Oscillator
   bool ind_TriX ( int sPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iTriX ( glb_EAS , glb_EAP , sPeriod , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 36: Larry Williams' Percent Range
   bool ind_WPR ( int sPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iWPR ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 37: Variable Index Dynamic Average
   bool ind_VIDyA ( int sCMO=15 , int sEMA=12 , int sShift=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iVIDyA ( glb_EAS , glb_EAP , sCMO , sEMA , sShift , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 38: Volumes
   bool ind_Volumes () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      if ( goTrim ( glb_EAS ) == "" ) { return false ; }
      if ( glb_BD < 1 ) { return false ; }
      int F = iVolumes ( glb_EAS , glb_EAP , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   //===========================================================================================================
   //=====                                   CONFIGURARBLE INDICATORS                                      =====
   //===========================================================================================================

   double sATR ( int safPeriod , ENUM_TIMEFRAMES safTF=PERIOD_CURRENT , int safLoc=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         glb_EAP = safTF ;
         double result = 0 ;
         if ( ind_ATR ( safPeriod ) == false ) {
            result = 0 ;
         } else {
            result = B0 [ safLoc ] ; }
      glb_EAP = sCurr_Period ;
      return ( result ) ; }

   double sMA ( string safType , int safPeriod , ENUM_TIMEFRAMES safTF=PERIOD_CURRENT , int safLoc=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         glb_EAP = safTF ;
         double result = 0 ;
         if ( ind_MA ( safType , safPeriod ) == false ) {
            result = 0 ;
         } else {
            result = B0 [ safLoc ] ; }
      glb_EAP = sCurr_Period ;
      return ( result ) ; }

   double sRSI ( int safPeriod , ENUM_TIMEFRAMES safTF=PERIOD_CURRENT , int safLoc=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         glb_EAP = safTF ;
         double result = 0 ;
         if ( ind_RSI ( safPeriod ) == false ) {
            result = 0 ;
         } else {
            result = B0 [ safLoc ] ; }
      glb_EAP = sCurr_Period ;
      return ( result ) ; }

   double sMFI ( int safPeriod , ENUM_TIMEFRAMES safTF=PERIOD_CURRENT , int safLoc=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         glb_EAP = safTF ;
         double result = 0 ;
         if ( ind_MFI ( safPeriod ) == false ) {
            result = 0 ;
         } else {
            result = B0 [ safLoc ] ; }
      glb_EAP = sCurr_Period ;
      return ( result ) ; }

   double sADX ( int safPeriod , ENUM_TIMEFRAMES safTF=PERIOD_CURRENT , int safLoc=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         glb_EAP = safTF ;
         double result = 0 ;
         if ( ind_ADX ( safPeriod ) == false ) {
            result = 0 ;
         } else {
            result = B0 [ safLoc ] ; }
      glb_EAP = sCurr_Period ;
      return ( result ) ; }

   //===========================================================================================================
   //=====                                    MY INDICATOR FUNCTIONS                                       =====
   //===========================================================================================================

   void myIndicator_Pivots ( int CandlesBack=100 , int CandlesInARow=5 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( ( CandlesBack > 0 ) && ( CandlesInARow > 0 ) ) {
         string LastPivot = "" , safName = "PivotLine" ;
         int safCounter = 1 , LastI = 0 ;
         int sCurr_BufferDepth = glb_BD ;
         glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + CandlesBack + CandlesInARow ) ; // Add another vraiable here
         if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
         goDraw_DeleteScreenObject ( safName ) ;
         for ( int i = CandlesInARow ; i < CandlesBack ; i++ ) {
            int safUpCounter = 0 , safDnCounter = 0 ;
            double safPivotPrice = 0 ;
            for ( int j = i + 1 ; j <= i + CandlesInARow ; j++ ) {
               if ( glb_PI[ i ].high >= glb_PI[ j ].high ) { safUpCounter += 1 ; }
               if ( glb_PI[ i ].low  <= glb_PI[ j ].low  ) { safDnCounter += 1 ; } }
            for ( int j = i - 1 ; j >= i - CandlesInARow ; j-- ) {
               if ( glb_PI[ i ].high >= glb_PI[ j ].high ) { safUpCounter += 1 ; }
               if ( glb_PI[ i ].low  <= glb_PI[ j ].low  ) { safDnCounter += 1 ; } }
               if ( safUpCounter == ( CandlesInARow * 2 ) ) {
                  if ( LastPivot != "HIGH" ) {
                     safPivotPrice = glb_PI[ i ].high ; LastPivot = "HIGH" ; safDnCounter = -1 ; LastI = i ; }}
               if ( safDnCounter == ( CandlesInARow * 2 ) ) {
                  if ( LastPivot != "LOW"  ) {
                     safPivotPrice = glb_PI[ i ].low ; LastPivot = "LOW" ; LastI = i ; }}
            if ( safPivotPrice > 0 ) {
               goDraw_ConnectedLine ( ( safName + (string)safCounter ) , 0 , safPivotPrice , glb_PI[i].time , clrGold ) ;
               safCounter += 1 ; }
         } glb_BD = sCurr_BufferDepth ; }}

   string myIndicator_HigherTFFractals ( string safRules="4" , ENUM_TIMEFRAMES safTimeFrame=PERIOD_CURRENT , int NoOfCandles=1440 , color safColor=clrGold ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Return upper line
      // RULE 2: Return lower line
      // RULE 3: Return upper and lower line
      // RULE 4: Just draw lines
      // RULE 5: Return Sell SL
      // RULE 6: Return Buy SL
      // RULE 7: Return Sell SL and Buy SL
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      int sCurr_BufferDepth = glb_BD ;
      glb_EAP = safTimeFrame ;
      glb_BD = MathMax ( sCurr_BufferDepth , NoOfCandles + 1 ) ;
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      // -------------------- handle indicator here
      if ( ind_Fractals () == false ) {
         glb_BD = sCurr_BufferDepth ;
         glb_EAP = sCurr_Period ;
         CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
         return ( "error" ) ; }
      double safUpperLine = 0 , safLowerLine = 0 ;
      double CurrentHigh = MathMax ( glb_PI [ glb_FC ].high , glb_PI [ 0 ].high ) ;
      double CurrentLow = MathMin ( glb_PI [ glb_FC ].low , glb_PI [ 0 ].low ) ;
      for ( int i = glb_FC + 2 ; i < glb_BD - 1 ; i++ ) {
         double safUpperFractal = B0 [ i ] ;
         double safLowerFractal = B1 [ i ] ;
         if ( ( safUpperFractal != EMPTY_VALUE ) && ( safUpperFractal > CurrentHigh ) && ( safUpperLine == 0 ) ) { safUpperLine = safUpperFractal ; }
         if ( ( safLowerFractal != EMPTY_VALUE ) && ( safLowerFractal < CurrentLow  ) && ( safLowerLine == 0 ) ) { safLowerLine = safLowerFractal ; }}
         // -------------------- RULE 4
         if ( StringFind ( safRules , "4" , 0 ) >= 0 ) {
            if ( safUpperLine > 0 ) {
               goDraw_HorizontalLine ( string ( safTimeFrame ) + "UpperFractal" , safUpperLine , safColor ) ;
            } else {
               ObjectDelete ( 0 , string ( safTimeFrame ) + "UpperFractal" ) ; }
            if ( safLowerLine > 0 ) {
               goDraw_HorizontalLine ( string ( safTimeFrame ) + "LowerFractal" , safLowerLine , safColor ) ;
            } else {
               ObjectDelete ( 0 , string ( safTimeFrame ) + "LowerFractal" ) ; }}
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) { result = string ( safUpperLine ) ; }
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) { result = string ( safLowerLine ) ; }
      // -------------------- RULE 3
      if ( StringFind ( safRules , "3" , 0 ) >= 0 ) { result = string ( safUpperLine ) + "|" + string ( safLowerLine ) ; }
      // -------------------- RULE 5
      if ( StringFind ( safRules , "5" , 0 ) >= 0 ) { result = string ( safUpperLine - sBid() ) ; }
      // -------------------- RULE 6
      if ( StringFind ( safRules , "6" , 0 ) >= 0 ) { result = string ( sAsk() - safLowerLine ) ; }
      // -------------------- RULE 7
      if ( StringFind ( safRules , "7" , 0 ) >= 0 ) { result = string ( safUpperLine - sBid() ) + "|" + string ( sAsk() - safLowerLine ) ; }
      glb_BD = sCurr_BufferDepth ;
      glb_EAP = sCurr_Period ;
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      return result ; }

   void myIndicator_OfficialPivotLevels () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         glb_EAP = PERIOD_D1 ;
         CopyRates ( glb_EAS , glb_EAP , 0 , 2 , glb_PI ) ;
         double sH = glb_PI[ 1 ].high ;
         double sL = glb_PI[ 1 ].low ;
         double sC = glb_PI[ 1 ].close ;
         double safPivot = ( sH + sL + sC ) / 3 ;
         double safRange = sH - sL ;
         double safR1 = ( safPivot * 2 ) - sL ;
         double safR2 = safPivot + safRange ;
         double safR3 = sH + ( 2 * ( safPivot - sL ) ) ;
         double safS1 = ( safPivot * 2 ) - sH ;
         double safS2 = safPivot - safRange ;
         double safS3 = sL - ( 2 * ( sH - safPivot ) ) ;
         goDraw_HorizontalLine ( "P" , safPivot , clrWhite ) ;
         goDraw_HorizontalLine ( "R1" , safR1 , clrRed ) ;
         goDraw_HorizontalLine ( "S1" , safS1 , clrBlue ) ;
         goDraw_HorizontalLine ( "R2" , safR2 , clrRed ) ;
         goDraw_HorizontalLine ( "S2" , safS2 , clrBlue ) ;
         goDraw_HorizontalLine ( "R3" , safR3 , clrRed ) ;
         goDraw_HorizontalLine ( "S3" , safS3 , clrBlue ) ;
      glb_EAP = sCurr_Period ;
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }

   string myIndicator_MultiIndOnScreen (
      string safRules="2345" ,
      string sType="EMA" ,
      int sTop=50 ,
      int sLeft=50 ,
      string sPeriod="5|10|20|50|75|100|150|200" ,
      int sSide=25 ,
      int sSpace=5 ,
      int sTriSide= 3 ,
      int Ind_B_Target=50 ,
      int Ind_Y_Target=25 ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // ----- RULE 1: Only Calc triangle
         // ----- Rule 2: Calc RSI
         // ----- Rule 3: Calc MFI
         // ----- Rule 4: Calc ADX
         // ----- Rule 5: Calc MAs
         string FinalResult = "" , SignalResult = "" , MomentumResult = "" ;
         // ------------------------------ Arrays
         ENUM_TIMEFRAMES sTF_Array [] = {
            PERIOD_D1 , PERIOD_H12 , PERIOD_H8 , PERIOD_H6 , PERIOD_H4 , PERIOD_H3 , PERIOD_H2 , PERIOD_H1 ,
            PERIOD_M30 , PERIOD_M20 , PERIOD_M15 , PERIOD_M12 , PERIOD_M10 , PERIOD_M6 , PERIOD_M5 ,
            PERIOD_M4 , PERIOD_M3 , PERIOD_M2 , PERIOD_M1 } ;
         string sTFName_Array [] = { "D1","H12","H8","H6","H4","H3","H2","H1","M30","M20","M15","M12","M10","M6","M5","M4","M3","M2","M1" } ;
         string sPeriod_Array [] ; StringSplit ( sPeriod , StringGetCharacter ( "|" , 0 ) , sPeriod_Array ) ;
         // ------------------------------ Old variables
         ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         int sCurr_BufferDepth = glb_BD ;
            glb_BD = 2 ;
            int sTriY = 1 ;
            double Price = ( sAsk() + sBid() ) / 2 ;
            // ------------------------------ Start grid here
            for ( int i=-1 ; i < ArraySize ( sTF_Array ) ; i ++ ) {
               for ( int j=-1 ; j < ArraySize ( sPeriod_Array ) ; j ++ ) {
                  // ------------------------------ Limit to only triangle
                  if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
                     if ( i < ( ArraySize ( sTF_Array ) - sTriSide ) ) { continue ; }
                     if ( j >= sTriY ) { continue ; }}
                  // ------------------------------ Variables
                  color sColor = clrBlack , tColor = clrWhite ;
                  string sADXRSIMFI = "" ;
                  double Ind_C , Ind_L , Ind_S_Target ;
                  int safAdjust = 0 ;
                  int sH = sLeft + ( i * ( sSide + sSpace ) ) ;
                  int sV = sTop + ( j * ( sSide + sSpace ) ) ;
                  string sName = sType + "|" + string (i) + "|" + string(j) ;
                  MomentumResult = " " ; SignalResult = "" ;
                  // ------------------------------ Remove Old square
                  ObjectDelete( 0 , sName ) ;
                  goDraw_PointRectangle ( sName , sH , sV , sSide , sSide , clrBlack , 4 ) ;
                  ChartRedraw() ; Sleep (1) ;
                  // ------------------------------ Draw from here to screen
                  if ( ( j == -1 ) && ( i == -1 ) ) { goDraw_WriteToScreen ( sName , sType , sH , sV ) ; // ---- Write Indicator Type
                  } else if ( i == -1 ) { goDraw_WriteToScreen ( sName , string ( sPeriod_Array[j] ) , sH , sV ) ; // ---- Write Period
                  } else if ( j == -1 ) { goDraw_WriteToScreen ( sName , sTFName_Array[i] , sH , sV ) ; // ---- Write timeframe name
                  } else {
                     // ------------------------------ Calc RSI
                     if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
                        Ind_S_Target = 100 - Ind_B_Target ;
                        sRSI ( (int)sPeriod_Array[j] , sTF_Array [i] ) ; Ind_C = B0 [ 0 ] ; Ind_L = B0 [ 1 ] ;
                        if ( Ind_C >= Ind_B_Target ) { if ( Ind_C > Ind_L ) { sADXRSIMFI += "B" ; } else { sADXRSIMFI += "b" ; }}
                        else if ( Ind_C < Ind_S_Target ) { if ( Ind_C < Ind_L ) { sADXRSIMFI += "S" ; } else { sADXRSIMFI += "s" ; }}}
                     // ------------------------------ Calc MFI
                     if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
                        Ind_S_Target = 100 - Ind_B_Target ;
                        sMFI ( (int)sPeriod_Array[j] , sTF_Array [i] ) ; Ind_C = B0 [ 0 ] ; Ind_L = B0 [ 1 ] ;
                        if ( Ind_C >= Ind_B_Target ) { if ( Ind_C > Ind_L ) { sADXRSIMFI += "B" ; } else { sADXRSIMFI += "b" ; }}
                        else if ( Ind_C < Ind_S_Target ) { if ( Ind_C < Ind_L ) { sADXRSIMFI += "S" ; } else { sADXRSIMFI += "s" ; }}}
                     // ------------------------------ Calc ADX
                     if ( StringFind ( safRules , "4" , 0 ) >= 0 ) {
                        sADX ( (int)sPeriod_Array[j] , sTF_Array [i] ) ; Ind_C = B0 [ 0 ] ; Ind_L = B0 [ 1 ] ;
                        if ( Ind_C > Ind_Y_Target ) { MomentumResult = sADXRSIMFI ; if ( Ind_C > Ind_L ) { MomentumResult += sADXRSIMFI ; }}}
                     // ------------------------------ Calc MA here
                     if ( StringFind ( safRules , "5" , 0 ) >= 0 ) {
                        sMA ( sType , (int)sPeriod_Array[j] , sTF_Array [i] ) ;
                        Ind_C = B0 [ 0 ] ; Ind_L = B0 [ 1 ] ;
                        if ( Price >= Ind_C ) {
                           if ( Ind_C > Ind_L ) { sColor = clrBlue ; tColor = clrWhite ; SignalResult += "B" ;
                           } else { sColor = clrLightBlue ; tColor = clrBlack ; SignalResult += "b" ; }}
                        else {
                           if ( Ind_C < Ind_L ) { sColor = clrRed ; tColor = clrBlack ; SignalResult += "S" ;
                           } else { sColor = clrLightPink ; tColor = clrBlack ; SignalResult += "s" ; }}}
                     // ------------------------------ Check if we r in the triangle
                     if ( ( i >= ( ArraySize ( sTF_Array ) - sTriSide ) ) && ( j < sTriY ) ) {
                        goDraw_PointRectangle ( sName+"B" , sH , sV , sSide , sSide , clrYellowGreen , 4 ) ;
                        FinalResult += MomentumResult + "-" + SignalResult + "-" ;
                        safAdjust = 3 ; }
                     // ------------------------------ Write new content
                     goDraw_PointRectangle ( sName , ( sH + safAdjust ) , ( sV + safAdjust ) , ( sSide - ( 2 * safAdjust ) ) , ( sSide - ( 2 * safAdjust ) ) , sColor , 4 ) ;
                     goDraw_WriteToScreen ( ( sName + "W" ) , MomentumResult , ( sH + sSpace ) , ( sV + sSpace ) , 0 , tColor ) ; }}
               // ------------------------------ Advance triangle Y by 1
               if ( i >= ( ArraySize ( sTF_Array ) - sTriSide ) ) { sTriY +=1 ; }}
         // ------------------------------ Return global variables
         glb_EAP = sCurr_Period ;
         glb_BD = sCurr_BufferDepth ;
         return ( FinalResult ) ; }

   //===========================================================================================================
   //=====                                     DRAWING FUNCTIONS                                           =====
   //===========================================================================================================

   void goDraw_VerticalLine ( string safName , datetime safTime , color safColor ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static int safCounter ;
      if ( safName == "" ) { safName = "VLine" + string ( safCounter ) ; }
      ObjectDelete ( 0 , safName ) ;
      ObjectCreate ( 0 , safName , OBJ_VLINE , 0 , safTime , 0 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safColor ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_STYLE , STYLE_DOT ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BACK , true ) ;
      safCounter += 1 ; }

   void goDraw_HorizontalLine ( string safName , double safPrice , color safColor ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static int safCounter ;
      if ( safName == "" ) { safName = "HLine" + string ( safCounter ) ; }
      ObjectDelete ( 0 , safName ) ;
      if ( safPrice > 0 ) {
      ObjectCreate ( 0 , safName , OBJ_HLINE , 0 , 0 , safPrice ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safColor ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_STYLE , STYLE_DOT ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BACK , true ) ;
      safCounter += 1 ; }}

   void goDraw_ConnectedLine ( string safName , int safIndex , double safPrice , datetime safTime , color safColor ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static int safCounter ;
      static double oldPrice [ 3 ] ;
      static datetime oldTime [ 3 ] ;
      if ( safName == "" ) { safName = "CLine" + string ( safCounter ) ; }
      if ( oldPrice [ safIndex ] ) {
         if ( oldTime [ safIndex ] > safTime ) {
            ObjectDelete ( 0 , safName ) ;
            ObjectCreate ( 0 , safName , OBJ_TREND , 0 , safTime , safPrice , oldTime [ safIndex ] , oldPrice [ safIndex ] ) ;
            ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safColor ) ;
            ObjectSetInteger ( 0 , safName , OBJPROP_STYLE , STYLE_DOT ) ;
            ObjectSetInteger ( 0 , safName , OBJPROP_BACK , true ) ;
            safCounter += 1 ; }}
      oldTime [ safIndex ] = safTime ;
      oldPrice [ safIndex ] = safPrice ; }

   void goDraw_PriceRectangle ( string safName , datetime LLT , double LLV , datetime URT , double URV , color safColor ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static int safCounter ;
      if ( safName == "" ) { safName = "RectPrc" + string ( safCounter ) ; }
      ObjectDelete ( 0, safName ) ;
      ObjectCreate ( 0, safName , OBJ_RECTANGLE , 0 , LLT , LLV , URT , URV ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safColor ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_FILL , true ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BACK , true ) ;
      safCounter += 1 ; }

   void goDraw_PointRectangle ( string safName , int safX1 , int safY1 , int safX2 , int safY2 , color safColor , int safCorner=2 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static int safCounter ;
      if ( safName == "" ) { safName = "RectPnt" + string ( safCounter ) ; }
      ObjectDelete ( 0 , safName ) ;
      ObjectCreate ( 0 , safName , OBJ_RECTANGLE_LABEL , 0 , 0 , 0 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_XDISTANCE , safX1 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_YDISTANCE , safY1 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_XSIZE , safX2 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_YSIZE , safY2 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_CORNER , safCorner ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BGCOLOR , safColor ) ;
      safCounter += 1 ; }

   void goDraw_Button ( string safName , int safX1 , int safY1 , int safX2 , int safY2 , color safBGColor , color safFGColor , string safText ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static int safCounter ;
      if ( safName == "" ) { safName = "Button" + string ( safCounter ) ; }
      ObjectDelete ( 0 , safName ) ;
      ObjectCreate ( 0 , safName , OBJ_BUTTON , 0 , 0 , 0 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_XDISTANCE , safX1 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_YDISTANCE , safY1 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_XSIZE , safX2 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_YSIZE , safY2 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_CORNER , 3 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BGCOLOR , safBGColor ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safFGColor ) ;
      ObjectSetString  ( 0 , safName , OBJPROP_TEXT , safText ) ;
      ChartSetInteger ( 0 , CHART_SHIFT , true ) ;
      ChartRedraw () ;
      safCounter += 1 ; }

   void goDraw_TextBox ( string safName , int safX1 , int safY1 , int safX2 , int safY2 , color safBGColor , color safFGColor , string safDefaultText ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static int safCounter ;
      if ( safName == "" ) { safName = "TextBox" + string ( safCounter ) ; }
      ObjectDelete ( 0 , safName ) ;
      ObjectCreate ( 0 , safName , OBJ_EDIT , 0 , 0 , 0 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_XDISTANCE , safX1 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_YDISTANCE , safY1 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_XSIZE , safX2 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_YSIZE , safY2 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_CORNER , 3 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BGCOLOR , safBGColor ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safFGColor ) ;
      ObjectSetString  ( 0 , safName , OBJPROP_TEXT , safDefaultText ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_ALIGN , ALIGN_CENTER ) ;
      ChartSetInteger ( 0 , CHART_SHIFT , true ) ;
      ChartRedraw () ;
      safCounter += 1 ; }

   void goDraw_WriteToCandle ( string safText , int safCandle , color safColor ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static int safCounter ;
      string safName = "CandleText" + string ( safCounter ) ;
      double safChartMax = ChartGetDouble ( 0 , CHART_PRICE_MAX , 0 ) ;
      double safChartMin = ChartGetDouble ( 0 , CHART_PRICE_MIN , 0 ) ;
      double CurrentHigh = glb_PI [ safCandle ].high ;
      double CurrentLow = glb_PI [ safCandle ].low ;
      datetime CurrentTime = glb_PI [ safCandle ].time ;
      ObjectDelete ( 0 , safName ) ;
      if ( ( safChartMax - CurrentHigh ) > ( CurrentLow - safChartMin ) ) {
         ObjectCreate ( 0 , safName , OBJ_TEXT , 0 , CurrentTime , CurrentHigh ) ;
         ObjectSetDouble ( 0 , safName, OBJPROP_ANGLE , 90 ) ;
      } else {
         ObjectCreate ( 0 , safName , OBJ_TEXT , 0 , CurrentTime , CurrentLow ) ;
         ObjectSetDouble ( 0 , safName, OBJPROP_ANGLE , -90 ) ; }
      ObjectSetString ( 0 , safName , OBJPROP_FONT , "Arial" ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_FONTSIZE , 8 ) ;
      ObjectSetString ( 0 , safName , OBJPROP_TEXT , "   " + safText ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safColor ) ;
      safCounter += 1 ; }

   void goDraw_DeleteScreenObject ( string safPrefix ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      for ( int i = ObjectsTotal ( 0 , 0 , -1 ) - 1 ; i >= 0 ; i-- ) {
         string safObjectName = "ZZZ" + ObjectName ( 0 , i , 0 , -1 ) ;
         if ( StringFind ( safObjectName , safPrefix , 0 ) >= 0 ) { ObjectDelete ( 0 , ObjectName ( 0 , i , 0 , -1 ) ) ; }}}

   void goDraw_LiveStopsOnChart ( double safSLV , double safTPV , double MaxAllowedSpread=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      int safCounter = 0 ;
      double safAsk = sAsk() ;
      double safBid = sBid() ;
      double safBSL = safBid - safSLV ;
      double safBTP = safAsk + safTPV ;
      double safSSL = safAsk + safSLV ;
      double safSTP = safBid - safTPV ;
      datetime safTime_C = glb_PI[ glb_FC + safCounter ].time ; datetime safFirstTime = safTime_C ;
      datetime safTime_L = glb_PI[ glb_FC + safCounter + 1 ].time ;
      if ( ( glb_AllowedStops == No_Stops ) || ( glb_AllowedStops == SL_Only ) ) { safBTP = 0 ; safSTP = 0 ; }
      if ( ( glb_AllowedStops == No_Stops ) || ( glb_AllowedStops == TP_Only ) ) { safBSL = 0 ; safSSL = 0 ; }
      if ( ( glb_AllowedTrade == Buy_and_Sell ) || ( glb_AllowedTrade == Buy_Only ) ) {
         if ( safBSL != 0 ) {
            goDraw_PriceRectangle ( "TempBuySL" , safTime_C , safBSL , safTime_L , safBid , clrLightPink ) ; }
         if ( safBTP != 0 ) {
            goDraw_PriceRectangle ( "TempBuyTP" , safTime_C , safBTP , safTime_L , safAsk , clrLightGreen ) ; }
         safCounter += 1 ; }
      if ( ( glb_AllowedTrade == Buy_and_Sell ) || ( glb_AllowedTrade == Sell_Only ) ) {
         safTime_C = glb_PI[ glb_FC + safCounter ].time ;
         safTime_L = glb_PI[ glb_FC + safCounter + 1 ].time ;
         if ( safSSL != 0 ) {
            goDraw_PriceRectangle ( "TempSellSL" , safTime_C , safSSL , safTime_L , safAsk , clrLightPink ) ; }
         if ( safSTP != 0 ) {
            goDraw_PriceRectangle ( "TempSellTP" , safTime_C , safSTP , safTime_L , safBid , clrLightGreen ) ; }}
      if ( MaxAllowedSpread > 0 ) {
         if ( ( safAsk - safBid ) >= MaxAllowedSpread ) {
            goDraw_PriceRectangle ( "TempTradeOn" , safFirstTime , safAsk , safTime_L , safBid , clrRed ) ;
         } else { ObjectDelete ( 0 , "TempTradeOn" ) ; }}}

   void goDraw_WriteToScreen ( string safName="" , string safText="" , int safX1=0 , int safY1=0 , int safYGap=0 , color safFGColor=clrYellow , color safBGColor=clrNONE ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static int safCounter ;
      static int safLastX ; if ( safX1 == 0 ) { safX1 = safLastX ; } else { safLastX = safX1 ; }
      static int safNextY ; if ( safY1 == 0 ) { safY1 = safNextY ; } else { safNextY = safY1 ; }
      static int safLastYGap ; if ( safYGap == 0 ) { safYGap = safLastYGap ; } else { safLastYGap = safYGap ; }
      if ( safName == "" ) { safName = "ScreenText" + string ( safCounter ) ; }
      ObjectDelete ( 0 , safName ) ;
      ObjectCreate ( 0 , safName , OBJ_LABEL , 0 , 0 , 0 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_XDISTANCE , safX1 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_YDISTANCE , safY1 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_ANCHOR , ANCHOR_LEFT_UPPER ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BGCOLOR , safBGColor ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safFGColor ) ;
      ObjectSetString ( 0 , safName , OBJPROP_FONT , "Arial" ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_FONTSIZE , 8 ) ;
      ObjectSetString  ( 0 , safName , OBJPROP_TEXT , safText ) ;
      safCounter += 1 ;
      safNextY += safYGap ; }

   void goDraw_ControlPanel (
      string safRules = "1234556789" ,
      int safY = 50 ,
      int safX = 175 ,
      int safYAdd = 50 ,
      double BigButton = 160 ,
      int SmallButton = 75 ,
      int ItemHeight = 30 ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         if ( StringFind ( safRules , "1" , 0 ) >= 0 )  {
            goDraw_Button ( "BuyButton" , safX , safY  , SmallButton , ItemHeight , clrBlue , clrWhite , "Buy" ) ;
            goDraw_Button ( "SellButton" , 90 , safY , SmallButton , ItemHeight , clrRed , clrWhite , "Sell" ) ;
            safY += safYAdd ; }
         if ( StringFind ( safRules , "2" , 0 ) >= 0 )  {
            goDraw_Button ( "ClosePositive" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Close Positive" ) ;
            safY += safYAdd ; }
         if ( StringFind ( safRules , "3" , 0 ) >= 0 )  {
            goDraw_Button ( "CloseMostProfit" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Close Most Profitable" ) ;
            safY += safYAdd ; }
         if ( StringFind ( safRules , "4" , 0 ) >= 0 )  {
            goDraw_Button ( "CloseAll" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Close All" ) ;
            safY += safYAdd ; }
         if ( StringFind ( safRules , "5" , 0 ) >= 0 )  {
            goDraw_Button ( "ForceBE" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Force BE" ) ;
            safY += safYAdd ; }
         if ( StringFind ( safRules , "6" , 0 ) >= 0 )  {
            goDraw_Button ( "SetSL" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Set SL after BE" ) ;
            safY += safYAdd ; }
         if ( StringFind ( safRules , "7" , 0 ) >= 0 )  {
            goDraw_Button ( "SetSLNow" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Set SL now" ) ;
            safY += safYAdd ; }
         if ( StringFind ( safRules , "8" , 0 ) >= 0 )  {
            goDraw_TextBox ( "CommentToClose" , safX , safY , ( (int) ( BigButton * 0.65 ) ) , ItemHeight , clrWhite , clrBlack , "Comment" ) ;
            goDraw_Button ( "KillButton" , 65 , safY , ( (int) ( BigButton * 0.3 ) ) , ItemHeight , clrGreen , clrWhite , "Kill" ) ;
            safY += safYAdd ; }
         if ( StringFind ( safRules , "9" , 0 ) >= 0 )  {
            goDraw_Button ( "PauseButton" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Pause ON/OFF" ) ;
            safY += safYAdd ; }}

   void goDraw_ButtonPress ( const string &sparam , string safType ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static color currentBG ;
      static color currentFG ;
      if ( UT ( safType ) == "DOWN" ) {
         currentBG = color ( ObjectGetInteger ( 0 , sparam , OBJPROP_BGCOLOR , 0 ) ) ;
         currentFG = color ( ObjectGetInteger ( 0 , sparam , OBJPROP_COLOR , 0 ) ) ;
         ObjectSetInteger ( 0 , sparam , OBJPROP_BGCOLOR , clrLightGray ) ;
         ObjectSetInteger ( 0 , sparam , OBJPROP_COLOR , clrBlack ) ;
         ChartRedraw () ;
      } else {
         Sleep ( 250 ) ;
         ObjectSetInteger ( 0 , sparam , OBJPROP_STATE , false ) ;
         ObjectSetInteger ( 0 , sparam , OBJPROP_BGCOLOR , currentBG ) ;
         ObjectSetInteger ( 0 , sparam , OBJPROP_COLOR , currentFG ) ;
         ChartRedraw () ; }}

   //===========================================================================================================
   //=====                              PRIVATE POSITION AND ORDER FUNCTIONS                               =====
   //===========================================================================================================

   void prvPosition_Trail ( double safSLV=0 , double safFactor=0.8 , double safAmount=0 , string safFilter="12" , int safATRPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // ---------- RULE 1: Check Symbol or Multi currency trail
      // ---------- RULE 2: Check Magic Number
      // ---------- RULE 3: Check Break Even / Amount = 0 unless overridden by safAmount
      // ---------- RULE 4: quit if BE and u already moved the SL to posOpen
      // -------------------- Return checks
      if ( PositionsTotal () < 1 ) { return ; }
      if ( ( safSLV == 0 ) && ( safAmount == 0 ) && ( safATRPeriod == 0 ) ) { return ; }
      double safSLV2Use = safSLV ;
      // -------------------- Save current global variables
      string sCurr_Symbol = glb_EAS ;
         // -------------------- Go thru all open one by one
         for ( int i = PositionsTotal () - 1 ; i >= 0 ; i-- ) {
            // -------------------- Check that ticket is selected
            ulong safTicket = PositionGetTicket ( i ) ;
            if ( !PositionSelectByTicket ( safTicket ) ) { continue ; }
            // -------------------- Check Break Even
            // if ( StringFind ( safFilter , "3" , 0 ) >= 0 ) { if ( sProfit() <= safAmount ) { continue ; }}
            // -------------------- Check Symbol
            string posSymbol = PositionGetString ( POSITION_SYMBOL ) ;
            if ( StringFind ( safFilter , "1" , 0 ) >= 0 ) {
               if ( posSymbol != glb_EAS ) { continue ; }
            } else {
               glb_EAS = posSymbol ;
               if ( safATRPeriod > 0 ) {
                  // -------------------- handle indicator here
                  if ( ind_ATR ( safATRPeriod ) == false ) {
                     goPrint ( "Unable to trail due to ATR error for " + glb_EAS ) ;
                     return ;  }
                  safSLV2Use = B0 [ glb_FC ] * safSLV ; }}
            // -------------------- Check Magic number
            if ( StringFind ( safFilter , "2" , 0 ) >= 0 ) { if ( UT ( GGS ( PositionGetString ( POSITION_COMMENT ) , 0 ) ) != UT ( glb_Magic ) ) { continue ; }}
            // -------------------- Variables
            double posOpenPrice = PositionGetDouble ( POSITION_PRICE_OPEN ) ;
            double posSL = PositionGetDouble ( POSITION_SL ) ;
            double posTP = ND ( PositionGetDouble ( POSITION_TP ) ) ;
            double safTrailStep = 3 * sPoint() ;
            // -------------------- Check for BreakEven
            if ( StringFind ( safFilter , "4" , 0 ) >= 0 ) { if ( posSL == posOpenPrice ) { continue ; }}
            // -------------------- Trail logic
            if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_BUY ) {
               double safBid = sBid() ;
               double newSL = safBid - safSLV2Use ;
               if ( StringFind ( safFilter , "3" , 0 ) >= 0 ) { if ( newSL < posOpenPrice ) { continue ; }}
               if ( ( newSL - posSL ) >= safTrailStep ) {
                  double newSLFactor = ND ( safBid - ( safSLV2Use * safFactor ) ) ;
                  if ( StringFind ( safFilter , "4" , 0 ) >= 0 ) {
                     newSLFactor = ND ( posOpenPrice ) ;
                     goBroadcast_SIG ( goTele_PrepMsg ( "TRBE" , (string)safSLV , (string)safFactor , (string)safAmount , safFilter , (string)safATRPeriod ) ) ;
                  } else {
                     goBroadcast_SIG ( goTele_PrepMsg ( "TRSLV" , (string)safSLV , (string)safFactor , (string)safAmount , safFilter , (string)safATRPeriod ) ) ; }
                  trade.PositionModify ( safTicket , newSLFactor , posTP ) ; }
            } else {
               if ( posSL == 0 ) { posSL = 999999 ; }
               double safAsk = sAsk() ;
               double newSL = safAsk + safSLV2Use ;
               if ( StringFind ( safFilter , "3" , 0 ) >= 0 ) { if ( newSL > posOpenPrice ) { continue ; }}
               if ( ( posSL - newSL ) >= safTrailStep ) {
                  double newSLFactor = ND ( safAsk + ( safSLV2Use * safFactor ) ) ;
                  if ( StringFind ( safFilter , "4" , 0 ) >= 0 ) {
                     newSLFactor = ND ( posOpenPrice ) ;
                     goBroadcast_SIG ( goTele_PrepMsg ( "TRBE" , (string)safSLV , (string)safFactor , (string)safAmount , safFilter , (string)safATRPeriod ) ) ;
                  } else {
                     goBroadcast_SIG ( goTele_PrepMsg ( "TRSLV" , (string)safSLV , (string)safFactor , (string)safAmount , safFilter , (string)safATRPeriod ) ) ; }
                  trade.PositionModify ( safTicket , newSLFactor , posTP ) ; }}}
      // -------------------- Return global variables
      glb_EAS = sCurr_Symbol ; }

   string prvPosition_Analytics ( string safRules="" , string safFilter="12" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // ---------- RULE 1: Check Symbol
      // ---------- RULE 2: Check Magic Number
      // -------------------- Return checks
      if ( PositionsTotal () < 1 ) { return "" ; }
      if ( safRules == "" ) { return "" ; }
      // -------------------- Return variables Here
      int safCountAll=0 , safCountBuy=0 , safCountSell=0 , safCountNoSL=0 , safCountSellNoSL=0 , safCountBuyNoSL=0 ;
      double safLotAll=0 , safLotBuy=0 , safLotSell=0 ;
      ulong safBiggestProfitTicket=0 , safBiggestLossTicket=0 , safSmallestProfitTicket=0 , safSmallestLossTicket=0 ;
      double safBiggestProfit=0 , safBiggestLoss=0 , safSmallestProfit=0 , safSmallestLoss=0 ;
      static int safMaxNo=0 ;
      double safNetProfit=0 ;
      string posComment="" , safAllComments="" ;
      // -------------------- Go thru all open one by one
      for ( int i = PositionsTotal () - 1 ; i >= 0 ; i-- ) {
         // -------------------- Check that ticket is selected
         ulong safTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( safTicket ) ) { continue ; }
         // -------------------- Check Symbol
         if ( StringFind ( safFilter , "1" , 0 ) >= 0 ) { if ( PositionGetString ( POSITION_SYMBOL ) != glb_EAS ) { continue ; }}
         // -------------------- Check Magic number
         posComment = PositionGetString ( POSITION_COMMENT ) ;
         if ( StringFind ( safFilter , "2" , 0 ) >= 0 ) { if ( UT ( GGS ( posComment , 0 ) ) != UT ( glb_Magic ) ) { continue ; }}
         safAllComments += posComment ;
         // -------------------- Variables
         double posLot = PositionGetDouble ( POSITION_VOLUME ) ;
         double posProfit = sProfit() ;
         // -------------------- Calculations Start Here
         safCountAll += 1 ;
         safLotAll += posLot ;
         safNetProfit += posProfit ;
         // -------------------- Biggest and smallest loss/profit tickets
         if( posProfit > 0 ) {
            if ( posProfit > safBiggestProfit ) { safBiggestProfit = posProfit ; safBiggestProfitTicket = safTicket ; }
            if ( safSmallestProfit == 0 ) { safSmallestProfit = posProfit ; safSmallestProfitTicket = safTicket ; }
            if ( posProfit < safSmallestProfit ) { safSmallestProfit = posProfit ; safSmallestProfitTicket = safTicket ; }
         } else {
            if ( posProfit < safBiggestLoss ) { safBiggestLoss = posProfit ; safBiggestLossTicket = safTicket ; }
            if ( safSmallestLoss == 0 ) { safSmallestLoss = posProfit ;  safSmallestLossTicket = safTicket ; }
            if ( posProfit > safSmallestLoss ) { safSmallestLoss = posProfit ; safSmallestLossTicket = safTicket ; }}
         // -------------------- No SL
         if ( PositionGetDouble ( POSITION_SL ) == 0 ) {
            safCountNoSL += 1 ;
            if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_BUY ) {
               safCountBuyNoSL += 1 ; } else { safCountSellNoSL += 1 ; }}
         // -------------------- Trail logic
         if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_BUY ) {
            safCountBuy += 1 ;
            safLotBuy += posLot ;
         } else {
            safCountSell += 1 ;
            safLotSell += posLot ;
         } // Close sell
      } // Next i
      // -------------------- Max no of positions open at the same time
      if ( safCountAll > safMaxNo ) { safMaxNo = safCountAll ; }
      // -------------------- Return here
      if ( StringFind ( safRules , "A" , 0 ) >= 0 ) { return (string) safCountAll ;
      } else if ( StringFind ( safRules , "B" , 0 ) >= 0 ) { return (string) safCountBuy ;
      } else if ( StringFind ( safRules , "C" , 0 ) >= 0 ) { return (string) safCountSell ;
      } else if ( StringFind ( safRules , "D" , 0 ) >= 0 ) { return (string) safCountNoSL ;
      } else if ( StringFind ( safRules , "E" , 0 ) >= 0 ) { return (string) safLotAll ;
      } else if ( StringFind ( safRules , "F" , 0 ) >= 0 ) { return (string) safLotBuy ;
      } else if ( StringFind ( safRules , "G" , 0 ) >= 0 ) { return (string) safLotSell ;
      } else if ( StringFind ( safRules , "H" , 0 ) >= 0 ) { return (string) safBiggestProfitTicket ;
      } else if ( StringFind ( safRules , "I" , 0 ) >= 0 ) { return (string) safBiggestLossTicket ;
      } else if ( StringFind ( safRules , "J" , 0 ) >= 0 ) { return (string) safSmallestProfitTicket ;
      } else if ( StringFind ( safRules , "K" , 0 ) >= 0 ) { return (string) safSmallestLossTicket ;
      } else if ( StringFind ( safRules , "L" , 0 ) >= 0 ) { return (string) safMaxNo ;
      } else if ( StringFind ( safRules , "M" , 0 ) >= 0 ) { return (string) safNetProfit ;
      } else if ( StringFind ( safRules , "N" , 0 ) >= 0 ) { return (string) safAllComments ;
      } else if ( StringFind ( safRules , "O" , 0 ) >= 0 ) { return (string) safCountBuyNoSL ;
      } else if ( StringFind ( safRules , "P" , 0 ) >= 0 ) { return (string) safCountSellNoSL ;
      } else { return "" ; }
   } // Close function

   void prvPosition_Closer ( string safRules="" , double safMinProfit=0 , string safFilter="12" , string safText="" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // ---------- RULE 1: Check Symbol
      // ---------- RULE 2: Check Magic Number
      // -------------------- Return checks
      if ( PositionsTotal () < 1 ) { return ; }
      if ( safRules == "" ) { return ; }
      // -------------------- Go thru all open one by one
      for ( int i = PositionsTotal () - 1 ; i >= 0 ; i-- ) {
         // -------------------- Check that ticket is selected
         ulong safTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( safTicket ) ) { continue ; }
         // -------------------- Check Symbol
         if ( StringFind ( safFilter , "1" , 0 ) >= 0 ) { if ( PositionGetString ( POSITION_SYMBOL ) != glb_EAS ) { continue ; }}
         // -------------------- Check Magic number
         if ( StringFind ( safFilter , "2" , 0 ) >= 0 ) { if ( UT ( GGS ( PositionGetString ( POSITION_COMMENT ) , 0 ) ) != UT ( glb_Magic ) ) { continue ; }}
         // -------------------- Close starts here
         long posType = PositionGetInteger ( POSITION_TYPE ) ;
         if ( StringFind ( safRules , "A" , 0 ) >= 0 ) { if ( posType == POSITION_TYPE_BUY ) { if ( sProfit() > safMinProfit ) {
            goBroadcast_SIG ( goTele_PrepMsg ( "CABP" , safRules , (string)safMinProfit , safFilter ) ) ;
            trade.PositionClose ( safTicket ) ; }}}
         if ( StringFind ( safRules , "B" , 0 ) >= 0 ) { if ( posType == POSITION_TYPE_SELL ) { if ( sProfit() > safMinProfit ) {
            goBroadcast_SIG ( goTele_PrepMsg ( "CASP" , safRules , (string)safMinProfit , safFilter ) ) ;
            trade.PositionClose ( safTicket ) ; }}}
         if ( StringFind ( safRules , "C" , 0 ) >= 0 ) { if ( sProfit() > safMinProfit ) {
            goBroadcast_SIG ( goTele_PrepMsg ( "CAPP" , safRules , (string)safMinProfit , safFilter ) ) ;
            trade.PositionClose ( safTicket ) ; }}
         if ( StringFind ( safRules , "D" , 0 ) >= 0 ) { if ( safText != "" ) {
            if ( StringFind ( PositionGetString ( POSITION_COMMENT ) , safText , 0 ) >= 0 ) { if ( sProfit() > safMinProfit ) {
               goBroadcast_SIG ( goTele_PrepMsg ( "KILL" , safRules , (string)safMinProfit , safFilter , safText ) ) ;
               trade.PositionClose ( safTicket ) ; }}}}
      } // Next i
   } // Close function

   string prvOrder_Analytics ( string safRules="" , string safFilter="12" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // ---------- RULE 1: Check Symbol
      // ---------- RULE 2: Check Magic Number
      // -------------------- Return checks
      if ( OrdersTotal () < 1 ) { return "" ; }
      if ( safRules == "" ) { return "" ; }
      // -------------------- Return variables Here
      int safCountAll=0 , safCountBuy=0 , safCountSell=0 ;
      double safLotAll=0 , safLotBuy=0 , safLotSell=0 ;
      static int safMaxNo=0 ;
      string ordComment="" , safAllComments="" ;
      // -------------------- Go thru all open one by one
      for ( int i = OrdersTotal () - 1 ; i >= 0 ; i-- ) {
         // -------------------- Check that ticket is selected
         ulong safTicket = OrderGetTicket ( i ) ;
         if ( !OrderSelect ( safTicket ) ) { continue ; }
         // -------------------- Check Symbol
         if ( StringFind ( safFilter , "1" , 0 ) >= 0 ) { if ( OrderGetString ( ORDER_SYMBOL ) != glb_EAS ) { continue ; }}
         // -------------------- Check Magic number
         ordComment = OrderGetString ( ORDER_COMMENT ) ;
         if ( StringFind ( safFilter , "2" , 0 ) >= 0 ) { if ( UT ( GGS ( ordComment , 0 ) ) != UT ( glb_Magic ) ) { continue ; }}
         safAllComments += ordComment ;
         // -------------------- Variables
         double ordLot = OrderGetDouble  ( ORDER_VOLUME_CURRENT ) ;
         // -------------------- Calculations Start Here
         safCountAll += 1 ;
         safLotAll += ordLot ;
         // -------------------- Trail logic
         if ( OrderGetInteger ( ORDER_TYPE ) == ORDER_TYPE_BUY ) {
            safCountBuy += 1 ;
            safLotBuy += ordLot ;
         } else {
            safCountSell += 1 ;
            safLotSell += ordLot ;
         } // Close sell
      } // Next i
      // -------------------- Max no of positions open at the same time
      if ( safCountAll > safMaxNo ) { safMaxNo = safCountAll ; }
      // -------------------- Return here
      if ( StringFind ( safRules , "A" , 0 ) >= 0 ) { return (string) safCountAll ;
      } else if ( StringFind ( safRules , "B" , 0 ) >= 0 ) { return (string) safCountBuy ;
      } else if ( StringFind ( safRules , "C" , 0 ) >= 0 ) { return (string) safCountSell ;
      } else if ( StringFind ( safRules , "D" , 0 ) >= 0 ) { return (string) safLotAll ;
      } else if ( StringFind ( safRules , "E" , 0 ) >= 0 ) { return (string) safLotBuy ;
      } else if ( StringFind ( safRules , "F" , 0 ) >= 0 ) { return (string) safLotSell ;
      } else if ( StringFind ( safRules , "G" , 0 ) >= 0 ) { return (string) safMaxNo ;
      } else if ( StringFind ( safRules , "H" , 0 ) >= 0 ) { return (string) safAllComments ;
      } else { return "" ; }
   } // Close function

   void prvOrder_Closer ( string safRules="" , double safValue=0 , string safFilter="12" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // ---------- RULE 1: Check Symbol
      // ---------- RULE 2: Check Magic Number
      // -------------------- Return checks
      if ( OrdersTotal () < 1 ) { return ; }
      if ( safRules == "" ) { return ; }
      // -------------------- Go thru all open one by one
      for ( int i = OrdersTotal () - 1 ; i >= 0 ; i-- ) {
         // -------------------- Check that ticket is selected
         ulong safTicket = OrderGetTicket ( i ) ;
         if ( !OrderSelect ( safTicket ) ) { continue ; }
         // -------------------- Check Symbol
         if ( StringFind ( safFilter , "1" , 0 ) >= 0 ) { if ( OrderGetString ( ORDER_SYMBOL ) != glb_EAS ) { continue ; }}
         // -------------------- Check Magic number
         if ( StringFind ( safFilter , "2" , 0 ) >= 0 ) { if ( UT ( GGS ( OrderGetString ( ORDER_COMMENT ) , 0 ) ) != UT ( glb_Magic ) ) { continue ; }}
         // -------------------- Delete starts here
         double ordOpenPrice = OrderGetDouble ( ORDER_PRICE_OPEN ) ;
         if ( StringFind ( safRules , "A" , 0 ) >= 0 ) { if ( ordOpenPrice > safValue ) {
            goBroadcast_SIG ( goTele_PrepMsg ( "COA" , safRules , (string)safValue , safFilter ) ) ;
            trade.OrderDelete ( safTicket ) ; }}
         if ( StringFind ( safRules , "B" , 0 ) >= 0 ) { if ( ordOpenPrice < safValue ) {
            goBroadcast_SIG ( goTele_PrepMsg ( "COB" , safRules , (string)safValue , safFilter ) ) ;
            trade.OrderDelete ( safTicket ) ; }}
         long ordType = OrderGetInteger ( ORDER_TYPE ) ;
         if ( StringFind ( safRules , "C" , 0 ) >= 0 ) { if ( ordType == ORDER_TYPE_BUY ) {
            goBroadcast_SIG ( goTele_PrepMsg ( "CABO" , safRules , (string)safValue , safFilter ) ) ;
            trade.OrderDelete ( safTicket ) ; }}
         if ( StringFind ( safRules , "D" , 0 ) >= 0 ) { if ( ordType == ORDER_TYPE_SELL ) {
            goBroadcast_SIG ( goTele_PrepMsg ( "CASO" , safRules , (string)safValue , safFilter ) ) ;
            trade.OrderDelete ( safTicket ) ; }}
      } // Next i
   } // Close function

   void goPositions_Retreive_OLD ( string &PositionLines[] ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- x
      ArrayResize ( PositionLines , 0 ) ;
      if ( PositionsTotal() < 1 ) { return ; }
      // -------------------- x
      for ( int i=0 ; i<PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         string posSymbol = PositionGetString ( POSITION_SYMBOL ) ;
         long posType = PositionGetInteger ( POSITION_TYPE ) ;
         double posLot = PositionGetDouble ( POSITION_VOLUME ) ;
         double posOpenPrice = PositionGetDouble ( POSITION_PRICE_OPEN ) ;
         string posTime = goTranslate_DateTime ( datetime ( PositionGetInteger ( POSITION_TIME ) ) ) ;
         double posDays = goCalc_DaysBetweenDates ( PositionGetInteger ( POSITION_TIME ) , TimeGMT() ) ;
         double posCurrentPrice = PositionGetDouble ( POSITION_PRICE_CURRENT ) ;
         double posSL = PositionGetDouble ( POSITION_SL ) ;
         double posTP = PositionGetDouble ( POSITION_TP ) ;
         double posProfit = PositionGetDouble ( POSITION_PROFIT ) ;
         double posSwap = PositionGetDouble ( POSITION_SWAP ) ;
         double posNetProfit = posProfit + posSwap ;
         string posComment = PositionGetString ( POSITION_COMMENT ) ;
         double posProfitPerDay = ND2 ( posProfit / posDays ) ;
         double posProfitPerLot = ND2 ( posProfit / posLot ) ;
         double posPriceMovePerc = ND2 ( ( MathAbs ( posCurrentPrice - posOpenPrice ) ) / ( posOpenPrice / 100 ) ) ;
         double posOnePercValue = ND2 ( MathAbs ( posNetProfit / posPriceMovePerc ) ) ;
         // -------------------- x
         string posTypeTrans = "OTHER" ;
         if ( posType == POSITION_TYPE_BUY ) { posTypeTrans = "BUY" ; }
         else if ( posType == POSITION_TYPE_SELL ) { posTypeTrans = "SELL" ; }
         // -------------------- x
         int sArraySize = ArraySize ( PositionLines ) ;
         ArrayResize ( PositionLines , ( sArraySize + 1 ) ) ;
         string result = "|" + (string) posTicket + "|" + (string) posSymbol + "|" + (string) posTypeTrans + "|" + (string) posLot + "|" ;
         result += (string) posOpenPrice + "|" + (string) posTime + "|" + (string) posCurrentPrice + "|" + (string) posSL + "|" ;
         result += (string) posTP + "|" + (string) posProfit + "|" + (string) posSwap + "|" + (string) posNetProfit + "|" ;
         result += (string) posDays + "|" + (string) posProfitPerDay + "|" + (string) posProfitPerLot + "|" + (string) posPriceMovePerc + "%" + "|" ;
         result += (string) posOnePercValue ;
         result += "|XYXYZ|" + (string) posComment + "|ZYXYX|" ;
         PositionLines [ sArraySize ] = result ; }}

   void goPositions_Retreive ( string &PositionLines[] ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- x
      ArrayResize ( PositionLines , 0 ) ;
      if ( PositionsTotal() < 1 ) { return ; }
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ; string result = "|" + (string) posTicket + "|" ; // --- posTicket
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         result += PositionGetString ( POSITION_SYMBOL ) + "|" ; // --- posSymbol
         // -------------------- x
         long posType = PositionGetInteger ( POSITION_TYPE ) ; // --- posType
         if ( posType == POSITION_TYPE_BUY ) { result += "BUY" + "|" ; }
         else if ( posType == POSITION_TYPE_SELL ) { result += "SELL" + "|" ; }
         else { result += "OTHER" + "|" ; }
         // -------------------- x
         double posLot = ND2 ( PositionGetDouble ( POSITION_VOLUME ) ) ; result += (string) posLot + "|" ; // --- posLots
         double posOpenPrice = ND ( PositionGetDouble ( POSITION_PRICE_OPEN ) ) ; result += (string) posOpenPrice + "|" ; // --- posOpenPrice
         result += goTranslate_DateTime ( datetime ( PositionGetInteger ( POSITION_TIME ) ) ) + "|" ; // --- posTime
         double posCurrentPrice = ND ( PositionGetDouble ( POSITION_PRICE_CURRENT ) ) ; result += (string) posCurrentPrice + "|" ; // --- posCurrentPrice
         result += (string) ND ( PositionGetDouble ( POSITION_SL ) ) + "|" ; // --- posSL
         result += (string) ND ( PositionGetDouble ( POSITION_TP ) ) + "|" ; // --- posTP
         double posProfit = PositionGetDouble ( POSITION_PROFIT ) ; result += (string) posProfit + "|" ; // --- posProfit
         double posSwap = PositionGetDouble ( POSITION_SWAP ) ; result += (string) posSwap + "|" ; // --- posSwap
         double posNetProfit = posProfit + posSwap ; result += (string) posNetProfit + "|" ; // --- posNetProfit
         double posDays = goCalc_DaysBetweenDates ( PositionGetInteger ( POSITION_TIME ) , TimeGMT() ) ; result += (string) posDays + "|" ; // --- posDays
         result += (string) ND2 ( posNetProfit / posDays ) + "|" ; // --- posProfitPerDay
         result += (string) ND2 ( posNetProfit / posLot ) + "|" ; // --- posProfitPerLot
         double posPriceMovePerc = ND2 ( ( MathAbs ( posCurrentPrice - posOpenPrice ) ) / ( posOpenPrice / 100 ) ) ; result += (string) posPriceMovePerc + "%|" ; // --- posPriceMovePerc
         result += (string) ND2 ( MathAbs ( posNetProfit / posPriceMovePerc ) ) + "|" ; // --- posOnePercValue
         result += "XYXYZ|" + PositionGetString ( POSITION_COMMENT ) + "|ZYXYX|" ; // --- posComment
         // -------------------- x
         int sArraySize = ArraySize ( PositionLines ) ;
         ArrayResize ( PositionLines , ( sArraySize + 1 ) ) ;
         PositionLines [ sArraySize ] = result ; }}

   //===========================================================================================================
   //=====                                         TRADE FUNCTION                                          =====
   //===========================================================================================================

   void sBuy (
      enumTradeCount safTradeType=Single_Trade , int NoOfTrades=1 , double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 ,
      double safStopsMultiple=0.5 , double safLot=-1 , string safType="B" , double safStart=0 , string safComment="" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // -------------------- Construct comment if not passed into function
         if ( safComment == "" ) { safComment = glb_Magic + "|" + safType + "/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + glb_EAS ; }
         // -------------------- Check for beacon mode, and send beacon
         if ( glb_BeaconMode == true ) {
            goBroadcast_SIG (
               goTele_PrepMsg ( safType , string ( safTradeType ) , string ( NoOfTrades ) , string ( sPow ( safSLV ) ) ,
                  string ( sPow ( safTPV ) ) , string ( sPow ( safPercCalcSLV ) ) , string ( safStopsMultiple ) ,
                  string ( ND2 ( safLot ) ) , string ( ND ( safStart ) ) , string ( glb_LotSize ) , safComment ) ) ;
         } else {
            // -------------------- if not beacon, then Add symbol to data windows if not there
            // goSymbol_AddToDataWindow ( glb_EAS ) ;
            // -------------------- Do multi trade here
            if ( safTradeType == Multi_Trade ) {
               sBuyMulti ( NoOfTrades , safSLV , safTPV , safPercCalcSLV , safStopsMultiple , safLot , safType , safStart , safComment ) ; }
            // -------------------- Do multi minimum trades here
            else if ( safTradeType == Multi_Min_Trade ) {
               sBuyMultiMin ( NoOfTrades , safSLV , safTPV , safPercCalcSLV , safStopsMultiple , safLot , safType , safStart , safComment ) ; }
            // -------------------- Do single trade here
            else { sBuySingle ( safSLV , safTPV , safPercCalcSLV , safLot , safType , safStart , safComment ) ; }}}

   void sBuyMulti (
      int NoOfTrades=1 , double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safStopsMultiple=0 ,
      double safLot=-1 , string safType="B" , double safStart=0 , string safComment="" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         if ( glb_BeaconMode == true ) { return ; }
         // -------------------- Calc divided lot here
         if ( safPercCalcSLV == 0 ) { if ( safSLV != 0 ) { safPercCalcSLV = safSLV ; }}
         double safLot2Use = goCalc_LotSize ( safPercCalcSLV , safLot ) / NoOfTrades ;
         // -------------------- If lot is bigger than minimum
         if ( safLot2Use >= sMin() ) {
            for ( int i = 1 ; i <= NoOfTrades ; i ++ ) {
               double safSLVAddon=0 , safTPVAddon=0 ;
               if ( safStopsMultiple > 0 ) {
                  safSLVAddon = safSLV * safStopsMultiple * ( i - 1 ) ;
                  safTPVAddon = safTPV * safStopsMultiple * ( i - 1 ) ; }
               sBuySingle ( ( safSLV + safSLVAddon ) , ( safTPV + safTPVAddon ) , 0 , safLot2Use , safType , safStart , safComment ) ; }}
         // -------------------- If lot was smaller then just do one trade
         else { sBuySingle ( safSLV , safTPV , safPercCalcSLV , safLot , safType , safStart , safComment ) ; }}

   void sBuyMultiMin (
      int MaxNoOfTrades=10 , double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safStopsMultiple=0 ,
      double safLot=-1 , string safType="B" , double safStart=0 , string safComment="" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         if ( glb_BeaconMode == true ) { return ; }
         // -------------------- Calc divided lot here
         if ( safPercCalcSLV == 0 ) { if ( safSLV != 0 ) { safPercCalcSLV = safSLV ; }}
         int safNoOfLoops = int ( goCalc_LotSize ( safPercCalcSLV , safLot ) / sMin() ) ; safLot = sMin() ;
         if ( safNoOfLoops > MaxNoOfTrades ) {
            do { safNoOfLoops = safNoOfLoops / 2 ; safLot = safLot * 2 ; } while ( safNoOfLoops > MaxNoOfTrades ) ; }
         for ( int i = 1 ; i <= safNoOfLoops ; i ++ ) {
            double safSLVAddon=0 , safTPVAddon=0 ;
            if ( safStopsMultiple > 0 ) {
               safSLVAddon = safSLV * safStopsMultiple * ( i - 1 ) ;
               safTPVAddon = safTPV * safStopsMultiple * ( i - 1 ) ; }
            sBuySingle ( ( safSLV + safSLVAddon ) , ( safTPV + safTPVAddon ) , 0 , safLot , safType , safStart , safComment ) ; }}

   void sBuySingle ( double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safLot=-1 , string safType="B" , double safStart=0 , string safComment="" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_BeaconMode == true ) { return ; }
      if ( ( glb_AllowedTrade == No_Trade ) || ( glb_AllowedTrade == Sell_Only ) ) { return ; }
      double safEnd ; if ( safStart == 0 ) { safStart = sAsk() ; safEnd = sBid() ; } else { safEnd = safStart ; }
      if ( glb_UpperTradeLimit > 0 ) { if ( safStart > glb_UpperTradeLimit ) { return ; }}
      if ( safPercCalcSLV == 0 ) { if ( safSLV != 0 ) { safPercCalcSLV = safSLV ; }}
      if ( safTPV > 0 ) { if ( ( glb_AllowedStops == SL_and_TP ) || ( glb_AllowedStops == TP_Only ) ) { safTPV = safStart + safTPV ; }}
      if ( safSLV > 0 ) { if ( ( glb_AllowedStops == SL_and_TP ) || ( glb_AllowedStops == SL_Only ) ) { safSLV = safEnd - safSLV ; }}
      // safComment = glb_Magic + "|B|" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "|" + glb_EAS + "|" + safComment ;
      if ( safLot == -1 ) { safLot = goCalc_LotSize ( safPercCalcSLV , safLot ) ; }
      if ( glb_MinTradeMode ) { safLot = MathMin ( sMin() , safLot ) ; }
      if ( safType == "B" ) { trade.Buy ( ND2 ( safLot ) , glb_EAS , ND ( safStart ) , ND ( safSLV ) , ND ( safTPV ) , safComment ) ; glb_LastTradeTime = TimeGMT () ; }
      else if ( safType == "BS" ) { trade.BuyStop ( ND2 ( safLot ) , ND ( safStart ) , glb_EAS , ND ( safSLV ) , ND ( safTPV ) , ORDER_TIME_GTC , 0 , safComment ) ; }
      else if ( safType == "BL" ) { trade.BuyLimit ( ND2 ( safLot ) , ND ( safStart ) , glb_EAS , ND ( safSLV ) , ND ( safTPV ) , ORDER_TIME_GTC , 0 , safComment ) ; }}

   void sSell (
      enumTradeCount safTradeType=Single_Trade , int NoOfTrades=1 , double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 ,
      double safStopsMultiple=0.5 , double safLot=-1 , string safType="S" , double safStart=0 , string safComment="" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // -------------------- Construct comment if not passed into function
         if ( safComment == "" ) { safComment = glb_Magic + "|" + safType + "/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + glb_EAS ; }
         // -------------------- Check for beacon mode, and send beacon
         if ( glb_BeaconMode == true ) {
            goBroadcast_SIG (
               goTele_PrepMsg ( safType , string ( safTradeType ) , string ( NoOfTrades ) , string ( sPow ( safSLV ) ) ,
                  string ( sPow ( safTPV ) ) , string ( sPow ( safPercCalcSLV ) ) , string ( safStopsMultiple ) ,
                  string ( ND2 ( safLot ) ) , string ( ND ( safStart ) ) , string ( glb_LotSize ) , safComment ) ) ;
         } else {
            // -------------------- if not beacon, then Add symbol to data windows if not there
            // goSymbol_AddToDataWindow ( glb_EAS ) ;
            // -------------------- Do multi trade here
            if ( safTradeType == Multi_Trade ) {
               sSellMulti ( NoOfTrades , safSLV , safTPV , safPercCalcSLV , safStopsMultiple , safLot , safType , safStart , safComment ) ; }
            // -------------------- Do multi minimum trades here
            else if ( safTradeType == Multi_Min_Trade ) {
               sSellMultiMin ( NoOfTrades , safSLV , safTPV , safPercCalcSLV , safStopsMultiple , safLot , safType , safStart , safComment ) ; }
            // -------------------- Do single trade here
            else { sSellSingle ( safSLV , safTPV , safPercCalcSLV , safLot , safType , safStart , safComment ) ; }}}

   void sSellMulti (
      int NoOfTrades=1 , double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safStopsMultiple=0 ,
      double safLot=-1 , string safType="S" , double safStart=0 , string safComment="" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         if ( glb_BeaconMode == true ) { return ; }
         // -------------------- Calc divided lot here
         if ( safPercCalcSLV == 0 ) { if ( safSLV != 0 ) { safPercCalcSLV = safSLV ; }}
         double safLot2Use = goCalc_LotSize ( safPercCalcSLV , safLot ) / NoOfTrades ;
         // -------------------- If lot is bigger than minimum
         if ( safLot2Use >= sMin() ) {
            for ( int i = 1 ; i <= NoOfTrades ; i ++ ) {
               double safSLVAddon=0 , safTPVAddon=0 ;
               if ( safStopsMultiple > 0 ) {
                  safSLVAddon = safSLV * safStopsMultiple * ( i - 1 ) ;
                  safTPVAddon = safTPV * safStopsMultiple * ( i - 1 ) ; }
               sSellSingle ( ( safSLV + safSLVAddon ) , ( safTPV + safTPVAddon ) , 0 , safLot2Use , safType , safStart , safComment ) ; }}
         // -------------------- If lot was smaller then just do one trade
         else { sSellSingle ( safSLV , safTPV , safPercCalcSLV , safLot , safType , safStart , safComment ) ; }}

   void sSellMultiMin (
      int MaxNoOfTrades=10 , double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safStopsMultiple=0 ,
      double safLot=-1 , string safType="S" , double safStart=0 , string safComment="" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         if ( glb_BeaconMode == true ) { return ; }
         // -------------------- Calc divided lot here
         if ( safPercCalcSLV == 0 ) { if ( safSLV != 0 ) { safPercCalcSLV = safSLV ; }}
         int safNoOfLoops = int ( goCalc_LotSize ( safPercCalcSLV , safLot ) / sMin() ) ; safLot = sMin() ;
         if ( safNoOfLoops > MaxNoOfTrades ) {
            do { safNoOfLoops = safNoOfLoops / 2 ; safLot = safLot * 2 ; } while ( safNoOfLoops > MaxNoOfTrades ) ; }
         for ( int i = 1 ; i <= safNoOfLoops ; i ++ ) {
            double safSLVAddon=0 , safTPVAddon=0 ;
            if ( safStopsMultiple > 0 ) {
               safSLVAddon = safSLV * safStopsMultiple * ( i - 1 ) ;
               safTPVAddon = safTPV * safStopsMultiple * ( i - 1 ) ; }
            sSellSingle ( ( safSLV + safSLVAddon ) , ( safTPV + safTPVAddon ) , 0 , safLot , safType , safStart , safComment ) ; }}

   void sSellSingle ( double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safLot=-1 , string safType="S" , double safStart=0 , string safComment="" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_BeaconMode == true ) { return ; }
      if ( ( glb_AllowedTrade == No_Trade ) || ( glb_AllowedTrade == Buy_Only ) ) { return ; }
      double safEnd ; if ( safStart == 0 ) { safStart = sBid() ; safEnd = sAsk() ; } else { safEnd = safStart ; }
      if ( glb_LowerTradeLimit > 0 ) { if ( safStart < glb_LowerTradeLimit ) { return ; }}
      if ( safPercCalcSLV == 0 ) { if ( safSLV != 0 ) { safPercCalcSLV = safSLV ; }}
      if ( safTPV > 0 ) { if ( ( glb_AllowedStops == SL_and_TP ) || ( glb_AllowedStops == TP_Only ) ) { safTPV = safStart - safTPV ; }}
      if ( safSLV > 0 ) { if ( ( glb_AllowedStops == SL_and_TP ) || ( glb_AllowedStops == SL_Only ) ) { safSLV = safEnd + safSLV ; }}
      // safComment = glb_Magic + "|S|" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "|" + glb_EAS + "|" + safComment ;
      if ( safLot == -1 ) { safLot = goCalc_LotSize ( safPercCalcSLV , safLot ) ; }
      if ( glb_MinTradeMode ) { safLot = MathMin ( sMin() , safLot ) ; }
      if ( safType == "S"  ) { trade.Sell ( ND2 ( safLot ) , glb_EAS , ND ( safStart ) , ND ( safSLV ) , ND ( safTPV ) , safComment ) ; glb_LastTradeTime = TimeGMT () ; }
      else if ( safType == "SS"  ) { trade.SellStop ( ND2 ( safLot ) , ND ( safStart ) , glb_EAS , ND ( safSLV ) , ND ( safTPV ) , ORDER_TIME_GTC , 0 , safComment ) ; }
      else if ( safType == "SL"  ) { trade.SellLimit ( ND2 ( safLot ) , ND ( safStart ) , glb_EAS , ND ( safSLV ) , ND ( safTPV ) , ORDER_TIME_GTC , 0 , safComment ) ; }}

   void goCreate_Grid ( string safRules="1" , int safGridSizeInPoints=0 , int safNoOfGrids=10 , double safLotSize=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( ( safGridSizeInPoints > 0 ) && ( safNoOfGrids > 0 ) && ( safLotSize > 0 ) ) {
         // RULE 1: use postions and orders
         // RULE 2: use orders only
         // RULE 3: Close all positions if count reaches 4
         string safString2Search = "" ;
         double safGridSize = safGridSizeInPoints * sPoint() ;
         double safAsk = sAsk() ;
         double safBid = sBid() ;
         double safUpper = safAsk + ( ( safNoOfGrids / 2 ) * safGridSize ) ;
         double safLower = safAsk - ( ( safNoOfGrids / 2) * safGridSize ) ;
         // -------------------- RULE 3
         if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
            if ( goCount_PositionsTotal() >= 4 ) {
               goClose_AllOrders () ;
               goClose_AllPositions () ; }}
         // -------------------- RULE 1
         if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
            safString2Search = prvOrder_Analytics ( "H" ) + prvPosition_Analytics ( "N" ) ; }
         // -------------------- RULE 2
         if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
            safString2Search = prvOrder_Analytics ( "H" ) ; }
            for ( double i = 0 ; i <= safUpper ; i += safGridSize ) {
               if ( ( i >= safLower ) && ( i <= safUpper ) ) {
                  if ( i < safAsk ) {
                     if ( StringFind ( safString2Search , ( string ( i ) + "S|" ) , 0 ) == -1 ) {
                        sSellSingle ( 0 , safGridSize , 0 , safLotSize , "SS" , i , string ( i ) + "S|" ) ; }
                     if ( StringFind ( safString2Search , ( string ( i ) + "B|" ) , 0 ) == -1 ) {
                        sBuySingle ( 0 , safGridSize , 0 , safLotSize , "BL" , i , string ( i ) + "B|" ) ; }
                  } else {
                     if ( StringFind ( safString2Search , ( string ( i ) + "B|" ) , 0 ) == -1 ) {
                        sBuySingle ( 0 , safGridSize , 0 , safLotSize , "BS" , i , string ( i ) + "B|" ) ; }
                     if ( StringFind ( safString2Search , ( string ( i ) + "S|" ) , 0 ) == -1 ) {
                        sSellSingle ( 0 , safGridSize , 0 , safLotSize , "SL" , i , string ( i ) + "S|" ) ; } }}}
         if ( goCount_OrdersTotal () > ( safNoOfGrids * 3 ) ) { goTrim_Orders ( safUpper , safLower ) ; } }}

   //===========================================================================================================
   //=====                                         TEST FUNCTIONS                                          =====
   //===========================================================================================================

   void goKillAccount_Check ( int sMaxDD , int sMaxDays , double sStartBalance , int sMinutesSinceLastTrade ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( !MQLInfoInteger ( MQL_TESTER ) ) { return ; }
      // -------------------- x
      static double safHighestValue ;
      // -------------------- Main Logic
      if ( sMaxDD > 0 ) {
         // -------------------- Variables
         double safEquity = sEqu() ;
         double safBalance = sBal() ;
         // -------------------- Calc
         if ( MathMax ( safBalance , safEquity ) > safHighestValue ) {
            safHighestValue = MathMax ( safBalance , safEquity ) ; }
         // -------------------- x
         if ( safEquity < ( safHighestValue / 100 * ( 100 - sMaxDD ) ) ) {
            goKillAccount_Execute ( sStartBalance ) ;
            goPrint ( "Kill test due to Equ < Highest Value" ) ;
            ExpertRemove() ; }
         // -------------------- x
         if ( safEquity < ( safBalance / 100 * ( 100 - sMaxDD ) ) ) {
            goKillAccount_Execute ( sStartBalance ) ;
            goPrint ( "Kill test due to Equ < Bal" ) ;
            ExpertRemove() ; }
         // -------------------- x
         if ( safEquity < ( sStartBalance / 100 * ( 100 - sMaxDD ) ) ) {
            goClose_AllPositionsByForce () ;
            goPrint ( "Kill test due to Equ < Start Balance" ) ;
            ExpertRemove() ; }}
      // -------------------- x
      if ( sMaxDays > 0 ) {
         if ( sMinutesSinceLastTrade > ( sMaxDays * 24 * 60 ) ) {
            goKillAccount_Execute ( sStartBalance ) ;
            goPrint ( "Kill test due to idle days" ) ;
            ExpertRemove() ; }}}

   void goKillAccount_Execute ( double StartBalance , bool SecurityIsOn=true , int safPercent=90 , int safMaxRuns=10000 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // if ( SecurityIsOn == true ) { // <<<<<< UNCOMMENTING WILL CAUSE TESTER HANG
      //    if ( goSecurity_CheckAccountType ( ACCOUNT_TRADE_MODE_REAL ) == true ) {
      //       goPrint ( "Quit account kill because of real account" ) ;
      //       return ; }}
      if ( MQLInfoInteger ( MQL_TESTER ) == false ) {
         goPrint ( "Quit account kill because not in test mode" ) ;
         return ; }
      double safLotSLV = goCalc_PercentSLV ( "" , "1245" , 1 ) ;
      glb_LotSize = 1 ;
      for ( int i = 1 ; i<= safMaxRuns ; i++ ) {
         sBuySingle ( 0 , 0 , safLotSLV ) ;
         sSellSingle ( 0 , 0 , safLotSLV ) ;
         goClose_AllPositionsByForce () ;
         double safCurrentBalance = sBal() ;
         goPrint ( "Kill run number " + string(i) + ", Balance: " + string ( safCurrentBalance ) ) ;
         if ( safCurrentBalance < ( StartBalance * ( double ( safPercent ) / 100 ) ) ) { break ; }}}

   //===========================================================================================================
   //=====                                             TRAILS                                              =====
   //===========================================================================================================

   void goTrail_Immediately_SLV ( double safSLV ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      prvPosition_Trail ( safSLV , 0.8 , 0 , "12" ) ; }

   void goTrail_AfterBE_SLV ( double safSLV , double safMinProfit=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      prvPosition_Trail ( safSLV , 0.8 , safMinProfit , "123" ) ; }

   void goTrail_AfterBE_SLV_Multi ( double safATRMultiple=1 , double safMinProfit=0 , int safATRPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      prvPosition_Trail ( safATRMultiple , 0.8 , safMinProfit , "3" , safATRPeriod ) ; }

   void goTrail_OnlyBE ( double safSLV ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      prvPosition_Trail ( safSLV , 0.8 , 0 , "1234" ) ; }

   void goTrail_Stepped_TradeAmount ( double safAmount25 , double safAmount50 , double safAmount75 , string safFilter="12" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // ---------- RULE 1: Check Symbol
      // ---------- RULE 2: Check Magic Number
      // -------------------- Return checks
      if ( PositionsTotal () < 1 ) { return ; }
      // -------------------- Go thru all open one by one
      for ( int i = PositionsTotal () - 1 ; i >= 0 ; i-- ) {
         // -------------------- Check that ticket is selected
         ulong safTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( safTicket ) ) { continue ; }
         // -------------------- Check min profit
         double posProfit = sProfit() ;
         if ( posProfit < safAmount25 ) { continue ; }
         // -------------------- Check Symbol
         if ( StringFind ( safFilter , "1" , 0 ) >= 0 ) { if ( PositionGetString ( POSITION_SYMBOL ) != glb_EAS ) { continue ; }}
         // -------------------- Check Magic number
         if ( StringFind ( safFilter , "2" , 0 ) >= 0 ) { if ( UT ( GGS ( PositionGetString ( POSITION_COMMENT ) , 0 ) ) != UT ( glb_Magic ) ) { continue ; }}
         // -------------------- Variables
         double posOpenPrice = PositionGetDouble ( POSITION_PRICE_OPEN ) ;
         double posCurrentPrice = PositionGetDouble ( POSITION_PRICE_CURRENT ) ;
         double posSL = PositionGetDouble ( POSITION_SL ) ;
         double posTP = ND ( PositionGetDouble ( POSITION_TP ) ) ;
         // -------------------- Calculations
         double safRange = MathAbs ( posCurrentPrice - posOpenPrice ) ;
         if ( posProfit >= safAmount75 ) { safRange = ( safRange * 0.75 ) ; }
         else if ( posProfit >= safAmount50 ) { safRange = ( safRange * 0.50 ) ; }
         else { safRange = ( safRange * 0.25 ) ; }
         // -------------------- Trail logic
         if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_BUY ) {
            double newSL = ND ( posOpenPrice + safRange ) ;
            if ( newSL > posSL ) {
               goBroadcast_SIG ( goTele_PrepMsg ( "TRSA" , (string)safAmount25 , (string)safAmount50 , (string)safAmount75 , safFilter ) ) ;
               trade.PositionModify ( safTicket , newSL , posTP ) ; }
         } else {
            if ( posSL == 0 ) { posSL = 999999 ; }
            double newSL = ND ( posOpenPrice - safRange ) ;
            if ( newSL < posSL ) {
               goBroadcast_SIG ( goTele_PrepMsg ( "TRSA" , (string)safAmount25 , (string)safAmount50 , (string)safAmount75 , safFilter ) ) ;
               trade.PositionModify ( safTicket , newSL , posTP ) ; }}}}

   void goVtrail_Percent_AmountAll ( double safStartAmount=0 , double safPercent=0 , double safTrailMaxAmount=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      static double safSoftSL ;
      if ( goCount_PositionsTotal() > 0 ) {
         double safEqu = sEqu() ;
         if ( safSoftSL > 0 ) { if ( safEqu <= safSoftSL ) { goClose_AllPositions() ; safSoftSL = 0 ; return ; }}
         double safBal = sBal() ;
         double safDiff = safEqu - safBal ;
         double safTempSL = 0 ;
         if ( safDiff >= safStartAmount ) { safTempSL = safBal + ( safDiff * ( safPercent / 100 ) ) ; }
         if ( safTrailMaxAmount > 0 ) { if ( safTempSL > 0 ) {
            if ( ( safEqu - safTempSL ) > safTrailMaxAmount ) { safTempSL = safEqu - safTrailMaxAmount ; }}}
         if ( safTempSL > safSoftSL ) { safSoftSL = safTempSL ; }
      } else { safSoftSL = 0 ; }}

   void goVtrail_Stepped_AmountAll ( double safStep25=0 , double safStep50=0 , double safStep75=0 , double safTrailMaxAmount=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      static double safSoftSL ;
      if ( goCount_PositionsTotal() > 0 ) {
         double safEqu = sEqu() ;
         if ( safSoftSL > 0 ) { if ( safEqu <= safSoftSL ) { goClose_AllPositions() ; safSoftSL = 0 ; return ; }}
         double safBal = sBal() ;
         double safDiff = safEqu - safBal ;
         double safTempSL = 0 ;
         if ( ( safDiff >= safStep75 ) && ( safStep75 > 0 ) ) { safTempSL = safBal + ( safDiff * 0.75 ) ; }
         else if ( ( safDiff >= safStep50 ) && ( safStep50 > 0 ) ) { safTempSL = safBal + ( safDiff * 0.5 ) ; }
         else if ( ( safDiff >= safStep25 ) && ( safStep25 > 0 ) ) { safTempSL = safBal + ( safDiff * 0.25 ) ; }
         if ( safTrailMaxAmount > 0 ) { if ( safTempSL > 0 ) {
               if ( ( safEqu - safTempSL ) > safTrailMaxAmount ) { safTempSL = safEqu - safTrailMaxAmount ; }}}
         if ( safTempSL > safSoftSL ) { safSoftSL = safTempSL ; }
      } else { safSoftSL = 0 ; }}

   void Trail_After_XATR ( int sATRPeriod=14 , double sATRTrigger=2 , double sATRTrail=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- Get all open positions
      string AllPositions[] ;
      goPositions_Retreive ( AllPositions ) ;
      if ( ArraySize ( AllPositions ) < 1 ) { return ; }
      // -------------------- x
      string sCurr_Symbol = glb_EAS ;
         // -------------------- x
         for ( int i = 0 ; i < ArraySize ( AllPositions ) ; i++ ) {
            // -------------------- Split line into bits
            string posArray[] ;
            StringSplit ( AllPositions [ i ] , StringGetCharacter ( "|" , 0 ) , posArray ) ;
            if ( ArraySize ( posArray ) < 10 ) { continue ; }
            long posTicket = long ( posArray [ 1 ] ) ;
            string posCurr = posArray [ 2 ] ;
            string posType = posArray [ 3 ] ;
            double posOpenPrice = double ( posArray [ 5 ] ) ;
            double posSL = double ( posArray [ 8 ] ) ;
            double posTP = double ( posArray [ 9 ] ) ;
            // -------------------- x
            glb_EAS = posCurr ;
            // -------------------- x
            if ( ind_ATR ( sATRPeriod ) == false ) { continue ; }
            double ATR2Use = B0 [ glb_FC ] ;
            // -------------------- x
            if ( posType == "BUY" ) {
               double safBid = sBid() ;
               if ( safBid >= ( posOpenPrice + ( ATR2Use * sATRTrigger ) ) ) {
                  double newSL = safBid - ( ATR2Use * sATRTrail ) ;
                  if ( newSL > posSL ) {
                     goBroadcast_SIG ( goTele_PrepMsg ( "TR2SLV" , (string) sATRPeriod , (string) sATRTrigger , (string) sATRTrail ) ) ;
                     trade.PositionModify ( posTicket , ND ( newSL ) , ND ( posTP ) ) ; }}
            // -------------------- x
            } else if ( posType == "SELL" ) {
               double safAsk = sAsk() ;
               if ( safAsk <= ( posOpenPrice - ( ATR2Use * sATRTrigger ) ) ) {
                  if ( posSL == 0 ) { posSL = 999999 ; }
                  double newSL = safAsk + ( ATR2Use * sATRTrail ) ;
                  if ( newSL < posSL ) {
                     goBroadcast_SIG ( goTele_PrepMsg ( "TR2SLV" , (string) sATRPeriod , (string) sATRTrigger , (string) sATRTrail ) ) ;
                     trade.PositionModify ( posTicket , ND ( newSL ) , ND ( posTP ) ) ; }}
         }} glb_EAS = sCurr_Symbol ; }

   //===========================================================================================================
   //=====                                          SESSIONS                                               =====
   //===========================================================================================================

   string IsSession_Sydney ( int safStartLater=0 , int safEndEarlier=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return goSession_Check ( 22 , 7 , safStartLater , safEndEarlier ) ; }

   string IsSession_Tokyo ( int safStartLater=0 , int safEndEarlier=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return goSession_Check ( 0 , 9 , safStartLater , safEndEarlier ) ; }

   string IsSession_London ( int safStartLater=0 , int safEndEarlier=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return goSession_Check ( 8 , 17 , safStartLater , safEndEarlier ) ; }

   string IsSession_NewYork ( int safStartLater=0 , int safEndEarlier=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return goSession_Check ( 13 , 22 , safStartLater , safEndEarlier ) ; }

   string IsSession_Auto ( string safRules = "1" , int safStartLater=0 , int safEndEarlier=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // RULE 1: Return if either of the sessions is a Y
      // RULE 2: Return if both of the sessions is a Y
      // RULE 3: Return if none of the sessions is a Y
      string result = "" , safString = "" ;
      safString = glb_EAS ; if ( StringFind ( safString , "USD" , 0 ) >= 0 ) { result += IsSession_NewYork ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "CAD" , 0 ) >= 0 ) { result += IsSession_NewYork ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "US30" , 0 ) >= 0 ) { result += IsSession_NewYork ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "SPX500" , 0 ) >= 0 ) { result += IsSession_NewYork ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "NDX100" , 0 ) >= 0 ) { result += IsSession_NewYork ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "US2000" , 0 ) >= 0 ) { result += IsSession_NewYork ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "GBP" , 0 ) >= 0 ) { result += IsSession_London ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "EUR" , 0 ) >= 0 ) { result += IsSession_London ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "CHF" , 0 ) >= 0 ) { result += IsSession_London ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "FRA40" , 0 ) >= 0 ) { result += IsSession_London ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "GER30" , 0 ) >= 0 ) { result += IsSession_London ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "UK100" , 0 ) >= 0 ) { result += IsSession_London ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "EUSTX50" , 0 ) >= 0 ) { result += IsSession_London ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "JPY" , 0 ) >= 0 ) { result += IsSession_Tokyo ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "JPN225" , 0 ) >= 0 ) { result += IsSession_Tokyo ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "HK50" , 0 ) >= 0 ) { result += IsSession_Tokyo ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "AUD" , 0 ) >= 0 ) { result += IsSession_Sydney ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "NZD" , 0 ) >= 0 ) { result += IsSession_Sydney ( safStartLater , safEndEarlier ) ; }
      safString = glb_EAS ; if ( StringFind ( safString , "ASX200" , 0 ) >= 0 ) { result += IsSession_Sydney ( safStartLater , safEndEarlier ) ; }
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         if ( StringFind ( result , "Y" , 0 ) >= 0 ) { return "Y" ; } else { return "X" ; }}
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
         if ( ( result == "Y" ) || ( result == "YY" ) ) { return "Y" ; } else { return "X" ; }}
      // -------------------- RULE 3
      if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
         if ( StringFind ( result , "Y" , 0 ) < 0 ) { return "Y" ; } else { return "X" ; }}
      return result ; }

   string goSession_Check ( int safSessionStart , int safSessionEnd , int safStartLater , int safEndEarlier ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      MqlDateTime safDateTime ;
      string result = "X" ;
      TimeToStruct ( TimeGMT() , safDateTime ) ;
      int safCurrentHour = safDateTime.hour ;
      safSessionStart = go24HourAdjust ( ( safSessionStart + safStartLater) ) ;
      safSessionEnd = go24HourAdjust ( ( safSessionEnd - safEndEarlier) ) ;
      if ( safSessionStart < safSessionEnd ) {
         if ( ( safCurrentHour >= safSessionStart ) && ( safCurrentHour < safSessionEnd ) ) { result = "Y" ; }
      } else if ( safSessionStart > safSessionEnd ) {
         if ( ( safCurrentHour >= safSessionStart ) || ( safCurrentHour < safSessionEnd ) ) { result = "Y" ; } }
      return result ; }

   //===========================================================================================================
   //=====                                   DATE AND TIME FUNCTIONS                                       =====
   //===========================================================================================================

   bool IsNewHour () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static string safLastHour ;
      string safTime2Check = StringSubstr ( goGetDateTime() , 0 , 8 ) ;
      if ( safTime2Check == safLastHour ) { return false ; }
      safLastHour = safTime2Check ;
      return true ; }

   bool IsNewDay () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static string safLastDay ;
      string safDay2Check = StringSubstr ( goGetDateTime() , 0 , 6 ) ;
      if ( safDay2Check == safLastDay ) { return false ; }
      safLastDay = safDay2Check ;
      return true ; }

   bool IsNewMonth () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static string safLastMonth ;
      string safDate2Check = StringSubstr ( goGetDateTime() , 0 , 4 ) ;
      if ( safDate2Check == safLastMonth ) { return false ; }
      safLastMonth = safDate2Check ;
      return true ; }

   string goPrepDate ( string safInput ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      safInput = "00" + safInput ;
      int safLen = StringLen ( safInput ) ;
      return StringSubstr ( safInput , safLen - 2 , -1 ) ; }

   string goGetDateTime_OLD ( int safShiftBack=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      MqlDateTime safDateTime ;
      string result ;
      TimeToStruct ( ( TimeGMT () - safShiftBack ) , safDateTime ) ;
      // string DayOfWeekName_Array [] = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" } ;
      result += goPrepDate ( string ( safDateTime.year ) ) ;
      result += goPrepDate ( string ( safDateTime.mon ) ) ;
      result += goPrepDate ( string ( safDateTime.day ) ) ;
      result += goPrepDate ( string ( safDateTime.hour ) ) ;
      result += goPrepDate ( string ( safDateTime.min ) ) ;
      result += goPrepDate ( string ( safDateTime.sec ) ) ;
      // result += DayOfWeekName_Array [ safDateTime.day_of_week ] ;
      return result ; }

   string goGetDateTime ( int safShiftBack=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return goTranslate_DateTime ( ( TimeGMT () - safShiftBack ) ) ; }

   string goTranslate_DateTime ( datetime safInput ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      MqlDateTime safDateTime ;
      string result ;
      TimeToStruct ( safInput , safDateTime ) ;
      // string DayOfWeekName_Array [] = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" } ;
      result += goPrepDate ( string ( safDateTime.year ) ) ;
      result += goPrepDate ( string ( safDateTime.mon ) ) ;
      result += goPrepDate ( string ( safDateTime.day ) ) ;
      result += goPrepDate ( string ( safDateTime.hour ) ) ;
      result += goPrepDate ( string ( safDateTime.min ) ) ;
      result += goPrepDate ( string ( safDateTime.sec ) ) ;
      // result += DayOfWeekName_Array [ safDateTime.day_of_week ] ;
      return result ; }

   string goFindDayName () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      MqlDateTime safDateTime ;
      TimeToStruct ( TimeGMT () , safDateTime ) ;
      string DayOfWeekName_Array [] = { "SUN" , "MON" , "TUE" , "WED" , "THU" , "FRI" , "SAT" } ;
      return DayOfWeekName_Array [ safDateTime.day_of_week ] ; }

   int goFindHour () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      MqlDateTime safDateTime ;
      TimeToStruct ( TimeGMT () , safDateTime ) ;
      return safDateTime.hour ; }

   int go24HourAdjust ( int safInput ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( safInput > 23 ) { safInput = safInput - 24 ; }
      if ( safInput < 0 ) { safInput = safInput + 24 ; }
      return safInput ; }

   string IsDayOk2Trade ( string safOkDays , string safCutter="|" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( StringFind ( safCutter + safOkDays + safCutter , safCutter + goFindDayName() + safCutter , 0 ) >= 0 ) { return "Y" ; } else { return "X" ; } }

   string IsHourOk2Trade ( string safOkHours , string safCutter="|" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( StringFind ( safCutter + safOkHours + safCutter , safCutter + (string)goFindHour() + safCutter , 0 ) >= 0 ) { return "Y" ; } else { return "X" ; } }

   string goDelayMondayStart ( int safStartHour=8 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string safDayName = goFindDayName() ;
      if ( safDayName == "SAT" ) { return "X" ; }
      if ( safDayName == "SUN" ) { return "X" ; }
      if ( safDayName == "MON" ) { if ( goFindHour() < safStartHour ) { return "X" ; }}
      return "Y" ; }

   string goEndFridayEarly ( int safEndHour=20 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string safDayName = goFindDayName() ;
      if ( safDayName == "SAT" ) { return "X" ; }
      if ( safDayName == "SUN" ) { return "X" ; }
      if ( safDayName == "FRI" ) { if ( goFindHour() >= safEndHour ) { return "X" ; }}
      return "Y" ; }

   string goCalcStayPeriod ( int safStayPeriodInMinutes=15 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      MqlDateTime safDateTime ;
      string result = "Y" ;
      if ( safStayPeriodInMinutes > 0 ) {
         TimeToStruct ( ( TimeGMT () - glb_LastTradeTime ) , safDateTime ) ;
         int safCalcMinutes = ( ( safDateTime.day - 1 ) * 1440 ) + ( safDateTime.hour * 60 ) + safDateTime.min ;
         if ( safCalcMinutes <= ( safStayPeriodInMinutes ) ) { result = "X" ; }
      } return result ; }

   string goTranslate_TimeFrameName ( int safTimeFrame2Check ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      int safTFNumber [] = { 1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 16385, 16386, 16387, 16388, 16390, 16392, 16396, 16408, 32769, 49153 } ;
      string safTFName [] = { "M1", "M2", "M3", "M4", "M5", "M6", "M10", "M12", "M15", "M20", "M30", "H1", "H2", "H3", "H4", "H6", "H8", "H12", "D1", "W1", "MN1" } ;
      return safTFName [ ArrayBsearch ( safTFNumber , safTimeFrame2Check ) ] ; }

   double goCalc_MinutesBetweenDates ( datetime safStartDate , datetime safEndDate ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( MathAbs ( double ( ( safEndDate - safStartDate ) / 60 ) ) ) ; }

   double goCalc_HoursBetweenDates ( datetime safStartDate , datetime safEndDate ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( MathAbs ( double ( ( safEndDate - safStartDate ) / ( 60 * 60 ) ) ) ) ; }

   double goCalc_DaysBetweenDates ( datetime safStartDate , datetime safEndDate ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( MathAbs ( double ( ( safEndDate - safStartDate ) / ( 60 * 60 * 24 ) ) ) ) ; }

   bool IsDay_NoTradeDay ( string safNoTradeDays="|1223|1224|1225|1226|1227|1228|1229|1230|1231|0101|0102|0103|0104|0105|" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string safTodayDate = "|" + string ( StringSubstr ( goGetDateTime () , 2 , 4 ) ) + "|" ;
      if ( StringFind ( "|" + safNoTradeDays + "|" , safTodayDate , 0 ) >= 0 ) { return ( true ) ; } else { return ( false ) ; }}

   bool IsDay_Ok2TradeDay ( string safOkTradeDays ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string safTodayDate = "|" + string ( StringSubstr ( goGetDateTime () , 2 , 4 ) ) + "|" ;
      if ( StringFind ( "|" + safOkTradeDays + "|" , safTodayDate , 0 ) >= 0 ) { return ( true ) ; } else { return ( false ) ; }}

   string goFindLastDayNameString ( string sDayName ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      MqlDateTime safDateTime ;
      TimeToStruct ( TimeGMT () , safDateTime ) ;
      int safToday = safDateTime.day_of_week ;
      int safDay2Find = 999 ;
      string DayOfWeekName_Array [] = { "SUN" , "MON" , "TUE" , "WED" , "THU" , "FRI" , "SAT" } ;
      for ( int i = 0 ; i < ArraySize ( DayOfWeekName_Array ) ; i ++ ) {
         if ( DayOfWeekName_Array [ i ] == UT ( sDayName ) ) { safDay2Find = i ; break ; }}
      if ( safDay2Find == 999 ) { return "error" ; }
      int safDiff = safToday - safDay2Find + 7 ;
      if ( safDiff > 7 ) { safDiff -= 7 ; }
      return ( StringSubstr ( goGetDateTime ( ( safDiff * 60 * 60 * 24 ) ) , 0 , 6 ) ) ; }

   //===========================================================================================================
   //=====                                           CANDLES                                               =====
   //===========================================================================================================

   bool IsNewCandle () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      static datetime safLastCandle ;
      if ( safLastCandle == glb_PI [ glb_FC ].time ) { return false ; }
      safLastCandle = glb_PI [ glb_FC ].time ;
      return true ; }

   string IsCandle_Up () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_PI[ glb_FC ].open < glb_PI[ glb_FC ].close ) { return "Y" ; } else { return "X" ; } }

   string IsCandle_Down () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_PI[ glb_FC ].open > glb_PI[ glb_FC ].close ) { return "Y" ; } else { return "X" ; } }

   string IsCandle_Hammer_OLD ( string safRules="123" , double safMinSize=0 , int safCandle=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Candle is bigger than size trigger
      // RULE 2: Candle body to wick ratio is correct
      // RULE 3: Candle body is full
      // RULE 4: Open and close relation
      double safHigh = glb_PI[ safCandle ].high ;
      double safOpen = glb_PI[ safCandle ].open ;
      double safClose = glb_PI[ safCandle ].close ;
      double safLow = glb_PI[ safCandle ].low ;
      double safMax = MathMax ( safOpen , safClose ) ;
      double safMin = MathMin ( safOpen , safClose ) ;
      double safBody = safMax - safMin ;
      double safHammer = 0 ;
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         if ( ( safHigh - safLow ) >= safMinSize ) { result += "Y" ; } else { return "X" ; } }
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
         double safDistance = ( safHigh - safLow ) * 0.382 ;
         if ( ( safHigh - safMin ) <= safDistance ) { result += "B" ; safHammer = safHigh - safMin ; }
         else if ( ( safMax - safLow ) <= safDistance ) { result += "S" ; safHammer = safMax - safLow ; }
         else { return "X" ; }
         // -------------------- RULE 3
         if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
            if ( safBody > ( safHammer * 0.85 ) ) { result += "Y" ; } else { return "X" ; } } }
      // -------------------- RULE 4
      if ( StringFind ( safRules , "4" , 0 ) >= 0 ) {
         if ( safOpen > safClose ) { result += "S" ; }
         else if ( safClose > safOpen ) { result += "B" ; }
         else { return "X" ; } }
      return result ; }

   string IsCandle_Engulfing ( string safRules="12345" , double safMinSize=0 , int safCandle=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Candle is bigger than size trigger
      // RULE 2: Check current candle direction
      // RULE 3: Check last candle direction
      // RULE 4: Current close higher is higher and lower is lower
      // RULE 5: Current open higher is higher and lower is lower
      // RULE 6: Current high and low and higher and lower than last high and low
      double safCurrO = glb_PI[ safCandle ].open ;
      double safCurrC = glb_PI[ safCandle ].close ;
      double safCurrH = glb_PI[ safCandle ].high ;
      double safCurrL = glb_PI[ safCandle ].low ;
      double safLastO = glb_PI[ safCandle + 1 ].open ;
      double safLastC = glb_PI[ safCandle + 1 ].close ;
      double safLastH = glb_PI[ safCandle + 1 ].high ;
      double safLastL = glb_PI[ safCandle + 1 ].low ;
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         if ( MathAbs ( safCurrC - safCurrO ) >= safMinSize ) { result += "Y" ; } else { return "X" ; } }
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
         if ( safCurrO < safCurrC ) { result += "B" ; }
         else if ( safCurrO > safCurrC ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 3
      if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
         if ( safLastO > safLastC ) { result += "B" ; }
         else if ( safLastO < safLastC ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 4
      if ( StringFind ( safRules , "4" , 0 ) >= 0 ) {
         if ( safCurrC >= safLastO ) { result += "B" ; }
         else if ( safCurrC <= safLastO ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 5
      if ( StringFind ( safRules , "5" , 0 ) >= 0 ) {
         if ( safCurrO <= safLastC ) { result += "B" ; }
         else if ( safCurrO >= safLastC ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 6
      if ( StringFind ( safRules , "6" , 0 ) >= 0 ) {
         if ( ( safCurrH > safLastH ) && ( safCurrL < safLastL ) ) { result += "Y" ; } else { return "X" ; } }
      return result ; }

   string goCandle_Clasify () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      double CurrentHigh   = glb_PI[ glb_FC ].high ;
      double CurrentLow    = glb_PI[ glb_FC ].low ;
      double LastHigh      = glb_PI[ glb_FC + 1 ].high ;
      double LastLow       = glb_PI[ glb_FC + 1 ].low ;
      if ( ( CurrentHigh >= LastHigh ) && ( CurrentLow >= LastLow ) ) { return "Up Candle" ; }
      if ( ( CurrentHigh <= LastHigh ) && ( CurrentLow <= LastLow ) ) { return "Down Candle" ; }
      if ( ( CurrentHigh >= LastHigh ) && ( CurrentLow <= LastLow ) ) { return "Outside Candle" ; }
      if ( ( CurrentHigh <= LastHigh ) && ( CurrentLow >= LastLow ) ) { return "Inside Candle" ; }
      return "Unclassified Candle" ; }

   string IsCandle_Gapping ( string safRules="1" , double safDistance=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Current open is further than distance from las close
      // RULE 2: Gapping direction filter
      if ( safDistance > 0 ) {
         double safCurrentOpen = glb_PI[0].open ;
         double safLastClose = glb_PI[1].close ;
         double myGAP = MathAbs ( safCurrentOpen - safLastClose ) ;
         // -------------------- RULE 1
         if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
            if ( myGAP >= safDistance ) { result += "Y" ; } else { return "X" ; }}
         // -------------------- RULE 2
         if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
            if ( safCurrentOpen > safLastClose ) { result += "B" ; }
            else if ( safCurrentOpen < safLastClose ) { result += "S" ; }
            else { return "X" ; }}
      } return result ; }

   string IsCandle_45PercentShadow ( string safRules="23" , double safMinSize=0 , int safCandle=1 , double safPercent=45 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      string resultOther = "" ;
      // RULE 1: Candle is bigger than size trigger
      // RULE 2: Shadow is more than 45 percent of candle
      // RULE 3: Add direction bias to result
      double safPercent2Use = ( safPercent / 100 ) ;
      double safHigh = glb_PI[ safCandle ].high ;
      double safOpen = glb_PI[ safCandle ].open ;
      double safClose = glb_PI[ safCandle ].close ;
      double safLow = glb_PI[ safCandle ].low ;
      double safMax = MathMax ( safOpen , safClose ) ;
      double safMin = MathMin ( safOpen , safClose ) ;
      double safFullSize = safHigh - safLow ;
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         if ( ( safHigh - safLow ) >= safMinSize ) { result += "Y" ; } else { return "X" ; } }
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
         if ( ( ( safHigh - safMax ) >= safFullSize * safPercent2Use ) && ( safMin == safLow ) ) { result += "Y" ; resultOther = "S" ; }
         else if ( ( ( safMin - safLow ) >= safFullSize * safPercent2Use ) && ( safHigh == safMax ) ) { result += "Y" ; resultOther = "B" ; }
         else { return "X" ; }}
      // -------------------- RULE 3
      if ( StringFind ( safRules , "3" , 0 ) >= 0 ) { result = result + resultOther ; }
      return result ; }

   string IsCandle_EngulphingAfterXInRow ( int safStart , int safNumber ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // ------------------------------ Decide if you need more price data
      if ( ( safStart + safNumber + 1 ) > glb_BD ) {
         CopyRates ( glb_EAS , glb_EAP , 0 , ( safStart + safNumber + 1 ) , glb_PI ) ; }
      // ------------------------------ VARIABLES
      double C0_O = glb_PI[ safStart ].open ;
      double C0_C = glb_PI[ safStart ].close ;
      double safHigh = 0 ;
      double safLow = 9999999 ;
      // ------------------------------ X Candle checks here
      for ( int i = safStart + 1 ; i <= ( safStart + safNumber ) ; i ++ ) {
         // ------------------------------ check that candles trend
         if ( i != ( safStart + safNumber ) ) {
            if ( glb_PI[ i ].close > glb_PI[ i + 1 ].close ) { result += "S" ; }
            else if ( glb_PI[ i ].close < glb_PI[ i + 1 ].close ) { result += "B" ; }
            else { result = "X" ; }}
         // ------------------------------ check candles direction
         if ( glb_PI[ i ].open < glb_PI[ i ].close ) { result += "S" ; }
         else if ( glb_PI[ i ].open > glb_PI[ i ].close ) { result += "B" ; }
         else { result = "X" ; }
         // ------------------------------ find highest and lowest points
         if ( glb_PI[ i ].high > safHigh ) { safHigh = glb_PI[ i ].high ; }
         if ( glb_PI[ i ].low < safLow ) { safLow = glb_PI[ i ].low ; }}
      // ------------------------------ Check if last candle engulphs the rest
      if ( glb_PI[ safStart ].high > safHigh ) { result += "Y" ; } else { result = "X" ; }
      if ( glb_PI[ safStart ].low < safLow ) { result += "Y" ; } else { result = "X" ; }
      // ------------------------------ Check last candle direction
      if ( C0_O > C0_C ) { result += "S" ; }
      else if ( C0_O < C0_C ) { result += "B" ; }
      else { result = "X" ; }
      // ------------------------------ return result
      return ( result ) ; }

   string prvCandle_Analytics ( string safRules="AB" , int safCandle=1 , double safMultiple=1 , int safATRPeriod=1440 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE A / Is range more that ATR multiple
      // RULE B / Is candle open same as close
      // RULE C / Is candle bearish
      // RULE D / Is candle bullish
      // RULE E / Is current body max higher than last body max
      // RULE F / Is current body min lower than last body min
      // RULE G / Is current high higher than last high
      // RULE H / Is current low lower than last low
      // RULE I / Is upper wick equal to zero
      // RULE J / Is lower wick equal to zero
      // RULE K / Is upper wick not equal to zero
      // RULE L / Is lower wick not equal to zero
      // RULE M / Is candle body not equal to zero
      // RULE N / Is upper wick bigger than body multiple
      // RULE O / Is lower wick bigger than body multiple
      // RULE P / Are wicks lengths within multiple of each other
      // RULE Q / Are candle bodies matching tops
      // RULE R / Are candle bodies matching bottoms
      // -------------------- Current Candle
      double cHigh         = glb_PI [ safCandle ].high ;
      double cLow          = glb_PI [ safCandle ].low ;
      double cOpen         = glb_PI [ safCandle ].open ;
      double cClose        = glb_PI [ safCandle ].close ;
      double cRange        = cHigh - cLow ;
      double cBody         = MathAbs ( cOpen - cClose ) ;
      double cMax          = MathMax ( cOpen , cClose ) ;
      double cMin          = MathMin ( cOpen , cClose ) ;
      double cUpperWick    = cHigh - cMax ;
      double cLowerWick    = cMin - cLow ;
      // double cMiddle       = cLow + ( cRange / 2 ) ;
      // -------------------- Last Candle
      double lHigh         = glb_PI [ safCandle + 1 ].high ;
      double lLow          = glb_PI [ safCandle + 1 ].low ;
      double lOpen         = glb_PI [ safCandle + 1 ].open ;
      double lClose        = glb_PI [ safCandle + 1 ].close ;
      // double lRange        = lHigh - lLow ;
      // double lBody         = MathAbs ( lOpen - lClose ) ;
      double lMax          = MathMax ( lOpen , lClose ) ;
      double lMin          = MathMin ( lOpen , lClose ) ;
      // double lUpperWick    = lHigh - lMax ;
      // double lLowerWick    = lMin - lLow ;
      // double lMiddle       = lLow + ( lRange / 2 ) ;
      // -------------------- RULE A / Is Range more that ATR Multiple
      if ( StringFind ( safRules , "A" , 0 ) >= 0 ) {
         if ( ind_ATR ( safATRPeriod ) == false ) { return "X" ; }
         double cATR = B0 [ safCandle ] ;
         if ( cRange >= ( cATR * safMultiple ) ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE B / Is candle body equal to zero
      if ( StringFind ( safRules , "B" , 0 ) >= 0 ) {
         if ( cBody == 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE C / Is candle bearish
      if ( StringFind ( safRules , "C" , 0 ) >= 0 ) {
         if ( cOpen > cClose ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE D / Is candle bullish
      if ( StringFind ( safRules , "D" , 0 ) >= 0 ) {
         if ( cOpen < cClose ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE E / Is current body max higher than last body max
      if ( StringFind ( safRules , "E" , 0 ) >= 0 ) {
         if ( cMax > lMax ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE F / Is current body min lower than last body min
      if ( StringFind ( safRules , "F" , 0 ) >= 0 ) {
         if ( cMin < lMin ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE G / Is current high higher than last high
      if ( StringFind ( safRules , "G" , 0 ) >= 0 ) {
         if ( cHigh > lHigh ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE H / Is current low lower than last low
      if ( StringFind ( safRules , "H" , 0 ) >= 0 ) {
         if ( cLow < lLow ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE I / upper wick equals zero
      if ( StringFind ( safRules , "I" , 0 ) >= 0 ) {
         if ( cUpperWick == 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE J / lower wick equals zero
      if ( StringFind ( safRules , "J" , 0 ) >= 0 ) {
         if ( cLowerWick == 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE K / upper wick not equal to zero
      if ( StringFind ( safRules , "K" , 0 ) >= 0 ) {
         if ( cUpperWick > 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE L / lower wick not equal to zero
      if ( StringFind ( safRules , "L" , 0 ) >= 0 ) {
         if ( cLowerWick > 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE M / Is candle body not equal to zero
      if ( StringFind ( safRules , "M" , 0 ) >= 0 ) {
         if ( cBody > 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE N / upper wick bigger than range multiple
      if ( StringFind ( safRules , "N" , 0 ) >= 0 ) {
         if ( cUpperWick >= ( cRange * safMultiple ) ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE O / lower wick bigger than range multiple
      if ( StringFind ( safRules , "O" , 0 ) >= 0 ) {
         if ( cLowerWick >= ( cRange * safMultiple ) ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE P / Wicks are within multiple of each other
      if ( StringFind ( safRules , "P" , 0 ) >= 0 ) {
         if ( ( cUpperWick >= ( cLowerWick * safMultiple ) ) &&
            ( cLowerWick >= ( cUpperWick * safMultiple ) ) ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE Q / Are candle bodies matching tops
      if ( StringFind ( safRules , "Q" , 0 ) >= 0 ) {
         if ( cMax == lMax ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE R / Are candle bodies matching bottoms
      if ( StringFind ( safRules , "R" , 0 ) >= 0 ) {
         if ( cMin == lMin ) { result += "Y" ; } else { return "X" ; }}
      return result ; }

      string IsCandle_Dogi ( string CandleRules="BKLP" , double WickRatio=0.8 ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // RULE B / Is Open and Close the same
         // RULE K / upper wick not equal to zero
         // RULE L / lower wick not equal to zero
         // RULE P / Wicks are within 80% of each other
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC , WickRatio ) ;
         return ( result ) ; }

      string IsCandle_Dragonfly_Dogi ( string CandleRules="BIL" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // RULE B / Is Open and Close the same
         // RULE I / upper wick equals zero
         // RULE L / lower wick not equal to zero
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC ) ;
         return ( result ) ; }

      string IsCandle_Gravestone_Dogi ( string CandleRules="BJK" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // RULE B / Is Open and Close the same
         // RULE J / lower wick equals zero
         // RULE K / upper wick not equal to zero
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC ) ;
         return ( result ) ; }

      string IsCandle_Bullish_Engulfing ( string FirstCandleRules="DEF" , string SecondCandleRules="C" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         string result = "" ;
         // RULE D / Is candle bullish ( Current )
         // RULE E / Is current body max higher than last body max
         // RULE F / Is current body min lower than last body min
         result += prvCandle_Analytics ( FirstCandleRules , glb_FC ) ;
         // RULE C / Is candle bearish ( Last )
         result += prvCandle_Analytics ( SecondCandleRules , ( glb_FC + 1 ) ) ;
         if ( StringFind ( result , "X" , 0 ) >= 0 ) { return "X" ; }
         return ( result ) ; }

      string IsCandle_Bearish_Engulfing ( string FirstCandleRules="CEF" , string SecondCandleRules="D" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         string result = "" ;
         // RULE C / Is candle bearish ( Current )
         // RULE E / Is current body max higher than last body max
         // RULE F / Is current body min lower than last body min
         result += prvCandle_Analytics ( FirstCandleRules , glb_FC ) ;
         // RULE D / Is candle bullish ( Last )
         result += prvCandle_Analytics ( SecondCandleRules , ( glb_FC + 1 ) ) ;
         if ( StringFind ( result , "X" , 0 ) >= 0 ) { return "X" ; }
         return ( result ) ; }

      string IsCandle_Hammer ( string CandleRules="DIO", double WickRatio=0.5 ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // RULE D / Is candle bullish
         // RULE I / upper wick equals zero
         // RULE O / lower wick bigger than 50%
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC , WickRatio ) ;
         return ( result ) ; }

      string IsCandle_Hangingman ( string CandleRules="CIO" , double WickRatio=0.5 ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // RULE C / Is candle bearish
         // RULE I / upper wick equals zero
         // RULE O / lower wick bigger than 50%
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC , WickRatio ) ;
         return ( result ) ; }

      string IsCandle_Marubozu ( string CandleRules="AMIJ" , double ATRFactor=1.25 ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // RULE A / Is Range more that 1.25 ATR Multiple
         // RULE M / Is candle body not equal to zero
         // RULE I / upper wick equals zero
         // RULE J / lower wick equals zero
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC , ATRFactor ) ;
         return ( result ) ; }

      string IsCandle_Tweezer_Tops ( string FirstCandleRules="ILMQ" , string SecondCandleRules="ILM" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         string result = "" ;
         // RULE I / upper wick equals zero
         // RULE L / lower wick not equal to zero
         // RULE M / Is candle body not equal to zero
         // RULE Q / Are candle bodies matching tops
         result += prvCandle_Analytics ( FirstCandleRules , glb_FC ) ;
         // RULE I / upper wick equals zero
         // RULE L / lower wick not equal to zero
         // RULE M / Is candle body not equal to zero
         result += prvCandle_Analytics ( SecondCandleRules , ( glb_FC + 1 ) ) ;
         if ( StringFind ( result , "X" , 0 ) >= 0 ) { return "X" ; }
         return ( result ) ; }

      string IsCandle_Tweezer_Bottoms ( string FirstCandleRules="JKMR" , string SecondCandleRules="JKM" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         string result = "" ;
         // RULE J / lower wick equals zero
         // RULE K / upper wick not equal to zero
         // RULE M / Is candle body not equal to zero
         // RULE R / Are candle bodies matching bottoms
         result += prvCandle_Analytics ( FirstCandleRules , glb_FC ) ;
         // RULE J / lower wick equals zero
         // RULE K / upper wick not equal to zero
         // RULE M / Is candle body not equal to zero
         result += prvCandle_Analytics ( SecondCandleRules , ( glb_FC + 1 ) ) ;
         if ( StringFind ( result , "X" , 0 ) >= 0 ) { return "X" ; }
         return ( result ) ; }

   //===========================================================================================================
   //=====                                         LOCAL FILE                                              =====
   //===========================================================================================================

   void prvLocalFile_ConstructName ( string safFileNameSuffix="" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string safServer     = goCleanString ( AccountInfoString ( ACCOUNT_SERVER ) ) ;
      string safAccountNo  = goCleanString ( string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ) ;
      string safCurrency   = goCleanString ( glb_EAS ) ;
      string safAddOn      = goCleanString ( safFileNameSuffix ) ;
      glb_FileName = safServer + "-" + safAccountNo + "-" + safCurrency ;
      if ( StringLen ( safAddOn ) > 0 ) { glb_FileName += "-" + safAddOn ; }
      glb_FileName += ".txt" ; }

   bool goLocalFile_Write ( string safText2Write , string safFileNameSuffix="" , string safOverrideFileName="" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return false ; }
      // -------------------- Set filename
      string safFileName2Use = glb_FileName ;
      if ( StringLen ( safOverrideFileName ) > 0 ) { safFileName2Use = safOverrideFileName ; }
      if ( StringLen ( safFileName2Use ) < 1 ) {
         prvLocalFile_ConstructName ( safFileNameSuffix ) ;
         safFileName2Use = glb_FileName ; }
      // -------------------- Set timestamp and string to write
      string safTimeStamp = StringSubstr ( goGetDateTime() , 0 , 12 ) ;
      string result = safTimeStamp + ": " + safText2Write ;
      // -------------------- Open file to write
      int f = FileOpen ( safFileName2Use , FILE_READ | FILE_WRITE | FILE_TXT ) ;
      if ( f == INVALID_HANDLE ) { return false ; }
      FileSeek ( f , 0 , SEEK_END ) ;
      if ( StringLen ( safText2Write ) > 0 ) { FileWrite ( f , result ) ; }
      FileClose ( f ) ;
      return true ; }

   bool goLocalFile_Read ( string &FileContent[] , string safOverrideFileName="" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return false ; }
      // -------------------- Filename check
      string safFileName2Use = glb_FileName ;
      if ( StringLen ( safOverrideFileName ) > 0 ) { safFileName2Use = safOverrideFileName ; }
      if ( StringLen ( safFileName2Use ) < 1 ) { return false ; }
      // -------------------- Open file to read
      ArrayResize ( FileContent , 0 ) ;
      int f = FileOpen ( safFileName2Use , FILE_READ | FILE_TXT ) ;
      if ( f == INVALID_HANDLE ) { return false ; }
      FileReadArray ( f , FileContent , 0 , WHOLE_ARRAY ) ;
      FileClose ( f ) ;
      return true ; }

   //===========================================================================================================
   //=====                                      GENERAL FUNCTIONS                                          =====
   //===========================================================================================================

   void goDebug ( string sFuncName="" ) {
      goPrint ( sFuncName ) ; }

   void goClearBuffers () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static bool safSetCorrectly ;
      ArrayResize ( B0 , 0 , 0 ) ;
      ArrayResize ( B1 , 0 , 0 ) ;
      ArrayResize ( B2 , 0 , 0 ) ;
      ArrayResize ( B3 , 0 , 0 ) ;
      ArrayResize ( B4 , 0 , 0 ) ;
      if ( safSetCorrectly != true ) {
         ArraySetAsSeries ( B0 , true ) ;
         ArraySetAsSeries ( B1 , true ) ;
         ArraySetAsSeries ( B2 , true ) ;
         ArraySetAsSeries ( B3 , true ) ;
         ArraySetAsSeries ( B4 , true ) ;
         safSetCorrectly = true ; }}

   void goOnInit ( string sBotType ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- Expiry date check
      if ( goSecurity_CheckExpiryDate ( datetime("2024.01.01") , 90 ) == false ) { ExpertRemove () ; return ; }
      // -------------------- Check version
      if ( !MQLInfoInteger ( MQL_TESTER ) ) {
         if ( goSecurity_VersionCheck ( sBotType ) == false ) { ExpertRemove () ; return ; }}
      // -------------------- Order price array correctly
      ArraySetAsSeries ( glb_PI , true ) ;
      // -------------------- Prep Symbol array
      string safSymbols =  "EURUSD|GBPUSD|EURGBP|USDJPY|CHFJPY|EURCHF|EURJPY|GBPCHF|GBPJPY|USDCHF|" ;
             safSymbols += "AUDCAD|AUDCHF|AUDJPY|AUDNZD|AUDUSD|CADCHF|CADJPY|EURAUD|EURCAD|EURNZD|" ;
             safSymbols += "GBPAUD|GBPCAD|GBPNZD|NZDJPY|NZDUSD|USDCAD|" ;
             safSymbols += "NZDCAD|NZDCHF" ;
      StringSplit ( safSymbols , StringGetCharacter ( "|" , 0 ) , glb_SymbolArray ) ;
      // -------------------- Prep base currency
      if ( UT ( AccountInfoString ( ACCOUNT_CURRENCY ) ) != "USD" ) {
         glb_BaseCurr = goSet_BaseAccountCurrency ( AccountInfoString ( ACCOUNT_CURRENCY ) ) ; }}

   string UT ( string safInput ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      StringTrimLeft ( safInput ) ;
      StringTrimRight ( safInput ) ;
      StringToUpper ( safInput ) ;
      return safInput ; }

   string goTrim ( string safInput ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      StringTrimLeft ( safInput ) ;
      StringTrimRight ( safInput ) ;
      return safInput ; }

   string GGS ( string safString , int safLoc=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result[] ;
      int i = StringSplit ( safString , StringGetCharacter ( "|" , 0 ) , result ) ;
      if ( i > safLoc ) { return result [ safLoc ] ; } else { return "" ; }}

   string goCleanSignal ( string safSignal ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      StringReplace ( safSignal , "Y" , "" ) ;
      StringReplace ( safSignal , "C" , "" ) ;
      StringReplace ( safSignal , "T" , "" ) ;
      string goBuy = safSignal ; StringReplace ( goBuy , "B" , "" ) ; if ( goBuy == "" ) { result += "B" ; }
      string goSel = safSignal ; StringReplace ( goSel , "S" , "" ) ; if ( goSel == "" ) { result += "S" ; }
      if ( ( goBuy == "" ) && ( goSel == "" ) ) { return "X" ; }
      return result ; }

   string goReverseSignal ( string safString ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      StringReplace ( safString , "B" , "A" ) ;
      StringReplace ( safString , "S" , "B" ) ;
      StringReplace ( safString , "A" , "S" ) ;
      return safString ; }

   bool GCS ( string safSignal ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- if there is an x then return false
      if ( StringFind ( safSignal , "X" , 0 ) >= 0 ) { return false ; }
      // -------------------- if there is a b and s at the same time then also return false
      if ( StringFind ( safSignal , "B" , 0 ) >= 0 ) {
         if ( StringFind ( safSignal , "S" , 0 ) >= 0 ) { return false ; }}
      // -------------------- finally if its only b or s only then return true
      return true ; }

   void goLog ( enumLogType safType, string safString ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static string LastString ;
      static string safFileName = string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + ".csv" ;
      if ( ( safType > No_Log ) && ( StringLen ( safString ) ) > 0 ) {
         if ( safString != LastString ) {
            LastString = safString ;
            string safTimeStamp = StringSubstr ( goGetDateTime () , 0 , 12 ) ;
            string result = " > > > > > " + safTimeStamp + ": " + safString ;
            if ( safType == Journal ) { goPrint ( result ) ; }
            if ( safType == Excel ) {
               int f = FileOpen ( safFileName , FILE_READ | FILE_WRITE | FILE_CSV ) ;
               FileSeek ( f , 0 , SEEK_END ) ;
               FileWrite ( f , safTimeStamp , safString ) ;
               FileClose ( f ) ; }}}}

   bool goRead_FileContent ( string safFilePath , string &AllLinesArray[] ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return false ; }
      int safCounter = 0 ;
      int F = FileOpen ( safFilePath , FILE_SHARE_READ | FILE_TXT | FILE_ANSI ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      FileSeek ( F , 0 , SEEK_SET ) ;
      while ( !FileIsEnding ( F ) ) {
         ArrayResize ( AllLinesArray , safCounter + 1 ) ;
         AllLinesArray [ safCounter ] = FileReadString ( F ) ;
         safCounter += 1 ; }
      FileClose ( F ) ;
      return true ; }

   string goRead_Website (
      string safOriginalURL ,
      string safPreviewURL = "" ,
      int safTimeOut = 6000 ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         if ( glb_SilentMode == true ) { return ( "" ) ; }
         char safResult [] , safPostData [] ;
         if ( safPreviewURL == "" ) { safPreviewURL = safOriginalURL ; }
         string safType = "Content-Type: application/x-www-form-urlencoded" ;
         string safAgent = "user-agent:Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36 OPR/65.0.3467.62" ;
         string safHeaders = safType + "\r\n" + safAgent ;
         int res = WebRequest ( "GET" , safPreviewURL , NULL , safOriginalURL , safTimeOut , safPostData , 0 , safResult , safHeaders ) ;
         string safHTML = "" ; for ( int i = 0 ; i <= ArraySize ( safResult ) - 1 ; i++ ) { safHTML += CharToString ( safResult [ i ] ) ; }
         // if ( safHTML == "" ) { goPrint ( "Please ensure this website " + safOriginalURL + " is allowed in your MT5 settings" ) ; }
         if ( safHTML == "" ) { goPrint ( "Unable to contact server" ) ; }
         return ( safHTML ) ; }

   double ND ( double safInput ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return NormalizeDouble ( MathRound ( safInput , sDigits() ) , sDigits() ) ; }

   double ND2 ( double safInput ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = string ( NormalizeDouble ( MathRound ( safInput , 2 ) , 2 ) ) ;
      int safLoc = StringFind ( result , "." ) ;
      if ( safLoc == -1 ) { return double ( result ) ; }
      int safLength = StringLen ( result ) ;
      if ( safLength > safLoc + 3 ) { result = StringSubstr ( result , 0 , ( safLoc + 3 ) ) ; }
      return double ( result ) ; }

   double sAsk () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ND ( SymbolInfoDouble ( glb_EAS, SYMBOL_ASK ) ) ; }

   double sBid () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ND ( SymbolInfoDouble ( glb_EAS , SYMBOL_BID ) ) ; }

   double sBal () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return AccountInfoDouble ( ACCOUNT_BALANCE ) ; }

   double sEqu () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return AccountInfoDouble ( ACCOUNT_EQUITY ) ; }

   double sMax () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ND2 ( SymbolInfoDouble ( glb_EAS , SYMBOL_VOLUME_MAX ) ) ; }

   double sMin () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ND2 ( SymbolInfoDouble ( glb_EAS ,SYMBOL_VOLUME_MIN ) ) ; }

   double sProfit () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return PositionGetDouble ( POSITION_PROFIT ) + PositionGetDouble ( POSITION_SWAP ) ; }

   double sFreeMargin () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return AccountInfoDouble ( ACCOUNT_MARGIN_FREE ) ; }

   void goPrint ( string safString ) {
      // goLocalFile_Write ( safString ) ;
      Print ( ">   >   >   >   > " + safString ) ; }

   int sPow ( double safInput ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // return int ( ( safInput * MathPow ( 10 , sDigits() ) ) ) ; }
      double result = 0 ;
      int safDigits = sDigits() ;
      if ( safDigits == 1 ) { result = safInput * 10 ; }
      else if ( safDigits == 2 ) { result = safInput * 100 ; }
      else if ( safDigits == 3 ) { result = safInput * 1000 ; }
      else if ( safDigits == 4 ) { result = safInput * 10000 ; }
      else if ( safDigits == 5 ) { result = safInput * 100000 ; }
      else if ( safDigits == 6 ) { result = safInput * 1000000 ; }
      else if ( safDigits == 7 ) { result = safInput * 10000000 ; }
      return ( (int)result ) ; }

   double sNetProfit () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( double ( prvPosition_Analytics ( "M" ) ) ) ; }

   double sSpread () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( SymbolInfoInteger ( glb_EAS , SYMBOL_SPREAD ) * sPoint() ) ; }

   int sDigits () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return int ( SymbolInfoInteger ( glb_EAS , SYMBOL_DIGITS ) ) ; }

   double sPoint () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return SymbolInfoDouble ( glb_EAS , SYMBOL_POINT ) ; }

   int sRandomNumber ( int safMinValue, int safMaxValue ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      double safRand = double ( MathRand() ) / 32767 ;
      return int ( MathMin ( safMaxValue , safMinValue + ( ( safMaxValue + 1 - safMinValue ) * safRand ) ) ) ; }

   string goHTML_Cutter ( string safInput, string safStartCut="" , string safEndCut="" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( UT ( safInput ) == "" ) { return "" ; }
      int saf01 , saf02 , saf03 ;
      if ( StringLen ( safStartCut ) > 0 ) { saf01 = StringFind ( safInput , safStartCut , 0 ) ; saf02 = StringLen ( safStartCut ) ; }
         else { saf01 = 0 ; saf02 = 0 ; }
      if ( StringLen ( safEndCut ) > 0 ) { saf03 = StringFind ( safInput , safEndCut , saf01 ) ; } else { saf03 = StringLen ( safInput ) ; }
      if ( saf03 <= saf01 ) { return "" ; }
      return StringSubstr ( safInput , ( saf01 + saf02 ) , ( saf03 - ( saf01 + saf02 ) ) ) ; }

   void goOnTrade () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static double safLastBalance = 0 ;
      static int safLossesInRow , safProfitsInRow ;
      double safBalance = sBal() ;
      if ( safBalance > safLastBalance ) { safProfitsInRow += 1 ; safLossesInRow = 0 ; }
      else if ( safBalance < safLastBalance ) { safLossesInRow += 1 ; safProfitsInRow = 0 ; }
      else return ;
      safLastBalance = safBalance ;
      goPrint ( "Profits in a row: " + (string)safProfitsInRow + " / Loss in a row: " + (string)safLossesInRow ) ; }

   string goTranslate_RiskLevel ( int safRiskLevel=Medium ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // Auto=7 , Highest=6 , Higher=5 , High=4 , Medium=3 , Low=2 , Lower=1 , Lowest=0
      if ( safRiskLevel == Auto ) {
         double safFreeMargin = AccountInfoDouble ( ACCOUNT_MARGIN_FREE ) ;
         if ( safFreeMargin > 5000 ) { return "1245" ; }
         if ( safFreeMargin > 3000 ) { return "1245B" ; }
         else { return "1245C" ; }}
      else if ( safRiskLevel == Highest ) { return "1245" ; }
      else if ( safRiskLevel == Higher ) { return "1245B" ; }
      else if ( safRiskLevel == High ) { return "1245C" ; }
      else if ( safRiskLevel == Medium ) { return "1245D" ; }
      else if ( safRiskLevel == Low ) { return "1245E" ; }
      else if ( safRiskLevel == Lower ) { return "1245A" ; }
      else { return "12456" ; }}

   string goSet_BaseAccountCurrency ( string safCurrency ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      for ( int i = ArraySize ( glb_SymbolArray ) - 1 ; i >= 0 ; i-- ) {
         string safSymbol = UT ( glb_SymbolArray [i] ) ;
         if ( safSymbol == "" ) { continue ; }
         if ( ( UT ( safCurrency + "USD" ) == safSymbol ) ||
              ( UT ( "USD" + safCurrency ) == safSymbol ) ) {
                  result = safSymbol ;
                  break ; }}
      return ( result ) ; }

   void goSort_AllPositionsByProfit ( string &StringArray[] , double &ValueArray[] ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      // -------------------- Variables
      int safCounter = 0 ;
      string result = "" ;
      // -------------------- Go thru all open one by one
      for ( int i = PositionsTotal () - 1 ; i >= 0 ; i-- ) {
         // -------------------- Check that ticket is selected
         ulong safTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( safTicket ) ) { continue ; }
         // -------------------- Get profit and add if negative
         double posProfit = sProfit () ;
         if ( posProfit >= 0 ) { continue ; }
         // -------------------- Add ticket and its profit to array
         ArrayResize ( StringArray , safCounter + 1 ) ;
         ArrayResize ( ValueArray , safCounter + 1 ) ;
         StringArray [ safCounter ] = "|" + string ( posProfit ) + "|" + string ( safTicket ) + "|" ;
         ValueArray [ safCounter ] = posProfit ;
         safCounter += 1 ; }
      // -------------------- Sort Values array
      ArraySort ( ValueArray ) ;
      // -------------------- Sort String array
      for ( int i = 0 ; i < ArraySize ( ValueArray ) ; i++ ) {
         for ( int j = 0 ; j < ArraySize ( StringArray ) ; j++ ) {
            if ( StringFind ( StringArray [ j ] , string ( ValueArray [ i ] ) , 0 ) >= 0 ) {
               result += StringArray [ j ] + CharToString ( 1 ) ; StringArray [ j ] = "" ; break ; }}}
      // -------------------- Finalize here
      ArrayResize ( StringArray , 0 ) ;
      StringSplit ( result , 1 , StringArray ) ;
      ArrayResize ( StringArray , ( ArraySize ( StringArray ) - 1 ) ) ; }

   string goSymbols_GetAllInDataWindow () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "|" ;
      for ( int i = 0 ; i < SymbolsTotal ( true ) ; i++ ) {
         result += SymbolName ( i , true ) + "|" ; }
      return ( result ) ; }

   void goSymbol_AddToDataWindow ( string safSymbol2Add ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- return if symbol already in data windows
      if ( SymbolInfoInteger ( safSymbol2Add , SYMBOL_VISIBLE ) ) { return ; }
      SymbolSelect ( safSymbol2Add , true ) ; }

   void goSymbols_OpenChartWithTimeFrame ( const string safSymbol , const ENUM_TIMEFRAMES safTF ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      long chartID = 0 ;
      while ( ( chartID = ChartNext ( chartID ) ) > 0 ) {
         string chartSymbol = ChartSymbol ( chartID ) ;
         ENUM_TIMEFRAMES chartTF = ChartPeriod ( chartID ) ;
         if ( ( chartSymbol == safSymbol ) && ( chartTF == safTF ) ) {
            goPrint ( "Chart for: " + safSymbol + " / " + string ( safTF ) + " is already open" ) ;
            return ; }}
      if ( !SymbolSelect ( safSymbol , true ) ) {
         goPrint ( "Failed to add chart for: " + safSymbol ) ;
         return ;
      } else {
         goPrint ( "Added chart for: " + safSymbol ) ; }
      ChartOpen ( safSymbol, safTF ) ; }

   void goSymbols_RemoveAllFromDataWindowExcept ( const string safSymbol , const ENUM_TIMEFRAMES safTF ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      long chartID = 0 ;
      while ( ( chartID = ChartNext ( chartID ) ) > 0 ) {
         string chartSymbol = ChartSymbol ( chartID ) ;
         ENUM_TIMEFRAMES chartTF = ChartPeriod ( chartID ) ;
         if ( ( chartSymbol != safSymbol ) || ( chartTF != safTF ) ) { ChartClose ( chartID ) ; }}}

   void goSunsetRobot ( string safSettings ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      bool SunsetOK = false ;
      if ( glb_SunsetDate != "" ) {
         if ( long ( StringSubstr ( goGetDateTime () , 0 , 6 ) ) > long ( glb_SunsetDate ) ) { SunsetOK = true ; }}
      if ( glb_SunsetDays > 0 ) {
         if ( IsNewDay() == true ) {
            glb_SunsetDays = glb_SunsetDays - 1 ;
            if ( glb_SunsetDays < 1 ) { SunsetOK = true ; }}}
      if ( SunsetOK == true ) {
         goBroadcast_OPS ( goTele_PrepMsg ( glb_Magic , "BEACON" , "SUNSET" , safSettings ) ) ;
         ExpertRemove () ; }}

   string goCleanString ( string safInput ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string safAllowedCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890" ;
      string result = "";
      for ( int i = 0 ; i < StringLen ( safInput ) ; i++ ) {
         string safLetter = StringSubstr ( safInput , i , 1 ) ;
         if ( StringFind ( safAllowedCharacters , safLetter ) != -1 ) {
            result += safLetter ; }}
      return result ; }

   bool goCheck_ConfigString ( string safConfigString ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- Variables
      safConfigString = UT ( safConfigString ) ;
      // -------------------- Config String symbol check
      string Symbol2Use = glb_EAS ;
      StringReplace ( Symbol2Use , "." , "" ) ;
      if ( StringFind ( safConfigString , UT ( Symbol2Use ) , 0 ) < 1 ) {
         goPrint ( " Incorrect Config String versus Chart !" ) ;
         ExpertRemove () ; return false ; }
      // -------------------- Config String broker check
      bool OK2Continue = false ;
      string safBroker = UT ( AccountInfoString ( ACCOUNT_COMPANY ) ) ;
      if ( StringFind ( safBroker , "BLUEBERRY" , 0 ) >= 0 ) {
         if ( StringFind ( safConfigString , "BB" , 0 ) >= 0 ) { OK2Continue = true ; }}
      else if ( StringFind ( safBroker , "EIGHTCAP" , 0 ) >= 0 ) {
         if ( StringFind ( safConfigString , "8CAP" , 0 ) >= 0 ) { OK2Continue = true ; }}
      else if ( StringFind ( safBroker , "MEX" , 0 ) >= 0 ) {
         if ( StringFind ( safConfigString , "MB" , 0 ) >= 0 ) { OK2Continue = true ; }}
      else if ( StringFind ( safBroker , "VANTAGE" , 0 ) >= 0 ) {
         if ( StringFind ( safConfigString , "VAN" , 0 ) >= 0 ) { OK2Continue = true ; }}
      else if ( StringFind ( safBroker , "TRADEVIEW" , 0 ) >= 0 ) {
         if ( StringFind ( safConfigString , "TVM" , 0 ) >= 0 ) { OK2Continue = true ; }}
      if ( OK2Continue == false ) {
         goPrint ( " Incorrect broker for Config String !" ) ;
         ExpertRemove () ; return false ; } return true ; }

   string goTranslate_Broker () {
      string safBroker = UT ( AccountInfoString ( ACCOUNT_COMPANY ) ) ;
      if ( StringFind ( safBroker , "BLUEBERRY" , 0 ) >= 0 ) { return "BB" ; }
      else if ( StringFind ( safBroker , "EIGHTCAP" , 0 ) >= 0 ) { return "8CAP" ; }
      else if ( StringFind ( safBroker , "MEX" , 0 ) >= 0 ) { return "MB" ; }
      else if ( StringFind ( safBroker , "VANTAGE" , 0 ) >= 0 ) { return "VAN" ; }
      else if ( StringFind ( safBroker , "TRADEVIEW" , 0 ) >= 0 ) { return "TVM" ; }
      return ( safBroker ) ; }

   string goCleanFileName ( string safFN ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = safFN ;
      StringReplace ( result , "XL" , "" ) ;
      StringReplace ( result , ".mq5" , "" ) ;
      StringReplace ( result , ".mqh" , "" ) ;
      StringReplace ( result , ".ex5" , "" ) ;
      return ( result ) ; }

   //===========================================================================================================
   //=====                                       CALC FUNCTIONS                                            =====
   //===========================================================================================================

   double goCalc_LotSize ( double safPercSLV , double safLot = -1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- Min lot mode here
      if ( glb_MinTradeMode ) { return ( NormalizeDouble ( sMin() , 2 ) ) ; }
      // -------------------- Variables here
      double TempResult = 0 , FinalResult = 0 ;
      double LotSize2Use = glb_LotSize ;
      // -------------------- Calc amount 2 use here
      double safAmount2CalcFrom = AccountInfoDouble ( ACCOUNT_MARGIN_FREE ) ;
      if ( glb_BeaconMode == true ) { safAmount2CalcFrom = MathMax ( safAmount2CalcFrom , 10000 ) ; }
      double safAmount2Use = safAmount2CalcFrom ;
      if ( glb_MaxCapitalValue > 0 ) { safAmount2Use = MathMin ( safAmount2Use , glb_MaxCapitalValue ) ; }
      if ( glb_MaxCapitalPerc > 0 ) { safAmount2Use = MathMin ( safAmount2Use , ( safAmount2CalcFrom * glb_MaxCapitalPerc / 100 ) ) ; }
      // -------------------- Handle Max DD here
      if ( glb_MaxDDTrigger > 0 ) {
         if ( glb_MaxDDBehaviour != Do_Noting ) {
            if ( sEqu() <= ( sBal() * ( 100 - glb_MaxDDTrigger ) / 100 ) ) {
               // -------------------- Here we handle DD Max Stop Trade
               if ( glb_MaxDDBehaviour == Stop_Trade ) { return ( 0.00 ) ; }
               // -------------------- Here we handle DD Max Trade Min
               if ( glb_MaxDDBehaviour == Trade_Minimum ) { LotSize2Use = 0 ; }
               // -------------------- Here we handle DD Max Half/Half/Min
               if ( glb_MaxDDBehaviour == Trade_Half_Half_Min ) {
                  LotSize2Use = LotSize2Use / 2 ;
                  if ( sEqu() <= ( sBal() * ( 100 - ( glb_MaxDDTrigger * 2 ) ) / 100 ) ) {
                     LotSize2Use = LotSize2Use / 2 ; }
                  if ( sEqu() <= ( sBal() * ( 100 - ( glb_MaxDDTrigger * 3 ) ) / 100 ) ) {
                     LotSize2Use = 0 ; }}}}}
      // -------------------- If safLot = -1
      if ( safLot == -1 ) {
         // -------------------- GlobalSize uses 1000 Factor
         if ( LotSize2Use == 0 ) {
            TempResult = double ( sMin() * ( int ( ( ( safAmount2Use ) / 1000 ) ) ) ) ; }
         // -------------------- GlobalSize uses minimum
         else if ( LotSize2Use == 0.01 ) {
            if ( int ( ( ( safAmount2Use ) / 1000 ) ) > 0 ) {
               return ( NormalizeDouble ( sMin() , 2 ) ) ;
            } else { return ( 0.00 ) ; }}
         // -------------------- GlobalSize uses Percent of account
         else {
            // -------------------- There is a SLV to calculate stops
            if ( safPercSLV > 0 ) {
               safAmount2Use = safAmount2Use * ( LotSize2Use / 100 ) ;
               TempResult = safAmount2Use / sPow ( safPercSLV ) ;
               if ( glb_BaseCurr != "USD" ) { TempResult = TempResult * goCalc_ExchangeRate () ; }
            // -------------------- There is no SLV and hence return 0
            } else { return ( 0.00 ) ; }}
      // -------------------- If safLot != -1
      } else { TempResult = safLot ; }
      // -------------------- Check max lof per 1K here
      if ( glb_MaxLotPerK > 0 ) { TempResult = ND2 ( MathMin ( TempResult , ( safAmount2CalcFrom / 1000 * glb_MaxLotPerK ) ) ) ; }
      // -------------------- Min Max check
      if ( TempResult < sMin() ) { return ( 0.00 ) ; }
      if ( TempResult > sMax() ) { return ( NormalizeDouble ( sMax() , 2 ) ) ; }
      // -------------------- Here we check for step
      double safStep = SymbolInfoDouble ( glb_EAS , SYMBOL_VOLUME_STEP ) ;
      do { FinalResult += safStep ; } while ( FinalResult <= TempResult ) ;
      if ( FinalResult > TempResult ) { FinalResult = FinalResult - safStep ; }
      return ( NormalizeDouble ( FinalResult , 2 ) ) ; }

   double goCalc_SLBasedOnFractals ( string safType ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      double result = 0 ;
      if ( safType == "B" ) { result = double ( myIndicator_HigherTFFractals ( "6" ) ) ; }
      if ( safType == "S" ) { result = double ( myIndicator_HigherTFFractals ( "5" ) ) ; }
      return result ; }

   double goCalc_PercentSLV ( string safType , string safRules="123" , int safDivider=1 ,int safMinPoints=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // 1: ATR14 - 2: ATR1440 - 3: Fractals - 4: ATR7200 - 5: ATR28800 - 6: Price/Divider
      // 7: BB - 8: D1 ATR220 / Divider - 9: Ichi cloud - A: Last year Max-Min/Dicider
      // B: M15 ATR96 / Divider - C: H1 ATR120 / Divider - D: D1 ATR22 / Divider
      double SLV01 = 0 ; if ( StringFind ( safRules , "1" , 0 ) >= 0 ) { SLV01 = sATR ( 14 ) ; }
      double SLV02 = 0 ; if ( StringFind ( safRules , "2" , 0 ) >= 0 ) { SLV02 = sATR ( 1440 ) ; }
      double SLV03 = 0 ; if ( StringFind ( safRules , "3" , 0 ) >= 0 ) { SLV03 = goCalc_SLBasedOnFractals ( safType ) ; }
      double SLV04 = 0 ; if ( StringFind ( safRules , "4" , 0 ) >= 0 ) { SLV04 = sATR ( 7200 ) ; }
      double SLV05 = 0 ; if ( StringFind ( safRules , "5" , 0 ) >= 0 ) { SLV05 = sATR ( 28800 ) ; }
      double SLV06 = 0 ; if ( StringFind ( safRules , "6" , 0 ) >= 0 ) { SLV06 = ( sAsk() / safDivider ) ; }
      double SLV07 = 0 ; if ( StringFind ( safRules , "7" , 0 ) >= 0 ) {
      // BOL: 0 - BASE LINE , 1 - UPPER BAND , 2 - LOWER BAND
         // -------------------- handle indicator here
         if ( ind_Band ( 20 , 0 , 2 ) == false ) { return 0 ; }
         SLV07 = ( ( ( B1 [ glb_FC ] - B2 [ glb_FC ] ) / 4 ) * 3 ) ; }
      double SLV08 = 0 ; if ( StringFind ( safRules , "8" , 0 ) >= 0 ) { SLV08 = sATR ( 220 , PERIOD_D1 ) / safDivider ; }
      double SLV09 = 0 ; if ( StringFind ( safRules , "9" , 0 ) >= 0 ) {
         // -------------------- handle indicator here
         if ( ind_Ichimoku () == false ) { return 0 ; }
         double safCloudA = B2 [ glb_FC + 26 ] ;
         double safCloudB = B3 [ glb_FC + 26 ] ;
         double safPrice = glb_PI[ glb_FC ].close ;
         if ( ( ( safPrice > safCloudA ) && ( safPrice < safCloudB ) ) || ( ( safPrice < safCloudA ) && ( safPrice > safCloudB ) ) ) { return 0 ; }
         SLV09 = MathMax ( MathAbs ( safPrice - safCloudA ) , MathAbs ( safPrice - safCloudB ) ) ; }
      double SLVA = 0 ; if ( StringFind ( safRules , "A" , 0 ) >= 0 ) {
         ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         glb_EAP = PERIOD_D1 ;
         goClearBuffers () ;
         CopyHigh ( glb_EAS , glb_EAP , glb_FC , 220 , B4 ) ;
         int safNum = ArrayMaximum ( B4 ) ;
         double safMax = B4 [ safNum ] ;
         CopyLow ( glb_EAS , glb_EAP , glb_FC , 220 , B4 ) ;
         safNum = ArrayMinimum ( B4 ) ;
         double safMin = B4 [ safNum ] ;
         SLVA = ( safMax - safMin ) / safDivider ;
         glb_EAP = sCurr_Period ; }
      double SLVB = 0 ; if ( StringFind ( safRules , "B" , 0 ) >= 0 ) { SLVB = sATR ( 288 , PERIOD_M5 ) / safDivider ; }
      double SLVC = 0 ; if ( StringFind ( safRules , "C" , 0 ) >= 0 ) { SLVC = sATR ( 96 , PERIOD_M15 ) / safDivider ; }
      double SLVD = 0 ; if ( StringFind ( safRules , "D" , 0 ) >= 0 ) { SLVD = sATR ( 120 , PERIOD_H1 ) / safDivider ; }
      double SLVE = 0 ; if ( StringFind ( safRules , "E" , 0 ) >= 0 ) { SLVE = sATR ( 22 , PERIOD_D1 ) / safDivider ; }
      double result = MathMax(MathMax(MathMax(MathMax(MathMax(MathMax(MathMax(MathMax(MathMax(MathMax(MathMax(MathMax(MathMax(
         SLV01,SLV02),SLV03),SLV04),SLV05),SLV06),SLV07),SLV08),SLV09),SLVA),SLVB),SLVC),SLVD),SLVE) ;
      if ( safMinPoints > 0 ) { result = MathMax ( result , ( safMinPoints * sPoint() ) ) ; }
      return ( result ) ; }

   double goCalc_AverageOfString ( string safInput ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      double result = 0 , safCounter = 0 ;
      string safArray[] ;
      StringSplit ( safInput , StringGetCharacter ( "|" , 0 ) , safArray ) ;
      for ( int i = ArraySize ( safArray ) - 1 ; i >= 0 ; i-- ) {
         if ( StringLen ( UT ( safArray [ i ] ) ) > 0 ) {
            result += double ( safArray [ i ] ) ;
            safCounter += 1 ; }}
      return ( result / safCounter ) ; }

   string goCalc_TradeRange ( string safRules="1" , int safHours=120 , double safPercent=85 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Trade if within trade percent range
      // RULE 2: Use middle filter to buy below middle and sell above
      if ( ( safHours > 0 ) && ( safPercent > 0 ) ) {
         ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         glb_EAP = PERIOD_H1 ;
            CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
            double safMax = goFind_High ( safHours , glb_FC , 2 ) ;
            double safMin = goFind_Low ( safHours , glb_FC , 2 ) ;
            double safRange = safMax - safMin ;
            double safMiddle = safMin + ( safRange / 2 ) ;
            safRange = safRange * ( safPercent / 100 ) ;
            double safUpper = safMiddle + ( safRange / 2 ) ;
            double safLower = safMiddle - ( safRange / 2 ) ;
         glb_EAP = sCurr_Period ;
         CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
         // -------------------- RULE 1
         if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
            if ( ( sAsk() < safUpper ) && ( sBid() > safLower ) ) { result += "Y" ; } else { result += "X" ; } }
         // -------------------- RULE 2
         if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
            double CurrentPrice = glb_PI [ glb_FC ].close ;
            if ( CurrentPrice < safMiddle ) { result += "B" ; }
            else if ( CurrentPrice > safMiddle ) { result += "S" ; }
            else { result += "X" ; } } }
      return result ; }

   void goSet_TradeLimits ( int NoOfWeeks=260 , double NoOfPercent=10 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      double sGlobalOnePercent=0 ;
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         glb_EAP = PERIOD_W1 ;
         double safPeriodMax = goFind_High ( NoOfWeeks , 0 ) ;
         double safPeriodMin = goFind_Low ( NoOfWeeks , 0 ) ;
         double safHigh = sAsk() + ( ( safPeriodMax - safPeriodMin ) / 1 ) ;
         double safLow = sBid() - ( ( safPeriodMax - safPeriodMin ) / 1 ) ;
         sGlobalOnePercent = ( safHigh - safLow ) / 200 ;
         glb_UpperTradeLimit = safPeriodMax - ( NoOfPercent * sGlobalOnePercent ) ;
         glb_LowerTradeLimit = safPeriodMin + ( NoOfPercent * sGlobalOnePercent ) ;
      glb_EAP = sCurr_Period ; }

   double goCalc_DailyD1ATR ( int safPeriod=14 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( sATR ( safPeriod , PERIOD_D1 ) ) ; }

   double goCalc_DailyM1ATR ( int safPeriod=1440 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( sATR ( safPeriod , PERIOD_M1 ) ) ; }

   double goCalc_SLVByDayMovement ( int safNoOfDays2Use=220 , int safHLDivider=20 , int safAvgDivider=5  ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = safNoOfDays2Use ;
         // -------------------- HL Method
         sATR ( 1 , PERIOD_D1 ) ;
         double resultHL = B0 [ ArrayMaximum ( B0 ) ] / safHLDivider ;
         sATR ( safNoOfDays2Use , PERIOD_D1 ) ;
         double resultAvg = B0 [ 1 ] / safAvgDivider ;
      glb_BD = sCurr_BufferDepth ;
      return ( MathMax ( resultHL , resultAvg ) ) ; }

   double goCalc_ExchangeRate () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      double result = 0 ;
      string sCurr_Symbol = glb_EAS ;
         glb_EAS = UT ( glb_BaseCurr ) ;
         string safCurrency = glb_EAS ;
         double safFactor = ( sAsk() + sBid() ) / 2 ;
         StringReplace ( safCurrency , "USD" , "" ) ; ;
         if ( ( safCurrency + "USD" ) ==  glb_EAS ) { result = ( safFactor ) ; }
         else if ( ( "USD" + safCurrency ) == glb_EAS ) { result = ( 1 / safFactor ) ; }
      glb_EAS = sCurr_Symbol ;
      return ( result ) ; }

   double goCalc_LastYearDayRange ( int safDivider=3 , int safDays=220 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      double result = 0 ;
      CopyRates ( glb_EAS , PERIOD_D1 , 0 , safDays , glb_PI ) ;
      for ( int i = 0 ; i < ArraySize ( glb_PI ) ; i ++ ) {
         double safRange = ( ( glb_PI[ i ].high - glb_PI[ i ].low ) / safDivider ) ;
         if ( safRange > result ) { result = safRange ; }}
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      return ( result ) ; }

   //===========================================================================================================
   //=====                                    CURRENCY STRENGTH METERS                                     =====
   //===========================================================================================================

   string goSignal_Finviz (
      string safRules ="3" ,
      string safURL = "https://finviz.com/forex_performance.ashx" ,
      string safStartCutter = "var performance = {" ,
      string safEndCutter = "};" ,
      string safPairSplitter = "," ,
      string safPairValueSplitter = ":" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // RULE 2: Return the whole result line back, not a trade signal
         // RULE 3: Return buy/sell signal plus pair and values
         // RULE 4: No zero allowed
         // RULE 5: Disgard currency if it is not in session
         // RULE 6: High must be +ve and low must be -ve
         // RULE 7: return only changed signals
         // -------------------- Go read HTML and get relevant snippet
         string safStart2End = goHTML_Cutter ( goRead_Website ( safURL ) , safStartCutter , safEndCutter ) ;
         // -------------------- Clean "" from the line
         StringReplace ( safStart2End , CharToString ( 34 ) , "" ) ;
         // -------------------- RULE 2
         if ( StringFind ( safRules , "2" , 0 ) >= 0 ) { return safStart2End ; }
         // -------------------- Now pass data line to common function for processing
         return goCurrencyStrengthMeter_Common ( safRules , safStart2End , safPairSplitter , safPairValueSplitter ) ; }

   string goSignal_CurStrMtr (
      string safRules ="3" ,
      string safURL = "https://currencystrengthmeter.org/" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // RULE 1: Return HTML
         // RULE 2: Return the whole result line back, not a trade signal
         // RULE 3: Return buy/sell signal plus pair and values
         // RULE 4: No zero allowed
         // RULE 5: Disgard currency if it is not in session
         // RULE 6: High must be +ve and low must be -ve
         // RULE 7: return only changed signals
         // -------------------- Cutters
         string safStartCutter = "<p class=" + CharToString ( 34 ) + "title" + CharToString ( 34 ) + ">" ;
         string safEndCutter = "style=" + CharToString ( 34 ) + "height:" ;
         string safPairSplitter = "," ;
         string safPairValueSplitter = ":" ;
         // -------------------- read data from website
         string safHTML = goRead_Website ( safURL ) ;
         if ( safHTML == "" ) { return "" ; }
         // -------------------- RULE 1
         if ( StringFind ( safRules , "1" , 0 ) >= 0 ) { return safHTML ; }
         // -------------------- cut HTML into lines the represent each currency result
         string result [] ;
         StringReplace ( safHTML , safStartCutter , CharToString ( 1 ) ) ;
         StringSplit ( safHTML , 1 , result ) ;
         if ( ArraySize ( result ) < 2 ) { return "" ; }
         // -------------------- Go thru lines one by one
         string result2 [] ;
         string safStart2End = "" ;
         for ( int i = 1 ; i <= ArraySize ( result ) - 1 ; i++ ) {
            string safCurrencyName = StringSubstr ( result [ i ] , 1 , 3 ) ;
            // -------------------- cut each currency result to get value
            StringReplace ( result [ i ] , safEndCutter , CharToString ( 1 ) ) ;
            StringSplit ( result [ i ] , 1 , result2 ) ;
            if ( ArraySize ( result2 ) < 2 ) { return "" ; }
            string safCurrencyValue = UT ( StringSubstr ( result2 [ 1 ] , 0 , 4 ) ) ;
            StringReplace ( safCurrencyValue , "%" , "" ) ;
            safStart2End += safCurrencyName + safPairValueSplitter + safCurrencyValue + safPairSplitter ; }
            safStart2End = StringSubstr ( safStart2End , 0 , StringLen ( safStart2End ) - 1 ) ;
         // -------------------- RULE 2
         if ( StringFind ( safRules , "2" , 0 ) >= 0 ) { return safStart2End ; }
         // -------------------- Now pass data line to common function for processing
         return goCurrencyStrengthMeter_Common ( safRules , safStart2End , safPairSplitter , safPairValueSplitter ) ; }

   string goSignal_MyCSM (
      string safRules ="3" ,
      ENUM_TIMEFRAMES safTimeFrame = PERIOD_W1 ,
      int safPeriod = 15 ,
      int safFC = -1 ,
      string safPairSplitter = "," ,
      string safPairValueSplitter = ":" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // RULE 2: Return the whole result line back, not a trade signal
         // RULE 3: Return buy/sell signal plus pair and values
         // RULE 4: No zero allowed
         // RULE 5: Disgard currency if it is not in session
         // RULE 6: High must be +ve and low must be -ve
         // RULE 7: return only changed signals
         string result = "" ;
         // -------------------- Save Current State
         ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         string sCurr_Symbol = glb_EAS ;
         int sCurr_FirstCandle = glb_FC ;
         // -------------------- Set new parameterd
         glb_EAP = safTimeFrame ;
         if ( safFC != -1 ) { glb_FC = safFC ; }
         // -------------------- Create pair list
         string safSymbolArray[] = { "EURUSD" , "GBPUSD" , "USDJPY" , "USDCHF" , "AUDUSD" , "NZDUSD" , "USDCAD" } ;
         // -------------------- Go thru currencies one by one and get values
         for ( int i = 0 ; i < ArraySize ( safSymbolArray ) ; i++ ) {
            glb_EAS = safSymbolArray [ i ] ;
            CopyRates ( glb_EAS , glb_EAP , 0 , ( glb_FC + safPeriod + 1 ) , glb_PI ) ;
            double CurrentPrice  = glb_PI [ glb_FC ].close ;
            double OldPrice      = glb_PI [ glb_FC + safPeriod ].close ;
            // -------------------- Here we inverse the values if the USD is the second currency
            if ( StringFind ( glb_EAS , "USD" , 0 ) < 2 ) { CurrentPrice = 1 / CurrentPrice ; OldPrice = 1 / OldPrice ; }
            // -------------------- Calc change here
            double safChange = ND2 ( ( 100 * ( ( CurrentPrice - OldPrice ) / OldPrice ) ) ) ;
            // goPrint ( glb_EAS + ": " + string ( safChange ) ) ;
            StringReplace ( glb_EAS , "USD" , "" ) ;
            result += glb_EAS + safPairValueSplitter + string ( safChange ) + safPairSplitter ;
         } // ----- next symbol
         result += "USD" + safPairValueSplitter + "0" ;
         // -------------------- Return Current State
         glb_EAP = sCurr_Period ;
         glb_EAS = sCurr_Symbol ;
         glb_FC = sCurr_FirstCandle ;
         CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
         // -------------------- RULE 2
         if ( StringFind ( safRules , "2" , 0 ) >= 0 ) { return result ; }
         // -------------------- Now pass data line to common function for processing
         return goCurrencyStrengthMeter_Common ( safRules , result , safPairSplitter , safPairValueSplitter ) ; }

   string goCurrencyStrengthMeter_Common (
      string safRules ,
      string safInputString ,
      string safPairSplitter ,
      string safPairValueSplitter ,
      string safNotAllowedSymbols="BTC" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // RULE 3: Return buy/sell signal plus pair and values
         // RULE 4: No zero allowed
         // RULE 5: Disgard currency if it is not in session
         // RULE 6: High must be +ve and low must be -ve
         // RULE 7: return only changed signals
         string result[] ;
         // -------------------- Split data line into individual currencies
         StringSplit ( safInputString , StringGetCharacter ( safPairSplitter , 0 ) , result ) ;
         if ( ArraySize ( result ) < 2 ) { return "" ; }
         // -------------------- Go thru currencies to find highest and lowest
         string result2 [] ;
         double safHighestValue = -999999 , safLowestValue = 999999 ;
         string safHighestCurrency = "" , safLowestCurrency = "" ;
         for ( int i = 0 ; i <= ArraySize ( result ) - 1 ; i++ ) {
            string safLine = result [ i ] ;
            StringSplit ( safLine , StringGetCharacter ( safPairValueSplitter , 0 ) , result2 ) ;
            if ( ArraySize ( result2 ) < 2 ) { continue ; }
            // -------------------- Check that currency is selected correctly
            string safCurrencyName = result2 [ 0 ] ;
            if ( StringLen ( UT ( safCurrencyName ) ) != 3 ) { continue ; }
            // -------------------- RULE 5
            string safOriginalRules = safRules ;
            if ( StringFind ( safRules , "5" , 0 ) >= 0 ) {
               string sCurr_Symbol = glb_EAS ;
               glb_EAS = safCurrencyName ;
               if ( IsSession_Auto () != "Y" ) {
                  glb_EAS = sCurr_Symbol ;
                  safRules = safOriginalRules ;
                  continue ; }
               glb_EAS = sCurr_Symbol ;
               safRules = safOriginalRules ; }
            // -------------------- RULE 4
            double safCurrencyValue = double ( result2 [ 1 ] ) ;
            safOriginalRules = safRules ;
            if ( StringFind ( safRules , "4" , 0 ) >= 0 ) {
               if ( safCurrencyValue == 0 ) {
                  safRules = safOriginalRules ;
                  continue ; }
               safRules = safOriginalRules ; }
            if ( StringFind ( safNotAllowedSymbols , safCurrencyName , 0 ) >= 0 ) { continue ; }
            // -------------------- RULE 6
            safOriginalRules = safRules ;
            if ( StringFind ( safRules , "6" , 0 ) >= 0 ) {
               if ( ( safCurrencyValue > safHighestValue ) && ( safCurrencyValue > 0 ) ) {
                  safHighestValue = safCurrencyValue ;
                  safHighestCurrency = safCurrencyName ; }
               if ( ( safCurrencyValue < safLowestValue ) && ( safCurrencyValue < 0 ) ) {
                  safLowestValue = safCurrencyValue ;
                  safLowestCurrency = safCurrencyName ; }
            } else {
               if ( safCurrencyValue > safHighestValue ) {
                  safHighestValue = safCurrencyValue ;
                  safHighestCurrency = safCurrencyName ; }
               if ( safCurrencyValue < safLowestValue ) {
                  safLowestValue = safCurrencyValue ;
                  safLowestCurrency = safCurrencyName ; }}
         } // ----- next i
         if ( ( safHighestCurrency == "" ) || ( safLowestCurrency == "" ) ) { return "" ; }
         // -------------------- check is selected symbols are allowed to trade from a list
         string safCurrency2Trade = "" ;
         int safFindHigh = 0 , safFindLow = 0 ;
         for ( int i = 0 ; i <= ArraySize ( glb_SymbolArray ) - 1 ; i++ ) {
            string safCurrencyPair = glb_SymbolArray [ i ] ;
            safFindHigh = StringFind ( safCurrencyPair , safHighestCurrency , 0 ) ;
            safFindLow = StringFind ( safCurrencyPair , safLowestCurrency , 0 ) ;
            if ( ( safFindHigh > -1 ) && ( safFindLow > -1 ) ) { safCurrency2Trade = safCurrencyPair ; break ; }}
         if ( safCurrency2Trade == "" ) { return "" ; }
         // -------------------- Decide here if we buy or sell
         string safFinalResult = "" ;
         if ( safFindHigh < safFindLow ) { safFinalResult = "B|" + safCurrency2Trade ; }
         else if ( safFindHigh > safFindLow ) { safFinalResult = "S|" + safCurrency2Trade ; }
         else { safFinalResult = "X|" ; }
         // -------------------- Final result here
         safFinalResult += "|" + string ( safHighestValue ) + "|" + string ( safLowestValue ) ;
         // -------------------- RULE 7
         static string safLastResult ;
         if ( StringFind ( safRules , "7" , 0 ) >= 0 ) {
            if ( safFinalResult == safLastResult ) {
               return "" ;
            } else {
               safLastResult = safFinalResult ; }}
         // -------------------- RULE 3
         if ( StringFind ( safRules , "3" , 0 ) >= 0 ) { return safFinalResult ; }
         return "" ; }

   string goCheck_BarChartOpinion (
      string safSymbol ,
      string safRules ="13" ,
      string safURL = "https://www.barchart.com/forex/quotes/%5E" ,
      string safStartCutter = ">Overall Average:<" ,
      string safEndCutter = ">Barchart Opinion<" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         // RULE 1: Check BarChart new opinion
         // RULE 2: Check BarChart legacy opinion
         // RULE 3: Check for soft words
         string result = "" , safArray[] ;
         if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
            string safStart2End = UT ( goHTML_Cutter ( goRead_Website ( safURL + safSymbol + "/opinion" ) , safStartCutter , safEndCutter ) ) ;
            StringReplace ( safStart2End , "SPAN>" , "|" ) ; // ----- Cut by SPAN tag to get individual components
            StringSplit ( safStart2End , StringGetCharacter ( "|" , 0 ) , safArray ) ; // ----- Split to the above here
            StringReplace ( safStart2End , safArray[2] , "|" ) ; // ----- Remove the website text part here
            if ( ( StringFind ( safStart2End , "100%" , 0 ) < 0 ) ) { return "X" ; }
            if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
               result += goCheck_BarChartOpinionWords ( safStart2End ) ; }
            if ( ( StringFind ( safStart2End , "BUY" , 0 ) >= 0 ) ) { result += "B" ; }
            else if ( ( StringFind ( safStart2End , "SELL" , 0 ) >= 0 ) ) { result += "S" ; }
            else { return "X" ; }}
         if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
            string safStart2End = UT ( goHTML_Cutter ( goRead_Website ( safURL + safSymbol + "/opinion-legacy" ) , safStartCutter , safEndCutter ) ) ;
            StringReplace ( safStart2End , "SPAN>" , "|" ) ; // ----- Cut by SPAN tag to get individual components
            StringSplit ( safStart2End , StringGetCharacter ( "|" , 0 ) , safArray ) ; // ----- Split to the above here
            StringReplace ( safStart2End , safArray[2] , "|" ) ; // ----- Remove the website text part here
            if ( ( StringFind ( safStart2End , "100%" , 0 ) < 0 ) ) { return "X" ; }
            if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
               result += goCheck_BarChartOpinionWords ( safStart2End ) ; }
            if ( ( StringFind ( safStart2End , "BUY" , 0 ) >= 0 ) ) { result += "B" ; }
            else if ( ( StringFind ( safStart2End , "SELL" , 0 ) >= 0 ) ) { result += "S" ; }
            else { return "X" ; }}
         return ( result ) ; }

   string goCheck_BarChartOpinionWords ( string safInput , string safWords="WEAK|AVERAGE|MINIMUM|SOFT|GOOD" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string safWordsArray[] ;
      StringSplit ( safWords , StringGetCharacter ( "|" , 0 ) , safWordsArray ) ;
      for ( int i = ArraySize ( safWordsArray ) - 1 ; i >= 0 ; i-- ) {
         // -------------------- If name is empty then skip to next
         string safWord2Check = UT ( safWordsArray [i] ) ;
         if ( safWord2Check == "" ) { continue ; }
         if ( ( StringFind ( safInput , safWord2Check , 0 ) >= 0 ) ) { return "X" ; }}
      return "" ; }

   string goSignal_MyOpinion ( string safRules="123" , string safType="SMA" , int safLoc=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // RULE 1: Check price to MAs
      // RULE 2: Check momentum 3 to 10 for MA
      // RULE 3: Check momentum 3 to 10 for Price
      // -------------------- Save current global variables
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      int sCurr_BufferDepth = glb_BD ;
         // -------------------- New Declarations
         glb_EAP = PERIOD_D1 ;
         glb_BD = 11 ;
         string result = "" ;
         // -------------------- Var here
         CopyRates( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
         double safPrice = ( sAsk() + sBid() ) / 2 ;
         // -------------------- handle indicator here
         if ( ind_MA ( safType , 20 ) == false ) {
            glb_EAP = sCurr_Period ;
            glb_BD = sCurr_BufferDepth ;
            CopyRates( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
            return "X" ; }
         double MA_20  = B0 [ safLoc ] ; double MA_20_3  = B0 [ safLoc + 3 ] ; double MA_20_10  = B0 [ safLoc + 10 ] ;
         // -------------------- RULE 1
         if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
            // -------------------- handle indicator here
            if ( ind_MA ( safType , 50 ) == false ) {
               glb_EAP = sCurr_Period ;
               glb_BD = sCurr_BufferDepth ;
               CopyRates( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
               return "X" ; }
            double MA_50  = B0 [ safLoc ] ;
            // -------------------- handle indicator here
            if ( ind_MA ( safType , 100 ) == false ) {
               glb_EAP = sCurr_Period ;
               glb_BD = sCurr_BufferDepth ;
               CopyRates( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
               return "X" ; }
            double MA_100 = B0 [ safLoc ] ;
            // -------------------- handle indicator here
            if ( ind_MA ( safType , 150 ) == false ) {
               glb_EAP = sCurr_Period ;
               glb_BD = sCurr_BufferDepth ;
               CopyRates( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
               return "X" ; }
            double MA_150 = B0 [ safLoc ] ;
            // -------------------- handle indicator here
            if ( ind_MA ( safType , 200 ) == false ) {
               glb_EAP = sCurr_Period ;
               glb_BD = sCurr_BufferDepth ;
               CopyRates( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
               return "X" ; }
            double MA_200 = B0 [ safLoc ] ;
            // -------------------- Checks here
            if ( safPrice > MA_20 )    { result += "B" ; } else { result += "S" ; }
            if ( safPrice > MA_50 )    { result += "B" ; } else { result += "S" ; }
            if ( safPrice > MA_100 )   { result += "B" ; } else { result += "S" ; }
            if ( safPrice > MA_150 )   { result += "B" ; } else { result += "S" ; }
            if ( safPrice > MA_200 )   { result += "B" ; } else { result += "S" ; }
            if ( MA_20 > MA_50 )       { result += "B" ; } else { result += "S" ; }
            if ( MA_20 > MA_100 )      { result += "B" ; } else { result += "S" ; }
            if ( MA_20 > MA_200 )      { result += "B" ; } else { result += "S" ; }
            if ( MA_50 > MA_100 )      { result += "B" ; } else { result += "S" ; }
            if ( MA_50 > MA_150 )      { result += "B" ; } else { result += "S" ; }
            if ( MA_50 > MA_200 )      { result += "B" ; } else { result += "S" ; }
            if ( MA_100 > MA_200 )     { result += "B" ; } else { result += "S" ; }}
         // -------------------- RULE 2
         if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
            double MA_20_3_range = MathAbs ( ( MA_20 - MA_20_3 ) / 3 ) ;
            double MA_20_10_range = MathAbs ( ( MA_20_3 - MA_20_10 ) / 7 ) ;
            if ( MA_20_3_range < MA_20_10_range ) { result = "X" ; }}
         // -------------------- RULE 3
         if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
            double safPrice_3 = glb_PI[ safLoc + 3 ].close ;
            double safPrice_10 = glb_PI[ safLoc + 10 ].close ;
            double Price_3_range = MathAbs ( ( safPrice - safPrice_3 ) / 3 ) ;
            double Price_10_range = MathAbs ( ( safPrice_3 - safPrice_10 ) / 7 ) ;
            if ( Price_3_range < Price_10_range ) { result = "X" ; }}
      // -------------------- Return global variables to their original values
      glb_EAP = sCurr_Period ;
      glb_BD = sCurr_BufferDepth ;
      CopyRates( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      return ( result ) ; }

   //===========================================================================================================
   //=====                                            ORCHARD                                              =====
   //===========================================================================================================

   double Double2Ticks ( double safValue ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( safValue / SymbolInfoDouble ( glb_EAS , SYMBOL_TRADE_TICK_SIZE ) ) ; }

   double Ticks2Double ( double safTicks ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( safTicks * SymbolInfoDouble ( glb_EAS , SYMBOL_TRADE_TICK_SIZE ) ) ; }

   double Points2Double ( int safPoints ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( safPoints * SymbolInfoDouble ( glb_EAS , SYMBOL_POINT ) ) ; }

   double PercentSLSize ( double safPercent , double safLots ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( RiskSLSize ( ( sEqu() * safPercent ) , safLots ) ) ; } // 1% = 0.01

   double PercentRiskLots ( double safPercent , double safSLSize ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      return ( RiskLots ( ( sEqu() * safPercent ) , safSLSize ) ) ; } // 1% = 0.01

   double RiskLots ( double safRiskAmount , double safSLSize ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      double safTicks = Double2Ticks ( safSLSize ) ;
      double safTickValue = SymbolInfoDouble ( glb_EAS , SYMBOL_TRADE_TICK_VALUE ) ;
      double safLotRisk = safTicks * safTickValue ;
      double safRiskLots = safRiskAmount / safLotRisk ;
      return safRiskLots ; }

   double RiskSLSize ( double safRiskAmount , double safLots ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      double safTickValue = SymbolInfoDouble ( glb_EAS , SYMBOL_TRADE_TICK_VALUE ) ;
      double safTicks = safRiskAmount / ( safLots * safTickValue ) ;
      double safSLSize = Ticks2Double ( safTicks ) ;
      return safSLSize ; }

   //===========================================================================================================
   //=====                                           BROADCAST                                             =====
   //===========================================================================================================

   // -------------------- Channels
   // "-1001760124674" // F-SQUARE
   // "-1001486227005" // SNR_In
   // "-1001501253934" // SNR_Out
   // "-1001642437269" // SNR_Analytics
   // "-1001633555419" // SNR_OPS
   // "-1002087660238" // SNR_OTP
   // "-1002108490781" // SNR_TST

   // -------------------- Bots
   // "5329994003:AAEKkBHY6lDux_C66BtCO0TE9Wx3ozFcnUg" // SNR_Test_001_bot // SNR_Signal_Bot
   // "5116032297:AAEgIs64v7rWKIpDI843zMT4GpdNAqtM1e0" // SNR_OY_bot       // SNR_OPS_Bot
   // "5304085024:AAHHXmjnZarEV2ibfa3tJ41UUQOifcrRl0c" // SNR_Ichi_bot     // SNR_ANA_Bot
   // "5255947594:AAF4ad7cEPKPYeyyl9y9HLAc5GbdBu-UT0g" // SNR_BB_bot       // SNR_ID_Bot
   // "6385486447:AAEZCGszJz5U-71Dm8lrePiUsZR6sPx2Y18" // SNR_OTP_bot      // SNR_OTP_Bot

   void goBroadcast_SIG ( string safMsg ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return ; }
      if ( ( glb_BroadID == "" ) || ( safMsg == "" ) ) { return ; }
      prvTele_Send ( safMsg , "-1001760124674" , "5329994003:AAEKkBHY6lDux_C66BtCO0TE9Wx3ozFcnUg" ) ; }

   void goBroadcast_TST ( string safMsg ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return ; }
      if ( ( glb_BroadID == "" ) || ( safMsg == "" ) ) { return ; }
      prvTele_Send ( safMsg , "-1002108490781" , "5116032297:AAEgIs64v7rWKIpDI843zMT4GpdNAqtM1e0" ) ; }

   void goBroadcast_OPS ( string safMsg ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return ; }
      if ( ( glb_BroadID == "" ) || ( safMsg == "" ) ) { return ; }
      prvTele_Send ( safMsg , "-1001633555419" , "5116032297:AAEgIs64v7rWKIpDI843zMT4GpdNAqtM1e0" ) ; }

   void goBroadcast_OTP ( string safMsg ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return ; }
      if ( ( glb_BroadID == "" ) || ( safMsg == "" ) ) { return ; }
      prvTele_Send ( safMsg , "-1002087660238" , "6385486447:AAEZCGszJz5U-71Dm8lrePiUsZR6sPx2Y18" ) ; }

   void goBroadcast_ANA ( string safMsg ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return ; }
      if ( ( glb_BroadID == "" ) || ( safMsg == "" ) ) { return ; }
      prvTele_Send ( safMsg , "-1001642437269" , "5304085024:AAHHXmjnZarEV2ibfa3tJ41UUQOifcrRl0c" ) ; }

   void goBroadcast_ID ( string safTOP ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return ; }
      string sCurr_BroadcastID = glb_BroadID ;
         glb_BroadID = "MyID" ;
         string sMessage2Send = goTele_PrepMsg ( IntegerToString ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ,
            AccountInfoString ( ACCOUNT_COMPANY ) , AccountInfoString ( ACCOUNT_NAME ) , AccountInfoString ( ACCOUNT_SERVER ) ,
            string ( sBal() ) , string ( sEqu() ) , string ( glb_AllowedTrade ) , string ( PositionsTotal() ) ,
            string ( OrdersTotal() ) , string ( safTOP ) ) ;
         prvTele_Send ( sMessage2Send , "-1001486227005" , "5255947594:AAF4ad7cEPKPYeyyl9y9HLAc5GbdBu-UT0g" ) ;
      glb_BroadID  = sCurr_BroadcastID ; }

   //===========================================================================================================
   //=====                                            TELEGRAM                                             =====
   //===========================================================================================================

   string goTele_PrepMsg (
      string sType , string sVal1="" , string sVal2="" , string sVal3="" , string sVal4="" , string sVal5="" ,
      string sVal6="" ,string sVal7="" , string sVal8="" , string sVal9="" , string sVal10="" , string sVal11="" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         if ( glb_SilentMode == true ) { return ( "" ) ; }
         // -------------------- Header
         string result = glb_MsgStart + glb_BroadID + "|" + goGetDateTime() + "|" + sType + "|" ;
         // -------------------- Body
         result += sVal1 + "|" + sVal2 + "|" + sVal3 + "|" + glb_EAS + "|" + sVal4 + "|" + sVal5 + "|" ;
         result += sVal6 + "|" + sVal7 + "|" + sVal8 + "|" + sVal9 + "|" + sVal10 + "|" + sVal11 + "|" ;
         // -------------------- Footer
         string resultHash = goSecurity_Encoder ( result ) ;
         resultHash = goTele_CreateHashSnippet ( resultHash , -1 ) ;
         return ( result + resultHash + glb_MsgEnd ) ; }

   void prvTele_Send ( string safMsg , string safTeleChatID , string safTeleToken ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return ; }
      if ( safMsg == "" ) { return ; }
      if ( safTeleChatID == "" ) { return ; }
      if ( safTeleToken == "" ) { return ; }
      // -------------------- check for duplicate messages first
      // static datetime safLastCandle ;
      // static string safLastText ;
      // if ( safLastCandle != glb_PI [ glb_FC ].time ) {
      //    safLastText = "|" ;
      //    safLastCandle = glb_PI [ glb_FC ].time ; }
      // if ( StringFind ( safLastText , safMsg , 0 ) >= 0 ) { return ; }
      // -------------------- Start constructing message here
      string safTeleURL = "https://api.telegram.org" ;
      string safRequestURL = StringFormat ( "%s/bot%s/sendmessage?chat_id=%s&parse_mode=HTML&text=%s" , safTeleURL , safTeleToken , safTeleChatID , safMsg ) ;
      string safHeaders , safResultHeaders ;
      char safPostData [] , safResultData [] ;
      WebRequest ( "POST" , safRequestURL , safHeaders , 6000 , safPostData , safResultData , safResultHeaders ) ;
      // -------------------- Add to duplicate message string
      // safLastText += "|" + safMsg + "|" ;
      // -------------------- Do server send here
      if ( glb_Write2Server == true ) {
         glb_ServerPHP = "saveeofy.php" ;
         glb_ServerPath = "/SNRobotiX/" ;
         if ( safTeleChatID == "-1001760124674" ) { glb_ServerFileName = "signals.txt" ; }
         else if ( safTeleChatID == "-1001633555419" ) { glb_ServerFileName = "operations.txt" ; }
         else if ( safTeleChatID == "-1001486227005" ) { glb_ServerFileName = "incoming.txt" ; }
         else if ( safTeleChatID == "-1001642437269" ) { glb_ServerFileName = "analysis.txt" ; }
         else if ( safTeleChatID == "-1002087660238" ) { glb_ServerFileName = "onetimepass.txt" ; }
         else if ( safTeleChatID == "-1002108490781" ) { glb_ServerFileName = "cpuutility.txt" ; }
         else { glb_ServerFileName = "catchall.txt" ; }
         goServer_Write_String ( safMsg ) ; }
      // -------------------- Write to journal here
      goPrint ( "Sent Msg: " + safMsg + " with BroadcaseID: " + glb_BroadID ) ; }

   void goTele_GetMsgs (
      string safRobotName ,
      string &AllMsgsArray[] ,
      string safTelePreviewURL = "https://t.me/s/fsquareaps" ,
      string safTeleOriginalURL = "https://t.me/fsquareaps" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         if ( glb_SilentMode == true ) {
            ArrayResize ( AllMsgsArray , 0 ) ;
            return ; }
         if ( safRobotName == "" ) { return ; }
         int safCounter = 0 ;
         string safHTML = goRead_Website ( safTeleOriginalURL , safTelePreviewURL ) ;
         if ( safHTML == "" ) { return ; }
         string result [] , result2 [] ;
         StringReplace ( safHTML , glb_MsgStart , CharToString ( 1 ) ) ;
         StringSplit ( safHTML , 1 , result ) ;
         if ( ArraySize ( result ) < 2 ) { return ; }
         for ( int i = 1 ; i <= ArraySize ( result ) - 1 ; i++ ) {
            // -------------------- Handle emergency ID
            if ( StringFind ( result [ i ] , "IDIDID" , 0 ) >= 0 ) {
               ArrayResize ( AllMsgsArray , safCounter + 1 ) ;
               AllMsgsArray [ safCounter ] = "||ID||||" + glb_EAS + "||||||||" ; }
            // -------------------- Handle emergency STOP
            if ( StringFind ( result [ i ] , "STOPSTOPSTOP" , 0 ) >= 0 ) {
               ArrayResize ( AllMsgsArray , safCounter + 1 ) ;
               AllMsgsArray [ safCounter ] = "||STOP||||" + glb_EAS + "||||||||" ; }
            StringReplace ( result [ i ] , glb_MsgEnd , CharToString ( 1 ) ) ;
            StringSplit ( result [ i ] , 1 , result2 ) ;
            if ( ArraySize ( result2 ) < 1 ) { continue ; }
            if ( !goTele_CheckMsgAgeAndName ( safRobotName , result2 [ 0 ] ) ) { continue ; }
            if ( !goTele_CheckMsgHash ( result2 [ 0 ] ) ) { continue ; }
            if ( !goTele_CheckMsgRepeat ( result2 [ 0 ] ) ) { continue ; }
            ArrayResize ( AllMsgsArray , safCounter + 1 ) ;
            AllMsgsArray [ safCounter ] = result2 [ 0 ] ;
            safCounter += 1 ; }}

   bool goTele_CheckMsgHash ( string safMsg ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( safMsg == "" ) { return false ; }
      string result [] ;
      StringSplit ( safMsg , StringGetCharacter ( "|" , 0 ) , result ) ;
      if ( ArraySize ( result ) < 2 ) { return false ; }
      string safHash2Check = result [ ArraySize ( result ) - 1 ] ;
      StringReplace ( safMsg , safHash2Check , "" ) ;
      string safHashNew = goSecurity_Encoder ( glb_MsgStart + safMsg ) ;
      if ( StringFind ( safHashNew , safHash2Check , 0 ) >= 0 ) { return true ; } else { return false ; }}

   bool goTele_CheckMsgAgeAndName (
      string safRobotName ,
      string safMsg ,
      int safLookupPeriod = 90 ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         if ( safRobotName == "" ) { return false ; }
         if ( safMsg == "" ) { return false ; }
         string result [] ;
         StringSplit ( safMsg , StringGetCharacter ( "|" , 0 ) , result ) ;
         if ( ArraySize ( result ) < 2 ) { return false ; }
         string safMsgBroadcastID = UT ( result [ 0 ] ) ;
         string safDateTime2Check = result [ 1 ] ;
         string safDateTimeMin = goGetDateTime( safLookupPeriod ) ;
         if ( safDateTime2Check < safDateTimeMin ) { return false ; }
         // -------------------- Ignore if broadcast is TEST
         if ( UT ( safMsgBroadcastID ) == "TEST" ) { return false ; }
         // -------------------- Accept if same as robot name
         if ( UT ( safRobotName ) == UT ( safMsgBroadcastID ) ) { return true ; }
         // -------------------- Accept if broadcast is ALL
         if ( UT ( safMsgBroadcastID ) == "ALL" ) { return true ; }
         // -------------------- Accept if its your account number
         if ( safMsgBroadcastID == string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ) { return true ; }
         // -------------------- Accept if broadcast is in robot name
         if ( StringFind ( ( ";" + UT ( safRobotName ) + ";" ) , ( ";" + UT ( safMsgBroadcastID ) + ";" ) , 0 ) >= 0 ) { return true ; }
         return false ; }

   bool goTele_CheckMsgRepeat ( string safMsg , int safMaxLength = 1500 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( safMsg == "" ) { return false ; }
      bool result = true ;
      static string safOldMsgs ;
      if ( StringReplace ( safOldMsgs , safMsg , "" ) > 0 ) { result = false ; }
      safOldMsgs += safMsg ;
      if ( StringLen ( safOldMsgs ) > safMaxLength ) {
         safOldMsgs = StringSubstr ( safOldMsgs , ( StringLen ( safOldMsgs ) - safMaxLength ) , safMaxLength ) ; }
      return result ; }

   string goTele_CreateHashSnippet (
      string safInput ,
      int safLength = 8 ,
      string safAccepted = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         string result = "" ;
         string safLetter = "" ;
         if ( safLength == -1 ) { safLength = sRandomNumber ( 5 , 9 ) ; }
         for ( int i = 0 ; i < StringLen ( safInput ) ; i++ ) {
            string safAccepted2Use = safAccepted ;
            safLetter = StringSubstr ( safInput , i , 1 ) ;
            if ( StringFind ( safAccepted2Use , safLetter , 0 ) >= 0 ) { result += safLetter ; } else { result = "" ; }
            if ( StringLen ( result ) >= safLength ) { break ; }}
         return result ; }

   //===========================================================================================================
   //=====                                            SNR HTML                                             =====
   //===========================================================================================================

   void goSNR_HTML_Header ( string safRules="3" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // RULE 1: Add Search link
      // RULE 2: Add Home link
      // RULE 3: Add Contact-Us link
      // RULE 5: Add Back link
      // RULE 4: Full viewport centered content box
      // RULE A: Add Account Summary Page CSS
      // RULE B: Add Account Search Page CSS
      prvA2H ( "--NEWFILE--" ) ;
      prvA2H ( "<!DOCTYPE html>" ) ;
      prvA2H ( "<html lang='en'>" ) ;
      prvA2H ( "<head>" ) ;
      prvA2H ( "<meta charset='UTF-8'>" ) ;
      prvA2H ( "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" ) ;
      prvA2H ( "<link href='https://fonts.googleapis.com/css?family=Montserrat' rel='stylesheet'>" ) ;
      prvA2H ( "<title>SNRobotiX</title>" ) ;
      prvA2H ( "<style>" ) ;
      prvA2H ( ":root {" ) ;
      prvA2H ( "--clr1:#f7f7f7;" ) ;
      prvA2H ( "--clr2:#d3d3d3;" ) ;
      prvA2H ( "--clr3:#1e3c64;" ) ;
      prvA2H ( "--clr4:#0b0921;" ) ;
      prvA2H ( "--clr5:#d9bf6b;" ) ;
      prvA2H ( "--navbarH: 70px;" ) ;
      prvA2H ( "--navbarW: 80%;" ) ;
      prvA2H ( "--navlogoH: 30px;" ) ;
      prvA2H ( "--navlinkS: 20px;" ) ;
      prvA2H ( "--footerH: 70px;" ) ;
      prvA2H ( "--lineH: 30px;" ) ;
      prvA2H ( "--headerH:50px;}" ) ;
      prvA2H ( ".navbarbox, .contentbox, .line, .lineheader, .field, .subtot , form , .footerbox{" ) ;
      prvA2H ( "display:flex;" ) ;
      prvA2H ( "align-items: center;" ) ;
      prvA2H ( "justify-content:center;}" ) ;
      prvA2H ( "body{font-family:Montserrat;background-color:var(--clr4);color:var(--clr1);padding:0;margin:0;}" ) ;
      prvA2H ( "form{flex-direction:column;width:100%;}" ) ;
      prvA2H ( ".navbarbox{background-color:var(--clr4);position:fixed;top:0;width:100%;z-index:10;}" ) ;
      prvA2H ( ".navbar{color:var(--clr5);display:flex;align-items:center;height:var(--navbarH);width:var(--navbarW);z-index:20;}" ) ;
      prvA2H ( ".navlogo{margin-right:auto;}" ) ;
      prvA2H ( ".navlogo img{height:var(--navlogoH);}" ) ;
      prvA2H ( ".navlink{margin-left:auto;}" ) ;
      prvA2H ( ".navlink a , .footerbox a {color:var(--clr5);text-decoration:none;margin-left:var(--navlinkS);}" ) ;
      prvA2H ( ".contentbox{margin-top:var(--navbarH);flex-direction: column;width:100%;}" ) ;
      prvA2H ( ".line{height: var(--lineH);}" ) ;
      prvA2H ( ".line:hover{color:var(--clr5);font-weight: bold;}" ) ;
      prvA2H ( ".subtot{height: var(--lineH);color:var(--clr2);}" ) ;
      prvA2H ( ".subtot:hover{color:green;font-weight: bold;}" ) ;
      prvA2H ( ".lineheader{background-color: var(--clr4);font-weight:bold;position:sticky;top:var(--navbarH);height:var(--headerH);z-index:5}" ) ;
      prvA2H ( ".footerbox{text-align: center;background-color:var(--clr4);height:var(--footerH);width:100%;}" ) ;
      prvA2H ( ".wp200{width: 200px;}.wp150{width: 150px;}.wp100{width: 100px;}.wp75{width: 75px;}" ) ;
      prvA2H ( ".h5{height:5vh;}.h15{height:15vh;}.h20{height:20vh;}.h25{height:25vh;}.h80{height:80vh;}" ) ;
      prvA2H ( ".w20{width:20%;}.w25{width:25%;}.w40{width:40%;}.w50{width:50%;}.w60{width:60%;}" ) ;
      prvA2H ( ".fl{float:left;}.fr{float:right;}.fcc{display:flex;align-items:center;justify-content:center;}" ) ;
      prvA2H ( "#backbutton:hover {cursor:pointer;}" ) ;
      prvA2H ( "@media screen and (max-width:767px){.field:not(.mobile),.footerbox:not(.mobile) {display:none}}" ) ;
      if ( StringFind ( safRules , "A" , 0 ) >= 0 ) {
         prvA2H ( ".perf-section{width:55%;float:left;}" ) ;
         prvA2H ( ".perf-header{float:left;display:flex;justify-content: center;font-size: 1.5em;color:var(--clr5)}" ) ;
         prvA2H ( ".perf-main{float:left;display:flex;justify-content: center;font-size: 6em;margin-top: 20px;}" ) ;
         prvA2H ( ".perf-submain{float:left;display:flex;justify-content: center;font-size: 3.5em;}" ) ;
         prvA2H ( ".perf-table-text{margin-bottom: 12px;font-size: 1.3em;}" ) ;
         prvA2H ( ".perf-table-number{margin-bottom: 12px;font-size: 1.3em;text-align:right;}" ) ; }
      if ( StringFind ( safRules , "B" , 0 ) >= 0 ) {
         prvA2H ( ".search-header {font-size:2.2em;padding:10px;color:var(--clr5);}" ) ;
         prvA2H ( ".search-text{min-height:50px;min-width:300px;font-size:1.2em;margin:20px;width:50%;text-align:center;}" ) ;
         prvA2H ( ".search-error{min-height:20px;font-size:1em;text-align:center;color:red;}" ) ;
         prvA2H ( ".search-button{height:90px;margin:10px;}" ) ; }
      prvA2H ( "</style>" ) ;
      prvA2H ( "<script>" ) ;
      prvA2H ( "  document.addEventListener('DOMContentLoaded', function() {" ) ;
      prvA2H ( "     document.getElementById('backbutton').addEventListener('click', function() {" ) ;
      prvA2H ( "        window.history.back();});});" ) ;
      prvA2H ( "</script> " ) ;
      prvA2H ( "</head>" ) ;
      prvA2H ( "<body>" ) ;
      prvA2H ( "<div class='navbarbox'>" ) ; // Start of NavBarBox
      prvA2H ( "<div class='navbar'>" ) ; // Start of NavBar
      prvA2H ( "<div class='navlogo'>" ) ; // Start of Logo
      prvA2H ( "<a href='https://snrobotix.com'>" ) ;
      prvA2H ( "<img src='https://sherifawzi.github.io/Pics/SNR.png' alt='Logo'>" ) ;
      prvA2H ( "</a>" ) ;
      prvA2H ( "</div>" ) ; // End of Logo
      prvA2H ( "<div class='navlink'>" ) ; // Start of Links
      if ( StringFind ( safRules , "5" , 0 ) >= 0 ) { prvA2H ( "<a id='backbutton'>BACK</a>" ) ; }
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) { prvA2H ( "<a href='http://snrpro.dk/'>SEARCH</a>" ) ; }
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) { prvA2H ( "<a href='https://snrobotix.com'>HOME</a>" ) ; }
      if ( StringFind ( safRules , "3" , 0 ) >= 0 ) { prvA2H ( "<a href='mailto:hello@snrobotix.com'>CONTACT US</a>" ) ; }
      prvA2H ( "</div>" ) ; // End of Links
      prvA2H ( "</div>" ) ; // End of NavBar
      prvA2H ( "</div>" ) ; // End of NavBarBox
      if ( StringFind ( safRules , "4" , 0 ) >= 0 ) {
         prvA2H ( "<div class='contentbox h80'>" ) ; // Start of ContentBox
      } else {
         prvA2H ( "<div class='contentbox'>" ) ; }} // Start of ContentBox all screen height

   void goSNR_HTML_Footer ( string safRules="1" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // RULE 1: Add Last Update footer
      // RULE 2: Add copyright footer
      prvA2H ( "</div>" ) ; // End of ContentBox
      prvA2H ( "<div class='footerbox'>" ) ; // Start of Footer
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         prvA2H ( "Last updated: " + string ( TimeGMT() ) + " GMT" ) ; }
      else if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
         string safThisYear = StringSubstr ( goGetDateTime() , 0 , 2 ) ;
         string safCopyRight = "\x00A9" ;
         prvA2H ( "<p>" + safCopyRight + " 2022-20" + safThisYear + " SNRobotiX ApS. All Rights Reserved. | Applebys Pl. 7, 1411 København | Email:<a href='mailto:hello@snrobotix.com'>hello@snrobotix.com</a></p>" ) ; }
      prvA2H ( "</div>" ) ; // End of Footer
      prvA2H ( "</body>" ) ; // End of Body
      prvA2H ( "</html>" ) ; // End of HTML
      // -------------------- Write remaining data before closing here
      goPrint ( "Data sent to server in " + string ( prvA2H ( "--FLUSH--" ) ) + " bits " ) ; }

   void goSNR_HTML_SearchPage () {
      glb_ServerPHP = "saveeofn.php" ;
      glb_ServerPath = "/PERFHIST/" ;
      glb_ServerFileName = "search.html" ;
      goSNR_HTML_Header ( "34B" ) ;
         // -------------------- SEARCH HEADER
         prvA2H ( "<div class='search-header'>SNR | Performance</div>" ) ;
         // -------------------- SEARCH TEXTBOX
         prvA2H ( "<input type='text' id='accountNumber' placeholder='Enter Account Number' class='search-text field mobile'>" ) ;
         // -------------------- SEARCH ERROR MESSAGES
         prvA2H ( "<div id='error_message' class='search-error error-message snrfont'></div>" ) ;
         // -------------------- SEARCH BUTTON
         prvA2H ( "<a href='#' onclick='GoCheckAccountHistory(); return false;'>" ) ;
         prvA2H ( "<img src='https:/sherifawzi.github.io/Pics/ExitDoor.png' alt='search' class='search-button' title='Retrieve account trading history'>" ) ;
         prvA2H ( "</a>" ) ;
         prvA2H ( "<script>" ) ;
         prvA2H ( "  document.getElementById('accountNumber').addEventListener('keydown', function(event) {" ) ;
         prvA2H ( "    if (event.keyCode === 13) {" ) ;
         prvA2H ( "      event.preventDefault();" ) ;
         prvA2H ( "      GoCheckAccountHistory();}});" ) ;
         prvA2H ( " function GoCheckAccountHistory() { var safAccount = " ) ;
         prvA2H ( "   document.getElementById('accountNumber').value;" ) ;
         prvA2H ( "     if (safAccount.length < 3) { var errorMessage = " ) ;
         prvA2H ( "       document.getElementById('error_message'); errorMessage.textContent = " ) ;
         prvA2H ( "       'Invalid Account Number!'; return; }" ) ;
         prvA2H ( "   var pageExists = checkPageExists(safAccount);" ) ;
         prvA2H ( "   if (pageExists) {" ) ;
         prvA2H ( "     window.location.href = '/PERFHIST/' + safAccount + '.html';" ) ;
         prvA2H ( "   } else {" ) ;
         prvA2H ( "     var errorMessage = document.getElementById('error_message'); " ) ;
         prvA2H ( "     errorMessage.textContent = 'Account History Not Found!'; return; }}" ) ;
         prvA2H ( " function checkPageExists(accountNumber) {" ) ;
         prvA2H ( "   var xhr = new XMLHttpRequest(); xhr.open('HEAD', '/PERFHIST/' + accountNumber + '.html', " ) ;
         prvA2H ( "   false); xhr.send(); return xhr.status != 404; }" ) ;
         prvA2H ( "</script>" ) ;
      goSNR_HTML_Footer ( "2" ) ; }

   void goSNR_OTP_LoginPage () {
      glb_ServerPHP = "saveeofn.php" ;
      glb_ServerPath = "/ONETIME/" ;
      glb_ServerFileName = "otplogin.html" ;
      goSNR_HTML_Header ( "34B" ) ;
        prvA2H ( "<form action='sendotp.php' method='post'>" ) ;
        prvA2H ( "<div class='search-header'><label for='clientemail'>SNR | Client Login</label></div>" ) ;
        prvA2H ( "<input type='text' name='clientemail' id='clientemail' placeholder='Enter Your Email' class='search-text field mobile'>" ) ;
        prvA2H ( "<div id='error_message' class='search-error error-message snrfont'></div>" ) ;
        prvA2H ( "<input type='image' src='https:/sherifawzi.github.io/Pics/ExitDoor.png' alt='search' class='search-button' title='Click to Login'>" ) ;
        prvA2H ( "</form>" ) ;
      goSNR_HTML_Footer ( "2" ) ; }

   void goSNR_OTP_LoginPHP () {
      glb_ServerPHP = "saveeofn.php" ;
      glb_ServerPath = "/ONETIME/" ;
      glb_ServerFileName = "sendotp.php" ;
      string sD = CharToString (34) ;
      prvA2H ( "--NEWFILE--" ) ;
         prvA2H ( "<?php" ) ;
         prvA2H ( "if(isset($_POST['clientemail'])){" ) ;
         prvA2H ( "  $clientemail = $_POST['clientemail'];" ) ;
         prvA2H ( "  $encoded = base64_encode($clientemail);" ) ;
         prvA2H ( "  $bot = '6385486447:AAEZCGszJz5U-71Dm8lrePiUsZR6sPx2Y18';" ) ;
         prvA2H ( "  $channel = '-1002087660238';" ) ;
         prvA2H ( "  header(" + sD + "Location: https://api.telegram.org/bot$bot/sendmessage?chat_id=$channel&text=$encoded" + sD + ");" ) ;
         prvA2H ( "  exit;}" ) ;
         prvA2H ( "?>" ) ;
      prvA2H ( "--FLUSH--" ) ; }

   void goSNR_OTP_VerifyPage () {
      glb_ServerPHP = "saveeofn.php" ;
      glb_ServerPath = "/ONETIME/" ;
      glb_ServerFileName = "otpverify.html" ;
      goSNR_HTML_Header ( "534B" ) ;
        prvA2H ( "<form action='verifyotp.php' method='post'>" ) ;
        prvA2H ( "<div class='search-header'><label for='otpphrase'>SNR | OTP Verify</label></div>" ) ;
        prvA2H ( "<input type='text' name='otpphrase' id='otpphrase' placeholder='Enter Your One Time Password' class='search-text field mobile'>" ) ;
        prvA2H ( "<div id='error_message' class='search-error error-message snrfont'></div>" ) ;
        prvA2H ( "<input type='image' src='https:/sherifawzi.github.io/Pics/ExitDoor.png' alt='search' class='search-button' title='Click to Verify'>" ) ;
        prvA2H ( "</form>" ) ;
      goSNR_HTML_Footer ( "2" ) ; }

   void goSNR_OTP_VerifyPHP () {
      glb_ServerPHP = "saveeofn.php" ;
      glb_ServerPath = "/ONETIME/" ;
      glb_ServerFileName = "verifyotp.php" ;
      string sD = CharToString (34) ;
      prvA2H ( "--NEWFILE--" ) ;
         prvA2H ( "<?php" ) ;
         prvA2H ( "if(isset($_POST['otpphrase'])){" ) ;
         prvA2H ( "  $otpphrase = $_POST['otpphrase'];" ) ;
         prvA2H ( "  $bot = '6385486447:AAEZCGszJz5U-71Dm8lrePiUsZR6sPx2Y18';" ) ;
         prvA2H ( "  $channel = '-1002087660238';" ) ;
         prvA2H ( "  header(" + sD + "Location: https://api.telegram.org/bot$bot/sendmessage?chat_id=$channel&text=$otpphrase Verified" + sD + ");" ) ;
         prvA2H ( "  exit;}" ) ;
         prvA2H ( "?>" ) ;
      prvA2H ( "--FLUSH--" ) ; }

   //===========================================================================================================
   //=====                                             SERVER                                              =====
   //===========================================================================================================

   string goURLEncode ( string safInput ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      StringReplace ( safInput , " " , "%20" ) ;
      StringReplace ( safInput , "!" , "%21" ) ;
      StringReplace ( safInput , "'" , "%27" ) ;
      StringReplace ( safInput , "<" , "%3C" ) ;
      StringReplace ( safInput , ">" , "%3E" ) ;
      StringReplace ( safInput , "/" , "%2F" ) ;
      StringReplace ( safInput , "#" , "%23" ) ;
      StringReplace ( safInput , "+" , "%2B" ) ;
      StringReplace ( safInput , "&" , "%26" ) ;
      return safInput ; }

   void goServer_Write_String (
      string safTextToAdd ,
      string safWriteAppend = "a" ,
      int safTimeOut = 6000 ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         if ( glb_SilentMode == true ) { return ; }
         if ( glb_Write2Server == false ) { return ; }
         // -------------------- variables
         char safData[] , safResult[] ;
         string safResultHeaders , safURL , safHeaders ;
         // -------------------- Declares
         safURL =  glb_ServerIP + glb_ServerPHP + "?var1=" + glb_ServerPath + "&var2=" ;
         safURL += glb_ServerFileName + "&var3=" + safTextToAdd + "&var4=" + safWriteAppend ;
         safHeaders = "Content-Type: application/x-www-form-urlencoded" ;
         // -------------------- Main function here
         int res = WebRequest ( "POST" , safURL , safHeaders , safTimeOut , safData , safResult , safResultHeaders ) ; }

   bool goServer_ReadFile ( string safURL , string &AllMessages[] , string sStartDateTime="" , string sEndDateTime="" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { ArrayResize ( AllMessages , 0 ) ; return false ; }
      // -------------------- Read file content
      string safHTML = goRead_Website ( safURL , safURL ) ;
      if ( StringLen ( safHTML ) < 1 ) { return false ; }
      // -------------------- Split message by start and clear html
      string Result1[] , Result2[] ;
      StringReplace ( safHTML , glb_MsgStart , CharToString ( 1 ) ) ;
      StringSplit ( safHTML , 1 , Result1 ) ;
      safHTML = "" ;
      // -------------------- Clear output array here
      ArrayResize ( AllMessages , 0 ) ;
      // -------------------- Go thru message and split by end
      for ( int i=1 ; i<ArraySize ( Result1 ) ; i++ ) {
         StringReplace ( Result1 [ i ] , glb_MsgEnd , CharToString ( 1 ) ) ;
         StringSplit ( Result1 [ i ] , 1 , Result2 ) ;
         // -------------------- Check length and split into msg bits
         if ( ArraySize ( Result2 ) < 1 ) { continue ; }
         if ( StringLen ( UT ( Result2 [ 0 ] ) ) < 1 ) { continue ; }
         string LineBits [] ;
         StringSplit ( Result2 [ 0 ] , StringGetCharacter ( "|" , 0 ) , LineBits ) ;
         // -------------------- this removes anything that is time or test bots
         if ( ArraySize ( LineBits ) < 2 ) { continue ; }
         // -------------------- this removes anything earlier than select date
         if ( StringLen ( sStartDateTime ) > 0 ) { if ( LineBits [ 1 ] < sStartDateTime ) { continue ; }}
         if ( StringLen ( sEndDateTime ) > 0 ) { if ( LineBits [ 1 ] >= sEndDateTime ) { continue ; }}
         // -------------------- If it passes conditiond add to output array
         int sArraySize = ArraySize ( AllMessages ) ;
         ArrayResize ( AllMessages , ( sArraySize + 1 ) ) ;
         AllMessages [ sArraySize ] = Result2 [ 0 ] ; }
      return true ; }

   //===========================================================================================================
   //=====                                            HISTORY                                              =====
   //===========================================================================================================

   void goHistory_Retreive ( string &HistoryLines[] , string sStartDateTime="" , string sEndDateTime="" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- x
      ArrayResize ( HistoryLines , 0 ) ;
      // -------------------- Variables
      datetime safFromDate = datetime ( "01-01-2000" ) ;
      datetime safToDate = datetime ( "01-01-2050" ) ;
      // -------------------- Date Calculations
      if ( sStartDateTime != "" ) { safFromDate = datetime ( sStartDateTime ) ; }
      if ( sEndDateTime != "" ) { safToDate = datetime ( sEndDateTime ) ; }
      // -------------------- Get history for period
      if ( !HistorySelect ( safFromDate , safToDate ) ) { return ; }
      // -------------------- Go thru history line by line
      for ( int i=0 ; i < HistoryDealsTotal() ; i++ ) {
         ulong DealTicket = HistoryDealGetTicket ( i ) ;
         // -------------------- Check
         if ( !DealTicket ) { continue ; }
         // -------------------- History line data here
         long DealType     = HistoryDealGetInteger ( DealTicket , DEAL_TYPE ) ;
         long DealTime     = HistoryDealGetInteger ( DealTicket , DEAL_TIME ) ;
         string DealCurr   = HistoryDealGetString  ( DealTicket , DEAL_SYMBOL ) ;
         double DealLot    = HistoryDealGetDouble  ( DealTicket , DEAL_VOLUME ) ;
         double DealProfit = HistoryDealGetDouble  ( DealTicket , DEAL_PROFIT ) ;
         double DealSwap   = HistoryDealGetDouble  ( DealTicket , DEAL_SWAP ) ;
         double DealFee    = HistoryDealGetDouble  ( DealTicket , DEAL_FEE ) ;
         double DealComm   = HistoryDealGetDouble  ( DealTicket , DEAL_COMMISSION ) ;
         // -------------------- Check
         if ( ( DealProfit == 0 ) && ( DealSwap == 0 ) && ( DealFee == 0 ) && ( DealComm == 0 ) ) { continue ; }
         // -------------------- Net
         double DealNetProfit = DealProfit + DealSwap + DealFee + DealComm ;
         // -------------------- Trans Deal Type
         string DealTypeTrans = "" ;
         if ( DealType == DEAL_TYPE_BUY ) { DealTypeTrans = "BUY" ; }
         else if ( DealType == DEAL_TYPE_SELL ) { DealTypeTrans = "SELL" ; }
         else if ( DealType == DEAL_TYPE_BALANCE ) { DealTypeTrans = "BALANCE" ; }
         else if ( DealType == DEAL_TYPE_CREDIT ) { DealTypeTrans = "CREDIT" ; }
         else if ( DealType == DEAL_TYPE_CORRECTION ) { DealTypeTrans = "BALANCE" ; } // This is for vantage error
         else { DealTypeTrans = "OTHER(" + (string) DealType + ")" ; }
         // -------------------- If it passes conditiond add to output array
         int sArraySize = ArraySize ( HistoryLines ) ;
         ArrayResize ( HistoryLines , ( sArraySize + 1 ) ) ;
         string result = "|" + (string) DealTicket + "|" + (string) DealTypeTrans + "|" + (string) datetime ( DealTime ) + "|" ;
         result += (string) DealCurr + "|" + (string) DealLot + "|" + (string) DealProfit + "|" + (string) DealSwap + "|" ;
         result += (string) DealFee + "|" + (string) DealComm  + "|" + goTranslate_DateTime ( datetime ( DealTime ) ) + "|" ;
         result += (string) DealNetProfit + "|" ;
         HistoryLines [ sArraySize ] = result ; }}

   void goHistory_Send2Server () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return ; }
      if ( glb_Write2Server == false ) { return ; }
      // -------------------- Get history for period
      string HistoryLines[] ;
      string AppHistoryLines[] ;
      goHistory_Retreive ( HistoryLines ) ;
      if ( ArraySize ( HistoryLines ) < 1 ) { return ; }
      // -------------------- Variables
      string LastMonth = "" , DealTypeTrans = "" , oTradedCurr = "" , mTradedCurr = "" ;
      double LastLot = 0  , LastProfit = 0  , LastSwap = 0  , LastFee = 0  , LastComm = 0  , LastNetProfit = 0  , LastBalance = 0  ;
      double totalLot = 0 , totalProfit = 0 , totalSwap = 0 , totalFee = 0 , totalComm = 0 , totalNetProfit = 0 , totalBalance = 0 ;
      double totalDeposit = 0 , totalWithdrawal = 0 , totalCredit = 0 , totalAdjust = 0 ;
      int LastTrades = 0 , totalTrades = 0 , totTradedCurr = 0 , monTradedCurr = 0 ;
      double DailyROI = 0 , LOKAAdjust = 0 , AccountBalance = 0 ;
      // -------------------- Start details file here
      glb_ServerPHP = "saveeofn.php" ;
      glb_ServerPath = "/PERFHIST/" ;
      glb_ServerFileName = string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) + "_details.html" ;
      goSNR_HTML_Header ( "53" ) ;
      // ----------------------------------------------------------------------------------CONTENT START HERE
         prvA2H ( "<div class='line'></div>" ) ;
         prvA2H ( "<div class='lineheader'>" ) ;
         prvA2H ( "<div class='field wp200'>Date/Time</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>Type</div>" ) ;
         prvA2H ( "<div class='field wp75'>Size</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>Currency</div>" ) ;
         prvA2H ( "<div class='field wp100'>Profit</div>" ) ;
         prvA2H ( "<div class='field wp100'>Swap</div>" ) ;
         prvA2H ( "<div class='field wp100'>Fees</div>" ) ;
         prvA2H ( "<div class='field wp100'>Commission</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>Net</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>Balance</div>" ) ;
         prvA2H ( "</div>" ) ;
         // -------------------- Go thru history line by line
         for ( int i=0 ; i < ArraySize ( HistoryLines ) ; i++ ) {
            string safSplit[] ; StringSplit ( HistoryLines [ i ] , StringGetCharacter ( "|" , 0 ) , safSplit ) ;
            if ( ArraySize ( safSplit ) < 12 ) { continue ; }
            // -------------------- History line data here
            ulong DealTicket     = (ulong) safSplit [ 1 ] ;
            string DealType      = safSplit [ 2 ] ;
            string DealTime      = safSplit [ 3 ] ;
            string DealCurr      = safSplit [ 4 ] ;
            double DealLot       = (double) safSplit [ 5 ] ;
            double DealProfit    = (double) safSplit [ 6 ] ;
            double DealSwap      = (double) safSplit [ 7 ] ;
            double DealFee       = (double) safSplit [ 8 ] ;
            double DealComm      = (double) safSplit [ 9 ] ;
            string DealTimeTrans = safSplit [ 10 ] ;
            double DealNetProfit = (double) safSplit [ 11 ] ;
            // -------------------- Calc dates here
            string TodaysDay = StringSubstr ( DealTimeTrans , 0 , 6 ) ;
            string TodaysMonth = StringSubstr ( DealTimeTrans , 0 , 4 ) ;
            // -------------------- LOKA SKIP
            if ( string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) == "6001227" ) {
               if ( TodaysDay == "220922" ) { LOKAAdjust = 602.18 ; continue ; }}
            // -------------------- Write Month Change data here
            if ( LastMonth != TodaysMonth ) {
               LastMonth = TodaysMonth ;
               if ( i != 0 ) {
                  // -------------------- Month result
                  prvA2H ( "<div class='subtot'>" ) ;
                  prvA2H ( "<div class='field wp200'>" + "Month Total" + "</div>" ) ;
                  prvA2H ( "<div class='field wp100 mobile'>" + string ( totalTrades - LastTrades ) + "</div>" ) ; LastTrades = totalTrades ;
                  prvA2H ( "<div class='field wp75'>" + string ( ND2 ( totalLot - LastLot ) ) + "</div>" ) ; LastLot = totalLot ;
                  prvA2H ( "<div class='field wp100 mobile'>" + string ( monTradedCurr ) + "</div>" ) ; monTradedCurr = 0 ; mTradedCurr = "" ;
                  prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalProfit - LastProfit ) ) + "</div>" ) ; LastProfit = totalProfit ;
                  prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalSwap - LastSwap ) ) + "</div>" ) ; LastSwap = totalSwap ;
                  prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalFee - LastFee ) )  + "</div>" ) ; LastFee = totalFee ;
                  prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalComm - LastComm ) )  + "</div>" ) ; LastComm = totalComm ;
                  prvA2H ( "<div class='field wp100 mobile'>" + string ( ND2 ( totalNetProfit - LastNetProfit ) ) + "</div>" ) ; LastNetProfit = totalNetProfit ;
                  prvA2H ( "<div class='field wp100 mobile'>" + "" + "</div>" ) ;
                  prvA2H ( "</div>" ) ;
                  prvA2H ( "<div class='subtot'>" ) ;
                  prvA2H ( "<div class='field wp200'>" + "Cumulative" + "</div>" ) ;
                  prvA2H ( "<div class='field wp100 mobile'>" + string ( totalTrades ) + "</div>" ) ;
                  prvA2H ( "<div class='field wp75'>" + string ( ND2 ( totalLot ) ) + "</div>" ) ;
                  prvA2H ( "<div class='field wp100 mobile'>" + string ( totTradedCurr ) + "</div>" ) ;
                  prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalProfit ) ) + "</div>" ) ;
                  prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalSwap ) ) + "</div>" ) ;
                  prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalFee ) )  + "</div>" ) ;
                  prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalComm ) )  + "</div>" ) ;
                  prvA2H ( "<div class='field wp100 mobile'>" + string ( ND2 ( totalNetProfit ) ) + "</div>" ) ;
                  prvA2H ( "<div class='field wp100 mobile'>" + "" + "</div>" ) ;
                  prvA2H ( "</div>" ) ; }}
            // -------------------- Curr count
            if ( DealCurr != "" ) {
               // -------------------- Overall Curr
               if ( StringFind ( oTradedCurr , "|"+ DealCurr + "|" , 0 ) < 0 ) {
                  oTradedCurr +=  "|"+ DealCurr + "|" ; totTradedCurr += 1 ; }
               // -------------------- Month Curr
               if ( StringFind ( mTradedCurr , "|"+ DealCurr + "|" , 0 ) < 0 ) {
                  mTradedCurr +=  "|"+ DealCurr + "|" ; monTradedCurr += 1 ; }
               // -------------------- Calc profits
               totalProfit += DealProfit ;
               totalLot += DealLot ;
               totalSwap += DealSwap ;
               totalFee += DealFee ;
               totalComm += DealComm ;
               totalNetProfit += DealNetProfit ;
               totalTrades += 1 ; }
            // -------------------- Calculations here
            totalBalance += DealNetProfit ;
            // -------------------- Clasification here
            if ( DealType == "BALANCE" ) {
               if ( DealProfit > 0 ) {
                  if ( DealProfit < 1 ) { totalAdjust += DealProfit ; DealTypeTrans = "Adjust" ; }
                  else { totalDeposit += DealProfit ; DealTypeTrans = "Deposit" ; AccountBalance += DealNetProfit ; }
               } else {
                  if ( DealProfit > -1 ) { totalAdjust += DealProfit ; DealTypeTrans = "Adjust" ; }
                  else { totalWithdrawal += DealProfit ; DealTypeTrans = "Withdraw" ; AccountBalance += DealNetProfit ; }}}
            else if ( DealType == "CREDIT" ) { totalCredit += DealProfit ; DealTypeTrans = "Credit" ; }
            else if ( DealType == "BUY" ) { DealTypeTrans = "Buy" ; DailyROI += ( DealNetProfit / AccountBalance ) * 100 ; }
            else if ( DealType == "SELL" ) { DealTypeTrans = "Sell" ; DailyROI += ( DealNetProfit / AccountBalance ) * 100 ; }
            // -------------------- Write line here
            prvA2H ( "<div class='line'>" ) ;
            prvA2H ( "<div class='field wp200'>" + string ( datetime ( DealTime ) ) + "</div>" ) ;
            prvA2H ( "<div class='field wp100 mobile'>" + string ( DealTypeTrans ) + "</div>" ) ;
            prvA2H ( "<div class='field wp75'>" + string ( DealLot ) + "</div>" ) ;
            prvA2H ( "<div class='field wp100 mobile'>" + string ( DealCurr ) + "</div>" ) ;
            prvA2H ( "<div class='field wp100'>" + string ( ND2 ( DealProfit ) ) + "</div>" ) ;
            prvA2H ( "<div class='field wp100'>" + string ( ND2 ( DealSwap ) ) + "</div>" ) ;
            prvA2H ( "<div class='field wp100'>" + string ( ND2 ( DealFee ) ) + "</div>" ) ;
            prvA2H ( "<div class='field wp100'>" + string ( ND2 ( DealComm ) ) + "</div>" ) ;
            prvA2H ( "<div class='field wp100 mobile'>" + string ( ND2 ( DealNetProfit ) ) + "</div>" ) ;
            prvA2H ( "<div class='field wp100 mobile'>" + string ( ND2 ( totalBalance ) )  + "</div>" ) ;
            prvA2H ( "</div>" ) ;
            // -------------------- Write for app raw data
            int sAppArraySize = ArraySize ( AppHistoryLines ) ;
            ArrayResize ( AppHistoryLines , ( sAppArraySize + 1 ) ) ;
            string AppResult = "|" + string ( datetime ( DealTime ) ) ;
            AppResult += "|" + string ( DealTypeTrans ) ;
            AppResult += "|" + string ( DealLot ) ;
            AppResult += "|" + string ( DealCurr ) ;
            AppResult += "|" + string ( ND2 ( DealProfit ) ) ;
            AppResult += "|" + string ( ND2 ( DealSwap ) ) ;
            AppResult += "|" + string ( ND2 ( DealFee ) ) ;
            AppResult += "|" + string ( ND2 ( DealComm ) ) ;
            AppResult += "|" + string ( ND2 ( DealNetProfit ) ) ;
            AppResult += "|" + string ( ND2 ( totalBalance ) ) + "|" ;
            AppHistoryLines [ sAppArraySize ] = AppResult ;
            } // next i
         // -------------------- Month result
         prvA2H ( "<div class='subtot'>" ) ;
         prvA2H ( "<div class='field wp200'>" + "Month Total" + "</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( totalTrades - LastTrades ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75'>" + string ( ND2 ( totalLot - LastLot ) ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( monTradedCurr ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalProfit - LastProfit ) ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalSwap - LastSwap ) ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalFee - LastFee ) )  + "</div>" ) ;
         prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalComm - LastComm ) )  + "</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( ND2 ( totalNetProfit - LastNetProfit ) ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + "" + "</div>" ) ;
         prvA2H ( "</div>" ) ;
         // -------------------- Write totals here
         prvA2H ( "<div class='subtot'>" ) ;
         prvA2H ( "<div class='field wp200'>" + "Grand Total" + "</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( totalTrades ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75'>" + string ( ND2 ( totalLot ) ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( totTradedCurr ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalProfit ) ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalSwap ) ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalFee ) ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100'>" + string ( ND2 ( totalComm ) ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( ND2 ( totalNetProfit ) ) + "</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + "" + "</div>" ) ;
         prvA2H ( "</div>" ) ;
      // ----------------------------------------------------------------------------------CONTENT END HERE
      goSNR_HTML_Footer ( "1" ) ;
      // -------------------- Set broker login link
      string safBrokerLink = "https://snrobotix.com/get-started/" ;
      string safBroker = UT ( AccountInfoString ( ACCOUNT_COMPANY ) ) ;
      if ( StringFind ( safBroker , "BLUEBERRY" , 0 ) >= 0 ) { safBrokerLink = "https://secure.blueberrymarkets.com/en/site/login" ; }
      if ( StringFind ( safBroker , "EIGHTCAP" , 0 ) >= 0 ) { safBrokerLink = "https://portal.eightcap.com/en-US/auth/login" ; }
      if ( StringFind ( safBroker , "MEX" , 0 ) >= 0 ) { safBrokerLink = "https://my.multibankfx.com/en/traders/login" ; }
      if ( StringFind ( safBroker , "VANTAGE" , 0 ) >= 0 ) { safBrokerLink = "https://secure.vantagemarkets.com/login" ; }
      if ( StringFind ( safBroker , "TRADEVIEW" , 0 ) >= 0 ) { safBrokerLink = "https://www.tradeviewforex.com/cabinet/mt5" ; }
      // -------------------- Start summary file here
      string sDetailsFileURL = glb_ServerFileName ;
      glb_ServerFileName = string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) + ".html" ;
      goSNR_HTML_Header ( "534A" ) ;
      string safToolTip = "" ;
      // ----------------------------------------------------------------------------------CONTENT START HERE
         prvA2H ( "         <div class='perf-section h5'>" ) ;
         prvA2H ( "            <div class='perf-header w50'>BALANCE</div>" ) ;
         prvA2H ( "            <div class='perf-header w50'>ROI</div>" ) ;
         prvA2H ( "         </div>" ) ;
         prvA2H ( "         <div class='perf-section h20'>" ) ;
         safToolTip = "Account Balance: Total funds in the trading account, including profits and losses" ;
         prvA2H ( "            <div class='perf-main w50' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( totalBalance ) ) )+ "</div>" ) ;
         safToolTip = "The percentage of profit made compared to the money invested in the trading account" ;
         prvA2H ( "            <div class='perf-main w50' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( DailyROI ) ) ) + "%</div>" ) ;
         prvA2H ( "         </div>" ) ;
         prvA2H ( "         <div class='perf-section h15'>" ) ;
         safToolTip = "The total profit earned from trades after deducting all fees, expenses, and losses" ;
         if ( totalNetProfit >= 0 ) {
            prvA2H ( "            <div class='perf-submain w50' style='color:green;' title='" + safToolTip + "'>+" + goFormat_NumberWithCommas ( string ( ND2 ( totalNetProfit ) ) ) + "</div>" ) ;
         } else {
            prvA2H ( "            <div class='perf-submain w50' style='color:red;' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( totalNetProfit ) ) ) + "</div>" ) ; }
         prvA2H ( "         </div>" ) ;
         prvA2H ( "         <div class='perf-section h25'>" ) ;
         prvA2H ( "            <div class='w40 fl'>" ) ;
         prvA2H ( "               <div class='w40 fl'>" ) ;
         prvA2H ( "                  <div class='perf-table-text'>Deposit:</div>" ) ;
         prvA2H ( "                  <div class='perf-table-text'>Withdrawal:</div>" ) ;
         prvA2H ( "                  <div class='perf-table-text'>Credit/Adjust:</div>" ) ;
         prvA2H ( "                  <div class='perf-table-text'>Profit:</div>" ) ;
         prvA2H ( "                  <div class='perf-table-text'>Swap:</div>" ) ;
         prvA2H ( "                  <div class='perf-table-text'>Commission:</div>" ) ;
         prvA2H ( "                  <div class='perf-table-text'>Equity:</div>" ) ;
         prvA2H ( "               </div>" ) ;
         prvA2H ( "               <div class='w40 fl'>" ) ;
         safToolTip = "Account Deposits: Total funds added to the trading account for trading purposes" ;
         prvA2H ( "                  <div class='perf-table-number' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( totalDeposit ) ) ) + "</div>" ) ;
         safToolTip = "Total Withdrawals: The cumulative amount of funds taken out from the trading account over time" ;
         prvA2H ( "                  <div class='perf-table-number' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( totalWithdrawal ) ) ) + "</div>" ) ;
         safToolTip = "Funds added to the account from promotions or bonuses as well as changes made such as corrections or misc fees" ;
         prvA2H ( "                  <div class='perf-table-number' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( totalCredit + totalAdjust ) ) ) + "</div>" ) ;
         safToolTip = "Gross Profit: The total profit earned from trades before deducting any fees or expenses" ;
         prvA2H ( "                  <div class='perf-table-number' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( totalProfit ) ) ) + "</div>" ) ;
         safToolTip = "Overnight interest paid or earned for holding positions, based on currency interest rate differentials" ;
         prvA2H ( "                  <div class='perf-table-number' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( totalSwap ) ) ) + "</div>" ) ;
         safToolTip = "Commissions: Fees charged by your broker for executing trades in the forex market" ;
         prvA2H ( "                  <div class='perf-table-number' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( totalComm ) ) ) + "</div>" ) ;
         safToolTip = "Equity: The current value of the trading account, accounting for open positions and profits/losses" ;
         if ( sEqu() > ( totalDeposit - totalWithdrawal ) ) {
            prvA2H ( "                  <div class='perf-table-number' style='color:var(--clr1);' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( sEqu() + LOKAAdjust ) ) ) + "</div>" ) ;
         } else {
            prvA2H ( "                  <div class='perf-table-number' style='color:var(--clr1);' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( sEqu() + LOKAAdjust ) ) ) + "</div>" ) ; }
         prvA2H ( "               </div>" ) ;
         prvA2H ( "            </div>" ) ;
         prvA2H ( "            <div class='w20 fl fcc'>" ) ;
         prvA2H ( "               <a href='" + string ( sDetailsFileURL ) + "' class='h25 fcc'>" ) ;
         prvA2H ( "               <img src='https://sherifawzi.github.io/Pics/TradeList.png' alt='Logo' title='Detailed account activity'>" ) ;
         prvA2H ( "               </a>" ) ;
         prvA2H ( "            </div>" ) ;
         prvA2H ( "            <div class='w20 fl fcc'>" ) ;
         prvA2H ( "               <a href='https://snrobotix.com/our-bots/' class='h25 fcc'>" ) ;
         prvA2H ( "               <img src='https://sherifawzi.github.io/Pics/PieChart.png' alt='Logo' title='Overview of traded instruments'>" ) ;
         prvA2H ( "               </a>" ) ;
         prvA2H ( "            </div>" ) ;
         prvA2H ( "            <div class='w20 fl fcc'>" ) ;
         prvA2H ( "               <a href='" + safBrokerLink + "' class='h25 fcc'>" ) ;
         prvA2H ( "               <img src='https://sherifawzi.github.io/Pics/Wallet.png' alt='Logo' title='Add funds to your wallet'>" ) ;
         prvA2H ( "               </a>" ) ;
         prvA2H ( "            </div>" ) ;
         prvA2H ( "         </div>" ) ;
         prvA2H ( "<div class='line'></div>" ) ;
      // ----------------------------------------------------------------------------------CONTENT END HERE
      goSNR_HTML_Footer ( "1" ) ;
      // -------------------- Get open positions for app
      string AllPositions[] ;
      goPositions_Retreive( AllPositions ) ;
      // -------------------- Write App file
      glb_ServerFileName = string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) + ".raw" ;
      prvA2H ( "--NEWFILE--" ) ;
      for ( int appC = 0 ; appC < ArraySize ( AppHistoryLines ) ; appC++ ) {
         // prvA2H ( "|HISTORYLINE" + AppHistoryLines [ appC ] ) ; }
         prvA2H ( "|HL" + AppHistoryLines [ appC ] ) ; }
      for ( int appC = 0 ; appC < ArraySize ( AllPositions ) ; appC++ ) {
         // prvA2H ( "|OPENPOSITIONS" + AllPositions [ appC ] ) ; }
         prvA2H ( "|OP" + AllPositions [ appC ] ) ; }
         prvA2H ( "|BN|" + AccountInfoString ( ACCOUNT_COMPANY ) + "|" ) ;
         prvA2H ( "|BL|" + safBrokerLink + "|" ) ;
         prvA2H ( "|BC|" + UT ( AccountInfoString ( ACCOUNT_CURRENCY ) ) + "|" ) ;
         prvA2H ( "|BAL|" + string ( totalBalance ) + "|" ) ;
         prvA2H ( "|ROI|" + string ( DailyROI ) + "|" ) ;
         prvA2H ( "|PNL|" + string ( totalNetProfit ) + "|" ) ;
         prvA2H ( "|DP|" + string ( totalDeposit ) + "|" ) ;
         prvA2H ( "|WD|" + string ( totalWithdrawal ) + "|" ) ;
         prvA2H ( "|CR|" + string ( totalCredit ) + "|" ) ;
         // prvA2H ( "|xxx|" + string ( xxx ) + "|" ) ;
      goPrint ( "Data sent to server in " + string ( prvA2H ( "--FLUSH--" ) ) + " bits " ) ; }

   int prvA2H ( string safInput , int safMaxLength=500 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return ( 0 ) ; }
      if ( glb_Write2Server == false ) { return ( 0 ) ; }
      if ( StringLen ( glb_ServerFileName ) < 1 ) { return ( 0 ) ; }
      // -------------------- Clean input
      safInput = goTrim ( safInput ) ;
      // -------------------- Variables
      static string safString2Write ;
      static int safCount = 0 ;
      bool safWrite2Server = false ;
      string safWriteType = "a" ;
      if ( safCount == 0 ) { safWriteType = "w" ; }
      // -------------------- Reset check
      if ( safInput == "--FLUSH--" ) { safWrite2Server = true ; }
      // -------------------- New file marker
      else if ( safInput == "--NEWFILE--" ) {
         safString2Write = "" ;
         safCount = 0 ;
         return ( 0 ) ; }
      // -------------------- Create new file with header
      else if ( ( StringLen ( safString2Write ) + StringLen ( safInput ) ) > safMaxLength ) {
         safWrite2Server = true ;
      } else {
         safString2Write += "%0D%0A" + safInput ; }
      if ( safWrite2Server == true ) {
         goServer_Write_String ( goURLEncode ( safString2Write ) , safWriteType ) ;
         if ( safInput == "--FLUSH--" ) { safString2Write = "" ; } else { safString2Write = safInput ; }
         safCount += 1 ; } return safCount ; }

   //===========================================================================================================
   //=====                                            SECURITY                                             =====
   //===========================================================================================================

   bool goSecurity_CheckAccountType ( ENUM_ACCOUNT_TRADE_MODE safAllowedMode ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // ACCOUNT_TRADE_MODE_DEMO // ACCOUNT_TRADE_MODE_CONTEST // ACCOUNT_TRADE_MODE_REAL
      if ( AccountInfoInteger ( ACCOUNT_TRADE_MODE ) == safAllowedMode ) { return true ; }
      goPrint ( "Robot not allowed on this account type!" ) ; ExpertRemove () ;
      return false ; }

   bool goSecurity_CheckAccountSymbols ( string safAllowedSymbol ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_EAS == safAllowedSymbol ) { return true ; }
      goPrint ( "Symbol " + glb_EAS + " not allowed for this robot!" ) ; ExpertRemove () ;
      return false ; }

   bool goSecurity_CheckExpiryDate ( datetime safBuildDate , int safValidityInDays=7 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( !safBuildDate ) { safBuildDate = __DATETIME__ ; }
      datetime safExpiryDate = safBuildDate + ( safValidityInDays * 86400 ) ;
      goPrint ( "Robot license valid until " + string ( safExpiryDate ) ) ;
      if ( TimeCurrent() < safExpiryDate ) { return true ; }
      goPrint ( "Robot already expired!" ) ; ExpertRemove () ;
      return false ; }

   bool goSecurity_CheckLicense ( string safLicenseKey ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string safGeneratedKey = goSecurity_Encoder ( IntegerToString ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ) ;
      if ( safGeneratedKey == safLicenseKey ) { return true ; }
      goPrint ( "License check failed!" ) ; ExpertRemove () ;
      return false ; }

   string goSecurity_Encoder (
      string safInput ,
      string safKey = "tospcpujyjtuifcftudpnqbozjouifxpsmezbtfntfn" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         uchar safKeyChar [] ; StringToCharArray ( safKey , safKeyChar ) ;
         uchar safInputChar [] ; StringToCharArray ( ( safInput + safKey ) , safInputChar ) ;
         uchar safResultChar [] ;
         CryptEncode ( CRYPT_HASH_SHA256 , safInputChar , safKeyChar , safResultChar ) ;
         CryptEncode ( CRYPT_BASE64 , safResultChar , safResultChar , safResultChar ) ;
         return ( CharArrayToString ( safResultChar ) ) ; }

   bool goSecurity_VersionCheck ( string sBotType ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- Variables
      string safVersion = goTranslate_DateTime ( __DATETIME__ ) ;
      // -------------------- Contact expiry server and check expiry
      string safHTML = goRead_Website ( "https://sherifawzi.github.io/Tools/Dist" ) ;
      // -------------------- Abort if unable to contact server
      if ( StringLen ( UT ( safHTML ) ) < 1 ) {
         // goPrint ( "Unable to contact server" ) ;
         ExpertRemove () ; return false ; }
      // -------------------- Split HTML by lines
      string safArray [] ;
      string safLineSplit [] ;
      StringSplit ( safHTML , '\n' , safArray ) ;
      // -------------------- Check version here
      for ( int i=0 ; i < ArraySize ( safArray ) ; i++ ) {
         StringSplit ( safArray [ i ] , StringGetCharacter ( "|" , 0 ) , safLineSplit ) ;
         if ( ArraySize ( safLineSplit ) < 3 ) { continue ; }
         string safKey = safLineSplit [ 1 ] ;
         string safValue = safLineSplit [ 2 ] ;
         if ( UT ( safKey ) == UT ( sBotType ) ) {
            if ( long ( safVersion ) < long ( safValue ) ) {
               goPrint ( "A newer verion exists" ) ;
               ExpertRemove () ; return false ;
            } else {
               goPrint ( "Version check passed" ) ;
               return true ; }}}
         Print ( "Unable to verify version" ) ;
         ExpertRemove () ; return false ; }

   //===========================================================================================================
   //=====                                         COUNT FUNCTIONS                                         =====
   //===========================================================================================================

   int goCount_OrdersTotal () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( OrdersTotal () < 1 ) { return ( 0 ) ; }
      return ( int ( prvOrder_Analytics ( "A" ) ) ) ; }

   int goCount_OrdersBuy () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( OrdersTotal () < 1 ) { return ( 0 ) ; }
      return ( int ( prvOrder_Analytics ( "B" ) ) ) ; }

   int goCount_OrdersSell () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( OrdersTotal () < 1 ) { return ( 0 ) ; }
      return ( int ( prvOrder_Analytics ( "C" ) ) ) ; }

   int goCount_PositionsTotal () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; }
      return ( int ( prvPosition_Analytics ( "A" ) ) ) ; }

   int goCount_PositionsBuy () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; }
      return ( int ( prvPosition_Analytics ( "B" ) ) ) ; }

   int goCount_PositionsSell () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; }
      return ( int ( prvPosition_Analytics ( "C" ) ) ) ; }

   int goCount_NoSLPositions ( string safFilter="12" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; }
      return int ( prvPosition_Analytics ( "D" , safFilter ) ) ; }

   int goCount_NoSLBuyPositions ( string safFilter="12" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; }
      return int ( prvPosition_Analytics ( "O" , safFilter ) ) ; }

   int goCount_NoSLSellPositions ( string safFilter="12" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; }
      return int ( prvPosition_Analytics ( "P" , safFilter ) ) ; }

   //===========================================================================================================
   //=====                                         CLOSE FUNCTIONS                                         =====
   //===========================================================================================================

   void goClose_AllBuyPositions ( double safMinProfit=-999999 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      prvPosition_Closer ( "A" , safMinProfit ) ; }

   void goClose_AllSellPositions ( double safMinProfit=-999999 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      prvPosition_Closer ( "B" , safMinProfit ) ; }

   void goClose_PositivePositions ( double safMinProfit=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      prvPosition_Closer ( "C" , safMinProfit ) ; }

   void goClose_PositionWithComment ( string safText , double safMinProfit=-999999 , string safFilter="" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      prvPosition_Closer ( "D" , safMinProfit , safFilter , safText ) ; }

   void goClose_BiggestProfitPosition () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      goBroadcast_SIG ( goTele_PrepMsg ( "CBPP" ) ) ;
      trade.PositionClose ( goFind_BiggestProfitPosition () ) ; }

   void goClose_BiggestLossPosition () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      goBroadcast_SIG ( goTele_PrepMsg ( "CBLP" ) ) ;
      trade.PositionClose ( goFind_BiggestLossPosition () ) ; }

   void goClose_AllOrders () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( OrdersTotal () < 1 ) { return ; }
      goBroadcast_SIG ( goTele_PrepMsg ( "CAO" ) ) ;
      do { prvOrder_Closer ( "A" , 0 ) ; } while ( goCount_OrdersTotal () > 0 ) ; }

   void goClose_AllPositions () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      goBroadcast_SIG ( goTele_PrepMsg ( "CAP" ) ) ;
      do { prvPosition_Closer ( "C" , -9999999 ) ; } while ( goCount_PositionsTotal () > 0 ) ; }

   void goClose_AllPositionsByForce () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      goBroadcast_SIG ( goTele_PrepMsg ( "FCAP" ) ) ;
      do { for ( int i = PositionsTotal () - 1 ; i >= 0 ; i-- ) {
         ulong safTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( safTicket ) ) { continue ; }
         trade.PositionClose ( safTicket ) ; }
      } while ( PositionsTotal () > 0 ) ; }

   void goClose_AllOrdersByForce () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( OrdersTotal () < 1 ) { return ; }
      goBroadcast_SIG ( goTele_PrepMsg ( "FCAO" ) ) ;
      do { for ( int i = OrdersTotal () - 1 ; i >= 0 ; i-- ) {
         ulong safTicket = OrderGetTicket ( i ) ;
         if ( !OrderSelect ( safTicket ) ) { continue ; }
         trade.OrderDelete ( safTicket ) ; }
      } while ( OrdersTotal () > 0 ) ; }

   void goClose_Amount_Percent ( double safPercentOverall=0 , double safPercentPerTrade=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ; }
      if ( ( safPercentOverall == 0 ) && ( safPercentPerTrade == 0 ) ) { return ; }
      double safBal = sBal() ;
      double safEqu = sEqu() ;
      if ( safEqu < safBal ) { return ; }
      double safOnePercent = safBal / 100 ;
      if ( safPercentOverall > 0 ) {
         double safTarget = safBal + ( safOnePercent * safPercentOverall ) ;
         if ( safEqu >= safTarget ) { goClose_AllPositions () ; }}
      if ( safPercentPerTrade > 0 ) {
         double safTarget = safBal + ( safOnePercent * safPercentPerTrade * goCount_PositionsTotal() ) ;
         if ( safEqu >= safTarget ) { goClose_AllPositions () ; }}}

   void goClose_OldPositions ( long safTicket , int safVal01 , double safVal02 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( safVal01 > 0 ) {
         MqlDateTime safDateTime ;
         string result = "" ;
         TimeToStruct ( ( TimeGMT () - PositionGetInteger ( POSITION_TIME ) ) , safDateTime ) ;
         int safCalcMinutes = ( ( safDateTime.day - 1 ) * 1440 ) + ( safDateTime.hour * 60 ) + safDateTime.min ;
         if ( safCalcMinutes >= ( safVal01 * 1440 ) ) { result += "Y" ; }
         if ( safVal02 > 0 ) { if ( sProfit() >= safVal02 ) { result += "Y" ; } else { result += "X" ; } }
         if ( ( result == "Y" ) || ( result == "YY" ) || ( result == "YYY" ) ) { trade.PositionClose ( safTicket ) ; }}} // missing broadcast message

   void goTrim_Orders ( double safUpper , double safLower ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      prvOrder_Closer ( "A" , safUpper ) ;
      prvOrder_Closer ( "B" , safLower ) ; }

   void goClose_OnRSI ( string safRules="1" , double safMinProfit=-999999 , double safBTrigger=55 , int safPeriod=2 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // RULE 1: Close all on trigger
      // RULE 2: Close buy or sell on trigger
      if ( PositionsTotal () < 1 ) { return ; }
      if ( safPeriod > 0 ) {
         double safSTrigger = 100 - safBTrigger ;
         // -------------------- handle indicator here
         if ( ind_RSI ( safPeriod ) == false ) {
            goPrint ( "Unable to close on RSI due to indicator load error" ) ;
            return ; }
         double RSI_C = B0 [ glb_FC ] ;
         double RSI_L = B0 [ glb_FC + 1 ] ;
         // -------------------- RULE 1
         if ( ( StringFind ( safRules , "1" , 0 ) >= 0 ) ) {
            if ( ( ( RSI_C > safBTrigger ) && ( RSI_L < safBTrigger ) ) ||
            ( ( RSI_C < safSTrigger ) && ( RSI_L > safSTrigger ) ) ) { goClose_PositivePositions ( safMinProfit ) ; }}
         // -------------------- RULE 2
         if ( ( StringFind ( safRules , "2" , 0 ) >= 0 ) ) {
            if ( ( RSI_C > safBTrigger ) && ( RSI_L < safBTrigger ) ) { goClose_AllSellPositions ( safMinProfit ) ; }
            if ( ( RSI_C < safSTrigger ) && ( RSI_L > safSTrigger ) ) { goClose_AllBuyPositions ( safMinProfit ) ; }}}}

   //===========================================================================================================
   //=====                                         FIND FUNCTIONS                                          =====
   //===========================================================================================================

   ulong goFind_BiggestLossPosition () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; }
      return ( ulong ( prvPosition_Analytics ( "I" ) ) ) ; }

   ulong goFind_SmallestLossPosition () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; }
      return ( ulong ( prvPosition_Analytics ( "K" ) ) ) ; }

   ulong goFind_BiggestProfitPosition () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; }
      return ( ulong ( prvPosition_Analytics ( "H" ) ) ) ; }

   ulong goFind_SmallestProfitPosition () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; }
      return ( ulong ( prvPosition_Analytics ( "J" ) ) ) ; }

   double goFind_High ( int NoOfCandles=7 , int StartCandle=1 , int ResultType=2 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      // 1 - Candle Number
      // 2 - Candle Value
      double result = 0 ;
      CopyHigh ( glb_EAS , glb_EAP , StartCandle , NoOfCandles , B4 ) ;
      int ArrayMax = ArrayMaximum ( B4 ) ;
      double ArrayMaxValue = B4 [ ArrayMax ] ;
      if ( ResultType == 1 ) { result = ArrayMax ; }
      if ( ResultType == 2 ) { result = ArrayMaxValue ; }
      return result ; }

   double goFind_Low ( int NoOfCandles=7 , int StartCandle=1 , int ResultType=2 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goClearBuffers () ;
      // 1 - Candle Number
      // 2 - Candle Value
      double result = 0 ;
      CopyLow ( glb_EAS , glb_EAP , StartCandle , NoOfCandles , B4 ) ;
      int ArrayMin = ArrayMinimum ( B4 ) ;
      double ArrayMinValue = B4 [ ArrayMin ] ;
      if ( ResultType == 1 ) { result = ArrayMin ; }
      if ( ResultType == 2 ) { result = ArrayMinValue ; }
      return result ; }

   long goFind_TickVolumeMax ( int NoOfCandles=7 , int StartCandle=1 , int ResultType=2 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // 1 - Candle Number
      // 2 - Candle Value
      long result = 0 ;
      long BTV[] ; ArraySetAsSeries( BTV , true ) ;
      CopyTickVolume ( glb_EAS , glb_EAP , StartCandle , NoOfCandles , BTV ) ;
      int ArrayMax = ArrayMaximum ( BTV ) ;
      long ArrayMaxValue = BTV [ ArrayMax ] ;
      if ( ResultType == 1 ) { result = ArrayMax ; }
      if ( ResultType == 2 ) { result = ArrayMaxValue ; }
      return result ; }

   string goFind_LowXCandlesAway ( int NoOfCandles , int StartCandle , int XCandlesAway ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( ( (int) goFind_Low ( NoOfCandles , StartCandle , 1 ) ) == ( StartCandle + XCandlesAway ) ) { return "Y" ; } else { return "X" ; } }

   string goFind_HighXCandlesAway ( int NoOfCandles , int StartCandle , int XCandlesAway ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( ( (int) goFind_High ( NoOfCandles , StartCandle , 1 ) ) == ( StartCandle + XCandlesAway ) ) { return "Y" ; } else { return "X" ; } }

   string goFind_HighLowInXCandles ( int NoOfCandles=7 , int StartCandle=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      if ( ( (int) goFind_Low ( NoOfCandles , StartCandle , 1 ) ) == StartCandle ) { result += "B" ; }
      else if ( ( (int) goFind_High ( NoOfCandles , StartCandle , 1 ) ) == StartCandle ) { result += "S" ; }
      else { return "X" ; }
      return result ; }

   //===========================================================================================================
   //=====                                        OTHER SIGNALS                                            =====
   //===========================================================================================================

   string goOnTickOpportunist ( string safRules="1" , int safTrigger=100 , double safAverageMultiple=3 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "X" ;
      // RULE 1: return buy/sell signals
      // RULE 2: return tick average
      // RULE 3: return last tick size
      static string safString ;
      static int safCounter ;
      static double safAverage ;
      static double LastPrice ;
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      double CurrentPrice = glb_PI[ glb_FC ].close ;
      if ( safCounter > 0 ) {
         safString += string ( MathAbs ( CurrentPrice - LastPrice ) ) + "|" ; }
      if ( safCounter > safTrigger ) {
         safAverage = goCalc_AverageOfString ( safString ) ;
         safCounter = 0 ;
         safString = "" ; }
      if ( safAverage > 0 ) {
         if ( ( MathAbs ( CurrentPrice - LastPrice ) ) >= ( safAverage * safAverageMultiple ) ) {
            if ( CurrentPrice > LastPrice ) { result = "B" ; }
            else if ( CurrentPrice < LastPrice ) { result = "S" ; }}}
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) { result = result ; }
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) { result = string ( safAverage ) ; }
      // -------------------- RULE 3
      if ( StringFind ( safRules , "3" , 0 ) >= 0 ) { result = string ( MathAbs ( CurrentPrice - LastPrice ) ) ; }
      LastPrice = CurrentPrice ;
      safCounter += 1 ;
   return result ; }

   string goCheck_SARChange () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // -------------------- handle indicator here
      if ( ind_SAR () == false ) {
         goPrint ( "Unable to load SAR indicator data" ) ;
         return "X" ; }
      double CurrentSAR = B0 [ glb_FC ] ;
      double LastSAR = B0 [ glb_FC + 1 ] ;
      double CurrentPrice = glb_PI[ glb_FC ].close ;
      double LastPrice = glb_PI[ glb_FC + 1 ].close ;
      if ( ( CurrentSAR < CurrentPrice ) && ( LastSAR > LastPrice ) ) { result += "B" ; }
      else if ( ( CurrentSAR > CurrentPrice ) && ( LastSAR < LastPrice ) ) { result += "S" ; }
      else { return "X" ; }
   return result ; }

   string goCheck_Daily200MA ( string safType , string safSymbol , int NoOfCandles=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      glb_EAP = PERIOD_D1 ;
      string sCurr_Symbol = glb_EAS ;
      glb_EAS = safSymbol ;
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      result = goSignal_Trend ( "1" , safType , 200 , 1 ) ;
      if ( NoOfCandles > 0 ) { result += goCheck_AboveMA4XCandles ( "2" , safType , 200 , NoOfCandles ) ; }
      glb_EAP = sCurr_Period ;
      glb_EAS = sCurr_Symbol ;
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      return result ; }

   string goCheck_Position2Yesterday ( string safRules="5" , ENUM_TIMEFRAMES safTF=PERIOD_D1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Trade using middle last day low and high
      // RULE 2: Trade using middle last day open and close
      // RULE 3: Trade if above or below last day high and low
      // RULE 4: Trade if above or below last day open and close
      // RULE 5: Trade if above or below last day pivot
      double safBuyTrigger = 0 , safSellTrigger = 0 ;
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      glb_EAP = safTF ;
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = 2 ;
         CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
         double LastHigh = glb_PI[1].high ;
         double LastLow = glb_PI[1].low ;
         double LastOpen = glb_PI[1].open ;
         double LastClose = glb_PI[1].close ;
         double safMin = MathMin ( LastOpen , LastClose ) ;
         double safMax = MathMax ( LastOpen , LastClose ) ;
         // -------------------- RULE 1
         if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
            safBuyTrigger = LastLow + ( ( LastHigh - LastLow ) / 2 ) ;
            safSellTrigger = safBuyTrigger ; }
         // -------------------- RULE 2
         if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
            safBuyTrigger = safMin + ( ( safMax - safMin ) / 2 ) ;
            safSellTrigger = safBuyTrigger ; }
         // -------------------- RULE 3
         if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
            safBuyTrigger = LastHigh ;
            safSellTrigger = LastLow ; }
         // -------------------- RULE 4
         if ( StringFind ( safRules , "4" , 0 ) >= 0 ) {
            safBuyTrigger = safMax ;
            safSellTrigger = safMin ; }
         // -------------------- RULE 5
         if ( StringFind ( safRules , "5" , 0 ) >= 0 ) {
            safBuyTrigger = ( LastHigh + LastLow + LastClose ) / 3 ;
            safSellTrigger = safBuyTrigger ; }
         // -------------------- result here
         if ( sAsk() > safBuyTrigger ) { result += "B" ; }
         else if ( sBid() < safSellTrigger ) { result += "S" ; }
         else { result += "X" ; }
      glb_EAP = sCurr_Period ;
      glb_BD = sCurr_BufferDepth ;
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      return result ; }

   string goCheck_DistanceFromMA ( string safType , int safPeriod , double safMaxDistance ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // -------------------- handle indicator here
      if ( ind_MA ( safType , safPeriod , 0 ) == false ) {
         goPrint ( "Unable to find distance from MA due to indicator error" ) ;
         return "X" ; }

      double CurrentPrice = glb_PI [ glb_FC ].close ;
      double CurrentMA = B0 [ glb_FC ] ;
      if ( MathAbs ( CurrentPrice - CurrentMA ) <= safMaxDistance ) { result += "Y" ; } else { return "X" ; }
      return result ; }

   string goCheck_LastCandleSize ( double safMaxSize , double safMinSize ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      double CurrentHigh = glb_PI[ glb_FC ].high ;
      double CurrentLow = glb_PI[ glb_FC ].low ;
      double safCandleSize = CurrentHigh - CurrentLow ;
      if ( safMaxSize > 0 ) { if ( safCandleSize >= safMaxSize ) { return "X" ; } else { result += "Y" ; } }
      if ( safMinSize > 0 ) { if ( safCandleSize <= safMinSize ) { return "X" ; } else { result += "Y" ; } }
      return result ; }

   bool IsItRange ( int NoOfCandles=100 , double safATRMultiple=8 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      bool result = false ;
      if ( ( NoOfCandles > 0 ) && ( safATRMultiple > 0 ) ) {
         double ATR2Use = goCalc_DailyM1ATR () ;
         double safHigh = goFind_High ( NoOfCandles , glb_FC , 2 ) ;
         double safLow  = goFind_Low  ( NoOfCandles , glb_FC , 2 ) ;
         double safSpread = safHigh - safLow ;
         if ( safSpread < ATR2Use * safATRMultiple ) { result = true ; }}
      return result ; }

   string goCheck_DailyComparison ( string safRules="1" , int NoOfDays=100 , int safStep=5 , double safPercent=75 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // RULE 1: return result string
      // RULE 2: return signal
      string result = "" , safSignal = "" ;
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      int sCurr_BufferDepth = glb_BD ;
      glb_EAP = PERIOD_D1 ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + NoOfDays + 1 ) ; // Add another vraiable here
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
      double CurrentHigh = glb_PI [ glb_FC ].high ;
      double CurrentLow  = glb_PI [ glb_FC ].low ;
      double safHigh=0 , safLow=0 ;
      for ( int i = glb_FC + safStep ; i < glb_FC + NoOfDays + 1 ; i = i + safStep ) {
         if ( CurrentHigh > glb_PI[ i ].high ) { result += "H" ; safHigh += 1 ; }
         else if ( CurrentLow < glb_PI[ i ].low ) { result += "L" ; safLow += 1 ; }
         else { result += "X" ; }}
      if ( ( safHigh > safLow ) &&
         ( ( safHigh / StringLen ( result ) ) >= ( safPercent / 100 ) ) &&
         ( StringSubstr ( result , 0 , 1 ) == "H" ) ) { result += " > > > BUY" ; safSignal = "B" ; }
      else if ( ( safLow > safHigh ) &&
         ( ( safLow / StringLen ( result ) ) >= ( safPercent / 100 ) ) &&
         ( StringSubstr ( result , 0 , 1 ) == "L" ) ) { result += " > > > SELL" ; safSignal = "S" ; }
      else { result += " > > > UNCLEAR" ; safSignal = "X" ; }
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) { result = safSignal ; }
      glb_EAP = sCurr_Period ;
      glb_BD = sCurr_BufferDepth ;
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      return result ; }

   string goCheck_AboveMA4XCandles ( string safRules , string safType , int safPeriod , int NoOfCandles ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      static string LastResult ;
      // RULE 1: Only return signal changes
      // RULE 2: check MA trending also
      if ( ( StringLen ( UT ( safType ) ) > 0 ) && ( NoOfCandles > 0 ) ) {
         int sCurr_BufferDepth = glb_BD ;
         glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + NoOfCandles ) ;
         if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
         // -------------------- handle indicator here
         if ( ind_MA ( safType , safPeriod , 0 ) == false ) {
            glb_BD = sCurr_BufferDepth ;
            return "X" ; }
         string safOriginalRules = safRules ;
         for ( int i = glb_FC ; i < NoOfCandles + glb_FC ; i++ ) {
            safRules = safOriginalRules ;
            double CurrentPrice = glb_PI[ i ].close ;
            double CurrentMA = B0 [ i ] ;
            if ( CurrentPrice > CurrentMA ) { result += "B" ; }
            else if ( CurrentPrice < CurrentMA ) { result += "S" ; }
            else { result += "X" ; }
            // -------------------- RULE 2
            if ( ( StringFind ( safRules , "2" , 0 ) >= 0 ) ) {
               result += goSignal_Trend ( "1" , safType , safPeriod , 1 ) ; }}
         // -------------------- RULE 1
         if ( ( StringFind ( safRules , "1" , 0 ) >= 0 ) ) {
            if ( result == LastResult ) { result += "X" ; } else { LastResult = result ; }}
         glb_BD = sCurr_BufferDepth ; }
      return result ; }

   //===========================================================================================================
   //=====                                           SIGNALS                                               =====
   //===========================================================================================================

   string goCheckTrending ( int safTrending=1 , string safGoingUp="B" , string safGoingDown="S" , string safOther="X" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      if ( safTrending < 1 ) { return result ; }
      for ( int i = 0 ; i < safTrending ; i++ ) {
         if ( B0 [ glb_FC + i ] > B0 [ glb_FC + i + 1 ] ) { result += safGoingUp ; }
         else if ( B0 [ glb_FC + i ] < B0 [ glb_FC + i + 1 ] ) { result += safGoingDown ; }
         else { return safOther ; }} return result ; }

   string goSignal_ADX ( string safRules="1" , string safType="ADX" , int safPeriod=5 , int safTrending=1 , int safStart=25 , int safEnd=75 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Main line rules / ADX above trade trigger
      // RULE 2: D+/D- rules
      // RULE 3: ADX cross from below to above trade trigger
      if ( safPeriod > 0 ) {
         int sCurr_BufferDepth = glb_BD ;
         glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending ) ;
         if ( safType == "ADX" ) {
            // -------------------- handle indicator here
            if ( ind_ADX ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "ADXW" ) {
            // -------------------- handle indicator here
            if ( ind_ADXW ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         // -------------------- RULE 1
         if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
            if ( safStart > 0 ) { if ( B0 [ glb_FC ] >= safStart ) { result += "Y" ; } else { result += "X" ; } }
            if ( safEnd > 0 ) { if ( B0 [ glb_FC ] <= safEnd ) { result += "Y" ; } else { result += "X" ; } }
            if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "Y" , "X"  , "X" ) ; } }
         // -------------------- RULE 2
         if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
            if ( B1 [ glb_FC ] > B2 [ glb_FC ] ) { result += "B" ; }
            else if ( B1 [ glb_FC ] < B2 [ glb_FC ] ) { result += "S" ; }
            else { result += "X" ; } }
         // -------------------- RULE 3
         if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
            if ( safStart > 0 ) {
               if ( ( B0 [ glb_FC ] >= safStart ) && ( B0 [ glb_FC + 1 ] < safStart ) ) {
                  result += "Y" ; } else { result += "X" ; } }
            if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "Y" , "X"  , "X" ) ; } }
         glb_BD = sCurr_BufferDepth ;
      } return result ; }

   string goSignal_ADXMulti ( string safRules="1" , string safType="ADX" , string safPeriod="5" , int safTrending=1 , int safStart=25 , int safEnd=75 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      static string LastResult ;
      double safLastPeriodValue = 0 ;
      // RULE 1: Main line rules / ADX above trade trigger
      // RULE 2: D+/D- rules
      // RULE 3: ADX cross from below to above trade trigger
      // RULE 4: Indicator value is above/below each other
      // RULE 5: Only return signal changes
      string safOriginalRules = safRules ;
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending ) ;
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
      string safTypeArray[] ; StringSplit ( ( safType + "|" ) , StringGetCharacter ( "|" , 0 ) , safTypeArray ) ;
      string safPeriodArray[] ; StringSplit ( ( safPeriod + "|" ) , StringGetCharacter ( "|" , 0 ) , safPeriodArray ) ;
      for ( int i = 0 ; i < ArraySize ( safPeriodArray ) - 1 ; i++ ) {
         for ( int j = 0 ; j < ArraySize ( safTypeArray ) - 1 ; j++ ) {
            int safPeriod2Use = int ( safPeriodArray[ i ] ) ;
            string safType2Use = safTypeArray[ j ] ;
            if ( safPeriod2Use > 0 ) {
               if ( StringLen ( UT ( safType2Use ) ) > 0 ) {
                  safRules = safOriginalRules ;
                  if ( safType2Use == "ADX" ) {
                     // -------------------- handle indicator here
                     if ( ind_ADX ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "ADXW" ) {
                     // -------------------- handle indicator here
                     if ( ind_ADXW ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  // -------------------- RULE 1
                  if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
                     if ( safStart > 0 ) { if ( B0 [ glb_FC ] >= safStart ) { result += "Y" ; } else { result += "X" ; } }
                     if ( safEnd > 0 ) { if ( B0 [ glb_FC ] <= safEnd ) { result += "Y" ; } else { result += "X" ; } }
                     if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "Y" , "X"  , "X" ) ; } }
                  // -------------------- RULE 2
                  if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
                     if ( B1 [ glb_FC ] > B2 [ glb_FC ] ) { result += "B" ; }
                     else if ( B1 [ glb_FC ] < B2 [ glb_FC ] ) { result += "S" ; }
                     else { result += "X" ; } }
                  // -------------------- RULE 3
                  if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
                     if ( safStart > 0 ) {
                        if ( ( B0 [ glb_FC ] >= safStart ) && ( B0 [ glb_FC + 1 ] < safStart ) ) {
                           result += "Y" ; } else { result += "X" ; } }
                     if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "Y" , "X"  , "X" ) ; }}
                  // -------------------- RULE 4
                  if ( ( StringFind ( safRules , "4" , 0 ) >= 0 ) ) {
                     if ( safLastPeriodValue != 0 ) {
                        if ( safLastPeriodValue > B0 [ glb_FC ] ) { result += "Y" ; } else { result += "X" ; }
                     } safLastPeriodValue = B0 [ glb_FC ] ; }}}}}
      // -------------------- RULE 5
      if ( ( StringFind ( safRules , "5" , 0 ) >= 0 ) ) {
         if ( result == LastResult ) { result += "X" ; } else { LastResult = result ; }}
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_Oscillator ( string safRules="1" , string safType="RSI" , int safPeriod=5 , int safTrending=1 , double safBStart=51 , double safSStart=49 , double safBEnd=75 , double safSEnd=25 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Cross above
      // RULE 2: Cross below from above
      // RULE 3: Cross below then above
      // RULE 4: Cross below only
      if ( safPeriod > 0 ) {
         int sCurr_BufferDepth = glb_BD ;
         glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending ) ;
         if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
         string safBuy = "B" , safSell = "S" ;
         if ( safType == "RSI" ) {
            // -------------------- handle indicator here
            if ( ind_RSI ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "CHAIKIN" ) {
            // -------------------- handle indicator here
            if ( ind_Chaikin () == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "CCI" ) {
            // -------------------- handle indicator here
            if ( ind_CCI ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "DEMARKER" ) {
            // -------------------- handle indicator here
            if ( ind_DeMarker ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "FORCE" ) {
            // -------------------- handle indicator here
            if ( ind_Force ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "MOMENTUM" ) {
            // -------------------- handle indicator here
            if ( ind_Momentum ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "WPR" ) {
            // -------------------- handle indicator here
            if ( ind_WPR ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "RVI" ) {
            // -------------------- handle indicator here
            if ( ind_RVI ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "MFI" ) {
            // -------------------- handle indicator here
            if ( ind_MFI ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "AO" ) {
            // -------------------- handle indicator here
            if ( ind_AO () == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "TRIX" ) {
            // -------------------- handle indicator here
            if ( ind_TriX ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "SOC" ) {
            // -------------------- handle indicator here
            if ( ind_Stochastic () == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "BULLS" ) {
            safSell = "X" ;
            // -------------------- handle indicator here
            if ( ind_Bulls ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "BEARS" ) {
            safBuy = "X" ;
            // -------------------- handle indicator here
            if ( ind_Bears ( safPeriod ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         double safCurrent = B0 [ glb_FC ] ;
         double safLast = B0 [ glb_FC + 1 ] ;
         // -------------------- RULE 1
         if ( ( StringFind ( safRules , "1" , 0 ) >= 0 ) ) {
            if ( safCurrent > safBStart ) { result += safBuy ; }
            else if ( safCurrent < safSStart ) { result += safSell ; }
            else { result += "X" ; }
            if ( safBEnd != 0 ) { if ( safCurrent > safBEnd ) { result += "X" ; } }
            if ( safSEnd != 0 ) { if ( safCurrent < safSEnd ) { result += "X" ; } }
            if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , safBuy , safSell  , "X" ) ; } }
         // -------------------- RULE 2
         if ( ( StringFind ( safRules , "2" , 0 ) >= 0 ) ) {
            if ( ( safCurrent < safBStart ) && ( safLast > safBStart ) ) { result += safBuy ; }
            else if ( ( safCurrent > safSStart ) && ( safLast < safSStart ) ) { result += safSell ; }
            else { result += "X" ; } }
         // -------------------- RULE 3
         if ( ( StringFind ( safRules , "3" , 0 ) >= 0 ) ) {
            if ( ( safCurrent > safBStart ) && ( safLast < safBStart ) ) { result += safBuy ; }
            else if ( ( safCurrent < safSStart ) && ( safLast > safSStart ) ) { result += safSell ; }
            else { result += "X" ; } }
         // -------------------- RULE 4
         if ( ( StringFind ( safRules , "4" , 0 ) >= 0 ) ) {
            if ( safCurrent < safBStart ) { result += safBuy ; }
            else if ( safCurrent > safSStart ) { result += safSell ; }
            else { result += "X" ; }
            if ( safBEnd != 0 ) { if ( safCurrent < safBEnd ) { result += "X" ; } }
            if ( safSEnd != 0 ) { if ( safCurrent > safSEnd ) { result += "X" ; } }
            if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , safSell , safBuy , "X" ) ; } }
         glb_BD = sCurr_BufferDepth ;
      } return result ; }

   string goSignal_OscillatorMulti ( string safRules="1" , string safType="RSI" , string safPeriod="5" , int safTrending=1 , double safBStart=51 , double safSStart=49 , double safBEnd=75 , double safSEnd=25 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      static string LastResult ;
      double safLastPeriodValue = 0 ;
      // RULE 1: Cross above
      // RULE 2: Cross below from above
      // RULE 3: Cross below then above
      // RULE 4: Cross below only
      // RULE 5: values are above/below each other
      // RULE 6: Only return signal changes
      string safOriginalRules = safRules ;
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending ) ;
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
      string safTypeArray[] ; StringSplit ( ( safType + "|" ) , StringGetCharacter ( "|" , 0 ) , safTypeArray ) ;
      string safPeriodArray[] ; StringSplit ( ( safPeriod + "|" ) , StringGetCharacter ( "|" , 0 ) , safPeriodArray ) ;
      for ( int i = 0 ; i < ArraySize ( safPeriodArray ) - 1 ; i++ ) {
         for ( int j = 0 ; j < ArraySize ( safTypeArray ) - 1 ; j++ ) {
            int safPeriod2Use = int ( safPeriodArray[ i ] ) ;
            string safType2Use = safTypeArray[ j ] ;
            if ( safPeriod2Use > 0 ) {
               if ( StringLen ( UT ( safType2Use ) ) > 0 ) {
                  safRules = safOriginalRules ;
                  string safBuy = "B" , safSell = "S" ;
                  if ( safType2Use == "RSI" ) {
                     // -------------------- handle indicator here
                     if ( ind_RSI ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "CHAIKIN" ) {
                     // -------------------- handle indicator here
                     if ( ind_Chaikin () == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "CCI" ) {
                     // -------------------- handle indicator here
                     if ( ind_CCI ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "DEMARKER" ) {
                     // -------------------- handle indicator here
                     if ( ind_DeMarker ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "FORCE" ) {
                     // -------------------- handle indicator here
                     if ( ind_Force ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "MOMENTUM" ) {
                     // -------------------- handle indicator here
                     if ( ind_Momentum ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "WPR" ) {
                     // -------------------- handle indicator here
                     if ( ind_WPR ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "RVI" ) {
                     // -------------------- handle indicator here
                     if ( ind_RVI ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "MFI" ) {
                     // -------------------- handle indicator here
                     if ( ind_MFI ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "AO" ) {
                     // -------------------- handle indicator here
                     if ( ind_AO () == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "TRIX" ) {
                     // -------------------- handle indicator here
                     if ( ind_TriX ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "BULLS" ) {
                     safSell = "X" ;
                     // -------------------- handle indicator here
                     if ( ind_Bulls ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "BEARS" ) {
                     safBuy = "X" ;
                     // -------------------- handle indicator here
                     if ( ind_Bears ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  double safCurrent = B0 [ glb_FC ] ;
                  double safLast = B0 [ glb_FC + 1 ] ;
                  // -------------------- RULE 1
                  if ( ( StringFind ( safRules , "1" , 0 ) >= 0 ) ) {
                     if ( safCurrent > safBStart ) { result += safBuy ; }
                     else if ( safCurrent < safSStart ) { result += safSell ; }
                     else { result += "X" ; }
                     if ( safBEnd != 0 ) { if ( safCurrent > safBEnd ) { result += "X" ; } }
                     if ( safSEnd != 0 ) { if ( safCurrent < safSEnd ) { result += "X" ; } }
                     if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , safBuy , safSell  , "X" ) ; } }
                  // -------------------- RULE 2
                  if ( ( StringFind ( safRules , "2" , 0 ) >= 0 ) ) {
                     if ( ( safCurrent < safBStart ) && ( safLast > safBStart ) ) { result += safBuy ; }
                     else if ( ( safCurrent > safSStart ) && ( safLast < safSStart ) ) { result += safSell ; }
                     else { result += "X" ; } }
                  // -------------------- RULE 3
                  if ( ( StringFind ( safRules , "3" , 0 ) >= 0 ) ) {
                     if ( ( safCurrent > safBStart ) && ( safLast < safBStart ) ) { result += safBuy ; }
                     else if ( ( safCurrent < safSStart ) && ( safLast > safSStart ) ) { result += safSell ; }
                     else { result += "X" ; } }
                  // -------------------- RULE 4
                  if ( ( StringFind ( safRules , "4" , 0 ) >= 0 ) ) {
                     if ( safCurrent < safBStart ) { result += safBuy ; }
                     else if ( safCurrent > safSStart ) { result += safSell ; }
                     else { result += "X" ; }
                     if ( safBEnd != 0 ) { if ( safCurrent < safBEnd ) { result += "X" ; } }
                     if ( safSEnd != 0 ) { if ( safCurrent > safSEnd ) { result += "X" ; } }
                     if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , safSell , safBuy , "X" ) ; }}
                  // -------------------- RULE 5
                  if ( ( StringFind ( safRules , "5" , 0 ) >= 0 ) ) {
                     if ( safLastPeriodValue != 0 ) {
                        if ( safLastPeriodValue > safCurrent ) { result += "B" ; }
                        else if ( safLastPeriodValue < safCurrent ) { result += "S" ; }
                        else { result += "X" ; }
                     } safLastPeriodValue = safCurrent ; }}}}}
      // -------------------- RULE 6
      if ( ( StringFind ( safRules , "6" , 0 ) >= 0 ) ) {
         if ( result == LastResult ) { result += "X" ; } else { LastResult = result ; }}
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_Trend ( string safRules="1" , string safType="EMA" , int safPeriod=20 , int safTrending=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Buy if price above MA
      // RULE 2: Price cross MA
      // RULE 3: Buy if price below MA !!!
      // RULE A: Close all on price/MA cross
      // RULE B: Close positive on price/MA cross
      // RULE C: Close buy/sell on price/MA cross
      // RULE D: Close buy/sell positive only on price/MA cross
      if ( safPeriod > 0 ) {
         int sCurr_BufferDepth = glb_BD ;
         glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending ) ;
         if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
         if ( safType == "EMA" ) {
            // -------------------- handle indicator here
            if ( ind_MA ( "EMA" , safPeriod , 0 ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "SMA" ) {
            // -------------------- handle indicator here
            if ( ind_MA ( "SMA" , safPeriod , 0 ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "SMMA" ) {
            // -------------------- handle indicator here
            if ( ind_MA ( "SMMA" , safPeriod , 0 ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "DEMA" ) {
            // -------------------- handle indicator here
            if ( ind_DEMA ( safPeriod , 0 ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "TEMA" ) {
            // -------------------- handle indicator here
            if ( ind_TEMA ( safPeriod , 0 ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "SAR" ) {
            // -------------------- handle indicator here
            if ( ind_SAR () == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "FRAMA" ) {
            // -------------------- handle indicator here
            if ( ind_FrAMA ( safPeriod , 0 ) == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "VIDYA" ) {
            // -------------------- handle indicator here
            if ( ind_VIDyA () == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         if ( safType == "AMA" ) {
            // -------------------- handle indicator here
            if ( ind_AMA () == false ) {
               glb_BD = sCurr_BufferDepth ;
               return "X" ; }}
         double safCurrentPrice = glb_PI[ glb_FC ].close ;
         double safLastPrice = glb_PI[ glb_FC + 1 ].close ;
         double safCurrentMA = B0 [ glb_FC ] ;
         double safLastMA = B0 [ glb_FC + 1 ] ;
         // -------------------- RULE 1
         if ( ( StringFind ( safRules , "1" , 0 ) >= 0 ) ) {
            if ( safCurrentPrice > safCurrentMA  ) { result += "B" ; }
            else if ( safCurrentPrice < safCurrentMA  ) { result += "S" ; }
            else { result += "X" ; }
            if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "B" , "S" , "X" ) ; } }
         // -------------------- RULE 2
         if ( ( StringFind ( safRules , "2" , 0 ) >= 0 ) ) {
            if ( ( safCurrentPrice > safCurrentMA  ) && ( safLastPrice < safLastMA  ) ) { result += "B" ; }
            else if ( ( safCurrentPrice < safCurrentMA  ) && ( safLastPrice > safLastMA  ) ) { result += "S" ; }
            else { result += "X" ; } }
         // -------------------- RULE 3
         if ( ( StringFind ( safRules , "3" , 0 ) >= 0 ) ) {
            if ( safCurrentPrice > safCurrentMA  ) { result += "S" ; }
            else if ( safCurrentPrice < safCurrentMA  ) { result += "B" ; }
            else { result += "X" ; }
            if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "S" , "B" , "X" ) ; } }
         // -------------------- RULE A
         if ( ( StringFind ( safRules , "A" , 0 ) >= 0 ) ) {
            if ( ( safCurrentPrice > safCurrentMA  ) && ( safLastPrice < safLastMA  ) ) { goClose_AllPositions() ; }
            else if ( ( safCurrentPrice < safCurrentMA  ) && ( safLastPrice > safLastMA  ) ) { goClose_AllPositions() ; }}
         // -------------------- RULE B
         if ( ( StringFind ( safRules , "B" , 0 ) >= 0 ) ) {
            if ( ( safCurrentPrice > safCurrentMA  ) && ( safLastPrice < safLastMA  ) ) { goClose_PositivePositions(0) ; }
            else if ( ( safCurrentPrice < safCurrentMA  ) && ( safLastPrice > safLastMA  ) ) { goClose_PositivePositions(0) ; }}
         // -------------------- RULE C
         if ( ( StringFind ( safRules , "C" , 0 ) >= 0 ) ) {
            if ( ( safCurrentPrice > safCurrentMA  ) && ( safLastPrice < safLastMA  ) ) { goClose_AllSellPositions() ; }
            else if ( ( safCurrentPrice < safCurrentMA  ) && ( safLastPrice > safLastMA  ) ) { goClose_AllBuyPositions() ; }}
         // -------------------- RULE D
         if ( ( StringFind ( safRules , "D" , 0 ) >= 0 ) ) {
            if ( ( safCurrentPrice > safCurrentMA  ) && ( safLastPrice < safLastMA  ) ) { goClose_AllSellPositions(0) ; }
            else if ( ( safCurrentPrice < safCurrentMA  ) && ( safLastPrice > safLastMA  ) ) { goClose_AllBuyPositions(0) ; }}
         glb_BD = sCurr_BufferDepth ;
      } return result ; }

   string goSignal_TrendMulti ( string safRules="1" , string safType="EMA" , string safPeriod="20" , int safTrending=1 , double safFan=0.8 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      static string LastResult ;
      double LastMAForCross_C = 0 ;
      double LastMAForCross_L = 0 ;
      double safLastPeriodMA = 0 ;
      double safLastPeriodMAforDist = 0 ;
      double safInitialFanning = 0 ;
      // RULE 1: Buy if price above MA
      // RULE 2: Price cross MA
      // RULE 3: MAs are above/below each other
      // RULE 4: Only return signal changes
      // RULE 5: MAs fanned out equally ( 80% to 1/80% )
      // RULE 6: Buy if price below MA !!!
      // RULE 7: Buy on MA cross
      // RULE A: Close all on price/MA cross
      // RULE B: Close positive on price/MA cross
      // RULE C: Close buy/sell on price/MA cross
      // RULE D: Close buy/sell positive only on price/MA cross
      // RULE E: Close all on 2MA cross
      // RULE F: Close positive on 2MA cross
      // RULE G: Close buy/sell on 2MA cross
      // RULE H: Close buy/sell positive only on 2MA cross
      string safOriginalRules = safRules ;
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending ) ;
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
      string safTypeArray[] ; StringSplit ( ( safType + "|" ) , StringGetCharacter ( "|" , 0 ) , safTypeArray ) ;
      string safPeriodArray[] ; StringSplit ( ( safPeriod + "|" ) , StringGetCharacter ( "|" , 0 ) , safPeriodArray ) ;
      for ( int i = 0 ; i < ArraySize ( safPeriodArray ) - 1 ; i++ ) {
         for ( int j = 0 ; j < ArraySize ( safTypeArray ) - 1 ; j++ ) {
            int safPeriod2Use = int ( safPeriodArray[ i ] ) ;
            string safType2Use = safTypeArray[ j ] ;
            if ( safPeriod2Use > 0 ) {
               if ( StringLen ( UT ( safType2Use ) ) > 0 ) {
                  safRules = safOriginalRules ;
                  if ( safType2Use == "EMA" ) {
                     // -------------------- handle indicator here
                     if ( ind_MA ( "EMA" , safPeriod2Use , 0 ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "SMA" ) {
                     // -------------------- handle indicator here
                     if ( ind_MA ( "SMA" , safPeriod2Use , 0 ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "SMMA" ) {
                     // -------------------- handle indicator here
                     if ( ind_MA ( "SMMA" , safPeriod2Use , 0 ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "DEMA" ) {
                     // -------------------- handle indicator here
                     if ( ind_DEMA ( safPeriod2Use , 0 ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "TEMA" ) {
                     // -------------------- handle indicator here
                     if ( ind_TEMA ( safPeriod2Use , 0 ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "SAR" ) {
                     // -------------------- handle indicator here
                     if ( ind_SAR () == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "FRAMA" ) {
                     // -------------------- handle indicator here
                     if ( ind_FrAMA ( safPeriod2Use , 0 ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "VIDYA" ) {
                     // -------------------- handle indicator here
                     if ( ind_VIDyA () == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "AMA" ) {
                     // -------------------- handle indicator here
                     if ( ind_AMA () == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  double safCurrentPrice = glb_PI[ glb_FC ].close ;
                  double safLastPrice = glb_PI[ glb_FC + 1 ].close ;
                  double safCurrentMA = B0 [ glb_FC ] ;
                  double safLastMA = B0 [ glb_FC + 1 ] ;
                  // -------------------- RULE 1
                  if ( ( StringFind ( safRules , "1" , 0 ) >= 0 ) ) {
                     if ( safCurrentPrice > safCurrentMA  ) { result += "B" ; }
                     else if ( safCurrentPrice < safCurrentMA  ) { result += "S" ; }
                     else { result += "X" ; }
                     if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "B" , "S" , "X" ) ; } }
                  // -------------------- RULE 6
                  if ( ( StringFind ( safRules , "6" , 0 ) >= 0 ) ) {
                     if ( safCurrentPrice > safCurrentMA  ) { result += "S" ; }
                     else if ( safCurrentPrice < safCurrentMA  ) { result += "B" ; }
                     else { result += "X" ; }
                     if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "S" , "B" , "X" ) ; } }
                  // -------------------- RULE 2
                  if ( ( StringFind ( safRules , "2" , 0 ) >= 0 ) ) {
                     if ( ( safCurrentPrice > safCurrentMA  ) && ( safLastPrice < safLastMA  ) ) { result += "B" ; }
                     else if ( ( safCurrentPrice < safCurrentMA  ) && ( safLastPrice > safLastMA  ) ) { result += "S" ; }
                     else { result += "X" ; }}
                  // -------------------- RULE 3
                  if ( ( StringFind ( safRules , "3" , 0 ) >= 0 ) ) {
                     if ( safLastPeriodMA != 0 ) {
                        if ( safLastPeriodMA > safCurrentMA ) { result += "B" ; }
                        else if ( safLastPeriodMA < safCurrentMA ) { result += "S" ; }
                        else { result += "X" ; }
                     } safLastPeriodMA = safCurrentMA ; }
                  // -------------------- RULE 5
                  if ( ( StringFind ( safRules , "5" , 0 ) >= 0 ) ) {
                     if ( safLastPeriodMAforDist != 0 ) {
                        if ( safInitialFanning == 0 ) {
                           safInitialFanning = MathAbs ( safCurrentMA - safLastPeriodMAforDist ) ;
                        } else {
                           double safAbsDist = MathAbs ( safCurrentMA - safLastPeriodMAforDist ) ;
                           if ( ( safAbsDist / safInitialFanning >= safFan ) && ( safAbsDist / safInitialFanning <= ( 1 / safFan ) ) ) {
                              result += "Y" ; } else { result += "X" ; }}
                     } safLastPeriodMAforDist = safCurrentMA ; }
                  // -------------------- RULE 7
                  if ( ( StringFind ( safRules , "7" , 0 ) >= 0 ) ) {
                     if ( ( LastMAForCross_C > 0 ) && ( LastMAForCross_L > 0 ) ) {
                        if ( ( safCurrentMA > LastMAForCross_C ) && ( safLastMA < LastMAForCross_L ) ) { result += "S" ; }
                        else if ( ( safCurrentMA < LastMAForCross_C ) && ( safLastMA > LastMAForCross_L ) ) { result += "B" ; }
                        else { result += "X" ; }
                        if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "B" , "S" , "X" ) ; }}}
                  // -------------------- RULE A
                  if ( ( StringFind ( safRules , "A" , 0 ) >= 0 ) ) {
                     if ( ( safCurrentPrice > safCurrentMA  ) && ( safLastPrice < safLastMA  ) ) { goClose_AllPositions() ; }
                     else if ( ( safCurrentPrice < safCurrentMA  ) && ( safLastPrice > safLastMA  ) ) { goClose_AllPositions() ; }}
                  // -------------------- RULE B
                  if ( ( StringFind ( safRules , "B" , 0 ) >= 0 ) ) {
                     if ( ( safCurrentPrice > safCurrentMA  ) && ( safLastPrice < safLastMA  ) ) { goClose_PositivePositions(0) ; }
                     else if ( ( safCurrentPrice < safCurrentMA  ) && ( safLastPrice > safLastMA  ) ) { goClose_PositivePositions(0) ; }}
                  // -------------------- RULE C
                  if ( ( StringFind ( safRules , "C" , 0 ) >= 0 ) ) {
                     if ( ( safCurrentPrice > safCurrentMA  ) && ( safLastPrice < safLastMA  ) ) { goClose_AllSellPositions() ; }
                     else if ( ( safCurrentPrice < safCurrentMA  ) && ( safLastPrice > safLastMA  ) ) { goClose_AllBuyPositions() ; }}
                  // -------------------- RULE D
                  if ( ( StringFind ( safRules , "D" , 0 ) >= 0 ) ) {
                     if ( ( safCurrentPrice > safCurrentMA  ) && ( safLastPrice < safLastMA  ) ) { goClose_AllSellPositions(0) ; }
                     else if ( ( safCurrentPrice < safCurrentMA  ) && ( safLastPrice > safLastMA  ) ) { goClose_AllBuyPositions(0) ; }}
                  if ( ( LastMAForCross_C > 0 ) && ( LastMAForCross_L > 0 ) ) {
                     // -------------------- RULE E
                     if ( ( StringFind ( safRules , "E" , 0 ) >= 0 ) ) {
                        if ( ( LastMAForCross_C > safCurrentMA  ) && ( LastMAForCross_L < safLastMA  ) ) { goClose_AllPositions() ; }
                        else if ( ( LastMAForCross_C < safCurrentMA  ) && ( LastMAForCross_L > safLastMA  ) ) { goClose_AllPositions() ; }}
                     // -------------------- RULE F
                     if ( ( StringFind ( safRules , "F" , 0 ) >= 0 ) ) {
                        if ( ( LastMAForCross_C > safCurrentMA  ) && ( LastMAForCross_L < safLastMA  ) ) { goClose_PositivePositions(0) ; }
                        else if ( ( LastMAForCross_C < safCurrentMA  ) && ( LastMAForCross_L > safLastMA  ) ) { goClose_PositivePositions(0) ; }}
                     // -------------------- RULE G
                     if ( ( StringFind ( safRules , "G" , 0 ) >= 0 ) ) {
                        if ( ( LastMAForCross_C > safCurrentMA  ) && ( LastMAForCross_L < safLastMA  ) ) { goClose_AllSellPositions() ; }
                        else if ( ( LastMAForCross_C < safCurrentMA  ) && ( LastMAForCross_L > safLastMA  ) ) { goClose_AllBuyPositions() ; }}
                     // -------------------- RULE H
                     if ( ( StringFind ( safRules , "H" , 0 ) >= 0 ) ) {
                        if ( ( LastMAForCross_C > safCurrentMA  ) && ( LastMAForCross_L < safLastMA  ) ) { goClose_AllSellPositions(0) ; }
                        else if ( ( LastMAForCross_C < safCurrentMA  ) && ( LastMAForCross_L > safLastMA  ) ) { goClose_AllBuyPositions(0) ; }}}
               LastMAForCross_C = safCurrentMA ; LastMAForCross_L = safLastMA ; }}}}
      // -------------------- RULE 4
      if ( ( StringFind ( safRules , "4" , 0 ) >= 0 ) ) {
         if ( result == LastResult ) { result += "X" ; } else { LastResult = result ; }}
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_Ichimoku ( string safRules="12345678" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // 0 - TENKANSEN LINE - RED , 1 - KIJUNSEN LINE - BLUE , 2 - SENKOUSPANA LINE - CLOUD A , 3 - SENKOUSPANB LINE - CLOUD B , 4 - CHIKOUSPAN LINE - SPAN
      string result = "" ;
      // RULE 1: Price is above/below current cloud
      // RULE 2: Future cloud is green/red
      // RULE 3: Price crosses out of cloud
      // RULE 4: Price is higher/lower than red and blue line
      // RULE 5: If red is above blue then buy
      // RULE 6: If red crosses above blue then buy
      // RULE 7: If lagging span is above cloud then buy
      // RULE 8: if lagging span is above price then buy
      // RULE A: Close if lagging span passes price
      // RULE B: Close if price crosses baseline (blue line)
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + 54 ) ;
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
      // -------------------- handle indicator here
      if ( ind_Ichimoku () == false ) {
         glb_BD = sCurr_BufferDepth ;
         return "X" ; }
      double CurrentPrice     = glb_PI [ glb_FC ].close ;
      double LastPrice        = glb_PI [ glb_FC + 1 ].close ;
      double CurrentCloudA    = B2 [ glb_FC + 26 ] ;
      double CurrentCloudB    = B3 [ glb_FC + 26 ] ;
      double FutureCloudA     = B2 [ glb_FC ] ;
      double FutureCloudB     = B3 [ glb_FC ] ;
      double LastCloudA       = B2 [ glb_FC + 27 ] ;
      double LastCloudB       = B3 [ glb_FC + 27 ] ;
      double CurrentRed       = B0 [ glb_FC ] ; // Conversion - Red
      double CurrentBlue      = B1 [ glb_FC ] ; // Baseline - Blue
      double LastRed          = B0 [ glb_FC + 1 ] ;
      double LastBlue         = B1 [ glb_FC + 1 ] ;
      double PastCloudA       = B2 [ glb_FC + 52 ] ;
      double PastCloudB       = B3 [ glb_FC + 52 ] ;
      double PastSpan         = B4 [ glb_FC ] ;
      double PastPrice        = glb_PI [ glb_FC + 26 ].close ;
      double BeforePastSpan   = B4 [ glb_FC + 1 ] ;
      double BeforePastPrice  = glb_PI [ glb_FC + 27 ].close ;
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         if ( CurrentPrice > MathMax ( CurrentCloudA , CurrentCloudB ) ) { result += "B" ; }
         else if ( CurrentPrice < MathMin ( CurrentCloudA , CurrentCloudB ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
         if ( FutureCloudA > FutureCloudB ) { result += "B" ; }
         else if ( FutureCloudB > FutureCloudA ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 3
      if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
         if ( ( CurrentPrice > MathMax ( CurrentCloudA , CurrentCloudB ) ) && ( LastPrice < MathMax ( LastCloudA , LastCloudB ) ) ) { result += "B" ; }
         else if ( ( CurrentPrice < MathMin ( CurrentCloudA , CurrentCloudB ) ) && ( LastPrice > MathMin ( LastCloudA , LastCloudB ) ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 4
      if ( StringFind ( safRules , "4" , 0 ) >= 0 ) {
         if ( CurrentPrice > MathMax ( CurrentRed , CurrentBlue ) ) { result += "B" ; }
         else if ( CurrentPrice < MathMin ( CurrentRed , CurrentBlue ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 5
      if ( StringFind ( safRules , "5" , 0 ) >= 0 ) {
         if ( CurrentRed > CurrentBlue ) { result += "B" ; }
         else if ( CurrentRed < CurrentBlue ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 6
      if ( StringFind ( safRules , "6" , 0 ) >= 0 ) {
         if ( ( CurrentRed > CurrentBlue ) && ( LastRed < LastBlue ) ) { result += "B" ; }
         else if ( ( CurrentRed < CurrentBlue ) && ( LastRed > LastBlue ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 7
      if ( StringFind ( safRules , "7" , 0 ) >= 0 ) {
         if ( PastSpan > MathMax ( PastCloudA , PastCloudB ) ) { result += "B" ; }
         else if ( PastSpan < MathMin ( PastCloudA , PastCloudB ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 8
      if ( StringFind ( safRules , "8" , 0 ) >= 0 ) {
         if ( PastSpan > PastPrice ) { result += "B" ; }
         else if ( PastSpan < PastPrice ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE A
      if ( StringFind ( safRules , "A" , 0 ) >= 0 ) {
         if ( ( PastSpan < PastPrice ) && ( BeforePastSpan > BeforePastPrice ) ) { result += "C" ; }
         if ( ( PastSpan > PastPrice ) && ( BeforePastSpan < BeforePastPrice ) ) { result += "T" ; } }
      // -------------------- RULE B
      if ( StringFind ( safRules , "B" , 0 ) >= 0 ) {
         if ( ( CurrentPrice > CurrentBlue ) && ( LastPrice < LastBlue ) ) { result += "T" ; }
         if ( ( CurrentPrice < CurrentBlue ) && ( LastPrice > LastBlue ) ) { result += "C" ; } }
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_MACD ( string safRules="12" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // 0 - MAIN_LINE (not smooth) , 1 - SIGNAL_LINE (smooth)
      string result = "" ;
      // RULE 1: Buy if MACD crosses above signal
      // RULE 2: If both lines are below zero then buy
      // RULE 3: Buy if lines are in right order and when last one crosses above zero
      // -------------------- handle indicator here
      if ( ind_MACD () == false ) { return "X" ; }
      double CurrentMACD   = B0 [ glb_FC ] ;
      double LastMACD      = B0 [ glb_FC + 1 ] ;
      double CurrentSignal = B1 [ glb_FC ] ;
      double LastSignal    = B1 [ glb_FC + 1 ] ;
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         if ( ( CurrentMACD > CurrentSignal ) && ( LastMACD < LastSignal ) ) { result += "B" ; }
         else if ( ( CurrentMACD < CurrentSignal ) && ( LastMACD > LastSignal ) ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
         if ( ( CurrentMACD < 0 ) && ( CurrentSignal < 0 ) ) { result += "B" ; }
         else if ( ( CurrentMACD > 0 ) && ( CurrentSignal > 0 ) ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 3
      if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
         if ( ( CurrentMACD > CurrentSignal ) && ( LastSignal < 0 ) && ( CurrentSignal > 0 ) ) { result += "B" ; }
         else if ( ( CurrentMACD < CurrentSignal ) && ( LastSignal > 0 ) && ( CurrentSignal < 0 ) ) { result += "S" ; }
         else { return "X" ; } }
      return result ; }

   string goSignal_SOC ( string safRules="13" , int safBStart=20 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // 0 - MAIN LINE , 1 - SIGNAL LINE
      string result = "" ;
      // RULE 1: Buy when %K crosses to above %D
      // RULE 2: Buy when both lines are below buy target
      // RULE 3: Buy when both lines cross back above buy target
      // -------------------- handle indicator here
      if ( ind_Stochastic () == false ) { return "X" ; }
      double CurrentK   = B0 [ glb_FC ] ;
      double LastK      = B0 [ glb_FC + 1 ] ;
      double CurrentD   = B1 [ glb_FC ] ;
      double LastD      = B1 [ glb_FC + 1 ] ;
      int safSStart     = 100 - safBStart ;
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         if ( ( CurrentK > CurrentD ) && ( LastK < LastD ) ) { result += "B" ; }
         else if ( ( CurrentK < CurrentD ) && ( LastK > LastD ) ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 2
      if ( ( StringFind ( safRules , "2" , 0 ) >= 0 ) ) {
         if ( ( CurrentK < safBStart ) && ( CurrentD < safBStart ) ) { result += "B" ; }
         else if ( ( CurrentK > safSStart ) && ( CurrentD > safSStart ) ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 3
      if ( ( StringFind ( safRules , "3" , 0 ) >= 0 ) ) {
         if ( ( CurrentK > safBStart ) && ( CurrentD > safBStart ) && ( LastK < safBStart ) && ( LastD < safBStart ) ) { result += "B" ; }
         else if ( ( CurrentK < safSStart ) && ( CurrentD < safSStart ) && ( LastK > safSStart ) && ( LastD > safSStart ) ) { result += "S" ; }
         else { return "X" ; } }
      return result ; }

   string goSignal_Channel ( string safRules="2" , string safType="BOL" , int safTrending=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // BOL: 0 - BASE LINE , 1 - UPPER BAND , 2 - LOWER BAND
      // ENV: 0 - UPPER LINE , 1 - LOWER LINE
      string result = "" ;
      static string LastLinePassType ;
      // RULE 1: Trade if you cross out of bands
      // RULE 2: Trade if you cross back into bands
      // RULE 3: Use middle line as filter - buy if below and sell if above
      // RULE 4: Use Last Line Pass type as filter - use lower and upper lines only
      // RULE 5: Use Last Line Pass type as filter - use middle line
      // RULE 6: Use middle line crossover as filter
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending ) ;
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
      double CurrentPrice     = glb_PI [ glb_FC ].close ;
      double LastPrice        = glb_PI [ glb_FC + 1 ].close ;
      double CurrentUpper = 0 , LastUpper = 0 , CurrentMiddle = 0 , LastMiddle = 0 , CurrentLower = 0 , LastLower = 0 ;
      if ( StringSubstr ( safType , 0 , 3 ) == "BOL" ) {
         StringReplace ( safType , "BOL" , "" ) ;
         // -------------------- handle indicator here
         if ( ind_Band ( 20 , 0 , double ( safType ) ) == false ) {
            glb_BD = sCurr_BufferDepth ;
            return "X" ; }
         CurrentUpper  = B1 [ glb_FC ] ;
         LastUpper     = B1 [ glb_FC + 1 ] ;
         CurrentMiddle = B0 [ glb_FC ] ;
         LastMiddle    = B0 [ glb_FC + 1 ] ;
         CurrentLower  = B2 [ glb_FC ] ;
         LastLower     = B2 [ glb_FC + 1 ] ;
         // -------------------- RULE 4
         if ( StringFind ( safRules , "4" , 0 ) >= 0 ) {
            if ( ( CurrentPrice > CurrentUpper ) && ( LastPrice < LastUpper ) ) { LastLinePassType = "S" ; }
            else if ( ( CurrentPrice < CurrentUpper ) && ( LastPrice > LastUpper ) ) { LastLinePassType = "S" ; }
            else if ( ( CurrentPrice > CurrentMiddle ) && ( LastPrice < LastMiddle ) ) { LastLinePassType = "X" ; }
            else if ( ( CurrentPrice < CurrentMiddle ) && ( LastPrice > LastMiddle ) ) { LastLinePassType = "X" ; }
            else if ( ( CurrentPrice > CurrentLower ) && ( LastPrice < LastLower ) ) { LastLinePassType = "B" ; }
            else if ( ( CurrentPrice < CurrentLower ) && ( LastPrice > LastLower ) ) { LastLinePassType = "B" ; }
            result += LastLinePassType ; }
         // -------------------- RULE 5
         if ( StringFind ( safRules , "5" , 0 ) >= 0 ) {
            if ( ( CurrentPrice > CurrentMiddle ) && ( LastPrice < LastMiddle ) ) { LastLinePassType = "B" ; }
            else if ( ( CurrentPrice < CurrentMiddle ) && ( LastPrice > LastMiddle ) ) { LastLinePassType = "S" ; }
            result += LastLinePassType ; }
         // -------------------- RULE 6
         if ( StringFind ( safRules , "6" , 0 ) >= 0 ) {
            if ( ( CurrentPrice > CurrentMiddle ) && ( LastPrice < LastMiddle ) ) { result += "B" ; }
            else if ( ( CurrentPrice < CurrentMiddle ) && ( LastPrice > LastMiddle ) ) { result += "S" ; }
            else { result += "X" ; }}
         // -------------------- Check for trending
         if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "B" , "S"  , "X" ) ; } }
      if ( safType == "ENV" ) {
         // -------------------- handle indicator here
         if ( ind_Envelopes () == false ) {
            glb_BD = sCurr_BufferDepth ;
            return "X" ; }
         CurrentUpper  = B0 [ glb_FC ] ;
         LastUpper     = B0 [ glb_FC + 1 ] ;
         CurrentLower  = B1 [ glb_FC ] ;
         LastLower     = B1 [ glb_FC + 1 ] ; }
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         if ( ( CurrentPrice < CurrentLower ) && ( LastPrice > LastLower ) ) { result += "B" ; }
         else if ( ( CurrentPrice > CurrentUpper ) && ( LastPrice < LastUpper ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
         if ( ( CurrentPrice > CurrentLower ) && ( LastPrice < LastLower ) ) { result += "B" ; }
         else if ( ( CurrentPrice < CurrentUpper ) && ( LastPrice > LastUpper ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 3
      if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
         if ( CurrentPrice < CurrentMiddle ) { result += "B" ; }
         else if ( CurrentPrice > CurrentMiddle ) { result += "S" ; }
         else { result += "X" ; } }
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_Fractal () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "X" ;
      // -------------------- handle indicator here
      if ( ind_Fractals () == false ) { return "X" ; }
      double safUpper      = B0 [ glb_FC + 1 ] ;
      double safLower      = B1 [ glb_FC + 1 ] ;
      double CurrentHigh   = glb_PI [ glb_FC ].high ;
      double CurrentLow    = glb_PI [ glb_FC ].low ;
      if ( ( safUpper != EMPTY_VALUE ) && ( safUpper > CurrentHigh ) ) { result = "S" ; }
      else if ( ( safLower != EMPTY_VALUE ) && ( safLower < CurrentLow ) ) { result = "B" ; }
      return result ; }

   string goSignal_IndicatorAverage ( string safRules="1" , string safType="STD" , int safPeriod=20 , int NoOfCandles=20 , int safTrending=1 , double safPercentTrigger=75 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: If value is higher than percent trigger then trade
      // RULE 2: if value is bigger than zero then trade
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + MathMax ( NoOfCandles , safTrending ) ) ;
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
      if ( safType == "VOL" ) {
         // -------------------- handle indicator here
         if ( ind_Volumes () == false ) {
            glb_BD = sCurr_BufferDepth ;
            return "X" ; }}
      if ( safType == "STD" ) {
         // -------------------- handle indicator here
         if ( ind_StdDev ( safPeriod , 0 ) == false ) {
            glb_BD = sCurr_BufferDepth ;
            return "X" ; }}
      if ( safType == "ATR" ) {
         // -------------------- handle indicator here
         if ( ind_ATR ( safPeriod ) == false ) {
            glb_BD = sCurr_BufferDepth ;
            return "X" ; }}
      double safCurrentValue = B0 [ glb_FC ] ;
      double safUpper = B0 [ ArrayMaximum ( B0 , glb_FC , WHOLE_ARRAY ) ] ;
      double safLower = B0 [ ArrayMinimum ( B0 , glb_FC , WHOLE_ARRAY ) ] ;
      double safTrigger = safLower + ( ( ( safUpper - safLower ) / 100 ) * safPercentTrigger ) ;
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         if ( safCurrentValue >= safTrigger ) { result += "Y" ; } else { result += "X" ; } }
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
         if ( safCurrentValue > 0 ) { result += "Y" ; } else { result += "X" ; } }
      if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "Y" , "X" , "X" ) ; }
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_IndicatorAverageMulti ( string safRules="1" , string safType="STD" , string safPeriod="20" , int NoOfCandles=20 , int safTrending=1 , double safPercentTrigger=75 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      static string LastResult ;
      double safLastPeriodValue = 0 ;
      // RULE 1: If value is higher than percent trigger then trade
      // RULE 2: if value is bigger than zero then trade
      // RULE 3: Indicator value is above/below each other
      // RULE 4: Only return signal changes
      string safOriginalRules = safRules ;
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + MathMax ( NoOfCandles , safTrending ) ) ;
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
      string safTypeArray[] ; StringSplit ( ( safType + "|" ) , StringGetCharacter ( "|" , 0 ) , safTypeArray ) ;
      string safPeriodArray[] ; StringSplit ( ( safPeriod + "|" ) , StringGetCharacter ( "|" , 0 ) , safPeriodArray ) ;
      for ( int i = 0 ; i < ArraySize ( safPeriodArray ) - 1 ; i++ ) {
         for ( int j = 0 ; j < ArraySize ( safTypeArray ) - 1 ; j++ ) {
            int safPeriod2Use = int ( safPeriodArray[ i ] ) ;
            string safType2Use = safTypeArray[ j ] ;
            if ( safPeriod2Use > 0 ) {
               if ( StringLen ( UT ( safType2Use ) ) > 0 ) {
                  safRules = safOriginalRules ;
                  if ( safType2Use == "VOL" ) {
                     // -------------------- handle indicator here
                     if ( ind_Volumes () == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "STD" ) {
                     // -------------------- handle indicator here
                     if ( ind_StdDev ( safPeriod2Use , 0 ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  if ( safType2Use == "ATR" ) {
                     // -------------------- handle indicator here
                     if ( ind_ATR ( safPeriod2Use ) == false ) {
                        glb_BD = sCurr_BufferDepth ;
                        return "X" ; }}
                  double safCurrentValue = B0 [ glb_FC ] ;
                  double safUpper = B0 [ ArrayMaximum ( B0 , glb_FC , WHOLE_ARRAY ) ] ;
                  double safLower = B0 [ ArrayMinimum ( B0 , glb_FC , WHOLE_ARRAY ) ] ;
                  double safTrigger = safLower + ( ( ( safUpper - safLower ) / 100 ) * safPercentTrigger ) ;
                  // -------------------- RULE 1
                  if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
                     if ( safCurrentValue >= safTrigger ) { result += "Y" ; } else { result += "X" ; } }
                  // -------------------- RULE 2
                  if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
                     if ( safCurrentValue > 0 ) { result += "Y" ; } else { result += "X" ; } }
                  if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "Y" , "X" , "X" ) ; }
                  // -------------------- RULE 3
                  if ( ( StringFind ( safRules , "3" , 0 ) >= 0 ) ) {
                     if ( safLastPeriodValue != 0 ) {
                        if ( safLastPeriodValue > safCurrentValue ) { result += "Y" ; } else { result += "X" ; }
                     } safLastPeriodValue = safCurrentValue ; }}}}}
      // -------------------- RULE 4
      if ( ( StringFind ( safRules , "4" , 0 ) >= 0 ) ) {
         if ( result == LastResult ) { result += "X" ; } else { LastResult = result ; }}
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_UpDownCandleRatio ( string safRules="1" , int NoOfCandles=10 , int StartCandle=1 , double safFactor=2 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Return signal based on number of up and down candles
      // RULE 2: Return signal based on total up and total down pips
      // RULE 3: return signal based on Candle Type wicks
      // RULE 4: return signal based on All wicks
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , StartCandle + NoOfCandles ) ; // Add another vraiable here
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
      int safUpCandles = 0 , safDownCandles = 0 ;
      double safUpPoints = 0 , safDownPoints = 0 , safUpTypeWicks = 0 , safDownTypeWicks = 0 , safUpAllWicks = 0 , safDownAllWicks = 0 ;
      for ( int i = StartCandle ; i < StartCandle + NoOfCandles ; i++ ) {
         safUpAllWicks += glb_PI[i].high - MathMax ( glb_PI[i].open , glb_PI[i].close ) ;
         safDownAllWicks += MathMin ( glb_PI[i].open , glb_PI[i].close ) - glb_PI[i].low ;
         if ( glb_PI[i].open < glb_PI[i].close ) {
            safUpCandles += 1 ;
            safUpPoints += ( glb_PI[i].close - glb_PI[i].open ) ;
            safUpTypeWicks += glb_PI[i].high - MathMax ( glb_PI[i].open , glb_PI[i].close ) ; }
         else if ( glb_PI[i].open > glb_PI[i].close ) {
            safDownCandles += 1 ;
            safDownPoints += ( glb_PI[i].open - glb_PI[i].close ) ;
            safDownTypeWicks += MathMin ( glb_PI[i].open , glb_PI[i].close ) - glb_PI[i].low ; }}
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         if ( safUpCandles == 0 ) { result += "S" ; }
         else if ( safDownCandles == 0 ) { result += "B" ; }
         else if ( safUpCandles / safDownCandles >= safFactor ) { result += "B" ; }
         else if ( safDownCandles / safUpCandles >= safFactor ) { result += "S" ; }
         else  { result += "X" ; }}
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
         if ( safUpPoints == 0 ) { result += "S" ; }
         else if ( safDownPoints == 0 ) { result += "B" ; }
         else if ( safUpPoints / safDownPoints >= safFactor ) { result += "B" ; }
         else if ( safDownPoints / safUpPoints >= safFactor ) { result += "S" ; }
         else  { result += "X" ; }}
      // -------------------- RULE 3
      if ( StringFind ( safRules , "3" , 0 ) >= 0 ) {
         if ( safUpTypeWicks == 0 ) { result += "B" ; }
         else if ( safDownTypeWicks == 0 ) { result += "S" ; }
         else if ( safUpTypeWicks / safDownTypeWicks >= safFactor ) { result += "S" ; }
         else if ( safDownTypeWicks / safUpTypeWicks >= safFactor ) { result += "B" ; }
         else  { result += "X" ; }}
      // -------------------- RULE 4
      if ( StringFind ( safRules , "4" , 0 ) >= 0 ) {
         if ( safUpAllWicks == 0 ) { result += "B" ; }
         else if ( safDownAllWicks == 0 ) { result += "S" ; }
         else if ( safUpAllWicks / safDownAllWicks >= safFactor ) { result += "S" ; }
         else if ( safDownAllWicks / safUpAllWicks >= safFactor ) { result += "B" ; }
         else  { result += "X" ; }}
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_Alligator ( string safRules="124" , int safTrending=1 , double safFan=0.8 , double safMinProfit=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      static string LastResult ;
      // RULE 1: Price above/below alligator
      // RULE 2: Alligator are in right order
      // RULE 3: Price above/below for 5 candles
      // RULE 4: MAs fanned out equally ( 80% to 1/80% )
      // RULE 5: Alligators are in right order for 5 candles
      // RULE 6: return when signal changes only
      // RULE A: Close on jaw/teeth crossover
      // RULE B: Close on jaw/lips crossover
      // RULE C: Close on teeth/lips crossover
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending + 5 ) ;
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
      // 0 - GATOR JAW LINE ( lower ) , 1 - GATOR TEETH LINE , 2 - GATOR LIPS LINE ( upper )
      // -------------------- handle indicator here
      if ( ind_Alligator () == false ) {
         glb_BD = sCurr_BufferDepth ;
         return "X" ; }
      double safCurrentPrice = glb_PI[ glb_FC ].close ;
      double safUpper = MathMax ( MathMax ( B0 [ glb_FC ] , B1 [ glb_FC ] ) , B2 [ glb_FC ] ) ;
      double safLower = MathMin ( MathMin ( B0 [ glb_FC ] , B1 [ glb_FC ] ) , B2 [ glb_FC ] ) ;
      // -------------------- Trending
      if ( safTrending > 0 ) {
         for ( int i = glb_FC ; i < glb_FC + safTrending ; i++ ) {
            if ( ( B0 [ i ] > B0 [ i + 1 ] ) && ( B1 [ i ] > B1 [ i + 1 ] ) && ( B2 [ i ] > B2 [ i + 1 ] ) ) { result += "B" ; }
            else if ( ( B0 [ i ] < B0 [ i + 1 ] ) && ( B1 [ i ] < B1 [ i + 1 ] ) && ( B2 [ i ] < B2 [ i + 1 ] ) ) { result += "S" ; }
            else { result += "X" ; }}}
      // -------------------- RULE 1
      if ( ( StringFind ( safRules , "1" , 0 ) >= 0 ) ) {
         if ( safCurrentPrice > safUpper ) { result += "B" ; }
         else if ( safCurrentPrice < safLower ) { result += "S" ; }
         else { result += "X" ; }}
      // -------------------- RULE 2
      if ( ( StringFind ( safRules , "2" , 0 ) >= 0 ) ) {
         if ( ( B2 [ glb_FC ] > B1 [ glb_FC ] ) && ( B1 [ glb_FC ] > B0 [ glb_FC ] ) ) { result += "B" ; }
         else if ( ( B2 [ glb_FC ] < B1 [ glb_FC ] ) && ( B1 [ glb_FC ] < B0 [ glb_FC ] ) ) { result += "S" ; }
         else { result += "X" ; }}
      // -------------------- RULE 3
      if ( ( StringFind ( safRules , "3" , 0 ) >= 0 ) ) {
         for ( int i = glb_FC ; i < glb_FC + 5 ; i++ ) {
            if ( glb_PI[ i ].close > MathMax ( MathMax ( B0 [ i ] , B1 [ i ] ) , B2 [ i ] ) ) { result += "B" ; }
            else if ( glb_PI[ i ].close < MathMin ( MathMin ( B0 [ i ] , B1 [ i ] ) , B2 [ i ] ) ) { result += "S" ; }
            else { result += "X" ; }}}
      // -------------------- RULE 4
      if ( ( StringFind ( safRules , "4" , 0 ) >= 0 ) ) {
         double safDist01 = MathAbs ( B0 [ glb_FC ] - B1 [ glb_FC ] ) ;
         double safDist02 = MathAbs ( B1 [ glb_FC ] - B2 [ glb_FC ] ) ;
         if ( ( safDist01 / safDist02 >= safFan ) && ( safDist01 / safDist02 <= ( 1 / safFan ) ) ) {
            result += "Y" ; } else { result += "X" ; }}
      // -------------------- RULE 5
      if ( ( StringFind ( safRules , "5" , 0 ) >= 0 ) ) {
         for ( int i = glb_FC ; i < glb_FC + 5 ; i++ ) {
            if ( ( B2 [ i ] > B1 [ i ] ) && ( B1 [ i ] > B0 [ i ] ) ) { result += "B" ; }
            else if ( ( B2 [ i ] < B1 [ i ] ) && ( B1 [ i ] < B0 [ i ] ) ) { result += "S" ; }
            else { result += "X" ; }}}
      // -------------------- RULE 6
      if ( ( StringFind ( safRules , "6" , 0 ) >= 0 ) ) {
         if ( result == LastResult ) { result += "X" ; } else { LastResult = result ; }}
      // -------------------- RULE A
      if ( ( StringFind ( safRules , "A" , 0 ) >= 0 ) ) {
         if ( ( ( B0 [ glb_FC + 1 ] > B1 [ glb_FC + 1 ] ) && ( B0 [ glb_FC ] < B1 [ glb_FC ] ) ) ||
         ( ( B0 [ glb_FC + 1 ] < B1 [ glb_FC + 1 ] ) && ( B0 [ glb_FC ] > B1 [ glb_FC ] ) ) ) {
            if ( PositionsTotal() > 0 ) { goClose_PositivePositions ( safMinProfit ) ; }}}
      // -------------------- RULE B
      if ( ( StringFind ( safRules , "B" , 0 ) >= 0 ) ) {
         if ( ( ( B0 [ glb_FC + 1 ] > B2 [ glb_FC + 1 ] ) && ( B0 [ glb_FC ] < B2 [ glb_FC ] ) ) ||
         ( ( B0 [ glb_FC + 1 ] < B2 [ glb_FC + 1 ] ) && ( B0 [ glb_FC ] > B2 [ glb_FC ] ) ) ) {
            if ( PositionsTotal() > 0 ) { goClose_PositivePositions ( safMinProfit ) ; }}}
      // -------------------- RULE C
      if ( ( StringFind ( safRules , "C" , 0 ) >= 0 ) ) {
         if ( ( ( B1 [ glb_FC + 1 ] > B2 [ glb_FC + 1 ] ) && ( B1 [ glb_FC ] < B2 [ glb_FC ] ) ) ||
         ( ( B1 [ glb_FC + 1 ] < B2 [ glb_FC + 1 ] ) && ( B1 [ glb_FC ] > B2 [ glb_FC ] ) ) ) {
            if ( PositionsTotal() > 0 ) { goClose_PositivePositions ( safMinProfit ) ; }}}
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_AwesomeOscillator ( string safRules="123" , int NoOfCandles=1440 , double safPercent=25 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Indicator above/below zero
      // RULE 2: Saucer entry
      // RULE 3: value above certain percet trigger
      // RULE 4: Indicator cross above/below zero
      // RULE 5: peaks entry
      int sCurr_BufferDepth = glb_BD ;
      if ( ( StringReplace ( safRules , "3" , "" ) == 0 ) ) { NoOfCandles = 1 ; }
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + NoOfCandles ) ;
      // -------------------- handle indicator here
      if ( ind_AO () == false ) {
         glb_BD = sCurr_BufferDepth ;
         return "X" ; }
      double AO_C = B0 [ glb_FC ] ; double AO_L = B0 [ glb_FC + 1 ] ; double AO_P = B0 [ glb_FC + 2 ] ;
      // -------------------- RULE 1
      if ( ( StringFind ( safRules , "1" , 0 ) >= 0 ) ) {
         if ( AO_C > 0 ) { result += "B" ; }
         else if ( AO_C < 0 ) { result += "S" ; }
         else { result += "X" ; }}
      // -------------------- RULE 2
      if ( ( StringFind ( safRules , "2" , 0 ) >= 0 ) ) {
         if ( ( ( AO_P > AO_L ) && ( AO_C > AO_L ) ) && ( AO_C > 0 ) ) { result += "B" ; }
         else if ( ( ( AO_P < AO_L ) && ( AO_C < AO_L ) ) && ( AO_C < 0 ) ) { result += "S" ; }
         else { result += "X" ; }}
      // -------------------- RULE 3
      if ( ( StringFind ( safRules , "3" , 0 ) >= 0 ) ) {
         double safAboveValue=0 , safAboveCount=0 , safBelowValue=0 , safBelowCount=0 ;
         for ( int i = glb_FC ; i < glb_FC + NoOfCandles + 1 ; i++ ) {
            if ( B0[ i ] > 0 ) { safAboveValue += B0[ i ] ; safAboveCount += 1 ; }
            else if ( B0[ i ] < 0 ) { safBelowValue += B0[ i ] ; safBelowCount += 1 ; }}
         double safAboveTrigger = 0 + MathAbs ( ( ( safAboveValue / safAboveCount ) / 50 * safPercent ) ) ;
         double safBelowTrigger = 0 - MathAbs ( ( ( safBelowValue / safBelowCount ) / 50 * safPercent ) ) ;
         if ( AO_C > safAboveTrigger ) { result += "B" ; }
         else if ( AO_C < safBelowTrigger ) { result += "S" ; }
         else { result += "X" ; }}
      // -------------------- RULE 4
      if ( ( StringFind ( safRules , "4" , 0 ) >= 0 ) ) {
         if ( ( AO_C > 0 ) && ( AO_L < 0 ) ) { result += "B" ; }
         else if ( ( AO_C < 0 ) && ( AO_L > 0 ) ) { result += "S" ; }
         else { result += "X" ; }}
      // -------------------- RULE 5
      if ( ( StringFind ( safRules , "5" , 0 ) >= 0 ) ) {
         if ( ( ( AO_P > AO_L ) && ( AO_C > AO_L ) ) && ( AO_C < 0 ) ) { result += "B" ; }
         else if ( ( ( AO_P < AO_L ) && ( AO_C < AO_L ) ) && ( AO_C > 0 ) ) { result += "S" ; }
         else { result += "X" ; }}
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_EntrySNR (
      string safRules ="ABCDE12" , string sTrend="EMA" , string sOsci="MFI" , string sPower="ADX" ) {
         //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
         string result = "" ;
         // RULE A: Half ATR filter
         // RULE B: Monday delay start
         // RULE C: Friday early close
         // RULE D: Is day ok to trade
         // RULE E: Is it session
         // RULE 1: Do checks on Period D1
         // RULE 2: Do checks on Period H1
         // RULE 3: Do checks on Period M1
         // -------------------- Check Half ATR rule
         if ( ( StringFind ( safRules , "A" , 0 ) >= 0 ) ) {
            if ( ind_ATR ( 14 ) == false ) { return ( "X" ) ; }
            double sATR_C = B0 [ glb_FC ] ;
            if ( ( sAsk() - sBid() ) > sATR_C * 0.5 ) { return ( "X" ) ; }}
         // -------------------- Monday delay start
         if ( ( StringFind ( safRules , "B" , 0 ) >= 0 ) ) {
            if ( goDelayMondayStart ( 8 ) == "X" ) { return ( "X" ) ; }}
         // -------------------- Friday early close
         if ( ( StringFind ( safRules , "C" , 0 ) >= 0 ) ) {
            if ( goEndFridayEarly ( 14 ) == "X" ) { return ( "X" ) ; }}
         // -------------------- No trade days check
         if ( ( StringFind ( safRules , "D" , 0 ) >= 0 ) ) {
            if ( IsDay_NoTradeDay () ) { return ( "X" ) ; }}
         // -------------------- Session check
         if ( ( StringFind ( safRules , "E" , 0 ) >= 0 ) ) {
            result += IsSession_Auto () ; }
         // -------------------- Store current period
         ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
            // -------------------- Calc on Daily indicators
            if ( ( StringFind ( safRules , "1" , 0 ) >= 0 ) ) {
               glb_EAP = PERIOD_D1 ;
               CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
               result += goSignal_Trend ( "1" , sTrend , 200 , 1 ) ;
               result += goSignal_Oscillator ( "1" , sOsci , 4 , 1 ) ;
               result += goSignal_ADX ( "1" , sPower , 4 , 1 ) ; }
            // -------------------- Calc on hourly indicators
            if ( ( StringFind ( safRules , "2" , 0 ) >= 0 ) ) {
            glb_EAP = PERIOD_H1 ;
               CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
               result += goSignal_Trend ( "1" , sTrend , 200 , 1 ) ;
               result += goSignal_Oscillator ( "1" , sOsci , 4 , 1 ) ;
               result += goSignal_ADX ( "1" , sPower , 4 , 1 ) ; }
            // -------------------- Calc on Minute indicators
            if ( ( StringFind ( safRules , "3" , 0 ) >= 0 ) ) {
               glb_EAP = PERIOD_M1 ;
               CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
               result += goSignal_Trend ( "1" , sTrend , 200 , 1 ) ;
               result += goSignal_Oscillator ( "1" , sOsci , 4 , 0 ) ;
               result += goSignal_ADX ( "1" , sPower , 4 , 0 ) ; }
         // -------------------- return to bot period
         glb_EAP = sCurr_Period ;
         CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
         return ( result ) ; }

   //===========================================================================================================
   //=====                                        NEW BOT TEMPLATE                                         =====
   //===========================================================================================================

/*

   #include <newFunctions.mqh>

   #define SNR_BOTVER      "Bot Version: xx.xx.xx"

   #property copyright     SNR_COPYRIGHT
   #property link          SNR_WEBSITE
   #property description   SNR_LIBVER
   #property description   SNR_BOTVER

   void OnInit () {
      goOnInit () ;
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      glb_FC               = 1 ;
      glb_BD               = 3 ;
      glb_SunsetDays       = 0 ;
      glb_Write2Server     = false ;
      glb_SilentMode       = false ;
      glb_DebugMode        = false ;
      glb_MinTradeMode     = false ;
      glb_BeaconMode       = false ;
      glb_Magic            = "SNR" ;
      glb_EAS              = _Symbol ;
      glb_BroadID          = "" ;
      glb_BaseCurr         = "USD" ;
      glb_FileName         = "" ;
      glb_SunsetDate       = "" ;
      glb_LotSize          = 0.01 ;
      glb_MaxCapitalValue  = 100 ;
      glb_MaxCapitalPerc   = 65 ;
      glb_MaxLotPerK       = 0.015 ;
      glb_MaxDDTrigger     = 0 ;
      glb_UpperTradeLimit  = 999999 ;
      glb_LowerTradeLimit  = 0 ;
      glb_MaxDDBehaviour   = Do_Noting ;
      glb_AllowedStops     = SL_and_TP ;
      glb_AllowedTrade     = No_Trade ;
      glb_EAP              = _Period ;
      goBroadcast_OPS ( goTele_PrepMsg ( "BOT" , "STARTED" , SNR_LIBVER , SNR_BOTVER ) ) ; }

   void OnTick () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( !IsNewCandle() ) { return ; }
      goCheckEntry () ;
      if ( PositionsTotal() > 0 ) { goCheckTrail () ; }}

   void goCheckEntry () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string mySig = "" ;
      if ( ind_ATR ( 14 ) == false ) { return ; }
      double ATR_C = B0 [ glb_FC ] ;
      // -------------------- Non indicator filters
      if ( goDelayMondayStart ( 8 ) == "X" ) { return ; }
      if ( goEndFridayEarly ( 14 ) == "X" ) { return ; }
      if ( IsDay_NoTradeDay () ) { return ; }
      if ( ( sAsk() - sBid() ) > ATR_C * 0.5 ) { return ; }
      // -------------------- indicator filters

      // -------------------- Trade here
      mySig = goCleanSignal ( mySig ) ;
      // -------------------- BUY HERE
      if ( mySig == "B" ) {
         sBuy () ;
         goDraw_VerticalLine ( "" , glb_PI [ glb_FC ].time , clrBlue ) ; }
      // -------------------- SELL HERE
      else if ( mySig == "S" ) {
         sSell () ;
         goDraw_VerticalLine ( "" , glb_PI [ glb_FC ].time , clrBlue ) ; }}

   void goCheckTrail () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      goTrail_AfterBE_SLV ( goCalc_DailyM1ATR ( 1440 ) ) ; }

*/

   //===========================================================================================================
   //=====                                            TEMPLATE                                             =====
   //===========================================================================================================

   string goStandardFunctionFormat ( string safRules="" , int safType=0 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string result = "" ;
      // RULE 1: Rule 1 explanation
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      string sCurr_Symbol = glb_EAS ;
      int sCurr_BufferDepth = glb_BD ;
         glb_EAP = PERIOD_D1 ;
         glb_EAS = "" ;
         glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 ) ; // Add another vraiable here
         if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; }
         double CurrentPrice     = glb_PI [ glb_FC ].close ;
         double LastPrice        = glb_PI [ glb_FC + 1 ].close ;
         // -------------------- RULE 1
         if ( StringFind ( safRules , "1" , 0 ) >= 0 ) { ; }
         // -------------------- RULE 2
         if ( StringFind ( safRules , "2" , 0 ) >= 0 ) { ; }
      glb_EAP = sCurr_Period ;
      glb_EAS = sCurr_Symbol ;
      glb_BD = sCurr_BufferDepth ;
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      return result ; }

   //===========================================================================================================
   //=====                                           AUTO DEPLOY                                           =====
   //===========================================================================================================

   void goAutoDeploy_LogBuyTrade ( double safATR , string safComment , string BotMagicSuffix , double safATRFactor=1.5 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string safTarget = string ( ND ( sAsk() + ( safATR * safATRFactor ) ) ) ;
      goLocalFile_Write ( "|AUTODEPLOY|B|" + safTarget + "|" + string ( glb_PI[0].time ) + "&" + safComment , BotMagicSuffix ) ; }

   void goAutoDeploy_LogSellTrade ( double safATR , string safComment , string BotMagicSuffix , double safATRFactor=1.5 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string safTarget = string ( ND ( sBid() - ( safATR * safATRFactor ) ) ) ;
      goLocalFile_Write ( "|AUTODEPLOY|S|" + safTarget + "|" + string ( glb_PI[0].time ) + "&" + safComment , BotMagicSuffix ) ; }

   void goAutoDeploy_Check ( string BotMagicSuffix , string BotConfigString , int MinTradeCount=3 , int MaxHoursOpen=3 , int MaxFailCount=3 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      if ( glb_SilentMode == true ) { return ; }
      // -------------------- Return if beacon already not a test
      if ( StringFind ( UT ( glb_Magic ) , "TEST" , 0 ) < 0 ) { return ; }
      // -------------------- Variables
      string FileContent[] ;
      int safSuccessCounter = 0 ;
      int safFailedCounter = 0 ;
      int safOpenCounter = 0 ;
      // -------------------- Read all log file data
      if ( !goLocalFile_Read ( FileContent ) ) { return ; }
      // -------------------- Go thru file content line by line
      for ( int i=0 ; i < ArraySize ( FileContent ) ; i ++ ) {
         // -------------------- If already deployed then silent quit
         if ( StringFind ( FileContent [i] , "|DEPLOYED|" , 0 ) >= 0 ) {
            StringReplace ( glb_Magic , "TEST" , "" ) ;
            glb_BroadID = glb_Magic ;
            goPrint ( ( glb_EAS + BotMagicSuffix ) + " - REDEPLOYED" ) ;
            return ; }
         // -------------------- If already rejected then quit
         if ( StringFind ( FileContent [i] , "|FAILEDAUTODEPLOY|" , 0 ) >= 0 ) {
            goPrint ( ( glb_EAS + BotMagicSuffix ) + " - DEPLOY FAILED" ) ;
            ExpertRemove () ; }
         // -------------------- If found an autodeploy then check if already closed
         if ( StringFind ( FileContent [i] , "|AUTODEPLOY|" , 0 ) >= 0 ) {
            // -------------------- Variables
            bool AlreadyClosed = false ;
            string LineSplits [] ;
            // -------------------- Split line to extract magic for comparison
            StringSplit ( FileContent [i] , StringGetCharacter ( "&" , 0 ) , LineSplits ) ;
            string TradeMagic = LineSplits[1] ;
            // -------------------- Go thru rest of file to look for close
            for ( int j=i ; j < ArraySize ( FileContent ) ; j ++ ) {
               // -------------------- Check if magix exists with suffic success
               if ( StringFind ( FileContent [j] , TradeMagic + "-SUCCESS" , 0 ) >= 0 ) {
                  // -------------------- Change variables and quit loop if found
                  AlreadyClosed = true ;
                  safSuccessCounter += 1 ;
                  break ;
               } // close SUCCESS check
               if ( StringFind ( FileContent [j] , TradeMagic + "-FAILED" , 0 ) >= 0 ) {
                  // -------------------- Change variables and quit loop if found
                  AlreadyClosed = true ;
                  safFailedCounter += 1 ;
                  break ;
               } // close FAIL check
            } // next j
            // -------------------- If trade is still open, then get last candles and check for close
            if ( AlreadyClosed == false ) {
               // -------------------- Get last 65 candle prices
               MqlRates myPI [] ;
               ArraySetAsSeries ( myPI , true ) ;
               CopyRates ( glb_EAS , glb_EAP , 0 , 65 , myPI ) ;
               // -------------------- Get trade direction
               string TradeInfo [] ;
               StringSplit ( LineSplits[0] , StringGetCharacter ( "|" , 0 ) , TradeInfo ) ;
               string TradeType = TradeInfo [2] ;
               double TradeCloseTrigger = double ( TradeInfo [3] ) ;
               string TradeOpentime = TradeInfo [4] ;
               // -------------------- go thru candles and see if price closed
               bool TradeClosed = false ;
               for ( int j=0 ; j < ArraySize ( myPI ) ; j ++ ) {
                  // -------------------- break if u r past the trade candle
                  if ( myPI[j].time <= datetime ( TradeOpentime ) ) { break ; }
                  if ( TradeType == "B" ) {
                     if ( myPI[j].high >= TradeCloseTrigger ) {
                        TradeClosed = true ;
                        break ; }
                  } else {
                     if ( myPI[j].low <= TradeCloseTrigger ) {
                        TradeClosed = true ;
                        break ; }
                  } // close trade type check
               } // next j
               // -------------------- Denote open trade if still open to stop autodeploy
               if ( TradeClosed == false ) { safOpenCounter += 1 ; }
               // -------------------- Write to file if trade was closed in last hour
               if ( TradeClosed == true ) {
                  double safElapsedTime = goCalc_HoursBetweenDates ( datetime ( TradeOpentime ) , myPI[0].time ) ;
                  if ( safElapsedTime <= MaxHoursOpen ) {
                     goLocalFile_Write ( ( TradeMagic + "-SUCCESS (" + string ( safElapsedTime ) + ")" ) , BotMagicSuffix ) ;
                     safSuccessCounter += 1 ;
                  } else {
                     goLocalFile_Write ( ( TradeMagic + "-FAILED (" + string ( safElapsedTime ) + ")" ) , BotMagicSuffix ) ;
                     safFailedCounter += 1 ;
                  }
               } // end of trade closed = true
            } // End of already closed = false
         } // End of found autodeploy
      } // Next i
      if ( safFailedCounter >= MaxFailCount ) {
         goBroadcast_OPS ( goTele_PrepMsg ( glb_Magic , "BEACON" , "FAILEDAUTODEPLOY" , ( glb_EAS + BotMagicSuffix + "|" + BotConfigString ) ) ) ;
         goLocalFile_Write ( "|FAILEDAUTODEPLOY|" , BotMagicSuffix ) ;
         ExpertRemove () ; }
      if ( ( safSuccessCounter >= MinTradeCount ) && ( safOpenCounter == 0 ) ) {
         StringReplace ( glb_Magic , "TEST" , "" ) ;
         glb_BroadID = glb_Magic ;
         goBroadcast_OPS ( goTele_PrepMsg ( glb_Magic , "BEACON" , "DEPLOYED" , ( glb_EAS + BotMagicSuffix + "|" + BotConfigString ) ) ) ;
         goLocalFile_Write ( "|DEPLOYED|" , BotMagicSuffix ) ;
      } // end of change from test to live bot
   } // End of Function

   //===========================================================================================================
   //=====                                             TESTER                                              =====
   //===========================================================================================================

   string sTestFN () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      static string result ;
      if ( StringLen ( result ) > 0 ) { return ( result ) ; }
      result = goTranslate_Broker() + "_" + glb_EAS ;
      StringReplace ( result , "." , "" ) ;
      StringToUpper ( result ) ;
      return ( result ) ; }

   bool goTester_FileWrite ( string sFN , string safText , string safType="a" ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- Newfile here
      if ( safType == "n" ) {
         if ( FileIsExist ( sFN , FILE_COMMON ) == true ) {
            FileDelete ( sFN , FILE_COMMON ) ; }}
      // -------------------- Open file to write
      int f = FileOpen ( sFN , FILE_READ | FILE_WRITE | FILE_TXT | FILE_COMMON ) ;
      if ( f == INVALID_HANDLE ) { return ( false ) ; }
      FileSeek ( f , 0 , SEEK_END ) ;
      if ( StringLen ( safText ) > 0 ) { FileWrite ( f , safText ) ; }
      FileClose ( f ) ;
      return ( true ) ; }

   bool goTester_FileRead ( string sFN , string &FileContent[] ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- Open file to read
      ArrayResize ( FileContent , 0 ) ;
      int f = FileOpen ( sFN , FILE_READ | FILE_WRITE | FILE_TXT | FILE_COMMON ) ;
      if ( f == INVALID_HANDLE ) { return ( false ) ; }
      FileReadArray ( f , FileContent , 0 , WHOLE_ARRAY ) ;
      FileClose ( f ) ;
      return ( true ) ; }

   bool goTester_CheckElapseTime ( long safAllowedTime=360000000 , bool SetStart=false ) {
      // -------------------- Variables
      string safFN = "ELAPSE" ;
      // -------------------- Set start of test here ontesterinit
      if ( SetStart == true ) {
         goTester_FileWrite ( safFN , string ( GetTickCount() ) , "n" ) ;
         return true ; }
      // -------------------- Read Elaspse file and do calculations
      string safFC [] ;
      goTester_FileRead ( safFN , safFC ) ;
      if ( ArraySize ( safFC ) < 1 ) { return true ; } // this is just to handle errors and not crash bot
      // -------------------- Main check here
      if ( MathAbs ( long ( safFC [ 0 ] ) - long ( GetTickCount() ) ) > safAllowedTime ) { return false ; }
      goTester_FileWrite ( safFN , string ( GetTickCount() ) ) ;
      return true ; }

   //===========================================================================================================
   //=====                                             TRIMMER                                             =====
   //===========================================================================================================

   bool goTrimmer_Execute ( string &PotentialTrades[] , double ClosingValueTarget , bool ClosePositions ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string safPotentialTickets = "Ticket(s): " ;
      if ( ArraySize ( PotentialTrades ) < 1 ) { return false ; }
      // -------------------- Variables
      string Prioritized [] ;
      double OriginalClosingValueTarget = ClosingValueTarget ;
      // -------------------- Go thru trades to prioritise
      for ( int j = 0 ; j < ArraySize ( PotentialTrades ) ; j++ ) {
         // -------------------- Variables
         double HighestLossPerPercent = 0 ;
         int HighestLossNumber = -1 ;
         // -------------------- find next biggest
         for ( int i = 0 ; i < ArraySize ( PotentialTrades ) ; i++ ) {
            string LineArray[] ;
            StringSplit ( PotentialTrades [ i ] , StringGetCharacter ( "|" , 0 ) , LineArray ) ;
            if ( ArraySize ( LineArray ) < 18 ) { continue ; }
            double posLossPerPercent = double ( LineArray [ 17 ] ) ;
            if ( posLossPerPercent > HighestLossPerPercent ) {
               HighestLossPerPercent = posLossPerPercent ;
               HighestLossNumber = i ; }}
         // -------------------- Add to potential array
         if ( HighestLossNumber > -1 ) {
            int sArrSize = ArraySize ( Prioritized ) ;
            ArrayResize ( Prioritized , sArrSize + 1 ) ;
            Prioritized [ sArrSize ] = PotentialTrades [ HighestLossNumber ] ;
            PotentialTrades [ HighestLossNumber ] = "" ; }}
      // -------------------- Write potentials in order to output
      int TradesToClose = 0 ;
      for ( int i = 0 ; i < ArraySize ( Prioritized ) ; i++ ) {
         string LineArray[] ;
         StringSplit ( Prioritized [ i ] , StringGetCharacter ( "|" , 0 ) , LineArray ) ;
         if ( ArraySize ( LineArray ) < 18 ) { continue ; }
         string posTicket = LineArray [ 1 ] ;
         double posNetProfit = double ( LineArray [ 12 ] ) ;
         double posLossPerPercent = double ( LineArray [ 17 ] ) ;
         if ( MathAbs ( posNetProfit ) <= MathAbs ( ClosingValueTarget ) ) {
            safPotentialTickets += posTicket + "/" + (string) posLossPerPercent + " , " ;
            if ( ClosePositions == true ) {
               trade.PositionClose ( long ( posTicket ) ) ;
               goPrint ( "Trimming ticket number: " + posTicket ) ; }
            ClosingValueTarget -= MathAbs ( posNetProfit ) ;
            TradesToClose += 1 ; }}
      // -------------------- Send telegram message here
      if ( ClosePositions == false ) {
         string sCurr_BroadcastID = glb_BroadID ;
         glb_BroadID = IntegerToString ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ;
            string sMessage2Send = goTele_PrepMsg (
               "Found " + (string) TradesToClose + "/" + (string) ArraySize ( PotentialTrades ) + " trim potentials" ,
               "Total Value: " + (string) ND2 ( OriginalClosingValueTarget ) ,
               safPotentialTickets ) ;
            goBroadcast_OPS ( sMessage2Send ) ;
         glb_BroadID  = sCurr_BroadcastID ; }
      if ( TradesToClose > 0 ) { return true ; } else { return false ; }}

   bool goTrimmer_Check ( double TargetROIPerc=2 , int PeriodInSeconds=2678400 , bool ClosePositions=false ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- Main defined variables
      string ThisPeriodStart = StringSubstr ( ( goGetDateTime ( PeriodInSeconds ) ) , 0 , 6 ) ;
      // -------------------- Working variables
      double TotalDepWith = 0 ;
      double TotalProfit = 0 ;
      double TotalROI = 0 ;
      double PeriodProfit = 0 ;
      double PeriodROI = 0 ;
      static string LastMonth ;
      double safMonthCount = 0 ;
      double PeriodValue = 0 ;
      double TotalValue = 0 ;
      bool OKtoROI = false ;
      // -------------------- Get history
      string HistoryLines[] ;
      goHistory_Retreive ( HistoryLines ) ;
      if ( ArraySize ( HistoryLines ) < 1 ) { return false ; }
      // -------------------- Go thru history
      for ( int i=0 ; i < ArraySize ( HistoryLines ) ; i++ ) {
         // -------------------- Split line
         string safSplit[] ;
         StringSplit ( HistoryLines [ i ] , StringGetCharacter ( "|" , 0 ) , safSplit ) ;
         if ( ArraySize ( safSplit ) < 12 ) { continue ; }
         // -------------------- Deal variables
         string DealType      = safSplit [ 2 ] ;
         string DealTimeTrans = safSplit [ 10 ] ;
         string DealMonth     = StringSubstr ( DealTimeTrans , 0 , 4 ) ;
         string DealMonthOnly = StringSubstr ( DealTimeTrans , 2 , 2 ) ;
         double DealNet       = (double) safSplit [ 11 ] ;
         // -------------------- Calc trade months
         if ( DealMonth != LastMonth ) {
            LastMonth = DealMonth ;
            if ( ( DealMonthOnly == "12" ) || ( DealMonthOnly == "01" ) ) {
               safMonthCount += 0.5 ;
            } else {
               safMonthCount += 1 ; }}
         // -------------------- Add to ROIs
         if ( ( DealType == "BUY" ) || ( DealType == "SELL" ) ) {
            TotalProfit += DealNet ;
            TotalROI += ( DealNet / TotalDepWith ) * 100 ;
            if ( StringSubstr ( DealTimeTrans , 0 , ( StringLen ( ThisPeriodStart ) ) ) >= ThisPeriodStart ) {
               PeriodProfit += DealNet ;
               PeriodROI += ( DealNet / TotalDepWith ) * 100 ; }}
         // -------------------- Add to overall balance
         else if ( DealType == "BALANCE" ) { TotalDepWith += DealNet ; }} // next i
      // -------------------- Total ROI Calc
      double PeriodROI2Protect = TargetROIPerc ;
      if ( PeriodROI > PeriodROI2Protect ) {
         OKtoROI = true ; PeriodValue = ( PeriodProfit / PeriodROI ) * ( PeriodROI - PeriodROI2Protect ) ; }
      // -------------------- Period ROI Calc
      double TotalROI2Protect = ( safMonthCount * TargetROIPerc ) * ( 2678400 / PeriodInSeconds ) ;
      if ( TotalROI > TotalROI2Protect ) {
         OKtoROI = true ; TotalValue = ( TotalProfit / TotalROI ) * ( TotalROI - TotalROI2Protect ) ; }
      // -------------------- Final check
      if ( OKtoROI == false ) { return false ; }
      // -------------------- Display variables to check here
      if ( ClosePositions == false ) {
         goPrint ( "===============================================" ) ;
         goPrint ( "Total Months: " + (string) safMonthCount ) ;
         goPrint ( "ROI (Total/Protect/To use): " + (string) ND2 ( TotalROI ) + " / " + (string) ND2 ( TotalROI2Protect ) + " / " + (string) ND2 ( TotalROI - TotalROI2Protect ) + "%" ) ;
         goPrint ( "Profit (Total/To use): " + (string) ND2 ( TotalProfit ) + " / " + (string) ND2 ( TotalValue ) ) ;
         goPrint ( "-----------------------------------------------" ) ;
         goPrint ( "Period Date: " + ThisPeriodStart ) ;
         goPrint ( "ROI (Period/Protect/To use): " + (string) ND2 ( PeriodROI ) + " / " + (string) ND2 ( PeriodROI2Protect ) + " / " + (string) MathMax ( 0 , ND2 ( PeriodROI - PeriodROI2Protect ) ) + "%" ) ;
         goPrint ( "Profit (Total/To use): " + (string) ND2 ( PeriodProfit ) + " / " + (string) ND2 ( PeriodValue ) ) ;
         goPrint ( "-----------------------------------------------" ) ;
         goPrint ( "Value to use: " + (string) ND2 ( MathMax ( PeriodValue , TotalValue ) ) ) ;
         goPrint ( "===============================================" ) ; }
      // -------------------- Choose value to use for trimming
      double ClosingValueTarget = MathMax ( PeriodValue , TotalValue ) ;
      if ( ClosingValueTarget <= 0 ) { return false ; }
      // -------------------- Get all open positions
      string AllPositions[] ;
      goPositions_Retreive( AllPositions ) ;
      if ( ArraySize ( AllPositions ) < 1 ) { return false ; }
      // -------------------- Find potential closures
      string PotentialTrades[] ;
      for ( int i = 0 ; i < ArraySize ( AllPositions ) ; i++ ) {
         // -------------------- Split line into bits
         string LineArray[] ;
         StringSplit ( AllPositions [ i ] , StringGetCharacter ( "|" , 0 ) , LineArray ) ;
         if ( ArraySize ( LineArray ) < 13 ) { continue ; }
         // -------------------- Get pos variables
         string posTime = LineArray [ 6 ] ;
         double posNetProfit = double ( LineArray [ 12 ] ) ;
         // -------------------- Is loss smaller than trim value
         if ( MathAbs ( posNetProfit ) < ClosingValueTarget ) {
            // -------------------- Is position open time within trim period
            if ( StringSubstr ( posTime , 0 , ( StringLen ( ThisPeriodStart ) ) ) < ThisPeriodStart ) {
               // -------------------- Add to potential array
               int sArrSize = ArraySize ( PotentialTrades ) ;
               ArrayResize ( PotentialTrades , sArrSize + 1 ) ;
               PotentialTrades [ sArrSize ] = AllPositions [ i ] ;
               goPrint ( PotentialTrades [ sArrSize ] ) ; }}}
      return ( goTrimmer_Execute ( PotentialTrades , ClosingValueTarget , ClosePositions ) ) ; }

   //===========================================================================================================
   //=====                                          COUNTER TRADE                                          =====
   //===========================================================================================================

   void goCounterTrade_Execute ( string sCurr , string sType , double sSize ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      string sCurr_Symbol = glb_EAS ;
         glb_EAS = sCurr ;
         // -------------------- Check trade conditions
         string mySig = "" ;
         mySig = goSignal_EntrySNR () ;
         // -------------------- Trade here
         mySig = goCleanSignal ( mySig ) ;
         if ( ( mySig == "S" ) || ( mySig == "B" ) ) {
            ind_ATR() ; double ATR2Use = B0 [ glb_FC ] ;
            if ( ( sType == "BUY" ) && ( mySig == "B" ) ) {
               sBuy ( 0 , 1 , 0 , ATR2Use , 0 , 0 , sSize ) ; }
            else if ( ( sType == "SELL" ) && ( mySig == "S" ) ) {
               sSell ( 0 , 1 , 0 , ATR2Use , 0 , 0 , sSize ) ; }}
      glb_EAS = sCurr_Symbol ; }

   void goCounterTrade_Check () {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // -------------------- Find current One Percent value
      double OnePercent = sBal() / 100 ;
      // -------------------- Get all open positions
      string AllPositions[] ;
      goPositions_Retreive ( AllPositions ) ;
      if ( ArraySize ( AllPositions ) < 1 ) { return ; }
      // -------------------- Go thru them one by one
      for ( int i = 0 ; i < ArraySize ( AllPositions ) ; i++ ) {
         // -------------------- Split line into bits
         string posArray [] ;
         StringSplit ( AllPositions [ i ] , StringGetCharacter ( "|" , 0 ) , posArray ) ;
         if ( ArraySize ( posArray ) < 13 ) { continue ; }
         // -------------------- Get pos variables
         string posCurr = posArray [ 2 ] ;
         string posType = posArray [ 3 ] ;
         double posSize = ND2 ( double ( posArray [ 4 ] ) ) ;
         double posSL = double ( posArray [ 8 ] ) ;
         double posNetProfit = double ( posArray [ 12 ] ) ;
         // -------------------- If positive then no counter
         if ( posNetProfit >= 0 ) { continue ; }
         // -------------------- If loss less than 1 percent then no counter
         if ( MathAbs ( posNetProfit ) < OnePercent ) { continue ; }
         // -------------------- Prep to check opposite
         string posTypeOpposite = "" ;
         if ( posType == "BUY" ) { posTypeOpposite = "SELL" ; }
         else if ( posType == "SELL" ) { posTypeOpposite = "BUY" ; }
         if ( posTypeOpposite == "" ) { continue ; }
         // -------------------- If opposite trade already exists then no counter
         bool OppositeExists = false ;
         for ( int j = 0 ; j < ArraySize ( AllPositions ) ; j++ ) {
            string chkArray [] ;
            StringSplit( AllPositions[j] , StringGetCharacter ( "|" , 0 ) , chkArray ) ;
            if ( ArraySize ( chkArray ) < 9 ) { continue ; }
            string chkCurr = chkArray [ 2 ] ;
            string chkType = chkArray [ 3 ] ;
            double chkSize = ND2 ( double ( chkArray [ 4 ] ) ) ;
            double chkSL = double ( chkArray [ 8 ] ) ;
            if ( ( chkCurr == posCurr ) && ( chkType == posTypeOpposite ) && ( chkSize == posSize ) ) { OppositeExists = true ; break ; }}
         if ( OppositeExists == true ) { continue ; }
         goCounterTrade_Execute ( posCurr , posTypeOpposite , posSize ) ; }}

   //===========================================================================================================
   //=====                                              TEMPS                                              =====
   //===========================================================================================================

   void goClose_EndOfPeriodChecks ( string safRules="1" , double safPerc=1 ) {
      //// if ( glb_DebugMode ) { goDebug ( __FUNCTION__ ) ; }
      // RULE 1: Close all period trades if equity is higher than balance
      // RULE 2: Close all period trades if equity is higher than last balance
      // RULE 3: Close biggest loss ONLY
      // -------------------- Variables
      static double LastBalance ;
      double safBalance = sBal() ;
      if ( LastBalance < 1 ) { LastBalance = safBalance ; } else { LastBalance = LastBalance * 1.001 ; }
      double safEquity = sEqu() ;
      double safDayProfit = ( MathMax ( safBalance , safEquity ) - LastBalance ) * safPerc ;
      // -------------------- Quit if no profit
      if ( safDayProfit <= 0 ) { return ; }
      goPrint ( "Last Day Profit: " + string ( safDayProfit ) ) ;
      // -------------------- RULE 1
      if ( StringFind ( safRules , "1" , 0 ) >= 0 ) {
         if ( safEquity > safBalance ) { goClose_AllPositions() ; }}
      // -------------------- RULE 2
      if ( StringFind ( safRules , "2" , 0 ) >= 0 ) {
         if ( LastBalance > 0 ) { // IMP check so as not to fuck up when u install on an account with open trades
            if ( safEquity > ( LastBalance * 1 ) ) { goClose_AllPositions() ; }}}
      // -------------------- Go get open positions sorted by biggest loss first
      if ( PositionsTotal () > 0 ) {
         string StringArray [] ;
         double ValueArray [] ;
         goSort_AllPositionsByProfit ( StringArray , ValueArray ) ;
         for ( int i = 0 ; i < ArraySize ( StringArray ) ; i++ ) {
            string result [] ; StringSplit ( StringArray [ i ] , StringGetCharacter ( "|" , 0 ) , result ) ;
            if ( ArraySize ( result ) >= 3 ) {
               ulong safTicket = ulong ( ulong ( result [ 2 ] ) ) ;
               double safLoss = double ( result [ 1 ] ) ;
               if ( ( safDayProfit + safLoss ) > 0 ) {
                  bool CloseSuccess = false ;
                  CloseSuccess = trade.PositionClose ( safTicket ) ; // missing broadcast message
                  if ( CloseSuccess == true ) { safDayProfit = safDayProfit + safLoss ; }}}
            // -------------------- RULE 3
            if ( StringFind ( safRules , "3" , 0 ) >= 0 ) { break ; }}}
      if ( PositionsTotal () < 1 ) {
         safBalance = sBal() ; if ( safBalance > LastBalance ) { LastBalance = safBalance ; }}
      goPrint ( "Last Balance: " + string ( LastBalance ) ) ; }

      string goFormat_NumberWithCommas ( string safInput ) {
         /// -------------------- Variables
         string result = "" ;
         /// -------------------- Find divider if exists
         int i = StringFind ( safInput , "." , 0 ) ;
         if ( i < 1 ) {
            i = StringLen ( safInput ) ;
         } else {
            result = StringSubstr ( safInput , i , -1 ) ; }
         /// -------------------- Go character by character to put commas
         int safCounter = 1 ;
         for ( int j = i - 1 ; j >= 0 ; j-- ) {
            result = StringSubstr ( safInput , j , 1 ) + result ;
            safCounter += 1 ;
            if ( safCounter == 4 ) {
               safCounter = 1 ;
               if ( j > 0 ) {
                  string safPreviousChar = StringSubstr ( safInput , j - 1 , 1 ) ;
                  if ( ( safPreviousChar != "+" ) && ( safPreviousChar != "-" ) ) {
                     result = "," + result ; }}}}
         return ( result ) ; }