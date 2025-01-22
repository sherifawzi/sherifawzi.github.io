
   #define SNR_COPYRIGHT   "Copyright 2023, F-SQUARE ApS"
   #define SNR_WEBSITE     "https://www.fsquare.dk"
   #define SNR_LIBVER      "Library Version: 25.01.22"

   #include <Trade\Trade.mqh>
   #include <Math\Stat\Math.mqh>
   CTrade trade ;

   //===========================================================================================================
   //=====                                            ENUMS                                                =====
   //===========================================================================================================

   enum enumRiskLevel      { Highest=0 , Higher=1 , High=2 , Medium=3 , Low=4 , Lower=5 , Lowest=6 } ;
   enum enumMaxDD          { Do_Noting=0 , Stop_Trade=1 , Trade_Minimum=2 , Trade_Half_Half_Min=3 } ;
   enum enumCounterTrade   { No_Counter=0 , Counter_Min=1 , Counter_50=2 , Counter_75=3 , Counter_Equal=4 , Counter_125=5 } ;
   enum enumCounterSL      { No_Counter_SL=0 , Counter_SL_10=1 , Counter_SL_25=2 , Counter_SL_50=3 , Counter_SL_75=4 , Counter_SL_90=5 } ;
   enum enumAllowedTrade   { No_Trade=0 , Buy_and_Sell=1 , Buy_Only=2 , Sell_Only=3 } ;

   //===========================================================================================================
   //=====                                            VARIABLES                                            =====
   //===========================================================================================================

      string            glb_Magic               = "SNR"           ; // EA Magic Number
      string            glb_EAS                 = _Symbol         ; // EA Symbol
      ENUM_TIMEFRAMES   glb_EAP                 = _Period         ; // EA Period
      int               glb_FC                  = 1               ; // Candle to use for calculations
      int               glb_BD                  = 3               ; // Indicator buffer depth
      string            glb_BroadID             = ""              ; // EA Broadcast ID
      bool              glb_RobotDisabled       = true            ; // Disable robot
      bool              glb_IsThisLive          = true            ; // Is this a test/Optimization or Live trading
      double            glb_LotSize             = 0.01            ; // Lost size [0=Min/1K, 0.01=Min, [NUMBER]=Percent of Free Margin]
      double            glb_MaxCapitalValue     = 0               ; // EA Max capital value to use [0=Disabled]
      double            glb_MaxCapitalPerc      = 0               ; // EA Max capital percent to use [0=Disabled]
      double            glb_MaxLotPerK          = 0               ; // EA Max capital trade size per 1K [0=Disabled]
      bool              glb_BeaconMode          = false           ; // Beacon mode activated
      double            glb_MaxDDTrigger        = 0               ; // Drawdown percent trigger [0=Disabled]
      enumMaxDD         glb_MaxDDBehaviour      = Do_Noting       ; // Drawdown trigger behaviour
      bool              glb_TickLock            = true            ; // Tick lock for onTick event
      double            glb_StartBalance        = 0               ; // Start balance for tests
      int               glb_MinsSinceTrade      = 0               ; // Minutes since last trade
      int               glb_MaxTries            = 3               ; // Max tries for trade actions
      enumAllowedTrade  glb_AllowedTrade        = No_Trade        ; // Allowed trade direction
      bool              glb_VerboseMode         = false           ; // Verbose mode on

   //===========================================================================================================
   //=====                                             ARRAYS                                              =====
   //===========================================================================================================

   MqlRates    glb_PI [] ;
   double      B0 [] , B1 [] , B2 [] , B3 [] , B4 [] ;
   string      glb_SymbolArray [] ;

   //===========================================================================================================
   //=====                                         CONST VARIABLES                                         =====
   //===========================================================================================================

   const string glb_MsgStart  = "XyXyXyZ|" ;
   const string glb_MsgEnd    = "|ZyXyXyX" ;
   const string glb_ServerIP  = "http://3.66.106.21/" ;
   const string glb_ServerPHP = "nsaveeof.php" ;
   string glb_ServerPath      = "/ERROR/" ;
   string glb_ServerFileName  = "catchall.txt" ;

   //===========================================================================================================
   //=====                                       INDICATOR FUNCTIONS                                       =====
   //===========================================================================================================

   // ------------------------------ 01: Accelerator Oscillator
   bool ind_AC () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iAC ( glb_EAS , glb_EAP ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 02: Accumulation/Distribution
   bool ind_AD () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iAD ( glb_EAS , glb_EAP , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 03: Average Directional Movement Index
   bool ind_ADX ( int sPeriod=14 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      // 0 - MAIN LINE / 1 - PLUS DI LINE / 2 - MINUS DI LINE
      int F = iADX ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      if ( !CopyBuffer ( F , 2 , 0 , glb_BD , B2 ) ) { return false ; }
      return true ; }

   // ------------------------------ 04: Average Directional Movement Index by Welles Wilder
   bool ind_ADXW ( int sPeriod=14 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      // 0 - MAIN LINE / 1 - PLUS DI LINE / 2 - MINUS DI LINE
      int F = iADXWilder ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      if ( !CopyBuffer ( F , 2 , 0 , glb_BD , B2 ) ) { return false ; }
      return true ; }

   // ------------------------------ 05: Alligator
   bool ind_Alligator ( int jawPeriod=13 , int jawShift=8 , int teethPeriod=8 , int teethShift=5 , int lipsPeriod=5 , int lipsShift=3 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      // 0 - GATOR JAW LINE / 1 - GATOR TEETH LINE / 2 - GATOR LIPS LINE
      int F = iAlligator ( glb_EAS , glb_EAP , jawPeriod , jawShift , teethPeriod , teethShift , lipsPeriod , lipsShift , MODE_SMMA , PRICE_MEDIAN ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      if ( !CopyBuffer ( F , 2 , 0 , glb_BD , B2 ) ) { return false ; }
      return true ; }

   // ------------------------------ 06: Adaptive Moving Average
   bool ind_AMA ( int sPeriod=15 , int fastMA=2 , int slowMA=30 , int sShift=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iAMA ( glb_EAS , glb_EAP , sPeriod , fastMA , slowMA , sShift , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 07: Awesome Oscillator
   bool ind_AO () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iAO ( glb_EAS , glb_EAP ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 08: Average True Range
   bool ind_ATR ( int sPeriod=14 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iATR ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 09: Bears Power
   bool ind_Bears ( int sPeriod=13 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iBearsPower ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 10: Bollinger Bands
   bool ind_Band ( int sPeriod=20 , int sShift=0 , double sDeviation=2.0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      // 0 - BASE LINE / 1 - UPPER BAND / 2 - LOWER BAND
      int F = iBands ( glb_EAS , glb_EAP , sPeriod, sShift , sDeviation , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      if ( !CopyBuffer ( F , 2 , 0 , glb_BD , B2 ) ) { return false ; }
      return true ; }

   // ------------------------------ 11: Bulls Power
   bool ind_Bulls ( int sPeriod=13 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iBullsPower ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 12: Commodity Channel Index
   bool ind_CCI ( int sPeriod=14 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iCCI ( glb_EAS , glb_EAP , sPeriod , PRICE_TYPICAL ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 13: Chaikin Oscillator
   bool ind_Chaikin ( int fastMA=3 , int slowMA=10 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iChaikin ( glb_EAS , glb_EAP , fastMA , slowMA , MODE_EMA , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 14: Double Exponential Moving Average
   bool ind_DEMA ( int sPeriod=14 , int sShift=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iDEMA ( glb_EAS , glb_EAP , sPeriod , sShift , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 15: DeMarker
   bool ind_DeMarker ( int sPeriod=14 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iDeMarker ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 16: Envelopes
   bool ind_Envelopes ( int sPeriod=14 , int sShift=0 , double sDeviation=0.1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      // 0 - UPPER LINE / 1 - LOWER LINE
      int F = iEnvelopes ( glb_EAS , glb_EAP , sPeriod , sShift , MODE_SMA , PRICE_CLOSE , sDeviation ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      return true ; }

   // ------------------------------ 17: Force Index
   bool ind_Force ( int sPeriod=13 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iForce ( glb_EAS , glb_EAP , sPeriod , MODE_SMA , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 18: Fractals
   bool ind_Fractals () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      // 0 - UPPER LINE / 1 - LOWER LINE
      int F = iFractals ( glb_EAS , glb_EAP ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      return true ; }

   // ------------------------------ 19: Fractal Adaptive Moving Average
   bool ind_FrAMA ( int sPeriod=14 , int sShift=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iFrAMA ( glb_EAS , glb_EAP , sPeriod , sShift , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 20: Gator
   bool ind_Gator ( int jawPeriod=13 , int jawShift=8 , int teethPeriod=8 , int teethShift=5 , int lipsPeriod=5 , int lipsShift=3 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iBWMFI ( glb_EAS , glb_EAP , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 23: Momentum
   bool ind_Momentum ( int sPeriod=14 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iMomentum ( glb_EAS , glb_EAP , sPeriod , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 24: Money Flow Index
   bool ind_MFI ( int sPeriod=14 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iMFI ( glb_EAS , glb_EAP , sPeriod , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 25: Moving Average
   bool ind_MA ( string sType , int sPeriod , int sShift=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = 0 ;
      if ( sType == "SMA" ) { F = iMA ( glb_EAS , glb_EAP , sPeriod , sShift , MODE_SMA , PRICE_CLOSE ) ; }
      if ( sType == "EMA" ) { F = iMA ( glb_EAS , glb_EAP , sPeriod , sShift , MODE_EMA , PRICE_CLOSE ) ; }
      if ( sType == "SMMA" ) { F = iMA ( glb_EAS , glb_EAP , sPeriod , sShift , MODE_SMMA , PRICE_CLOSE ) ; }
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 26: Moving Average of Oscillator
   bool ind_OsMA ( int fastMA=12 , int slowMA=26 , int sSignal=9 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iOsMA ( glb_EAS , glb_EAP , fastMA , slowMA , sSignal , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 27: Moving Averages Convergence/Divergence
   bool ind_MACD ( int fastMA=12 , int slowMA=26 , int sSignal=9 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      // 0 - MAIN LINE / 1 - SIGNAL LINE
      int F = iMACD ( glb_EAS , glb_EAP , fastMA , slowMA , sSignal , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      return true ; }

   // ------------------------------ 28: On Balance Volume
   bool ind_OBV () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iOBV ( glb_EAS , glb_EAP , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 29: Parabolic Stop and Reverse system
   bool ind_SAR ( double sStep=0.02 , int sMax=2 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iSAR ( glb_EAS , glb_EAP , sStep , sMax ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 30: Relative Strength Index
   bool ind_RSI ( int sPeriod=14 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iRSI ( glb_EAS , glb_EAP , sPeriod , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 31: Relative Vigor Index
   bool ind_RVI ( int sPeriod=10 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      // 0 - MAIN LINE / 1 - SIGNAL LINE
      int F = iRVI ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      return true ; }

   // ------------------------------ 32: Standard Deviation
   bool ind_StdDev ( int sPeriod=20 , int sShift=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iStdDev ( glb_EAS , glb_EAP , sPeriod , sShift , MODE_SMA , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 33: Stochastic Oscillator
   bool ind_Stochastic ( int sKPeriod=5 , int sDPeriod=3 , int sSlowing=3 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      // 0 - MAIN LINE / 1 - SIGNAL LINE
      int F = iStochastic ( glb_EAS , glb_EAP , sKPeriod , sDPeriod , sSlowing , MODE_SMA , STO_LOWHIGH ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      if ( !CopyBuffer ( F , 1 , 0 , glb_BD , B1 ) ) { return false ; }
      return true ; }

   // ------------------------------ 34: Triple Exponential Moving Average
   bool ind_TEMA ( int sPeriod=14 , int sShift=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iTEMA ( glb_EAS , glb_EAP , sPeriod , sShift , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 35: Triple Exponential Moving Averages Oscillator
   bool ind_TriX ( int sPeriod=14 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iTriX ( glb_EAS , glb_EAP , sPeriod , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 36: Larry Williams' Percent Range
   bool ind_WPR ( int sPeriod=14 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iWPR ( glb_EAS , glb_EAP , sPeriod ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 37: Variable Index Dynamic Average
   bool ind_VIDyA ( int sCMO=15 , int sEMA=12 , int sShift=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iVIDyA ( glb_EAS , glb_EAP , sCMO , sEMA , sShift , PRICE_CLOSE ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   // ------------------------------ 38: Volumes
   bool ind_Volumes () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      int F = iVolumes ( glb_EAS , glb_EAP , VOLUME_TICK ) ;
      if ( F == INVALID_HANDLE ) { return false ; }
      if ( !CopyBuffer ( F , 0 , 0 , glb_BD , B0 ) ) { return false ; }
      return true ; }

   //===========================================================================================================
   //=====                                    MULTI INDICATOR STARTERS                                     =====
   //===========================================================================================================

   // ------------------------------ Multi Osci getter
   bool ind_OSCI ( string sType , int sPeriod ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- Main logic
      if ( sType == "RSI" ) { return ( ind_RSI ( sPeriod ) ) ; }
      else if ( sType == "CHAIKIN" ) { return ( ind_Chaikin () ) ; }
      else if ( sType == "CCI" ) { return ( ind_CCI ( sPeriod ) ) ; }
      else if ( sType == "DEMARKER" ) { return ( ind_DeMarker ( sPeriod ) ) ; }
      else if ( sType == "FORCE" ) { return ( ind_Force ( sPeriod ) ) ; }
      else if ( sType == "MOMENTUM" ) { return ( ind_Momentum ( sPeriod ) ) ; }
      else if ( sType == "WPR" ) { return ( ind_WPR ( sPeriod ) ) ; }
      else if ( sType == "RVI" ) { return ( ind_RVI ( sPeriod ) ) ; }
      else if ( sType == "MFI" ) { return ( ind_MFI ( sPeriod ) ) ; }
      else if ( sType == "AO" ) { return ( ind_AO () ) ; }
      else if ( sType == "TRIX" ) { return ( ind_TriX ( sPeriod ) ) ; }
      else if ( sType == "SOC" ) { return ( ind_Stochastic () ) ; }
      else if ( sType == "BULLS" ) { return ( ind_Bulls ( sPeriod ) ) ; }
      else if ( sType == "BEARS" ) { return ( ind_Bears ( sPeriod ) ) ; }
      // -------------------- Return failure
      else { return false ; }}

   // ------------------------------ Multi Trend getter
   bool ind_TREND ( string sType , int sPeriod ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      goClearBuffers () ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- Main logic
      if ( sType == "EMA" ) { return ( ind_MA ( "EMA" , sPeriod , 0 ) ) ; }
      else if ( sType == "SMA" ) { return ( ind_MA ( "SMA" , sPeriod , 0 ) ) ; }
      else if ( sType == "SMMA" ) { return ( ind_MA ( "SMMA" , sPeriod , 0 ) ) ; }
      else if ( sType == "DEMA" ) { return ( ind_DEMA ( sPeriod , 0 ) ) ; }
      else if ( sType == "TEMA" ) { return ( ind_TEMA ( sPeriod , 0 ) ) ; }
      else if ( sType == "SAR" ) { return ( ind_SAR () ) ; }
      else if ( sType == "FRAMA" ) { return ( ind_FrAMA ( sPeriod , 0 ) ) ; }
      else if ( sType == "VIDYA" ) { return ( ind_VIDyA () ) ; }
      else if ( sType == "AMA" ) { return ( ind_AMA () ) ; }
      // -------------------- Return failure
      else { return false ; }}

   //===========================================================================================================
   //=====                                    CONFIGURARBLE INDICATORS                                     =====
   //===========================================================================================================

   double sATR ( int safPeriod , ENUM_TIMEFRAMES safTF=PERIOD_CURRENT , int safLoc=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( 0 ) ; }
      // -------------------- x
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      glb_EAP = safTF ;
         double result = 0 ; if ( ind_ATR ( safPeriod ) ) { result = B0 [ safLoc ] ; }
      glb_EAP = sCurr_Period ;
      return ( result ) ; }

   double sMA ( string safType , int safPeriod , ENUM_TIMEFRAMES safTF=PERIOD_CURRENT , int safLoc=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( 0 ) ; }
      // -------------------- x
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      glb_EAP = safTF ;
         double result = 0 ; if ( ind_MA ( safType , safPeriod ) ) { result = B0 [ safLoc ] ; }
      glb_EAP = sCurr_Period ;
      return ( result ) ; }

   double sRSI ( int safPeriod , ENUM_TIMEFRAMES safTF=PERIOD_CURRENT , int safLoc=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( 0 ) ; }
      // -------------------- x
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      glb_EAP = safTF ;
         double result = 0 ; if ( ind_RSI ( safPeriod ) ) { result = B0 [ safLoc ] ; }
      glb_EAP = sCurr_Period ;
      return ( result ) ; }

   double sMFI ( int safPeriod , ENUM_TIMEFRAMES safTF=PERIOD_CURRENT , int safLoc=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( 0 ) ; }
      // -------------------- x
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      glb_EAP = safTF ;
         double result = 0 ; if ( ind_MFI ( safPeriod ) ) { result = B0 [ safLoc ] ; }
      glb_EAP = sCurr_Period ;
      return ( result ) ; }

   double sADX ( int safPeriod , ENUM_TIMEFRAMES safTF=PERIOD_CURRENT , int safLoc=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( 0 ) ; }
      // -------------------- x
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      glb_EAP = safTF ;
         double result = 0 ; if ( ind_ADX ( safPeriod ) ) { result = B0 [ safLoc ] ; }
      glb_EAP = sCurr_Period ;
      return ( result ) ; }

   //===========================================================================================================
   //=====                                    MY INDICATOR FUNCTIONS                                       =====
   //===========================================================================================================

   void myIndicator_ZigZag ( int CandlesBack=100 , int CandlesInARow=5 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- Abort checks
      if ( ( CandlesBack <= 0 ) || ( CandlesInARow <= 0 ) ) { return ; }
      // -------------------- x
      string LastPivot = "" , safName = "PivotLine" ;
      int safCounter = 1 ;
      int sBD = glb_FC + 1 + CandlesBack + CandlesInARow ;
      // -------------------- Declarations and variables
      MqlRates sPI[] ; ArraySetAsSeries ( sPI , true ) ;
      CopyRates ( glb_EAS , glb_EAP , 0 , sBD , sPI ) ;
      // -------------------- x
      goDraw_DeleteScreenObject ( safName ) ;
      // -------------------- x
      for ( int i = CandlesInARow ; i < CandlesBack ; i++ ) {
         // -------------------- x
         int safUpCounter = 0 , safDnCounter = 0 ;
         double safPivotPrice = 0 ;
         // -------------------- x
         for ( int j = i + 1 ; j <= i + CandlesInARow ; j++ ) {
            if ( sPI[ i ].high >= sPI[ j ].high ) { safUpCounter += 1 ; }
            if ( sPI[ i ].low  <= sPI[ j ].low  ) { safDnCounter += 1 ; } }
         // -------------------- x
         for ( int j = i - 1 ; j >= i - CandlesInARow ; j-- ) {
            if ( sPI[ i ].high >= sPI[ j ].high ) { safUpCounter += 1 ; }
            if ( sPI[ i ].low  <= sPI[ j ].low  ) { safDnCounter += 1 ; } }
         // -------------------- x
         if ( safUpCounter == ( CandlesInARow * 2 ) ) {
            if ( LastPivot != "HIGH" ) {
               safPivotPrice = sPI[ i ].high ; LastPivot = "HIGH" ; safDnCounter = -1 ; }}
         // -------------------- x
         if ( safDnCounter == ( CandlesInARow * 2 ) ) {
            if ( LastPivot != "LOW"  ) {
               safPivotPrice = sPI[ i ].low ; LastPivot = "LOW" ; }}
         // -------------------- x
         if ( safPivotPrice > 0 ) {
            goDraw_ConnectedLine ( ( safName + (string)safCounter ) , 0 , safPivotPrice , sPI[i].time , clrGold ) ;
            safCounter += 1 ; }}}

   void myIndicator_OfficialPivotLevels ( string &PivotArray[] ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- Declarations and variables
      MqlRates sPI[] ; ArraySetAsSeries ( sPI , true ) ;
      CopyRates ( glb_EAS , PERIOD_D1 , 0 , 2 , sPI ) ;
      // -------------------- x
      double sH = sPI[ 1 ].high ;
      double sL = sPI[ 1 ].low ;
      double sC = sPI[ 1 ].close ;
      // -------------------- x
      double safPivot = ( sH + sL + sC ) / 3 ;
      double safRange = sH - sL ;
      double safR1 = ( safPivot * 2 ) - sL ;
      double safR2 = safPivot + safRange ;
      double safR3 = sH + ( 2 * ( safPivot - sL ) ) ;
      double safS1 = ( safPivot * 2 ) - sH ;
      double safS2 = safPivot - safRange ;
      double safS3 = sL - ( 2 * ( sH - safPivot ) ) ;
      // -------------------- x
      goDraw_HLine ( "R3" , safR3 , clrRed ) ;
         goArray_Add ( string ( safR3 ) , PivotArray ) ;
      // -------------------- x
      goDraw_HLine ( "R2" , safR2 , clrRed ) ;
         goArray_Add ( string ( safR2 ) , PivotArray ) ;
      // -------------------- x
      goDraw_HLine ( "R1" , safR1 , clrRed ) ;
         goArray_Add ( string ( safR1 ) , PivotArray ) ;
      // -------------------- x
      goDraw_HLine ( "P" , safPivot , clrWhite ) ;
         goArray_Add ( string ( safPivot ) , PivotArray ) ;
      // -------------------- x
      goDraw_HLine ( "S1" , safS1 , clrBlue ) ;
         goArray_Add ( string ( safS1 ) , PivotArray ) ;
      // -------------------- x
      goDraw_HLine ( "S2" , safS2 , clrBlue ) ;
         goArray_Add ( string ( safS2 ) , PivotArray ) ;
      // -------------------- x
      goDraw_HLine ( "S3" , safS3 , clrBlue ) ;
         goArray_Add ( string ( safS3 ) , PivotArray ) ; }

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
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
         // -------------------- x
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
         string sPeriod_Array [] ; StringSplit ( sPeriod , 124 , sPeriod_Array ) ;
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
                  if ( sFind ( safRules , "1" ) ) {
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
                     if ( sFind ( safRules , "2" ) ) {
                        Ind_S_Target = 100 - Ind_B_Target ;
                        sRSI ( (int)sPeriod_Array[j] , sTF_Array [i] ) ; Ind_C = B0 [ 0 ] ; Ind_L = B0 [ 1 ] ;
                        if ( Ind_C >= Ind_B_Target ) { if ( Ind_C > Ind_L ) { sADXRSIMFI += "B" ; } else { sADXRSIMFI += "b" ; }}
                        else if ( Ind_C < Ind_S_Target ) { if ( Ind_C < Ind_L ) { sADXRSIMFI += "S" ; } else { sADXRSIMFI += "s" ; }}}
                     // ------------------------------ Calc MFI
                     if ( sFind ( safRules , "3" ) ) {
                        Ind_S_Target = 100 - Ind_B_Target ;
                        sMFI ( (int)sPeriod_Array[j] , sTF_Array [i] ) ; Ind_C = B0 [ 0 ] ; Ind_L = B0 [ 1 ] ;
                        if ( Ind_C >= Ind_B_Target ) { if ( Ind_C > Ind_L ) { sADXRSIMFI += "B" ; } else { sADXRSIMFI += "b" ; }}
                        else if ( Ind_C < Ind_S_Target ) { if ( Ind_C < Ind_L ) { sADXRSIMFI += "S" ; } else { sADXRSIMFI += "s" ; }}}
                     // ------------------------------ Calc ADX
                     if ( sFind ( safRules , "4" ) ) {
                        sADX ( (int)sPeriod_Array[j] , sTF_Array [i] ) ; Ind_C = B0 [ 0 ] ; Ind_L = B0 [ 1 ] ;
                        if ( Ind_C > Ind_Y_Target ) { MomentumResult = sADXRSIMFI ; if ( Ind_C > Ind_L ) { MomentumResult += sADXRSIMFI ; }}}
                     // ------------------------------ Calc MA here
                     if ( sFind ( safRules , "5" ) ) {
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

   void myIndicator_HighsAndLowsChannel ( int safNoOfCandles , int safDistance , double safBuffer ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- Declarations and variables
      MqlRates sPI[] ; ArraySetAsSeries ( sPI , true ) ;
      CopyRates ( glb_EAS , glb_EAP , 0 , safNoOfCandles , sPI ) ;
      // -------------------- ;
      string sHigh [] , sLow [] ;
      safBuffer *= sPoint() ;
      // -------------------- Go thru candles and find highs and lows
      for ( int i = safDistance ; i < ( safNoOfCandles-safDistance ) ; i++ ) {
         // -------------------- Set counter
         int safCount = 0 ;
         // -------------------- Conditions for high
         for ( int j = i - safDistance ; j < i ; j++ ) {
            if ( sPI[ j ].high > sPI[ i ].high ) {
               safCount += 1 ; break ; }}
         if ( safCount == 0 ) {
            for ( int j = i + safDistance ; j > i ; j-- ) {
               if ( sPI[ j ].high > sPI[ i ].high ) {
                  safCount += 1 ; break ; }}}
         if ( safCount == 0 ) {
            goArray_Add ( string ( i ) , sHigh ) ; }
         // -------------------- Set counter
         safCount = 0 ;
         // -------------------- Conditions for low
         for ( int j = i - safDistance ; j < i ; j++ ) {
            if ( sPI[ j ].low < sPI[ i ].low ) {
               safCount += 1 ; break ; }}
         if ( safCount == 0 ) {
            for ( int j = i + safDistance ; j > i ; j-- ) {
               if ( sPI[ j ].low < sPI[ i ].low ) {
                  safCount += 1 ; break ; }}}
         if ( safCount == 0 ) {
            goArray_Add ( string ( i ) , sLow ) ; }}
      // -------------------- Draw highs
      for ( int x = ArraySize ( sHigh ) - 1 ; x >= 0 ; x-- ) {
         datetime safT = sPI [ int ( sHigh [ x ] ) ].time ;
         double safX = sPI [ int ( sHigh [ x ] ) ].high + safBuffer ;
         bool safRay = false ; if ( x <= 1 ) { safRay = true ; } // Show ray for last 2 lines
         goDraw_ConnectedLine ( "" , 0 , safX , safT , clrBlue , safRay ) ; }
      // -------------------- Draw lows
      for ( int x = ArraySize ( sLow ) - 1 ; x >= 0 ; x-- ) {
         datetime safT = sPI [ int ( sLow [ x ] ) ].time ;
         double safX = sPI [ int ( sLow [ x ] ) ].low - safBuffer ;
         bool safRay = false ; if ( x <= 1 ) { safRay = true ; } // Show ray for last 2 lines
         goDraw_ConnectedLine ( "" , 1 , safX , safT , clrRed , safRay ) ; }
      ChartRedraw () ; }

   void myIndicator_SupportAndResistance ( int safNoCandle=750 , int safPeak=10 , bool safConnectPeaks=false ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- Clear
      goDraw_DeleteScreenObject ( "ILine" ) ;
      goDraw_DeleteScreenObject ( "RayRight" ) ;
      // -------------------- Variables
      string safPriceArray[] , safTimeArray[] ;
      double safLastLow = 0 , safLastHigh = 0 ;
      datetime safLastLowTime = 0 , safLastHighTime = 0 ;
      // -------------------- Declarations and variables
      MqlRates sPI[] ; ArraySetAsSeries ( sPI , true ) ;
      CopyRates ( glb_EAS , glb_EAP , 0 , safNoCandle , sPI ) ;
      // -------------------- Go thru candles and find highs and lows
      for ( int i = safPeak ; i < ( safNoCandle - safPeak ) ; i++ ) {
         // -------------------- Set counter
         int safCountLow = 0 , safCountHigh = 0 ;
         // -------------------- Conditions for low
         for ( int j = 1 ; j <= safPeak ; j++ ) {
            if ( sPI[ i ].low  <= sPI[ i + j ].low  ) { safCountLow  += 1 ; }
            if ( sPI[ i ].low  <= sPI[ i - j ].low  ) { safCountLow  += 1 ; }
            if ( sPI[ i ].high >= sPI[ i + j ].high ) { safCountHigh += 1 ; }
            if ( sPI[ i ].high >= sPI[ i - j ].high ) { safCountHigh += 1 ; }}
         // -------------------- x
         if ( safCountLow  == safPeak * 2 ) {
            goArray_Add ( string ( sPI [ i ].low ) , safPriceArray ) ;
            goArray_Add ( string ( sPI [ i ].time ) , safTimeArray ) ;
            if ( safConnectPeaks ) { if ( safLastLow != 0 ) {
               goDraw_Line ( "" , safLastLow , safLastLowTime , sPI [ i ].low , sPI [ i ].time , clrRed ) ; }}
               safLastLow = sPI [ i ].low ; safLastLowTime = sPI [ i ].time ; }
         if ( safCountHigh == safPeak * 2 ) {
            goArray_Add ( string ( sPI [ i ].high ) , safPriceArray ) ;
            goArray_Add ( string ( sPI [ i ].time ) , safTimeArray ) ;
            if ( safConnectPeaks ) { if ( safLastHigh != 0 ) {
               goDraw_Line ( "" , safLastHigh , safLastHighTime , sPI [ i ].high , sPI [ i ].time , clrBlue ) ; }}
               safLastHigh = sPI [ i ].high ; safLastHighTime = sPI [ i ].time ; }}
      // -------------------- Go draw
      for ( int i = 0 ; i < ArraySize ( safPriceArray ) ; i++ ) {
         goDraw_RayRight ( "" , double ( safPriceArray [ i ] ) , datetime (safTimeArray [ i ] ) , clrGray ) ; }
      ChartRedraw() ; }

   void goWriteSwapsToScreen (
      int safX=325 , int safY=25 , int safW=100 , int safH=25 ,
      color safBG=clrLightBlue , color safFG=clrBlack , color safPOS=clrLightGreen , color safNEG=clrLightPink ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ; }
         // -------------------- x
         string safSplit [] ; StringSplit ( goSymbols_GetAllInDataWindow () , 124 , safSplit ) ;
         // -------------------- x
         int safOriginalX = safX , safRow = safH , safCol = safW ;
         // -------------------- x
         for ( int i = 1 ; i < ArraySize ( safSplit ) - 1 ; i++ ) {
            // -------------------- x
            double safValue = 0 ;
            color safColor = safBG ;
            safX = safOriginalX ;
            // -------------------- x
            goDraw_TextBox ( safSplit [ i ] + "Name" , safX , safY , safW , safH , safBG , safFG , safSplit [ i ] ) ; safX -= safCol ;
            // -------------------- x
            safValue = ND2 ( SymbolInfoDouble ( safSplit [ i ] , SYMBOL_SWAP_LONG ) ) ;
            if ( safValue < 0 ) { safColor = safNEG ;  } else if ( safValue > 0 ) { safColor = safPOS ; }
            goDraw_TextBox ( safSplit [ i ] + "Buy" , safX , safY , safW , safH , safColor , safFG , string ( safValue ) ) ; safX -= safCol ;
            // -------------------- x
            safValue = ND2 ( SymbolInfoDouble ( safSplit [ i ] , SYMBOL_SWAP_SHORT ) ) ;
            if ( safValue < 0 ) { safColor = safNEG ;  } else if ( safValue > 0 ) { safColor = safPOS ; }
            goDraw_TextBox ( safSplit [ i ] + "Sell" , safX , safY , safW , safH , safColor , safFG , string ( safValue ) ) ; safY += safRow ; }}

   //===========================================================================================================
   //=====                                     DRAWING FUNCTIONS                                           =====
   //===========================================================================================================

   void goDraw_VLine ( string safName , datetime safTime , color safColor ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      static int safCounter ;
      if ( safName == "" ) { safName = "VLine" + string ( safCounter ) ; }
      ObjectDelete ( 0 , safName ) ;
      ObjectCreate ( 0 , safName , OBJ_VLINE , 0 , safTime , 0 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safColor ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_STYLE , STYLE_DOT ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BACK , true ) ;
      safCounter += 1 ; }

   void goDraw_HLine ( string safName , double safPrice , color safColor ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      static int safCounter ;
      if ( safName == "" ) { safName = "HLine" + string ( safCounter ) ; }
      ObjectDelete ( 0 , safName ) ;
      if ( safPrice > 0 ) {
      ObjectCreate ( 0 , safName , OBJ_HLINE , 0 , 0 , safPrice ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safColor ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_STYLE , STYLE_DOT ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BACK , true ) ;
      safCounter += 1 ; }}

   void goDraw_ConnectedLine ( string safName , int safIndex , double safPrice , datetime safTime , color safColor , bool sTypeRay = false ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      static int safCounter ;
      static double oldPrice [ 10 ] ;
      static datetime oldTime [ 10 ] ;
      // -------------------- x
      if ( safName == "" ) { safName = "CLine" + string ( safCounter ) ; }
      // -------------------- x
      if ( oldPrice [ safIndex ] ) {
         ObjectDelete ( 0 , safName ) ;
         ObjectCreate ( 0 , safName , OBJ_TREND , 0 , safTime , safPrice , oldTime [ safIndex ] , oldPrice [ safIndex ] ) ;
         if ( sTypeRay == true ) { ObjectSetInteger ( 0 , safName , OBJPROP_RAY_LEFT , 1 ) ; }
         ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safColor ) ;
         ObjectSetInteger ( 0 , safName , OBJPROP_STYLE , STYLE_DOT ) ;
         ObjectSetInteger ( 0 , safName , OBJPROP_BACK , true ) ;
         safCounter += 1 ; }
      // -------------------- x
      oldTime [ safIndex ] = safTime ;
      oldPrice [ safIndex ] = safPrice ; }

   void goDraw_PriceRectangle ( string safName , datetime LLT , double LLV , datetime URT , double URV , color safColor ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      static int safCounter ;
      if ( safName == "" ) { safName = "RectPrc" + string ( safCounter ) ; }
      ObjectDelete ( 0, safName ) ;
      ObjectCreate ( 0, safName , OBJ_RECTANGLE , 0 , LLT , LLV , URT , URV ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safColor ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_FILL , true ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BACK , true ) ;
      safCounter += 1 ; }

   void goDraw_PointRectangle ( string safName , int safX1 , int safY1 , int safX2 , int safY2 , color safColor , int safCorner=2 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      for ( int i = ObjectsTotal ( 0 , 0 , -1 ) - 1 ; i >= 0 ; i-- ) {
         string safObjectName = "ZZZ" + ObjectName ( 0 , i , 0 , -1 ) ;
         if ( sFind ( safObjectName , safPrefix ) ) { ObjectDelete ( 0 , ObjectName ( 0 , i , 0 , -1 ) ) ; }}
      ChartRedraw() ; }

   void goDraw_LiveStopsOnChart ( double sSLV , double sTPV ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- Variables
      double sAsk = sAsk() ;
      double sBid = sBid() ;
      // -------------------- Handle Buy
      if ( sTPV > 0 ) {
         goDraw_PriceRectangle ( "BuyTP" , glb_PI [ glb_FC ].time , sAsk + sTPV , glb_PI [ glb_FC + 1 ].time , sAsk , clrLightBlue ) ; }
      if ( sSLV > 0 ) {
         goDraw_PriceRectangle ( "BuySL" , glb_PI [ glb_FC ].time , sBid - sSLV , glb_PI [ glb_FC + 1 ].time , sBid , clrPink ) ; }
      // -------------------- Handle Sell
      if ( sTPV > 0 ) {
         goDraw_PriceRectangle ( "SellTP" , glb_PI [ glb_FC + 1 ].time , sBid - sTPV , glb_PI [ glb_FC + 2 ].time , sBid , clrLightBlue ) ; }
      if ( sSLV > 0 ) {
         goDraw_PriceRectangle ( "SellSL" , glb_PI [ glb_FC + 1 ].time , sAsk + sSLV , glb_PI [ glb_FC + 2 ].time , sAsk , clrPink ) ; }}

   void goDraw_WriteToScreen ( string safName="" , string safText="" , int safX1=0 , int safY1=0 , int safYGap=0 , color safFGColor=clrYellow , color safBGColor=clrNONE ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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

   void goDraw_ButtonPress ( const string &sparam , string safType ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      static color currentBG ;
      static color currentFG ;
      if ( UT ( safType ) == "DOWN" ) {
         // -------------------- x
         goPrint ( "Button Press: " + sparam ) ;
         // -------------------- x
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

   void goDraw_RayRight ( string safName , double safPrice , datetime safTime , color safColor ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      static int safCounter ;
      if ( safName == "" ) { safName = "RayRight" + string ( safCounter ) ; }
      ObjectDelete ( 0 , safName ) ;
      ObjectCreate ( 0 , safName , OBJ_TREND , 0 , safTime , safPrice , safTime + 1000 , safPrice ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_RAY_RIGHT , 1 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safColor ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_STYLE , STYLE_DOT ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BACK , true ) ;
      safCounter += 1 ; }

   void goDraw_Line ( string safName , double sP1 , datetime sT1 , double sP2 , datetime sT2 , color safColor ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      static int safCounter ;
      if ( safName == "" ) { safName = "ILine" + string ( safCounter ) ; }
      ObjectDelete ( 0 , safName ) ;
      ObjectCreate ( 0 , safName , OBJ_TREND , 0 , sT1 , sP1 , sT2 , sP2 ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_COLOR , safColor ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_STYLE , STYLE_DOT ) ;
      ObjectSetInteger ( 0 , safName , OBJPROP_BACK , true ) ;
      safCounter += 1 ; }

   //===========================================================================================================
   //=====                                       CONTROL PANEL                                             =====
   //===========================================================================================================

   void goDraw_ControlPanel (
      string safRules = "1234556789" ,
      int safY = 50 ,
      int safX = 175 ,
      int safYAdd = 50 ,
      double BigButton = 160 ,
      int SmallButton = 75 ,
      int ItemHeight = 30 ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ; }
         // -------------------- x
         if ( sFind ( safRules , "1" ) )  {
            goDraw_Button ( "BuyButton" , safX , safY  , SmallButton , ItemHeight , clrBlue , clrWhite , "Buy" ) ;
            goDraw_Button ( "SellButton" , 90 , safY , SmallButton , ItemHeight , clrRed , clrWhite , "Sell" ) ;
            safY += safYAdd ; }
         if ( sFind ( safRules , "2" ) )  {
            goDraw_Button ( "ClosePositive" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Close Positive" ) ;
            safY += safYAdd ; }
         if ( sFind ( safRules , "3" ) )  {
            goDraw_Button ( "CloseMostProfit" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Close Most Profitable" ) ;
            safY += safYAdd ; }
         if ( sFind ( safRules , "4" ) )  {
            goDraw_Button ( "CloseAll" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Close All" ) ;
            safY += safYAdd ; }
         if ( sFind ( safRules , "5" ) )  {
            goDraw_Button ( "ForceBE" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Force BE" ) ;
            safY += safYAdd ; }
         if ( sFind ( safRules , "6" ) )  {
            goDraw_Button ( "SetSL" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Set SL after BE" ) ;
            safY += safYAdd ; }
         if ( sFind ( safRules , "7" ) )  {
            goDraw_Button ( "SetSLNow" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Set SL now" ) ;
            safY += safYAdd ; }
         if ( sFind ( safRules , "8" ) )  {
            goDraw_TextBox ( "CommentToClose" , safX , safY , ( (int) ( BigButton * 0.65 ) ) , ItemHeight , clrWhite , clrBlack , "Comment" ) ;
            goDraw_Button ( "KillButton" , 65 , safY , ( (int) ( BigButton * 0.3 ) ) , ItemHeight , clrGreen , clrWhite , "Kill" ) ;
            safY += safYAdd ; }
         if ( sFind ( safRules , "9" ) )  {
            goDraw_Button ( "PauseButton" , safX , safY , (int)BigButton , ItemHeight , clrGreen , clrWhite , "Pause ON/OFF" ) ;
            safY += safYAdd ; }}

   //===========================================================================================================
   //=====                                       POSITION FUNCTIONS                                        =====
   //===========================================================================================================

   void goPositions_Retreive ( string &PositionLines[] ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      ArrayResize ( PositionLines , 0 ) ;
      if ( PositionsTotal() < 1 ) { return ; }
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
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
         goArray_Add ( result , PositionLines ) ; }}

   string prvPositions_Template ( string safRules="" , string safFilter="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      if ( PositionsTotal() < 1 ) { return "" ; }
      // -------------------- x
      string result = "" ;
      // -------------------- Get open positions
      string PositionLines[] ; goPositions_Retreive ( PositionLines ) ;
      if ( ArraySize ( PositionLines ) < 1 ) { return ( result ) ; }
      // -------------------- Go thru positions one by one
      for ( int i=0 ; i < ArraySize ( PositionLines ) ; i++ ) {
         // -------------------- x
         string safSplit[] ; StringSplit ( PositionLines [ i ] , 124 , safSplit ) ;
         if ( ArraySize ( safSplit ) < 19 ) { continue ; }
         // -------------------- x
         ulong posTicket = ulong ( safSplit [ 1 ] ) ;
         string posSymbol = string ( safSplit [ 2 ] ) ;
         string posType = string ( safSplit [ 3 ] ) ;
         double posLot = double ( safSplit [ 4 ] ) ;
         double posOpenPrice = double ( safSplit [ 5 ] ) ;
         string posTime = string ( safSplit [ 6 ] ) ;
         double posCurrentPrice = double ( safSplit [ 7 ] ) ;
         double posSL = double ( safSplit [ 8 ] ) ;
         double posTP = double ( safSplit [ 9 ] ) ;
         double posProfit = double ( safSplit [ 10 ] ) ;
         double posSwap = double ( safSplit [ 11 ] ) ;
         double posNetProfit = double ( safSplit [ 12 ] ) ;
         double posDays = double ( safSplit [ 13 ] ) ;
         double posProfitPerDay = double ( safSplit [ 14 ] ) ;
         double posProfitPerLot = double ( safSplit [ 15 ] ) ;
         double posPriceMovePerc = double ( safSplit [ 16 ] ) ;
         double posOnePercValue = double ( safSplit [ 17 ] ) ;
         string posComment = string ( safSplit [ 18 ] ) ;
         // -------------------- Main logic here
      } return ( result ) ; }

   //===========================================================================================================
   //=====                                         ORDER FUNCTION                                          =====
   //===========================================================================================================

   void goOrders_Retreive ( string &OrderLines[] ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      ArrayResize ( OrderLines , 0 ) ;
      if ( OrdersTotal() < 1 ) { return ; }
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      for ( int i = 0 ; i < OrdersTotal() ; i++ ) {
         // -------------------- x
         ulong ordTicket = OrderGetTicket ( i ) ; string result = "|" + (string) ordTicket + "|" ; // --- ordTicket
         if ( !OrderSelect ( ordTicket ) ) { continue ; }
         // -------------------- x
         result += OrderGetString ( ORDER_SYMBOL ) + "|" ; // --- ordSymbol
         // -------------------- x
         long ordType = OrderGetInteger ( ORDER_TYPE ) ; // --- ordType
         if ( ordType == ORDER_TYPE_BUY ) { result += "BUY" + "|" ; }
         else if ( ordType == ORDER_TYPE_SELL ) { result += "SELL" + "|" ; }
         else { result += "OTHER" + "|" ; }
         // -------------------- x
         result += (string) ND2 ( OrderGetDouble ( ORDER_VOLUME_CURRENT ) ) + "|" ; // --- ordLots
         result += (string) ND ( OrderGetDouble ( ORDER_PRICE_OPEN ) ) + "|" ; // --- ordOpenPrice
         result += goTranslate_DateTime ( datetime ( OrderGetInteger  ( ORDER_TIME_EXPIRATION ) ) ) + "|" ; // --- ordTime
         result += (string) ND ( OrderGetDouble ( ORDER_PRICE_CURRENT ) ) + "|" ; // --- ordCurrentPrice
         result += (string) ND ( OrderGetDouble ( ORDER_SL ) ) + "|" ; // --- ordSL
         result += (string) ND ( OrderGetDouble ( ORDER_TP ) ) + "|" ; // --- ordTP
         result += "XYXYZ|" + OrderGetString ( ORDER_COMMENT ) + "|ZYXYX|" ; // --- posComment
         // -------------------- x
         goArray_Add ( result , OrderLines ) ; }}

   string prvOrders_Template ( string safRules="" , string safFilter="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      if ( OrdersTotal() < 1 ) { return "" ; }
      // -------------------- x
      string result = "" ;
      // -------------------- Get open positions
      string OrderLines[] ; goOrders_Retreive ( OrderLines ) ;
      if ( ArraySize ( OrderLines ) < 1 ) { return ( result ) ; }
      // -------------------- Go thru positions one by one
      for ( int i=0 ; i < ArraySize ( OrderLines ) ; i++ ) {
         // -------------------- x
         string safSplit[] ; StringSplit ( OrderLines [ i ] , 124 , safSplit ) ;
         if ( ArraySize ( safSplit ) < 11 ) { continue ; }
         // -------------------- x
         ulong ordTicket = ulong ( safSplit [ 1 ] ) ;
         string ordSymbol = string ( safSplit [ 2 ] ) ;
         string ordType = string ( safSplit [ 3 ] ) ;
         double ordLot = double ( safSplit [ 4 ] ) ;
         double ordOpenPrice = double ( safSplit [ 5 ] ) ;
         string ordExpiryTime = string ( safSplit [ 6 ] ) ;
         double ordCurrentPrice = double ( safSplit [ 7 ] ) ;
         double ordSL = double ( safSplit [ 8 ] ) ;
         double ordTP = double ( safSplit [ 9 ] ) ;
         string ordComment = string ( safSplit [ 10 ] ) ;
         // -------------------- Main logic here
      } return ( result ) ; }

   //===========================================================================================================
   //=====                                            HISTORY                                              =====
   //===========================================================================================================

   void goHistory_Retreive ( string &HistoryLines[] , string sStartDateTime="" , string sEndDateTime="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      ArrayResize ( HistoryLines , 0 ) ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
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
         string result = "|" + (string) DealTicket + "|" + (string) DealTypeTrans + "|" + (string) datetime ( DealTime ) + "|" ;
         result += (string) DealCurr + "|" + (string) DealLot + "|" + (string) DealProfit + "|" + (string) DealSwap + "|" ;
         result += (string) DealFee + "|" + (string) DealComm  + "|" + goTranslate_DateTime ( datetime ( DealTime ) ) + "|" ;
         result += (string) DealNetProfit + "|" ;
         goArray_Add ( result , HistoryLines ) ; }}

   string prvHistory_Template ( string safRules="" , string safFilter="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      string result = "" ;
      // -------------------- Get history for period
      string HistoryLines[] ; goHistory_Retreive ( HistoryLines ) ;
      if ( ArraySize ( HistoryLines ) < 1 ) { return ( result ) ; }
      // -------------------- Go thru history line by line
      for ( int i=0 ; i < ArraySize ( HistoryLines ) ; i++ ) {
         // -------------------- x
         string safSplit[] ; StringSplit ( HistoryLines [ i ] , 124 , safSplit ) ;
         if ( ArraySize ( safSplit ) < 12 ) { continue ; }
         // -------------------- x
         long DealTicket = long ( safSplit [ 1 ] ) ;
         string DealTypeTrans = string ( safSplit [ 2 ] );
         datetime DealTime = datetime ( safSplit [ 3 ] ) ;
         string DealCurr = string ( safSplit [ 4 ] ) ;
         double DealLot = double ( safSplit [ 5 ] ) ;
         double DealProfit = double ( safSplit [ 6 ] ) ;
         double DealSwap = double ( safSplit [ 7 ] ) ;
         double DealFee = double ( safSplit [ 8 ] ) ;
         double DealComm = double ( safSplit [ 9 ] ) ;
         string DealTimeTrans = string ( safSplit [ 10 ] ) ;
         double DealNetProfit = double ( safSplit [ 11 ] ) ;
         // -------------------- Main logic here
      } return ( result ) ; }

   //===========================================================================================================
   //=====                                         TRADE FUNCTION                                          =====
   //===========================================================================================================

   bool sBuy ( double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safLot=-1 , string safComment="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( false ) ; }
      // -------------------- x
      if ( glb_AllowedTrade == No_Trade ) { return ( false ) ; }
      if ( glb_AllowedTrade == Sell_Only ) { return ( false ) ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ( false ) ; }
      // -------------------- x
      string safComment2Use = glb_Magic + "/V2/B/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + safComment ;
      // -------------------- x
      if ( glb_BeaconMode == true ) {
         goBroadcast_SIG ( goTele_PrepMsg ( "B" , string ( sPow ( safSLV ) ) , string ( sPow ( safTPV ) ) ,
            string ( sPow ( safPercCalcSLV ) ) , string ( ND2 ( safLot ) ) , string ( glb_LotSize ) , safComment2Use ) ) ;
         return ( true ) ; }
      // -------------------- x
      bool safTradeSuccess = false ;
      int safTriesCount = 0 ;
      double safLot2Use = ND2 ( goCalc_LotSize ( safPercCalcSLV , safLot ) ) ;
      // -------------------- x
      while ( safTradeSuccess == false ) {
         // -------------------- x
         double safBid = sBid() ;
         double safAsk = ND ( sAsk() ) ;
         // -------------------- x
         double safTP = 0 ; if ( safTPV > 0 ) { safTP = ND ( ( safAsk + safTPV ) ) ; }
         double safSL = 0 ; if ( safSLV > 0 ) { safSL = ND ( ( safBid - safSLV ) ) ; }
         // -------------------- x
         safTradeSuccess = trade.Buy ( safLot2Use , glb_EAS , safAsk , safSL , safTP , safComment2Use ) ; Sleep ( 1000 ) ;
         // -------------------- x
         safTriesCount += 1 ; if ( safTriesCount >= glb_MaxTries ) { goPrint ( "Maximum number of tries reached" ) ; break ; }}
      // -------------------- x
      if ( safTradeSuccess ) { glb_MinsSinceTrade = 0 ; }
      // -------------------- x
      return ( safTradeSuccess ) ; }

   bool sSell ( double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safLot=-1 , string safComment="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( false ) ; }
      // -------------------- x
      if ( glb_AllowedTrade == No_Trade ) { return ( false ) ; }
      if ( glb_AllowedTrade == Buy_Only ) { return ( false ) ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ( false ) ; }
      // -------------------- x
      string safComment2Use = glb_Magic + "/V2/S/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + safComment ;
      // -------------------- x
      if ( glb_BeaconMode == true ) {
         goBroadcast_SIG ( goTele_PrepMsg ( "S" , string ( sPow ( safSLV ) ) , string ( sPow ( safTPV ) ) ,
            string ( sPow ( safPercCalcSLV ) ) , string ( ND2 ( safLot ) ) , string ( glb_LotSize ) , safComment2Use ) ) ;
         return ( true ) ; }
      // -------------------- x
      bool safTradeSuccess = false ;
      int safTriesCount = 0 ;
      double safLot2Use = ND2 ( goCalc_LotSize ( safPercCalcSLV , safLot ) ) ;
      // -------------------- x
      while ( safTradeSuccess == false ) {
         // -------------------- x
         double safAsk = sAsk() ;
         double safBid = ND ( sBid() ) ;
         // -------------------- x
         double safTP = 0 ; if ( safTPV > 0 ) { safTP = ND ( ( safBid - safTPV ) ) ; }
         double safSL = 0 ; if ( safSLV > 0 ) { safSL = ND ( ( safAsk + safSLV ) ) ; }
         // -------------------- x
         safTradeSuccess = trade.Sell ( safLot2Use , glb_EAS , safBid , safSL , safTP , safComment2Use ) ; Sleep ( 1000 ) ;
         // -------------------- x
         safTriesCount += 1 ; if ( safTriesCount >= glb_MaxTries ) { goPrint ( "Maximum number of tries reached" ) ; break ; }}
      // -------------------- x
      if ( safTradeSuccess ) { glb_MinsSinceTrade = 0 ; }
      // -------------------- x
      return ( safTradeSuccess ) ; }

   bool sBuyStop ( double safPrice , double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safLot=-1 , string safComment="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( false ) ; }
      // -------------------- x
      if ( glb_AllowedTrade == No_Trade ) { return ( false ) ; }
      if ( glb_AllowedTrade == Sell_Only ) { return ( false ) ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ( false ) ; }
      // -------------------- x
      string safComment2Use = glb_Magic + "/V2/BS/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + safComment ;
      // -------------------- x
      if ( glb_BeaconMode == true ) {
         goBroadcast_SIG ( goTele_PrepMsg ( "BS" , string ( safPrice ) , string ( sPow ( safSLV ) ) , string ( sPow ( safTPV ) ) ,
            string ( sPow ( safPercCalcSLV ) ) , string ( ND2 ( safLot ) ) , string ( glb_LotSize ) , safComment2Use ) ) ;
         return ( true ) ; }
      // -------------------- x
      bool safTradeSuccess = false ;
      int safTriesCount = 0 ;
      double safLot2Use = ND2 ( goCalc_LotSize ( safPercCalcSLV , safLot ) ) ;
      // -------------------- x
      while ( safTradeSuccess == false ) {
         // -------------------- x
         if ( sAsk() >= safPrice ) { break ; }
         // -------------------- x
         safPrice = ND ( safPrice ) ;
         // -------------------- x
         double safTP = 0 ; if ( safTPV > 0 ) { safTP = ND ( ( safPrice + safTPV ) ) ; }
         double safSL = 0 ; if ( safSLV > 0 ) { safSL = ND ( ( safPrice - safSLV ) ) ; }
         // -------------------- x
         safTradeSuccess = trade.BuyStop ( safLot2Use , safPrice , glb_EAS , safSL , safTP , ORDER_TIME_GTC , 0 , safComment2Use ) ; Sleep ( 1000 ) ;
         // -------------------- x
         safTriesCount += 1 ; if ( safTriesCount >= glb_MaxTries ) { goPrint ( "Maximum number of tries reached" ) ; break ; }}
      // -------------------- x
      if ( safTradeSuccess ) { glb_MinsSinceTrade = 0 ; }
      // -------------------- x
      return ( safTradeSuccess ) ; }

   bool sSellStop ( double safPrice , double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safLot=-1 , string safComment="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( false ) ; }
      // -------------------- x
      if ( glb_AllowedTrade == No_Trade ) { return ( false ) ; }
      if ( glb_AllowedTrade == Buy_Only ) { return ( false ) ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ( false ) ; }
      // -------------------- x
      string safComment2Use = glb_Magic + "/V2/SS/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + safComment ;
      // -------------------- x
      if ( glb_BeaconMode == true ) {
         goBroadcast_SIG ( goTele_PrepMsg ( "SS" , string ( safPrice ) , string ( sPow ( safSLV ) ) , string ( sPow ( safTPV ) ) ,
            string ( sPow ( safPercCalcSLV ) ) , string ( ND2 ( safLot ) ) , string ( glb_LotSize ) , safComment2Use ) ) ;
         return ( true ) ; }
      // -------------------- x
      bool safTradeSuccess = false ;
      int safTriesCount = 0 ;
      double safLot2Use = ND2 ( goCalc_LotSize ( safPercCalcSLV , safLot ) ) ;
      // -------------------- x
      while ( safTradeSuccess == false ) {
         // -------------------- x
         if ( sBid() <= safPrice ) { break ; }
         // -------------------- x
         safPrice = ND ( safPrice ) ;
         // -------------------- x
         double safTP = 0 ; if ( safTPV > 0 ) { safTP = ND ( ( safPrice - safTPV ) ) ; }
         double safSL = 0 ; if ( safSLV > 0 ) { safSL = ND ( ( safPrice + safSLV ) ) ; }
         // -------------------- x
         safTradeSuccess = trade.SellStop ( safLot2Use , safPrice , glb_EAS , safSL , safTP , ORDER_TIME_GTC , 0 , safComment2Use ) ; Sleep ( 1000 ) ;
         // -------------------- x
         safTriesCount += 1 ; if ( safTriesCount >= glb_MaxTries ) { goPrint ( "Maximum number of tries reached" ) ; break ; }}
      // -------------------- x
      if ( safTradeSuccess ) { glb_MinsSinceTrade = 0 ; }
      // -------------------- x
      return ( safTradeSuccess ) ; }

   bool sBuyLimit ( double safPrice , double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safLot=-1 , string safComment="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( false ) ; }
      // -------------------- x
      if ( glb_AllowedTrade == No_Trade ) { return ( false ) ; }
      if ( glb_AllowedTrade == Sell_Only ) { return ( false ) ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ( false ) ; }
      // -------------------- x
      string safComment2Use = glb_Magic + "/V2/BL/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + safComment ;
      // -------------------- x
      if ( glb_BeaconMode == true ) {
         goBroadcast_SIG ( goTele_PrepMsg ( "BL" , string ( safPrice ) , string ( sPow ( safSLV ) ) , string ( sPow ( safTPV ) ) ,
            string ( sPow ( safPercCalcSLV ) ) , string ( ND2 ( safLot ) ) , string ( glb_LotSize ) , safComment2Use ) ) ;
         return ( true ) ; }
      // -------------------- x
      bool safTradeSuccess = false ;
      int safTriesCount = 0 ;
      double safLot2Use = ND2 ( goCalc_LotSize ( safPercCalcSLV , safLot ) ) ;
      // -------------------- x
      while ( safTradeSuccess == false ) {
         // -------------------- x
         if ( sAsk() <= safPrice ) { break ; }
         // -------------------- x
         safPrice = ND ( safPrice ) ;
         // -------------------- x
         double safTP = 0 ; if ( safTPV > 0 ) { safTP = ND ( ( safPrice + safTPV ) ) ; }
         double safSL = 0 ; if ( safSLV > 0 ) { safSL = ND ( ( safPrice - safSLV ) ) ; }
         // -------------------- x
         safTradeSuccess = trade.BuyLimit ( safLot2Use , safPrice , glb_EAS , safSL , safTP , ORDER_TIME_GTC , 0 , safComment2Use ) ; Sleep ( 1000 ) ;
         // -------------------- x
         safTriesCount += 1 ; if ( safTriesCount >= glb_MaxTries ) { goPrint ( "Maximum number of tries reached" ) ; break ; }}
      // -------------------- x
      if ( safTradeSuccess ) { glb_MinsSinceTrade = 0 ; }
      // -------------------- x
      return ( safTradeSuccess ) ; }

   bool sSellLimit ( double safPrice , double safSLV=0 , double safTPV=0 , double safPercCalcSLV=0 , double safLot=-1 , string safComment="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( false ) ; }
      // -------------------- x
      if ( glb_AllowedTrade == No_Trade ) { return ( false ) ; }
      if ( glb_AllowedTrade == Buy_Only ) { return ( false ) ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ( false ) ; }
      // -------------------- x
      string safComment2Use = glb_Magic + "/V2/SL/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + safComment ;
      // -------------------- x
      if ( glb_BeaconMode == true ) {
         goBroadcast_SIG ( goTele_PrepMsg ( "SL" , string ( safPrice ) , string ( sPow ( safSLV ) ) , string ( sPow ( safTPV ) ) ,
            string ( sPow ( safPercCalcSLV ) ) , string ( ND2 ( safLot ) ) , string ( glb_LotSize ) , safComment2Use ) ) ;
         return ( true ) ; }
      // -------------------- x
      bool safTradeSuccess = false ;
      int safTriesCount = 0 ;
      double safLot2Use = ND2 ( goCalc_LotSize ( safPercCalcSLV , safLot ) ) ;
      // -------------------- x
      while ( safTradeSuccess == false ) {
         // -------------------- x
         if ( sBid() >= safPrice ) { break ; }
         // -------------------- x
         safPrice = ND ( safPrice ) ;
         // -------------------- x
         double safTP = 0 ; if ( safTPV > 0 ) { safTP = ND ( ( safPrice - safTPV ) ) ; }
         double safSL = 0 ; if ( safSLV > 0 ) { safSL = ND ( ( safPrice + safSLV ) ) ; }
         // -------------------- x
         safTradeSuccess = trade.SellLimit ( safLot2Use , safPrice , glb_EAS , safSL , safTP , ORDER_TIME_GTC , 0 , safComment2Use ) ; Sleep ( 1000 ) ;
         // -------------------- x
         safTriesCount += 1 ; if ( safTriesCount >= glb_MaxTries ) { goPrint ( "Maximum number of tries reached" ) ; break ; }}
      // -------------------- x
      if ( safTradeSuccess ) { glb_MinsSinceTrade = 0 ; }
      // -------------------- x
      return ( safTradeSuccess ) ; }

   //===========================================================================================================
   //=====                                      LITE TRADE FUNCTION                                        =====
   //===========================================================================================================

   bool sTrade ( string safType , double safPrice , double safSL , double safTP , double safLot , string safComment ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( false ) ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ( false ) ; }
      // -------------------- x
      bool safTradeSuccess = false ;
      int safTriesCount = 0 ;
      // -------------------- x
      while ( safTradeSuccess == false ) {
         // -------------------- x
         if ( safType == "B" ) { safTradeSuccess = trade.Buy ( ND2 ( safLot ) , glb_EAS , sAsk() , ND ( safSL ) , ND ( safTP ) , safComment ) ; }
         else if ( safType == "S" ) { safTradeSuccess = trade.Sell ( ND2 ( safLot ) , glb_EAS , sBid() , ND ( safSL ) , ND ( safTP ) , safComment ) ; }
         else if ( safType == "BS" ) { safTradeSuccess = trade.BuyStop   ( ND2 ( safLot ) , ND ( safPrice ) , glb_EAS , ND ( safSL ) , ND ( safTP ) , ORDER_TIME_GTC , 0 , safComment ) ; }
         else if ( safType == "SS" ) { safTradeSuccess = trade.SellStop  ( ND2 ( safLot ) , ND ( safPrice ) , glb_EAS , ND ( safSL ) , ND ( safTP ) , ORDER_TIME_GTC , 0 , safComment ) ; }
         else if ( safType == "BL" ) { safTradeSuccess = trade.BuyLimit  ( ND2 ( safLot ) , ND ( safPrice ) , glb_EAS , ND ( safSL ) , ND ( safTP ) , ORDER_TIME_GTC , 0 , safComment ) ; }
         else if ( safType == "SL" ) { safTradeSuccess = trade.SellLimit ( ND2 ( safLot ) , ND ( safPrice ) , glb_EAS , ND ( safSL ) , ND ( safTP ) , ORDER_TIME_GTC , 0 , safComment ) ; }
         // -------------------- x
         Sleep ( 1000 ) ; safTriesCount += 1 ; if ( safTriesCount >= glb_MaxTries ) { break ; }}
      // -------------------- x
      if ( safTradeSuccess ) { glb_MinsSinceTrade = 0 ; }
      // -------------------- x
      return ( safTradeSuccess ) ; }

   //===========================================================================================================
   //=====                                     NEW LOT CALC FUNCTIONS                                      =====
   //===========================================================================================================

   double goCalc_LotSizeBaseRiskAndSL ( double safRiskPercent , double safDistanceSL ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- Abort checks
      if ( ( safRiskPercent <= 0 ) || ( safDistanceSL <= 0 ) ) { return 0 ; }
      // -------------------- Variables
      double result = 0 ;
      // -------------------- Get tick info
      double safTickSize   = SymbolInfoDouble ( glb_EAS , SYMBOL_TRADE_TICK_SIZE ) ;
      double safTickValue  = SymbolInfoDouble ( glb_EAS , SYMBOL_TRADE_TICK_VALUE ) ; // value per 1 lot
      double safLotStep   = SymbolInfoDouble ( glb_EAS , SYMBOL_VOLUME_STEP ) ; // multiply by tick value to get step value
      // -------------------- Abort checks
      if ( ( safTickSize <= 0 ) || ( safTickValue <= 0 ) || ( safLotStep <= 0 ) ) { return 0 ; }
      // -------------------- Calc Amount 2 use
      double safAmountToRisk = AccountInfoDouble ( ACCOUNT_MARGIN_FREE ) * safRiskPercent / 100 ;
      // -------------------- Calc variables
      double safLotStepTickValue = safLotStep * safTickValue ; // value of 1 step
      double safTicksToSL = safDistanceSL / safTickSize ;
      // -------------------- Calc value of 1 lot step
      double safLossPerLotStep = safLotStepTickValue * safTicksToSL ;
      // -------------------- Abort checks
      if ( safLossPerLotStep <= 0 ) { return 0 ; }
      // -------------------- Calc final lot size
      result = ND2 ( ( safAmountToRisk / safLossPerLotStep ) * safLotStep ) ; // no of lot steps required
      // -------------------- min max checks
      if ( result > sMax() ) { result = sMax() ; }
      if ( result < sMin() ) { result = sMin() ; } // or zero in a perfect world
      // -------------------- Return value
      return result ; }

   //===========================================================================================================
   //=====                                     CURR LOT CALC FUNCTIONS                                     =====
   //===========================================================================================================

   double goCalc_LotSize ( double safPercSLV , double safLot = -1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- Calc amount 2 use here
      double safAmount = prvCalcLotSize_Amount2USe () ;
      // -------------------- Variables
      double result = safLot ;
      // -------------------- If safLot = -1
      if ( safLot == -1 ) {
         // -------------------- Handle 0
         if ( glb_LotSize == 0 ) {
            result = sMin() * safAmount / 1000 ; }
         // -------------------- Handle 0.01
         else if ( glb_LotSize == 0.01 ) {
            result = sMin() ; }
         // -------------------- Handle Other
         else { result = ( safAmount * ( glb_LotSize / 100 ) ) / sPow ( safPercSLV ) ; }
         // -------------------- Adjust for other base currencies
         if ( result > sMin() ) {
            if ( UT ( AccountInfoString ( ACCOUNT_CURRENCY ) ) != "USD" ) { result = result * goCalc_ExchangeRate () ; }}}
      // -------------------- Check Max DD adjustments
      result = prvCalcLotSize_MaxDDAdjust ( result , safAmount ) ;
      // -------------------- Check for lot limits
      result = prvCalcLotSize_LimitLot ( result , safAmount ) ;
      // -------------------- Step result
      result = prvCalcLotSize_StepLot ( result ) ;
      // -------------------- Return result
      return ( ND2 ( result ) ) ; }

   double prvCalcLotSize_Amount2USe () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- Initial amount
      double safAmount = AccountInfoDouble ( ACCOUNT_MARGIN_FREE ) ;
      // -------------------- Adjust if beacon mode to be min 10000
      if ( glb_BeaconMode == true ) {
         safAmount = MathMax ( safAmount , 10000 ) ; }
      // -------------------- Adjust if there is a value cap
      if ( glb_MaxCapitalValue > 0 ) {
         safAmount = MathMin ( safAmount , glb_MaxCapitalValue ) ; }
      // -------------------- Adjust if there is a percent cap
      if ( glb_MaxCapitalPerc > 0 ) {
         double safMaxAmount = safAmount * glb_MaxCapitalPerc / 100 ;
         safAmount = MathMin ( safAmount , safMaxAmount ) ; }
      // -------------------- Return result
      return ( safAmount ) ; }

   double prvCalcLotSize_LimitLot ( double safLot , double safAmount ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- Initial size
      double result = safLot ;
      // -------------------- Adjust max lot per K
      if ( glb_MaxLotPerK > 0 ) {
         // -------------------- Set max based on limited free equity
         double safMaxLot = safAmount / 1000 * glb_MaxLotPerK ;
         // -------------------- x
         result = MathMin ( result , safMaxLot ) ; }
      // -------------------- x
      if ( result < sMin() ) { result = sMin() ; }
      // if ( result < sMin() ) { result = 0.00 ; }
      if ( result > sMax() ) { result = sMax() ; }
      // -------------------- Return result
      return ( result ) ; }

   double prvCalcLotSize_StepLot ( double safLot ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- Initialize
      double result = 0 ;
      // -------------------- Get step amount
      double safStep = SymbolInfoDouble ( glb_EAS , SYMBOL_VOLUME_STEP ) ;
      // -------------------- Increment
      do { result += safStep ; } while ( result < safLot ) ;
      // -------------------- to cater for double shit rounding math
      if ( ( result - safLot ) > ( safStep * 0.5 ) ) { result = result - safStep ; }
      // -------------------- Return result
      return ( result ) ; }

   double prvCalcLotSize_MaxDDAdjust ( double safLot , double safAmount ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- Quit if no DD trigger set
      if ( glb_MaxDDTrigger == 0 ) { return ( safLot ) ; }
      // -------------------- Quit if no DD behaviour set
      if ( glb_MaxDDBehaviour == Do_Noting ) { return ( safLot ) ; }
      // -------------------- Initial
      double result = safLot ;
      double safBalance = sBal() ;
      double safEquity = sEqu() ;
      double safTrigger01 = safBalance * ( 100 - ( glb_MaxDDTrigger * 1 ) ) / 100 ;
      double safTrigger02 = safBalance * ( 100 - ( glb_MaxDDTrigger * 2 ) ) / 100 ;
      double safTrigger03 = safBalance * ( 100 - ( glb_MaxDDTrigger * 3 ) ) / 100 ;
      // -------------------- If first trigger not passed then quit
      if ( safEquity > safTrigger01 ) { return ( result ) ; }
      // -------------------- If trigger 1 passed and stop trade
      if ( glb_MaxDDBehaviour == Stop_Trade ) { return ( 0 ) ; }
      // -------------------- If trigger 1 passed and trade min
      if ( glb_MaxDDBehaviour == Trade_Minimum ) { return ( MathMin ( result , ( sMin() * safAmount / 1000 ) ) ) ; }
      // -------------------- If trigger 1 passed otherwise
      if ( glb_MaxDDBehaviour == Trade_Half_Half_Min ) {
         result = result / 2 ;
         // -------------------- If trigger 2 passed
         if ( safEquity <= safTrigger02 ) {
            result = result / 2 ;
            // -------------------- If trigger 3 passed
            if ( safEquity <= safTrigger03 ) {
               result = MathMin ( result , ( sMin() * safAmount / 1000 ) ) ; }}}
      // -------------------- Return result
      return ( result ) ; }

   //===========================================================================================================
   //=====                                      OTHER CALC FUNCTIONS                                       =====
   //===========================================================================================================

   string goTranslate_RiskLevel ( int safRiskLevel=Medium ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      if ( safRiskLevel == Highest ) { return "1245" ; }
      else if ( safRiskLevel == Higher ) { return "1245B" ; }
      else if ( safRiskLevel == High ) { return "1245C" ; }
      else if ( safRiskLevel == Medium ) { return "1245D" ; }
      else if ( safRiskLevel == Low ) { return "1245E" ; }
      else if ( safRiskLevel == Lower ) { return "1245A" ; }
      else { return "12456" ; }}

   double goCalc_PercentSLV ( string safType , string safRules="1245" , int safDivider=1 ,int safMinPoints=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      // 1: ATR14 - 2: ATR1440 - 4: ATR7200 - 5: ATR28800 - 6: Price/Divider
      // 7: BB - 8: D1 ATR220 / Divider - 9: Ichi cloud - A: Last year Max-Min/Dicider
      // B: M15 ATR96 / Divider - C: H1 ATR120 / Divider - D: D1 ATR22 / Divider
      // -------------------- Variables
      double result = 0 ;
      // -------------------- Calculations
      if ( sFind ( safRules , "1" ) ) { result = MathMax ( result , sATR ( 14 ) ) ; }
      if ( sFind ( safRules , "2" ) ) { result = MathMax ( result , sATR ( 1440 ) ) ; }
      if ( sFind ( safRules , "4" ) ) { result = MathMax ( result , sATR ( 7200 ) ) ; }
      if ( sFind ( safRules , "5" ) ) { result = MathMax ( result , sATR ( 28800 ) ) ; }
      if ( sFind ( safRules , "6" ) ) { result = MathMax ( result , ( sAsk() / safDivider ) ) ; }
      if ( sFind ( safRules , "8" ) ) { result = MathMax ( result , ( sATR ( 220 , PERIOD_D1 ) / safDivider ) ); }
      if ( sFind ( safRules , "B" ) ) { result = MathMax ( result , ( sATR ( 288 , PERIOD_M5 ) / safDivider ) ) ; }
      if ( sFind ( safRules , "C" ) ) { result = MathMax ( result , ( sATR ( 96 , PERIOD_M15 ) / safDivider ) ) ; }
      if ( sFind ( safRules , "D" ) ) { result = MathMax ( result , ( sATR ( 120 , PERIOD_H1 ) / safDivider ) ) ; }
      if ( sFind ( safRules , "E" ) ) { result = MathMax ( result , ( sATR ( 22 , PERIOD_D1 ) / safDivider ) ) ; }
      // -------------------- x
      if ( sFind ( safRules , "7" ) ) {
         if ( ind_Band ( 20 , 0 , 2 ) == false ) { return 0 ; }
         result = MathMax ( result , ( ( ( B1 [ glb_FC ] - B2 [ glb_FC ] ) / 4 ) * 3 ) ) ; }
      // -------------------- x
      if ( sFind ( safRules , "9" ) ) {
         // -------------------- handle indicator here
         if ( ind_Ichimoku () == false ) { return 0 ; }
         double safCloudA = B2 [ glb_FC + 26 ] ;
         double safCloudB = B3 [ glb_FC + 26 ] ;
         double safPrice = glb_PI[ glb_FC ].close ;
         if ( ( ( safPrice > safCloudA ) && ( safPrice < safCloudB ) ) || ( ( safPrice < safCloudA ) && ( safPrice > safCloudB ) ) ) { return 0 ; }
         result = MathMax ( result , ( MathMax ( MathAbs ( safPrice - safCloudA ) , MathAbs ( safPrice - safCloudB ) ) ) ) ; }
      // -------------------- x
      if ( sFind ( safRules , "A" ) ) {
         ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         glb_EAP = PERIOD_D1 ;
            goClearBuffers () ;
            CopyHigh ( glb_EAS , glb_EAP , glb_FC , 220 , B4 ) ;
            int safNum = ArrayMaximum ( B4 ) ;
            double safMax = B4 [ safNum ] ;
            CopyLow ( glb_EAS , glb_EAP , glb_FC , 220 , B4 ) ;
            safNum = ArrayMinimum ( B4 ) ;
            double safMin = B4 [ safNum ] ;
         glb_EAP = sCurr_Period ;
         result = MathMax ( result ,  ( ( safMax - safMin ) / safDivider ) ) ; }
      // -------------------- x
      if ( safMinPoints > 0 ) { result = MathMax ( result , ( safMinPoints * sPoint() ) ) ; }
      // -------------------- x
      return ( result ) ; }

   string goCalc_TradeRange (
      ENUM_TIMEFRAMES safTF=PERIOD_H1 , int safPeriod=120 , double safPercent=85 , bool safChart=false ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- Declarations and variables
         MqlRates sPI[] ; ArraySetAsSeries ( sPI , true ) ;
         CopyRates ( glb_EAS , safTF , 0 , ( safPeriod + 1 ) , sPI ) ;
         // -------------------- x
         double safMax=0 , safMin=999999 ;
         // -------------------- x
         for ( int x = glb_FC ; x <= safPeriod ; x++ ) {
            if ( sPI [ x ].high > safMax ) { safMax = sPI [ x ].high ; }
            if ( sPI [ x ].low  < safMin ) { safMin = sPI [ x ].low  ; }}
         // -------------------- x
         double safRange = safMax - safMin ;
         double safMiddle = safMin + ( safRange / 2 ) ;
         safRange = safRange * ( safPercent / 100 ) ;
         double safUpper = safMiddle + ( safRange / 2 ) ;
         double safLower = safMiddle - ( safRange / 2 ) ;
         // -------------------- x
         // if ( safChart ) {
         //    goDraw_HLine ( "rangemax" , safMax , clrGray ) ;
         //    goDraw_HLine ( "rangeupper" , safUpper , clrGray ) ;
         //    goDraw_HLine ( "rangemid" , safMiddle , clrGray ) ;
         //    goDraw_HLine ( "rangelower" , safLower , clrGray ) ;
         //    goDraw_HLine ( "rangemin" , safMin , clrGray ) ; }
         // -------------------- x
         if ( ( sAsk() < safUpper ) && ( sBid() > safLower ) ) { return "Y" ; }
         return "X" ; }

   double goCalc_TotalTradedLots () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      string HistoryLines[] ; goHistory_Retreive ( HistoryLines ) ;
      if ( ArraySize ( HistoryLines ) < 1 ) { return 0 ; }
      // -------------------- x
      double result = 0 ;
      // -------------------- x
      for ( int i=0 ; i < ArraySize ( HistoryLines ) ; i++ ) {
         // -------------------- x
         string safSplit[] ; StringSplit ( HistoryLines [ i ] , 124 , safSplit ) ;
         if ( ArraySize ( safSplit ) < 12 ) { continue ; }
         // -------------------- x
         result += double ( safSplit [ 5 ] ) ; }
      // -------------------- x
      return ( result ) ; }

   double goCalc_SymbolProfit ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      double result = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Calc
         result += PositionGetDouble ( POSITION_PROFIT ) + PositionGetDouble ( POSITION_SWAP ) ; }
      // -------------------- x
      return ( result ) ; }

   double goCalc_HistoricNetProfit ( string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- Working variables
      double TotalProfit = 0 ;
      sCurr = UT ( sCurr ) ;
      // -------------------- Get history
      string HistoryLines[] ; goHistory_Retreive ( HistoryLines ) ;
      if ( ArraySize ( HistoryLines ) < 1 ) { return 0 ; }
      // -------------------- Go thru history
      for ( int i=0 ; i < ArraySize ( HistoryLines ) ; i++ ) {
         // -------------------- Split line
         string safSplit[] ; StringSplit ( HistoryLines [ i ] , 124 , safSplit ) ;
         if ( ArraySize ( safSplit ) < 12 ) { continue ; }
         // -------------------- Deal variables
         string DealType      = safSplit [ 2 ] ;
         string DealCurr = string ( safSplit [ 4 ] ) ;
         double DealNet       = (double) safSplit [ 11 ] ;
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( DealCurr ) != sCurr ) { continue ; }}
         // -------------------- x
         if ( ( DealType == "BUY" ) || ( DealType == "SELL" ) ) { TotalProfit += DealNet ; }}
      // -------------------- x
      return ( TotalProfit ) ; }

   double goCalc_LastXCandleHigh ( int NoOfCandles , ENUM_TIMEFRAMES sTF=PERIOD_CURRENT ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return 0 ; }
      // -------------------- x
      double sPI[] ; ArraySetAsSeries ( sPI , true ) ;
      CopyHigh ( glb_EAS , sTF , 0 , ( NoOfCandles + 2 ) , sPI ) ;
      // -------------------- x
      double result = sPI [ glb_FC + 1 ] ;
      // -------------------- x
      for ( int i=1 ; i < NoOfCandles ; i++ ) {
         result = MathMax ( sPI [ glb_FC + 1 + i ] , result ) ; }
      // -------------------- x
      return ( result ) ; }

   double goCalc_LastXCandleLow ( int NoOfCandles , ENUM_TIMEFRAMES sTF=PERIOD_CURRENT ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return 0 ; }
      // -------------------- x
      double sPI[] ; ArraySetAsSeries ( sPI , true ) ;
      CopyLow ( glb_EAS , sTF , 0 , ( NoOfCandles + 2 ) , sPI ) ;
      // -------------------- x
      double result = sPI [ glb_FC + 1 ] ;
      // -------------------- x
      for ( int i=1 ; i < NoOfCandles ; i++ ) {
         result = MathMin ( sPI [ glb_FC + 1 + i ] , result ) ; }
      // -------------------- x
      return ( result ) ; }

   double goCalc_YesterdayDayRange () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      CopyHigh ( glb_EAS , PERIOD_D1 , 0 , 2 , B3 ) ;
      CopyLow  ( glb_EAS , PERIOD_D1 , 0 , 2 , B4 ) ;
      // -------------------- x
      return ND ( B3 [ 1 ] - B4 [ 1 ] ) ; }

   double goCalc_SLDistBasedOnLotAndLoss ( double sLot , double sLossAmount , bool sDeductSpread=false ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      double OneLotOneTickMoveValue = SymbolInfoDouble ( glb_EAS , SYMBOL_TRADE_TICK_VALUE ) * sLot ;
      double NoOfTicksToReachLossAmount = ( sLossAmount / OneLotOneTickMoveValue ) * sPoint() ;
      if ( sDeductSpread ) { NoOfTicksToReachLossAmount = NoOfTicksToReachLossAmount - sSpread() ; }
      return ( NoOfTicksToReachLossAmount ) ; }

   //===========================================================================================================
   //=====                                      ORDER FIND FUNCTIONS                                       =====
   //===========================================================================================================

   ulong goFind_LastPlacedOrder ( int sIndexFromEdge , string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( OrdersTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; }
      // -------------------- x
      datetime sLastDateTime = NULL ;
      // -------------------- x
      ulong result = NULL ;
      ulong resultMinus1 = NULL ;
      ulong resultMinus2 = NULL ;
      // -------------------- x
      for ( int i = 0 ; i < OrdersTotal() ; i++ ) {
         // -------------------- x
         ulong ordTicket = OrderGetTicket ( i ) ;
         if ( !OrderSelect ( ordTicket ) ) { continue ; }
         // -------------------- Check Symbol
         if ( sCurr != "" ) { if ( UT ( OrderGetString ( ORDER_SYMBOL ) ) != sCurr ) { continue ; }}
         // -------------------- Calculation here
         datetime ordOpenTime = datetime ( OrderGetInteger ( ORDER_TIME_SETUP ) ) ;
         // --------------------
         if ( ordOpenTime > sLastDateTime ) {
            // -------------------- x
            sLastDateTime = ordOpenTime ;
            // -------------------- x
            resultMinus2 = resultMinus1 ;
            resultMinus1 = result ;
            result = ordTicket ; }}
      // -------------------- x
      if ( sIndexFromEdge == 0 ) { return ( result ) ; }
      else if ( sIndexFromEdge == 1 ) { return ( resultMinus1 ) ; }
      else if ( sIndexFromEdge == 2 ) { return ( resultMinus2 ) ; }
      else { return ( 0 ) ; }}

   ulong goFind_LastStopOrder ( int sIndexFromEdge , string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( OrdersTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; }
      // -------------------- x
      datetime sLastDateTime = NULL ;
      // -------------------- x
      ulong result = NULL ;
      ulong resultMinus1 = NULL ;
      ulong resultMinus2 = NULL ;
      // -------------------- x
      for ( int i = 0 ; i < OrdersTotal() ; i++ ) {
         // -------------------- x
         ulong ordTicket = OrderGetTicket ( i ) ;
         if ( !OrderSelect ( ordTicket ) ) { continue ; }
         // -------------------- Check Symbol
         if ( sCurr != "" ) { if ( UT ( OrderGetString ( ORDER_SYMBOL ) ) != sCurr ) { continue ; }}
         // -------------------- Check Type Stop
         long ordType = OrderGetInteger ( ORDER_TYPE ) ;
         // -------------------- Check Type Stop
         if ( ordType == ORDER_TYPE_BUY ) { continue ; }
         else if ( ordType == ORDER_TYPE_SELL ) { continue ; }
         else if ( ordType == ORDER_TYPE_BUY_LIMIT ) { continue ; }
         else if ( ordType == ORDER_TYPE_SELL_LIMIT ) { continue ; }
         else if ( ordType == ORDER_TYPE_BUY_STOP_LIMIT ) { continue ; }
         else if ( ordType == ORDER_TYPE_SELL_STOP_LIMIT ) { continue ; }
         // -------------------- Calculation here
         datetime ordOpenTime = datetime ( OrderGetInteger ( ORDER_TIME_SETUP ) ) ;
         // --------------------
         if ( ordOpenTime > sLastDateTime ) {
            // -------------------- x
            sLastDateTime = ordOpenTime ;
            // -------------------- x
            resultMinus2 = resultMinus1 ;
            resultMinus1 = result ;
            result = ordTicket ; }}
      // -------------------- x
      if ( sIndexFromEdge == 0 ) { return ( result ) ; }
      else if ( sIndexFromEdge == 1 ) { return ( resultMinus1 ) ; }
      else if ( sIndexFromEdge == 2 ) { return ( resultMinus2 ) ; }
      else { return ( 0 ) ; }}

   ulong goFind_LastLimitOrder ( int sIndexFromEdge , string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( OrdersTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; }
      // -------------------- x
      datetime sLastDateTime = NULL ;
      // -------------------- x
      ulong result = NULL ;
      ulong resultMinus1 = NULL ;
      ulong resultMinus2 = NULL ;
      // -------------------- x
      for ( int i = 0 ; i < OrdersTotal() ; i++ ) {
         // -------------------- x
         ulong ordTicket = OrderGetTicket ( i ) ;
         if ( !OrderSelect ( ordTicket ) ) { continue ; }
         // -------------------- Check Symbol
         if ( sCurr != "" ) { if ( UT ( OrderGetString ( ORDER_SYMBOL ) ) != sCurr ) { continue ; }}
         // -------------------- Check Type Stop
         long ordType = OrderGetInteger ( ORDER_TYPE ) ;
         // -------------------- Check Type Stop
         if ( ordType == ORDER_TYPE_BUY ) { continue ; }
         else if ( ordType == ORDER_TYPE_SELL ) { continue ; }
         else if ( ordType == ORDER_TYPE_BUY_STOP ) { continue ; }
         else if ( ordType == ORDER_TYPE_SELL_STOP ) { continue ; }
         else if ( ordType == ORDER_TYPE_BUY_STOP_LIMIT ) { continue ; }
         else if ( ordType == ORDER_TYPE_SELL_STOP_LIMIT ) { continue ; }
         // -------------------- Calculation here
         datetime ordOpenTime = datetime ( OrderGetInteger ( ORDER_TIME_SETUP ) ) ;
         // --------------------
         if ( ordOpenTime > sLastDateTime ) {
            // -------------------- x
            sLastDateTime = ordOpenTime ;
            // -------------------- x
            resultMinus2 = resultMinus1 ;
            resultMinus1 = result ;
            result = ordTicket ; }}
      // -------------------- x
      if ( sIndexFromEdge == 0 ) { return ( result ) ; }
      else if ( sIndexFromEdge == 1 ) { return ( resultMinus1 ) ; }
      else if ( sIndexFromEdge == 2 ) { return ( resultMinus2 ) ; }
      else { return ( 0 ) ; }}

   //===========================================================================================================
   //=====                                     POSITION FIND FUNCTIONS                                     =====
   //===========================================================================================================

   ulong goFind_LastOpenedPosition ( int sIndexFromEdge , string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { 0 ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      datetime sLastDateTime = NULL ;
      // -------------------- x
      ulong result = NULL ;
      ulong resultMinus1 = NULL ;
      ulong resultMinus2 = NULL ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- x
         datetime posOpenTime = datetime ( PositionGetInteger ( POSITION_TIME ) ) ;
         // -------------------- x
         if ( posOpenTime > sLastDateTime ) {
            // -------------------- x
            sLastDateTime = posOpenTime ;
            // -------------------- x
            resultMinus2 = resultMinus1 ;
            resultMinus1 = result ;
            result = posTicket ; }}
      // -------------------- x
      if ( sIndexFromEdge == 0 ) { return ( result ) ; }
      else if ( sIndexFromEdge == 1 ) { return ( resultMinus1 ) ; }
      else if ( sIndexFromEdge == 2 ) { return ( resultMinus2 ) ; }
      else { return ( 0 ) ; }}

   ulong goFind_FirstOpenedPosition ( int sIndexFromEdge , string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { 0 ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      datetime sFirstDateTime = TimeGMT() ;
      // -------------------- x
      ulong result = NULL ;
      ulong resultMinus1 = NULL ;
      ulong resultMinus2 = NULL ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- x
         datetime posOpenTime = datetime ( PositionGetInteger ( POSITION_TIME ) ) ;
         // -------------------- x
         if ( posOpenTime < sFirstDateTime ) {
            // -------------------- x
            sFirstDateTime = posOpenTime ;
            // -------------------- x
            resultMinus2 = resultMinus1 ;
            resultMinus1 = result ;
            result = posTicket ; }}
      // -------------------- x
      if ( sIndexFromEdge == 0 ) { return ( result ) ; }
      else if ( sIndexFromEdge == 1 ) { return ( resultMinus1 ) ; }
      else if ( sIndexFromEdge == 2 ) { return ( resultMinus2 ) ; }
      else { return ( 0 ) ; }}

   ulong goFind_HighestBuy_LowestSell_Position ( int sIndexFromEdge , string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { 0 ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      double posHLPrice = NULL ;
      // -------------------- x
      ulong result = NULL ;
      ulong resultMinus1 = NULL ;
      ulong resultMinus2 = NULL ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- x
         long posType = PositionGetInteger ( POSITION_TYPE ) ;
         double posPrice = PositionGetDouble ( POSITION_PRICE_OPEN ) ;
         // -------------------- x
         if ( posHLPrice == NULL ) { posHLPrice = posPrice ; }
         // -------------------- x
         if ( posType == POSITION_TYPE_BUY ) {
            if ( posPrice >= posHLPrice ) {
               // -------------------- x
               posHLPrice = posPrice ;
               // -------------------- x
               resultMinus2 = resultMinus1 ;
               resultMinus1 = result ;
               result = posTicket ; }}
         // -------------------- x
         else if ( posType == POSITION_TYPE_SELL ) {
            if ( posPrice <= posHLPrice ) {
               // -------------------- x
               posHLPrice = posPrice ;
               // -------------------- x
               resultMinus2 = resultMinus1 ;
               resultMinus1 = result ;
               result = posTicket ; }}}
      // -------------------- x
      if ( sIndexFromEdge == 0 ) { return ( result ) ; }
      else if ( sIndexFromEdge == 1 ) { return ( resultMinus1 ) ; }
      else if ( sIndexFromEdge == 2 ) { return ( resultMinus2 ) ; }
      else { return ( 0 ) ; }}

   ulong goFind_LowestBuy_HighestSell_Position ( int sIndexFromEdge , string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { 0 ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      double posHLPrice = NULL ;
      // -------------------- x
      ulong result = NULL ;
      ulong resultMinus1 = NULL ;
      ulong resultMinus2 = NULL ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- x
         long posType = PositionGetInteger ( POSITION_TYPE ) ;
         double posPrice = PositionGetDouble ( POSITION_PRICE_OPEN ) ;
         // -------------------- x
         if ( posHLPrice == NULL ) { posHLPrice = posPrice ; }
         // -------------------- x
         if ( posType == POSITION_TYPE_BUY ) {
            if ( posPrice <= posHLPrice ) {
               // -------------------- x
               posHLPrice = posPrice ;
               // -------------------- x
               resultMinus2 = resultMinus1 ;
               resultMinus1 = result ;
               result = posTicket ; }}
         // -------------------- x
         else if ( posType == POSITION_TYPE_SELL ) {
            if ( posPrice >= posHLPrice ) {
               // -------------------- x
               posHLPrice = posPrice ;
               // -------------------- x
               resultMinus2 = resultMinus1 ;
               resultMinus1 = result ;
               result = posTicket ; }}}
      // -------------------- x
      if ( sIndexFromEdge == 0 ) { return ( result ) ; }
      else if ( sIndexFromEdge == 1 ) { return ( resultMinus1 ) ; }
      else if ( sIndexFromEdge == 2 ) { return ( resultMinus2 ) ; }
      else { return ( 0 ) ; }}

   ulong goFind_SmallestLotPosition ( int sIndexFromEdge , string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { 0 ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      double SmallestLotSize = NULL ;
      // -------------------- x
      ulong result = NULL ;
      ulong resultMinus1 = NULL ;
      ulong resultMinus2 = NULL ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- x
         double posLot = PositionGetDouble ( POSITION_VOLUME ) ;
         // -------------------- x
         if ( SmallestLotSize == NULL ) { SmallestLotSize = posLot ; }
         // -------------------- x
         if ( posLot <= SmallestLotSize ) {
            // -------------------- x
            SmallestLotSize = posLot ;
            // -------------------- x
            resultMinus2 = resultMinus1 ;
            resultMinus1 = result ;
            result = posTicket ; }}
      // -------------------- x
      if ( sIndexFromEdge == 0 ) { return ( result ) ; }
      else if ( sIndexFromEdge == 1 ) { return ( resultMinus1 ) ; }
      else if ( sIndexFromEdge == 2 ) { return ( resultMinus2 ) ; }
      else { return ( 0 ) ; }}

   ulong goFind_BiggestLotPosition ( int sIndexFromEdge , string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { 0 ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      double BiggestLotSize = NULL ;
      // -------------------- x
      ulong result = NULL ;
      ulong resultMinus1 = NULL ;
      ulong resultMinus2 = NULL ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- x
         double posLot = PositionGetDouble ( POSITION_VOLUME ) ;
         // -------------------- x
         if ( BiggestLotSize == NULL ) { BiggestLotSize = posLot ; }
         // -------------------- x
         if ( posLot >= BiggestLotSize ) {
            // -------------------- x
            BiggestLotSize = posLot ;
            // -------------------- x
            resultMinus2 = resultMinus1 ;
            resultMinus1 = result ;
            result = posTicket ; }}
      // -------------------- x
      if ( sIndexFromEdge == 0 ) { return ( result ) ; }
      else if ( sIndexFromEdge == 1 ) { return ( resultMinus1 ) ; }
      else if ( sIndexFromEdge == 2 ) { return ( resultMinus2 ) ; }
      else { return ( 0 ) ; }}

   //===========================================================================================================
   //=====                                    EXCHANGE / BASE CURRENCY                                     =====
   //===========================================================================================================

   double goCalc_ExchangeRate () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      double result = 0 ;
      string sCurr_Symbol = glb_EAS ;
      glb_EAS = goSet_BaseAccountCurrency ( AccountInfoString ( ACCOUNT_CURRENCY ) ) ;
         string safCurrency = glb_EAS ;
         double safFactor = ( sAsk() + sBid() ) / 2 ;
         StringReplace ( safCurrency , "USD" , "" ) ; ;
         if ( ( safCurrency + "USD" ) ==  glb_EAS ) { result = ( safFactor ) ; }
         else if ( ( "USD" + safCurrency ) == glb_EAS ) { result = ( 1 / safFactor ) ; }
      glb_EAS = sCurr_Symbol ;
      return ( result ) ; }

   string goSet_BaseAccountCurrency ( string safCurrency ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      string result = "" ;
      for ( int i = ArraySize ( glb_SymbolArray ) - 1 ; i >= 0 ; i-- ) {
         string safSymbol = UT ( glb_SymbolArray [i] ) ;
         if ( safSymbol == "" ) { continue ; }
         if ( ( UT ( safCurrency + "USD" ) == safSymbol ) || ( UT ( "USD" + safCurrency ) == safSymbol ) ) {
            result = safSymbol ; break ; }}
      return ( result ) ; }

   //===========================================================================================================
   //=====                                            ORCHARD                                              =====
   //===========================================================================================================

   double Double2Ticks ( double safValue ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return ( safValue / SymbolInfoDouble ( glb_EAS , SYMBOL_TRADE_TICK_SIZE ) ) ; }

   double Ticks2Double ( double safTicks ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return ( safTicks * SymbolInfoDouble ( glb_EAS , SYMBOL_TRADE_TICK_SIZE ) ) ; }

   double Points2Double ( int safPoints ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return ( safPoints * SymbolInfoDouble ( glb_EAS , SYMBOL_POINT ) ) ; }

   double PercentSLSize ( double safPercent , double safLots ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return ( RiskSLSize ( ( sEqu() * safPercent ) , safLots ) ) ; } // 1% = 0.01

   double PercentRiskLots ( double safPercent , double safSLSize ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return ( RiskLots ( ( sEqu() * safPercent ) , safSLSize ) ) ; } // 1% = 0.01

   double RiskLots ( double safRiskAmount , double safSLSize ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      double safTicks = Double2Ticks ( safSLSize ) ;
      double safTickValue = SymbolInfoDouble ( glb_EAS , SYMBOL_TRADE_TICK_VALUE ) ;
      double safLotRisk = safTicks * safTickValue ;
      double safRiskLots = safRiskAmount / safLotRisk ;
      return safRiskLots ; }

   double RiskSLSize ( double safRiskAmount , double safLots ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      double safTickValue = SymbolInfoDouble ( glb_EAS , SYMBOL_TRADE_TICK_VALUE ) ;
      double safTicks = safRiskAmount / ( safLots * safTickValue ) ;
      double safSLSize = Ticks2Double ( safTicks ) ;
      return safSLSize ; }

   //===========================================================================================================
   //=====                                             TRAILS                                              =====
   //===========================================================================================================

   void Trail_After_XATR ( int sATRPeriod , double sATRTrigger , double sATRTrail ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ; }
      // -------------------- x
      if ( ( sATRPeriod < 1 ) || ( sATRTrigger < 1 ) || ( sATRTrail < 1 ) ) { return ; }
      // -------------------- x
      string sCurr_Symbol = glb_EAS ;
         // -------------------- x
         for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
            // -------------------- x
            ulong posTicket = PositionGetTicket ( i ) ;
            if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
            // -------------------- x
            if ( sFind ( PositionGetString ( POSITION_COMMENT ) , "NO-SL" ) ) { continue ; }
            // -------------------- x
            glb_EAS = PositionGetString( POSITION_SYMBOL ) ;
            // -------------------- x
            double posSL = PositionGetDouble ( POSITION_SL ) ;
            double posTP = PositionGetDouble ( POSITION_TP ) ;
            double posOpenPrice = PositionGetDouble ( POSITION_PRICE_OPEN ) ;
            // -------------------- x
            if ( !ind_ATR ( sATRPeriod ) ) { continue ; }
            double ATR2Use = B0 [ glb_FC ] ;
            // -------------------- x
            if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_BUY ) {
               double safBid = sBid() ;
               if ( safBid >= ( posOpenPrice + ( ATR2Use * sATRTrigger ) ) ) {
                  double newSL = safBid - ( ATR2Use * sATRTrail ) ;
                  if ( ( newSL - posSL ) > ( 1 * sPoint() ) ) {
                     // goBroadcast_SIG ( goTele_PrepMsg ( "TR2SLV" , (string) sATRPeriod , (string) sATRTrigger , (string) sATRTrail ) ) ;
                     goPositionModify ( posTicket , newSL , posTP , "Trail_After_XATR" ) ; }}
            // -------------------- x
            } else if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_SELL ) {
               double safAsk = sAsk() ;
               if ( safAsk <= ( posOpenPrice - ( ATR2Use * sATRTrigger ) ) ) {
                  if ( posSL == 0 ) { posSL = posOpenPrice ; }
                  double newSL = safAsk + ( ATR2Use * sATRTrail ) ;
                  if ( ( posSL - newSL ) > ( 1 * sPoint() ) ) {
                     // goBroadcast_SIG ( goTele_PrepMsg ( "TR2SLV" , (string) sATRPeriod , (string) sATRTrigger , (string) sATRTrail ) ) ;
                     goPositionModify ( posTicket , newSL , posTP , "Trail_After_XATR" ) ; }}
         }} glb_EAS = sCurr_Symbol ; }

   void goTrail_PercentEquity ( double safMinProfit=0 , int safPercent=80 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      static double safHighestEquity ;
      double safBalance = sBal() ;
      double safEquity = sEqu() ;
      // -------------------- Initialization
      if ( safBalance == safEquity ) { safHighestEquity = safEquity ; return ; }
      // -------------------- Set new high level
      if ( safEquity > safHighestEquity ) { safHighestEquity = safEquity ; return ; }
      // -------------------- Only check if positive
      if ( ( safEquity - safBalance ) < safMinProfit ) { return ; }
      // -------------------- Check trail condition
      double safCloseThreshold = ( ( safHighestEquity - safBalance ) * ( double ( safPercent ) / 100 ) ) ;
      double safCurrentRange = safEquity - safBalance ;
      if ( safCurrentRange < safCloseThreshold ) { goClose_AllPositionsByForce ( "Trail highest equity percent breached" ) ; }}

   void goTrail_SetTP2BreakEven ( string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; } else { sCurr = UT ( sCurr ) ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ; }
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- check for No SL ( no trail )
         // if ( sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , "NO-SL" ) ) { continue ; }
         // -------------------- x
         string posCurr = UT ( PositionGetString ( POSITION_SYMBOL ) ) ;
         if ( sCurr != "" ) { if ( posCurr != sCurr ) { continue ; }}
         // -------------------- Do
         if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_BUY ) {
            double safNewTP = ND ( PositionGetDouble ( POSITION_PRICE_OPEN ) + ( 3 * sPoint( posCurr ) ) ) ;
            if ( goPositionModify ( posTicket , PositionGetDouble ( POSITION_SL ) , safNewTP , "goTrail_SetTP2BreakEven" ) ) {
               goPrint ( "Set " + string ( posTicket ) + " to breakeven " + string ( safNewTP ) ) ; }}
         if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_SELL ) {
            double safNewTP = ND ( PositionGetDouble ( POSITION_PRICE_OPEN ) - ( 3 * sPoint( posCurr ) ) ) ;
            if ( goPositionModify ( posTicket , PositionGetDouble ( POSITION_SL ) , safNewTP , "goTrail_SetTP2BreakEven" ) ) {
               goPrint ( "Set " + string ( posTicket ) + " to breakeven " + string ( safNewTP ) ) ; }}}}

   void goTrail_SetTP_xATR ( int safATRMultiple=1 , int safPeriod=14 , string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; } else { sCurr = UT ( sCurr ) ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ; }
      // -------------------- x
      string sCurr_Symbol = glb_EAS ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- check for No SL ( no trail )
         // if ( sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , "NO-SL" ) ) { continue ; }
         // -------------------- x
         string posCurr = UT ( PositionGetString ( POSITION_SYMBOL ) ) ;
         if ( sCurr != "" ) { if ( posCurr != sCurr ) { continue ; }}
         glb_EAS = posCurr ;
         // -------------------- x
         if ( !ind_ATR ( safPeriod ) ) { continue ; }
         double safATR = B0 [ glb_FC ] ;
         // -------------------- x
         double posSL = PositionGetDouble ( POSITION_SL ) ;
         double posOpenPrice = PositionGetDouble ( POSITION_PRICE_OPEN ) ;
         // -------------------- x
         double safNewTP = 0 ;
         if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_BUY ) { safNewTP = posOpenPrice + ( safATR * safATRMultiple ) ; }
         else if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_SELL ) { safNewTP = posOpenPrice - ( safATR * safATRMultiple ) ; }
         // -------------------- x
         goPositionModify ( posTicket , posSL , safNewTP , "goTrail_SetTP_xATR" ) ;
         goPrint ( "Set " + string ( posTicket ) + " TP to " + string ( safATRMultiple ) + " ATR at " + string ( safNewTP ) ) ; }
      // -------------------- x
      glb_EAS = sCurr_Symbol ; }

   void Trail_BE_Then_XATR ( int sATR_Period , double sBE_ATRs , double sTrigger_ATRs , double sTrail_ATRs ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- Return checks
      if ( PositionsTotal () < 1 ) { return ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ; }
      // -------------------- Capture current symbol
      string sCurr_Symbol = glb_EAS ;
         // -------------------- x
         for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
            // -------------------- x
            ulong posTicket = PositionGetTicket ( i ) ;
            if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
            // -------------------- x
            if ( sFind ( PositionGetString ( POSITION_COMMENT ) , "NO-SL" ) ) { continue ; }
            // -------------------- x
            glb_EAS = PositionGetString( POSITION_SYMBOL ) ;
            // -------------------- x
            if ( !ind_ATR ( sATR_Period ) ) { continue ; }
            double ATR2Use = B0 [ glb_FC ] ;
            // -------------------- x
            double posSL = PositionGetDouble ( POSITION_SL ) ;
            double posTP = PositionGetDouble ( POSITION_TP ) ;
            double posOpenPrice = PositionGetDouble ( POSITION_PRICE_OPEN ) ;
            // -------------------- Handle BE here
            if ( ( sBE_ATRs > 0 ) && ( posSL == 0 ) ) {
               double safBEDist = ATR2Use * sBE_ATRs ;
               // -------------------- x
               if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_BUY ) {
                  double safBid = sBid() ;
                  if ( safBid > ( posOpenPrice + safBEDist ) ) {
                     goPositionModify ( posTicket , ( safBid - safBEDist ) , posTP , "Trail_BE_Then_XATR" ) ; }}
               else if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_SELL ) {
                  double safAsk = sAsk() ;
                  if ( safAsk < ( posOpenPrice - safBEDist ) ) {
                     goPositionModify ( posTicket , ( safAsk + safBEDist ) , posTP , "Trail_BE_Then_XATR" ) ; }}}
            // -------------------- x
            if ( ( sTrigger_ATRs > 0 ) && ( sTrail_ATRs > 0 ) ) {
               double safTrailTrigger = ATR2Use * sTrigger_ATRs ;
               double safTrailDist = ATR2Use * sTrail_ATRs ;
               // -------------------- x
               if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_BUY ) {
                  double safBid = sBid() ;
                  if ( safBid >= posOpenPrice + safTrailTrigger ) {
                     double newSL = safBid - safTrailDist ;
                     if ( ( newSL - posSL ) > ( 1 * sPoint() ) ) {
                        goPositionModify ( posTicket , newSL , posTP , "Trail_BE_Then_XATR" ) ; }}}
               // -------------------- x
               else if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_SELL ) {
                  double safAsk = sAsk() ;
                  if ( safAsk <= posOpenPrice - safTrailTrigger ) {
                     double newSL = safAsk + safTrailDist ;
                     if ( posSL == 0 ) { posSL = posOpenPrice ; }
                     if ( ( posSL - newSL ) > ( 1 * sPoint() ) ) {
                        goPositionModify ( posTicket , newSL , posTP , "Trail_BE_Then_XATR" ) ; }}}}
      // -------------------- x
      } glb_EAS = sCurr_Symbol ; }

   //===========================================================================================================
   //=====                                         KILL FUNCTIONS                                          =====
   //===========================================================================================================

   bool goKillAccount_Check ( double sMaxDD , int sMaxDays , int safMarginCutOff=200 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( glb_IsThisLive == true ) { return false ; }
      // -------------------- x
      static double safHighestValue ;
      // -------------------- Variables
      double safEquity = sEqu() ;
      double safBalance = sBal() ;
      double safDDFraction = ( 100 - double ( sMaxDD ) ) / 100 ;
      double safKillTarget = glb_StartBalance * safDDFraction ;
      // -------------------- Margin Level < 200 Check
      if ( sMarginLevel() < safMarginCutOff ) {
         goPrint ( "Kill test due to Margin Level < " + string ( safMarginCutOff ) ) ;
         goKillAccount_Execute ( safKillTarget ) ; return true ; }
      // -------------------- Main Logic
      if ( sMaxDD > 0 ) {
         // -------------------- Calc
         if ( MathMax ( safBalance , safEquity ) > safHighestValue ) {
            safHighestValue = MathMax ( safBalance , safEquity ) ; }
         // -------------------- x
         if ( safEquity < ( safBalance * safDDFraction ) ) {
            goPrint ( "Kill test due to Equ < Bal" ) ;
            goKillAccount_Execute ( safKillTarget ) ; return true ; }
         // -------------------- x
         else if ( safEquity < ( safHighestValue * safDDFraction ) ) {
            goPrint ( "Kill test due to Equ < Highest Value" ) ;
            goKillAccount_Execute ( safKillTarget ) ; return true ; }
         // -------------------- x
         else if ( safEquity < safKillTarget ) {
            goPrint ( "Kill test due to Equ < Start Balance" ) ;
            goKillAccount_Execute ( safKillTarget ) ; return true ; }}
      // -------------------- x
      if ( sMaxDays > 0 ) {
         if ( glb_MinsSinceTrade > ( sMaxDays * 24 * 60 ) ) {
            goPrint ( "Kill test due to idle days" ) ;
            goKillAccount_Execute ( safKillTarget ) ; return true ; }}
      // -------------------- x
      return false ; }

   void goKillAccount_Execute ( double safKillTarget , string safRules="12" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- Stop if not in test mode
      if ( glb_IsThisLive == true ) {
         goPrint ( "Quit account kill because not in test mode" ) ;
         return ; }
      // -------------------- Calc lot size to use later here
      glb_LotSize = 0.25 ; double safLotSLV = goCalc_PercentSLV ( "" , "1245C" ) ;
      // -------------------- Execute open and close buy sell trades to deplete account
      if ( ( sFind ( safRules , "1" ) ) ) {
         int safMaxRuns = int ( sBal() ) ;
         for ( int i = 1 ; i<= safMaxRuns ; i++ ) {
            sBuy ( 0 , 0 , safLotSLV ) ;
            sSell ( 0 , 0 , safLotSLV ) ;
            goClose_AllPositionsByForce ( "Kill run number " + string(i) + ", Balance: " + string ( sBal() ) ) ;
            if ( sBal() < safKillTarget ) { break ; }}}
      // -------------------- First close all open positions
      goClose_AllPositionsByForce ( "goKillAccount_Execute" ) ;
      // -------------------- Withdraw from account until empty
      if ( ( sFind ( safRules , "2" ) ) ) {
         for ( int i = 1 ; i <= int ( sBal() / 10 )  ; i++ ) {
            TesterWithdrawal ( 100 ) ;
            Sleep ( 500 ) ;
            if ( sEqu() < safKillTarget ) { break ; }}}
      // -------------------- x
      glb_RobotDisabled = true ;
      ExpertRemove() ; }

   //===========================================================================================================
   //=====                                          SESSIONS                                               =====
   //===========================================================================================================

   string IsSession_Sydney ( int safStartLater=0 , int safEndEarlier=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      return goSession_Check ( 22 , 7 , safStartLater , safEndEarlier ) ; }

   string IsSession_Tokyo ( int safStartLater=0 , int safEndEarlier=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      return goSession_Check ( 0 , 9 , safStartLater , safEndEarlier ) ; }

   string IsSession_London ( int safStartLater=0 , int safEndEarlier=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      return goSession_Check ( 8 , 17 , safStartLater , safEndEarlier ) ; }

   string IsSession_NewYork ( int safStartLater=0 , int safEndEarlier=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      return goSession_Check ( 13 , 22 , safStartLater , safEndEarlier ) ; }

   string IsSession_Auto ( string safRules = "1" , int safStartLater=0 , int safEndEarlier=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      // RULE 1: Return if either of the sessions is a Y
      // RULE 2: Return if both of the sessions is a Y
      string result = "" ;
      if ( sFind ( glb_EAS , "USD" ) ) { result += IsSession_NewYork ( safStartLater , safEndEarlier ) ; }
      if ( sFind ( glb_EAS , "CAD" ) ) { result += IsSession_NewYork ( safStartLater , safEndEarlier ) ; }
      if ( sFind ( glb_EAS , "GBP" ) ) { result += IsSession_London ( safStartLater , safEndEarlier ) ; }
      if ( sFind ( glb_EAS , "EUR" ) ) { result += IsSession_London ( safStartLater , safEndEarlier ) ; }
      if ( sFind ( glb_EAS , "CHF" ) ) { result += IsSession_London ( safStartLater , safEndEarlier ) ; }
      if ( sFind ( glb_EAS , "JPY" ) ) { result += IsSession_Tokyo ( safStartLater , safEndEarlier ) ; }
      if ( sFind ( glb_EAS , "AUD" ) ) { result += IsSession_Sydney ( safStartLater , safEndEarlier ) ; }
      // -------------------- RULE 1
      if ( sFind ( safRules , "1" ) ) {
         if ( sFind ( result , "Y" ) ) { return "Y" ; } else { return "X" ; }}
      // -------------------- RULE 2
      if ( sFind ( safRules , "2" ) ) {
         if ( ( result == "Y" ) || ( result == "YY" ) ) { return "Y" ; } else { return "X" ; }}
      return result ; }

   string goSession_Check ( int safSessionStart , int safSessionEnd , int safStartLater , int safEndEarlier ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
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

   bool IsSession_Open () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // return ( true ) ; // <<<<<< TEMP DISABLE
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      MqlDateTime safDateTime ;
      datetime safTimeNow = TimeGMT () ;
      TimeToStruct ( safTimeNow , safDateTime ) ;
      // -------------------- x
      if ( safDateTime.day_of_week == 0 ) { if ( safDateTime.hour < 22 ) { return ( false ) ; }} // Sunday before market open
      if ( safDateTime.day_of_week == 6 ) { return ( false ) ; } // Saturday
      if ( safDateTime.day_of_week == 5 ) { if ( safDateTime.hour >= 22 ) { return ( false ) ; }} // Friday after market close
      // -------------------- x
      if ( safDateTime.hour >= 22 || safDateTime.hour < 7  ) { return ( true ) ; } // sydneySession
      if ( safDateTime.hour >= 0  && safDateTime.hour < 9  ) { return ( true ) ; } // tokyoSession
      if ( safDateTime.hour >= 8  && safDateTime.hour < 17 ) { return ( true ) ; } // londonSession
      if ( safDateTime.hour >= 13 && safDateTime.hour < 22 ) { return ( true ) ; } // newyorkSession
      // -------------------- x
      return ( false ) ; }

   //===========================================================================================================
   //=====                                   DATE AND TIME FUNCTIONS                                       =====
   //===========================================================================================================

   bool IsNewMinute () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      static string safLastMinute ;
      string safTime2Check = StringSubstr ( goGetDateTime() , 0 , 10 ) ;
      if ( safTime2Check == safLastMinute ) { return false ; }
      safLastMinute = safTime2Check ;
      return true ; }

   bool IsNewHour () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      static string safLastHour ;
      string safTime2Check = StringSubstr ( goGetDateTime() , 0 , 8 ) ;
      if ( safTime2Check == safLastHour ) { return false ; }
      safLastHour = safTime2Check ;
      return true ; }

   bool IsNewDay () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      static string safLastDay ;
      string safDay2Check = StringSubstr ( goGetDateTime() , 0 , 6 ) ;
      if ( safDay2Check == safLastDay ) { return false ; }
      safLastDay = safDay2Check ;
      return true ; }

   bool IsNewMonth () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      static string safLastMonth ;
      string safDate2Check = StringSubstr ( goGetDateTime() , 0 , 4 ) ;
      if ( safDate2Check == safLastMonth ) { return false ; }
      safLastMonth = safDate2Check ;
      return true ; }

   string goPrepDate ( string safInput ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      safInput = "00" + safInput ;
      int safLen = StringLen ( safInput ) ;
      return StringSubstr ( safInput , safLen - 2 , -1 ) ; }

   string goGetDateTime ( int safShiftBack=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      return goTranslate_DateTime ( ( TimeGMT () - safShiftBack ) ) ; }

   string goTranslate_DateTime ( datetime safInput ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      MqlDateTime safDateTime ;
      TimeToStruct ( TimeGMT () , safDateTime ) ;
      string DayOfWeekName_Array [] = { "SUN" , "MON" , "TUE" , "WED" , "THU" , "FRI" , "SAT" } ;
      return DayOfWeekName_Array [ safDateTime.day_of_week ] ; }

   int goFindHour () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      MqlDateTime safDateTime ;
      TimeToStruct ( TimeGMT () , safDateTime ) ;
      return safDateTime.hour ; }

   int go24HourAdjust ( int safInput ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( safInput > 23 ) { safInput = safInput - 24 ; }
      if ( safInput < 0 ) { safInput = safInput + 24 ; }
      return safInput ; }

   string IsDayOk2Trade ( string safOkDays , string safCutter="|" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      if ( sFind ( safCutter + safOkDays + safCutter , safCutter + goFindDayName() + safCutter ) ) { return "Y" ; } else { return "X" ; } }

   string IsHourOk2Trade ( string safOkHours , string safCutter="|" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      if ( sFind ( safCutter + safOkHours + safCutter , safCutter + (string)goFindHour() + safCutter ) ) { return "Y" ; } else { return "X" ; } }

   string goDelayMondayStart ( int safStartHour=8 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      string safDayName = goFindDayName() ;
      if ( safDayName == "SAT" ) { return "X" ; }
      if ( safDayName == "SUN" ) { return "X" ; }
      if ( safDayName == "MON" ) { if ( goFindHour() < safStartHour ) { return "X" ; }}
      return "Y" ; }

   string goEndFridayEarly ( int safEndHour=20 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      string safDayName = goFindDayName() ;
      if ( safDayName == "SAT" ) { return "X" ; }
      if ( safDayName == "SUN" ) { return "X" ; }
      if ( safDayName == "FRI" ) { if ( goFindHour() >= safEndHour ) { return "X" ; }}
      return "Y" ; }

   string goTranslate_TimeFrameName ( int safTimeFrame2Check ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      int safTFNumber [] = { 1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 16385, 16386, 16387, 16388, 16390, 16392, 16396, 16408, 32769, 49153 } ;
      string safTFName [] = { "M1", "M2", "M3", "M4", "M5", "M6", "M10", "M12", "M15", "M20", "M30", "H1", "H2", "H3", "H4", "H6", "H8", "H12", "D1", "W1", "MN1" } ;
      return safTFName [ ArrayBsearch ( safTFNumber , safTimeFrame2Check ) ] ; }

   double goCalc_MinutesBetweenDates ( datetime safStartDate , datetime safEndDate ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return ( MathAbs ( double ( ( safEndDate - safStartDate ) / 60 ) ) ) ; }

   double goCalc_HoursBetweenDates ( datetime safStartDate , datetime safEndDate ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return ( MathAbs ( double ( ( safEndDate - safStartDate ) / ( 60 * 60 ) ) ) ) ; }

   double goCalc_DaysBetweenDates ( datetime safStartDate , datetime safEndDate ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return ( MathAbs ( double ( ( safEndDate - safStartDate ) / ( 60 * 60 * 24 ) ) ) ) ; }

   bool IsDay_NoTradeDay ( string safNoTradeDays="|1223|1224|1225|1226|1227|1228|1229|1230|1231|0101|0102|0103|0104|0105|" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return true ; }
      // -------------------- x
      string safTodayDate = "|" + string ( StringSubstr ( goGetDateTime () , 2 , 4 ) ) + "|" ;
      if ( sFind ( "|" + safNoTradeDays + "|" , safTodayDate ) ) {
         glb_MinsSinceTrade = 15 * 24 * 60 * -1 ;
         return ( true ) ;
      } else {
         if ( glb_MinsSinceTrade < 0 ) { glb_MinsSinceTrade = 0 ; }
         return ( false ) ; }}

   bool IsDay_Ok2TradeDay ( string safOkTradeDays ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      string safTodayDate = "|" + string ( StringSubstr ( goGetDateTime () , 2 , 4 ) ) + "|" ;
      if ( sFind ( "|" + safOkTradeDays + "|" , safTodayDate ) ) { return ( true ) ; } else { return ( false ) ; }}

   string goFindLastDayNameString ( string sDayName ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
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

   bool IsHourX ( string safTriggerHours="00,02,04,06,08,10,12,14,16,18,20,22,24" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- Variables
      bool result = false ;
      static bool HourFoundBefore = false ;
      // -------------------- Main logic
      string safTime2Check = StringSubstr ( goGetDateTime() , 6 , 2 ) ;
      if ( sFind ( safTriggerHours , safTime2Check ) ) {
         if ( HourFoundBefore == false ) {
            result = true ;
            HourFoundBefore = true ; }
      } else {
         result = false ;
         HourFoundBefore = false ; }
      // -------------------- Return value here
      return ( result ) ; }

   bool goRepeatEvery_2Hours () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      return ( IsHourX ( "00,02,04,06,08,10,12,14,16,18,20,22,24" ) ) ; }

   bool goRepeatEvery_3Hours () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      return ( IsHourX ( "00,03,06,09,12,15,18,21,24" ) ) ; }

   bool goRepeatEvery_4Hours () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      return ( IsHourX ( "00,04,08,12,16,20,24" ) ) ; }

   bool goRepeatEvery_6Hours () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      return ( IsHourX ( "00,06,12,18,24" ) ) ; }

   bool goRepeatEvery_12Hours () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      return ( IsHourX ( "00,12,24" ) ) ; }

   int gofind_SecondOfDay () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      MqlDateTime safDateTime ;
      int result = 0 ;
      TimeToStruct ( TimeGMT() , safDateTime ) ;
      result += safDateTime.hour * 60 * 60 ;
      result += safDateTime.min * 60 ;
      result += safDateTime.sec ;
      return ( result ) ; }

   //===========================================================================================================
   //=====                                         LOCAL FILE                                              =====
   //===========================================================================================================

   bool goLocalFile_Write ( string sFN , string safText2Write , bool newFile=false ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- Filename check
      if ( StringLen ( sFN ) < 1 ) { return false ; }
      // -------------------- Newfile here
      if ( newFile ) { if ( FileIsExist ( sFN , FILE_COMMON ) == true ) { FileDelete ( sFN , FILE_COMMON ) ; }}
      // -------------------- Open file to write
      int f = FileOpen ( sFN , FILE_READ|FILE_WRITE|FILE_TXT|FILE_COMMON ) ;
      if ( f == INVALID_HANDLE ) { return false ; }
      // -------------------- goto end and write data
      FileSeek ( f , 0 , SEEK_END ) ;
      if ( StringLen ( safText2Write ) > 0 ) { FileWrite ( f , safText2Write ) ; }
      // -------------------- close
      FileClose ( f ) ;
      // -------------------- x
      return true ; }

   bool goLocalFile_Read ( string sFN , string &FileContent[] ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- Filename check
      if ( StringLen ( sFN ) < 1 ) { return false ; }
      // -------------------- Clear return array
      ArrayResize ( FileContent , 0 ) ;
      // -------------------- Open file to read
      int f = FileOpen ( sFN , FILE_READ|FILE_TXT|FILE_COMMON ) ;
      if ( f == INVALID_HANDLE ) { return false ; }
      // -------------------- Read into array
      FileReadArray ( f , FileContent , 0 , WHOLE_ARRAY ) ;
      // -------------------- close
      FileClose ( f ) ;
      // -------------------- x
      return true ; }

   //===========================================================================================================
   //=====                                         HTML FUNCTIONS                                          =====
   //===========================================================================================================

   string goRead_Website ( string safOriginalURL , string safPreviewURL = "" , int safTimeOut = 6000 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return "" ; }
      // -------------------- x
      char safResult [] , safPostData [] ;
      if ( safPreviewURL == "" ) { safPreviewURL = safOriginalURL ; }
      string safType = "Content-Type: application/x-www-form-urlencoded" ;
      string safAgent = "user-agent:Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36 OPR/65.0.3467.62" ;
      string safHeaders = safType + "\r\n" + safAgent ;
      int res = WebRequest ( "GET" , safPreviewURL , NULL , safOriginalURL , safTimeOut , safPostData , 0 , safResult , safHeaders ) ;
      string safHTML = "" ; for ( int i = 0 ; i <= ArraySize ( safResult ) - 1 ; i++ ) { safHTML += CharToString ( safResult [ i ] ) ; }
      if ( safHTML == "" ) { goPrint ( "Unable to contact server" ) ; }
      return ( safHTML ) ; }

   //===========================================================================================================
   //=====                                      SYMBOL FUNCTIONS                                           =====
   //===========================================================================================================

   string goSymbols_GetAllInDataWindow () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      string result = "|" ;
      for ( int i = 0 ; i < SymbolsTotal ( true ) ; i++ ) {
         result += SymbolName ( i , true ) + "|" ; }
      return ( result ) ; }

   void goSymbol_AddToDataWindow ( string safSymbol2Add ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- return if symbol already in data windows
      if ( SymbolInfoInteger ( safSymbol2Add , SYMBOL_VISIBLE ) ) { return ; }
      SymbolSelect ( safSymbol2Add , true ) ; }

   void goSymbol_RemoveFromDataWindow ( string safSymbol2Remove ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- return if symbol already in data windows
      if ( !SymbolInfoInteger ( safSymbol2Remove , SYMBOL_VISIBLE ) ) { return ; }
      SymbolSelect ( safSymbol2Remove , false ) ; }

   void goSymbols_OpenChartWithTimeFrame ( const string safSymbol , const ENUM_TIMEFRAMES safTF ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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

   void goSymbols_CloseAllChartsExceptCurrent () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      long safCurrentChartID = ChartID () ;
      long safSelectedChartID = 0 ;
      // -------------------- x
      while ( ( safSelectedChartID = ChartNext ( safSelectedChartID ) ) > 0 ) {
         if ( safSelectedChartID != safCurrentChartID ) { ChartClose ( safSelectedChartID ) ; } } }

   string goSymbols_GetNext () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- Get symbols in data windows
      string Symbols2LookIn [] ;
      string sDataWindowSymbols = goSymbols_GetAllInDataWindow() ;
      StringSplit ( sDataWindowSymbols , 124 , Symbols2LookIn ) ;
      for ( int x = 1 ; x < ArraySize ( Symbols2LookIn ) - 1 ; x++ ) {
         if ( Symbols2LookIn [ x ] == glb_EAS ) {
            if ( x == ArraySize ( Symbols2LookIn ) - 2 ) {
               return ( Symbols2LookIn [ 1 ] ) ;
            } else {
               return ( Symbols2LookIn [ x + 1 ] ) ; }}} return ( "" ) ; }

   //===========================================================================================================
   //=====                                            SECURITY                                             =====
   //===========================================================================================================

   bool goSecurity_CheckAccountType ( ENUM_ACCOUNT_TRADE_MODE safAllowedMode ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      //// if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      // ACCOUNT_TRADE_MODE_DEMO // ACCOUNT_TRADE_MODE_CONTEST // ACCOUNT_TRADE_MODE_REAL
      if ( AccountInfoInteger ( ACCOUNT_TRADE_MODE ) == safAllowedMode ) { return true ; }
      goPrint ( "Robot not allowed on this account type!" ) ;
      glb_RobotDisabled = true ;
      return false ; }

   bool goSecurity_CheckAccountSymbols ( string safAllowedSymbol ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      //// if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( glb_EAS == safAllowedSymbol ) { return true ; }
      goPrint ( "Symbol " + glb_EAS + " not allowed for this robot!" ) ;
      glb_RobotDisabled = true ;
      return false ; }

   bool goSecurity_CheckExpiryDate ( datetime safBuildDate , int safValidityInDays=7 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      //// if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !safBuildDate ) { safBuildDate = __DATETIME__ ; }
      datetime safExpiryDate = safBuildDate + ( safValidityInDays * 86400 ) ;
      goPrint ( "Robot license valid until " + string ( safExpiryDate ) ) ;
      if ( TimeCurrent() < safExpiryDate ) { return true ; }
      goPrint ( "Robot already expired!" ) ;
      glb_RobotDisabled = true ;
      return false ; }

   bool goSecurity_CheckLicense ( string safLicenseKey ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      //// if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      string safGeneratedKey = goSecurity_Encoder ( IntegerToString ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ) ;
      if ( safGeneratedKey == safLicenseKey ) { return true ; }
      goPrint ( "License check failed!" ) ;
      glb_RobotDisabled = true ;
      return false ; }

   string goSecurity_Encoder (
      string safInput ,
      string safKey = "tospcpujyjtuifcftudpnqbozjouifxpsmezbtfntfn" ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         //// if ( glb_RobotDisabled ) { return ; }
         // -------------------- x
         uchar safKeyChar [] ; StringToCharArray ( safKey , safKeyChar ) ;
         uchar safInputChar [] ; StringToCharArray ( ( safInput + safKey ) , safInputChar ) ;
         uchar safResultChar [] ;
         CryptEncode ( CRYPT_HASH_SHA256 , safInputChar , safKeyChar , safResultChar ) ;
         CryptEncode ( CRYPT_BASE64 , safResultChar , safResultChar , safResultChar ) ;
         return ( CharArrayToString ( safResultChar ) ) ; }

   bool goSecurity_VersionCheck ( string sBotType ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      //// if ( glb_RobotDisabled ) { return ; }
      // -------------------- Variables
      string safVersion = goTranslate_DateTime ( __DATETIME__ ) ;
      // -------------------- Read file content
      string safURL = "https://sherifawzi.github.io/Tools/Dist" ;
      string safArray [] ; goServer_ReadSimpleTextFile ( safURL , safArray ) ;
      if ( ArraySize ( safArray ) < 1 ) {
         goPrint ( "Unable to contact server" ) ;
         glb_RobotDisabled = true ;
         return false ; }
      // -------------------- x
      string safLineSplit [] ;
      // -------------------- Check version here
      for ( int i=0 ; i < ArraySize ( safArray ) ; i++ ) {
         StringSplit ( safArray [ i ] , 124 , safLineSplit ) ;
         if ( ArraySize ( safLineSplit ) < 3 ) { continue ; }
         string safKey = safLineSplit [ 1 ] ;
         string safValue = safLineSplit [ 2 ] ;
         if ( UT ( safKey ) == UT ( sBotType ) ) {
            if ( long ( safVersion ) < long ( safValue ) ) {
               goPrint ( "A newer verion exists" ) ;
               glb_RobotDisabled = true ;
               return false ;
            } else {
               goPrint ( "Version check passed" ) ;
               return true ; }}}
         goPrint ( "Unable to verify version" ) ;
         glb_RobotDisabled = true ;
         return false ; }

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
   // "-1002094215041" // SNR_COM

   // "-1002413257483" // ZEN_OPS
   // "-1002434703343" // ZEN_ORD

   // -------------------- Bots
   // "5329994003:AAEKkBHY6lDux_C66BtCO0TE9Wx3ozFcnUg" // SNR_Test_001_bot // SNR_Signal_Bot
   // "5116032297:AAEgIs64v7rWKIpDI843zMT4GpdNAqtM1e0" // SNR_OY_bot       // SNR_OPS_Bot
   // "5304085024:AAHHXmjnZarEV2ibfa3tJ41UUQOifcrRl0c" // SNR_Ichi_bot     // SNR_ANA_Bot
   // "5255947594:AAF4ad7cEPKPYeyyl9y9HLAc5GbdBu-UT0g" // SNR_BB_bot       // SNR_ID_Bot
   // "6385486447:AAEZCGszJz5U-71Dm8lrePiUsZR6sPx2Y18" // SNR_OTP_bot      // SNR_OTP_Bot

   // "7744601334:AAGP_XsfLX8x0pkcBmOv6uwTisuJweZLO_g" // ZEN_OPS_bot

   void goBroadcast_COM ( string safMsg ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      string sCurr_BroadID = glb_BroadID ;
         glb_BroadID = string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ;
         prvTele_Send ( safMsg , "-1002094215041" , "6385486447:AAEZCGszJz5U-71Dm8lrePiUsZR6sPx2Y18" ) ;
      glb_BroadID = sCurr_BroadID ; }

   void goBroadcast_SIG ( string safMsg ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      prvTele_Send ( safMsg , "-1001760124674" , "5329994003:AAEKkBHY6lDux_C66BtCO0TE9Wx3ozFcnUg" ) ; }

   void goBroadcast_TST ( string safMsg ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      prvTele_Send ( safMsg , "-1002108490781" , "5116032297:AAEgIs64v7rWKIpDI843zMT4GpdNAqtM1e0" ) ; }

   void goBroadcast_OPS ( string safMsg ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      prvTele_Send ( safMsg , "-1001633555419" , "5116032297:AAEgIs64v7rWKIpDI843zMT4GpdNAqtM1e0" ) ; }

   void goBroadcast_OTP ( string safMsg ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      prvTele_Send ( safMsg , "-1002087660238" , "6385486447:AAEZCGszJz5U-71Dm8lrePiUsZR6sPx2Y18" ) ; }

   void goBroadcast_ANA ( string safMsg ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      prvTele_Send ( safMsg , "-1001642437269" , "5304085024:AAHHXmjnZarEV2ibfa3tJ41UUQOifcrRl0c" ) ; }

   void goBroadcast_ZEN_OPS ( string safMsg ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      prvTele_Send ( safMsg , "-1002413257483" , "7744601334:AAGP_XsfLX8x0pkcBmOv6uwTisuJweZLO_g" ) ; }

   void goBroadcast_ZEN_ORD ( string safMsg ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      prvTele_Send ( safMsg , "-1002434703343" , "7744601334:AAGP_XsfLX8x0pkcBmOv6uwTisuJweZLO_g" ) ; }

   void goBroadcast_ID ( string safTOP ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      string sCurr_BroadcastID = glb_BroadID ;
         glb_BroadID = "MyID" ;
         string sMessage2Send = goTele_PrepMsg ( IntegerToString ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ,
            AccountInfoString ( ACCOUNT_COMPANY ) , AccountInfoString ( ACCOUNT_NAME ) , AccountInfoString ( ACCOUNT_SERVER ) ,
            // string ( sBal() ) , string ( sEqu() ) , string ( glb_AllowedTrade ) , string ( PositionsTotal() ) ,
            string ( sBal() ) , string ( sEqu() ) , "1" , string ( PositionsTotal() ) ,
            string ( OrdersTotal() ) , string ( safTOP ) ) ;
         prvTele_Send ( sMessage2Send , "-1001486227005" , "5255947594:AAF4ad7cEPKPYeyyl9y9HLAc5GbdBu-UT0g" ) ;
      glb_BroadID  = sCurr_BroadcastID ; }

   void goBroadcast_IAMALIVE ( string safType , string safBotVer , string safOptional="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      string sCurr_BroadcastID = glb_BroadID ;
         if ( UT ( glb_BroadID ) == "" ) { glb_BroadID = IntegerToString ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ; }
         goBroadcast_OPS ( goTele_PrepMsg ( safType , "STARTED" , SNR_LIBVER , safBotVer , goTranslate_Broker() , safOptional ) ) ;
      glb_BroadID = sCurr_BroadcastID ; }

   void goSay ( string safMsg , string safBroadID="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      string sCurr_BroadID = glb_BroadID ;
         glb_BroadID = string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ;
         if ( safBroadID != "" ) { glb_BroadID = safBroadID ; }
         prvTele_Send ( safMsg , "-1002087660238" , "6385486447:AAEZCGszJz5U-71Dm8lrePiUsZR6sPx2Y18" ) ;
      glb_BroadID = sCurr_BroadID ; }

   //===========================================================================================================
   //=====                                            TELEGRAM                                             =====
   //===========================================================================================================

   string goTele_PrepMsg (
      string sType , string sVal1="" , string sVal2="" , string sVal3="" , string sVal4="" , string sVal5="" ,
      string sVal6="" ,string sVal7="" , string sVal8="" , string sVal9="" , string sVal10="" , string sVal11="" ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
         // -------------------- x
         if ( !glb_IsThisLive ) { return ( "" ) ; }
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      if ( safMsg == "" ) { return ; }
      if ( glb_BroadID == "" ) { return ; }
      if ( safTeleChatID == "" ) { return ; }
      if ( safTeleToken == "" ) { return ; }
      // -------------------- Start constructing message here
      string safTeleURL = "https://api.telegram.org" ;
      string safRequestURL = StringFormat ( "%s/bot%s/sendmessage?chat_id=%s&parse_mode=HTML&text=%s" , safTeleURL , safTeleToken , safTeleChatID , safMsg ) ;
      string safHeaders , safResultHeaders ;
      char safPostData [] , safResultData [] ;
      WebRequest ( "POST" , safRequestURL , safHeaders , 6000 , safPostData , safResultData , safResultHeaders ) ;
      // -------------------- Do server send here
      string sCurr_ServerPath = glb_ServerPath ;
      string sCurr_ServerFileName = glb_ServerFileName ;
         glb_ServerPath = "/SNRobotiX/" ;
         if ( safTeleChatID == "-1001760124674" ) { glb_ServerFileName = "signals.txt" ; }
         else if ( safTeleChatID == "-1001633555419" ) { glb_ServerFileName = "operations.txt" ; }
         else if ( safTeleChatID == "-1001486227005" ) { glb_ServerFileName = "incoming.txt" ; }
         else if ( safTeleChatID == "-1001642437269" ) { glb_ServerFileName = "analysis.txt" ; }
         else if ( safTeleChatID == "-1002087660238" ) { glb_ServerFileName = "onetimepass.txt" ; }
         else if ( safTeleChatID == "-1002108490781" ) { glb_ServerFileName = "cpuutility.txt" ; }
         else if ( safTeleChatID == "-1002094215041" ) { glb_ServerFileName = "commercial.txt" ; }
         else if ( safTeleChatID == "-1002413257483" ) { glb_ServerFileName = "zenops.txt" ; }
         else if ( safTeleChatID == "-1002434703343" ) { glb_ServerFileName = "zenord.txt" ; }
         else { glb_ServerFileName = "catchall.txt" ; }
         goServer_Write_String ( safMsg , "a" , "yes" ) ;
      glb_ServerPath = sCurr_ServerPath ;
      glb_ServerFileName = sCurr_ServerFileName ;
      // -------------------- Write to journal here
      goPrint ( "Sent Msg: " + safMsg + " with BroadcaseID: " + glb_BroadID ) ; }

   void goTele_GetMsgs (
      string safRobotName ,
      string &AllMsgsArray[] ,
      string safTelePreviewURL = "https://t.me/s/fsquareaps" ,
      string safTeleOriginalURL = "https://t.me/fsquareaps" ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         ArrayResize ( AllMsgsArray , 0 ) ;
         // -------------------- x
         //// if ( glb_RobotDisabled ) { return ; }
         // -------------------- x
         if ( !glb_IsThisLive ) { return ; }
         // -------------------- x
         if ( safRobotName == "" ) { return ; }
         // -------------------- Read file content
         string result [] ; goServer_ReadSimpleTextFile ( safTelePreviewURL , result ) ;
         if ( ArraySize ( result ) < 1 ) { return ; }
         // -------------------- x
         for ( int i = 1 ; i <= ArraySize ( result ) - 1 ; i++ ) {
            // -------------------- Handle emergency ID
            if ( sFind ( UT ( result [ i ] ) , "IDIDID" ) ) {
               goArray_Add ( ( "||ID||||" + glb_EAS + "||||||||" ) , AllMsgsArray ) ; continue ; }
            // -------------------- Handle emergency STOP
            if ( sFind ( UT ( result [ i ] ) , "STOPSTOPSTOP" ) ) {
               goArray_Add ( ( "||STOP||||" + glb_EAS + "||||||||" ) , AllMsgsArray ) ; continue ; }
            // -------------------- Handle emergency Close all positive positions
            if ( sFind ( UT ( result [ i ] ) , "CAPPCAPPCAPP" ) ) {
               goArray_Add ( ( "||CAPP||||" + glb_EAS + "||||||||" ) , AllMsgsArray ) ; continue ; }
            // -------------------- Handle emergency set TP at breakeven
            if ( sFind ( UT ( result [ i ] ) , "TPBETPBETPBE" ) ) {
               goArray_Add ( ( "||TPBE||||" + glb_EAS + "||||||||" ) , AllMsgsArray ) ; continue ; }
            // -------------------- Handle emergency set TP at breakeven
            if ( sFind ( UT ( result [ i ] ) , "TPXATRTPXATRTPXATR" ) ) {
               goArray_Add ( ( "||TPXATR|1|||" + glb_EAS + "||||||||" ) , AllMsgsArray ) ; continue ; }
            // -------------------- x
            result [ i ] = goTele_ExtractMSG ( result [ i ] ) ;
            if ( StringLen ( result [ i ] ) < 1 ) { continue ; }
            // -------------------- x
            if ( !goTele_CheckMsgAgeAndName ( safRobotName , result [ i ] ) ) { continue ; }
            if ( !goTele_CheckMsgHash ( result [ i ] ) ) { continue ; }
            if ( !goTele_CheckMsgRepeat ( result [ i ] ) ) { continue ; }
            // -------------------- x
            goArray_Add ( result [ i ] , AllMsgsArray ) ; }}

   bool goTele_CheckMsgHash ( string safMsg ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      //// if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( safMsg == "" ) { return false ; }
      string result [] ;
      StringSplit ( safMsg , 124 , result ) ;
      if ( ArraySize ( result ) < 2 ) { return false ; }
      string safHash2Check = result [ ArraySize ( result ) - 1 ] ;
      StringReplace ( safMsg , safHash2Check , "" ) ;
      string safHashNew = goSecurity_Encoder ( glb_MsgStart + safMsg ) ;
      if ( sFind ( safHashNew , safHash2Check ) ) { return true ; } else { return false ; }}

   bool goTele_CheckMsgAgeAndName (
      string safRobotName ,
      string safMsg ,
      int safLookupPeriod = 90 ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         //// if ( glb_RobotDisabled ) { return ; }
         // -------------------- x
         if ( safRobotName == "" ) { return false ; }
         if ( safMsg == "" ) { return false ; }
         string result [] ;
         StringSplit ( safMsg , 124 , result ) ;
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
         if ( sFind ( ( ";" + UT ( safRobotName ) + ";" ) , ( ";" + UT ( safMsgBroadcastID ) + ";" ) ) ) { return true ; }
         return false ; }

   bool goTele_CheckMsgRepeat ( string safMsg , int safMaxLength = 1500 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      //// if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         //// if ( glb_RobotDisabled ) { return ; }
         // -------------------- x
         string result = "" ;
         string safLetter = "" ;
         if ( safLength == -1 ) { safLength = sRandomNumber ( 5 , 9 ) ; }
         for ( int i = 0 ; i < StringLen ( safInput ) ; i++ ) {
            string safAccepted2Use = safAccepted ;
            safLetter = StringSubstr ( safInput , i , 1 ) ;
            if ( sFind ( safAccepted2Use , safLetter ) ) { result += safLetter ; } else { result = "" ; }
            if ( StringLen ( result ) >= safLength ) { break ; }}
         return result ; }

   string goTele_ExtractMSG ( string safInput , string safStartSnip="" , string safEndSnip="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      //// if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( safStartSnip == "" ) { safStartSnip = glb_MsgStart ; }
      if ( safEndSnip == "" ) { safEndSnip = glb_MsgEnd ; }
      // -------------------- x
      int safStart = StringFind ( safInput , safStartSnip , 0 ) ;
      if ( safStart < 0 ) { return ( "" ) ; }
      safStart += StringLen ( safStartSnip ) ;
      // -------------------- x
      int safEnd = StringFind ( safInput , safEndSnip , 0 ) ;
      if ( safEnd  < 0 ) { return ( "" ) ; }
      // -------------------- x
      return ( StringSubstr ( safInput , safStart , ( safEnd - safStart ) ) ) ; }

   //===========================================================================================================
   //=====                                             SERVER                                              =====
   //===========================================================================================================

   string goURLEncode ( string safInput ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      //// if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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

   int goServer_Write_String ( string safTextToAdd , string safWriteAppend = "a" , string safAddTimeStamp = "no" , int safTimeOut = 6000 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return 0 ; }
      // -------------------- variables
      char safData[] , safResult[] ;
      string safResultHeaders , safURL , safHeaders ;
      // -------------------- Declares
      safURL =  glb_ServerIP + glb_ServerPHP + "?var1=" + glb_ServerPath + "&var2=" ;
      safURL += glb_ServerFileName + "&var3=" + goTrim ( safTextToAdd ) + "&var4=" + safWriteAppend + "&var5=" + safAddTimeStamp ;
      safHeaders = "Content-Type: application/x-www-form-urlencoded" ;
      // -------------------- Main function here
      return ( WebRequest ( "POST" , safURL , safHeaders , safTimeOut , safData , safResult , safResultHeaders ) ) ; }

   bool goServer_ReadOperationsFile ( string safURL , string &AllMessages[] , string sStartDateTime="" , string sEndDateTime="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return false ; }
      // -------------------- Clear output array here
      ArrayResize ( AllMessages , 0 ) ;
      // -------------------- Read file content
      string sFC [] ; goServer_ReadSimpleTextFile ( safURL , sFC ) ;
      if ( ArraySize ( sFC ) < 1 ) { return false ; }
      // -------------------- x
      for ( int x=0 ; x < ArraySize ( sFC ) ; x++ ) {
         // -------------------- x
         sFC [ x ] = goTele_ExtractMSG ( sFC [ x ] ) ;
         if ( StringLen ( sFC [ x ] ) < 1 ) { continue ; }
         // -------------------- x
         if ( ( StringLen ( sStartDateTime ) > 0 ) || ( StringLen ( sStartDateTime ) > 0 ) ) {
            // -------------------- x
            string LineBits [] ; StringSplit ( sFC [ x ] , 124 , LineBits ) ;
            if ( ArraySize ( LineBits ) < 2 ) { continue ; }
            // -------------------- this removes anything earlier than select date
            if ( StringLen ( sStartDateTime ) > 0 ) { if ( LineBits [ 1 ] < sStartDateTime ) { continue ; }}
            if ( StringLen ( sEndDateTime ) > 0 ) { if ( LineBits [ 1 ] >= sEndDateTime ) { continue ; }}}
         // -------------------- x
         goArray_Add ( "|" + sFC [ x ] + "|" , AllMessages ) ; }
         // -------------------- x
         return true ; }

   bool goServer_ReadSimpleTextFile ( string safURL , string &AllMessages[] ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      ArrayResize ( AllMessages , 0 ) ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return false ; }
      // -------------------- Read file content
      string safHTML = goRead_Website ( safURL , safURL ) ;
      if ( StringLen ( safHTML ) < 1 ) { return false ; }
      // -------------------- Split message by vbcrlf and clear html
      StringSplit ( safHTML , '\n' , AllMessages ) ;
      safHTML = "" ;
      return true ; }

   void goServer_GetFileList ( string safURL , string &safFNArray[] ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      ArrayResize ( safFNArray , 0 ) ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- Read file content
      string result [] ; goServer_ReadSimpleTextFile ( safURL , result ) ;
      if ( ArraySize ( result ) < 1 ) { return ; }
      // -------------------- Go thru HTML lines and find files
      for ( int x = 0 ; x < ArraySize ( result ) ; x++ ) {
         // -------------------- Find file link start
         int sLoc = StringFind ( result [ x ] , "a href=" , 0 ) ;
         if ( sLoc > 0 ) { result [ x ] = StringSubstr ( result [ x ] , sLoc + 8 , -1 ) ; } else { result [ x ] = "" ; }
         // -------------------- Find end of file name link href
         sLoc = StringFind ( result [ x ] , ">" , 0 ) ;
         if ( sLoc > 0 ) { result [ x ] = StringSubstr ( result [ x ] , 0 , sLoc - 1 ) ; } else { result [ x ] = "" ; }
         // -------------------- Use this to clean results from errors
         if ( sFind ( result [ x ] , "/" ) ) { result [ x ] = "" ; }
         if ( sFind ( result [ x ] , "?" ) ) { result [ x ] = "" ; }
         if ( sFind ( result [ x ] , ";" ) ) { result [ x ] = "" ; }
         // -------------------- Populate return array
         if ( StringLen ( result [ x ] ) > 0 ) { goArray_Add ( result [ x ] , safFNArray ) ; }}}

   //===========================================================================================================
   //=====                                         CURRENCY LIMITS                                         =====
   //===========================================================================================================

   bool goLimit_CurrencyPairExposure ( string safPair2Check , int safAllowedPairs=4 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      if ( PositionsTotal() < 1 ) { return ( true ) ; }
      // -------------------- Variables
      string safOpenCurr = "" ;
      int safOpenCount = 0 ;
      // -------------------- Get open positions
      string PositionLines[] ; goPositions_Retreive ( PositionLines ) ;
      if ( ArraySize ( PositionLines ) < 1 ) { return false ; }
      // -------------------- Go thru positions one by one
      for ( int i=0 ; i < ArraySize ( PositionLines ) ; i++ ) {
         // -------------------- x
         string safSplit[] ; StringSplit ( PositionLines [ i ] , 124 , safSplit ) ;
         if ( ArraySize ( safSplit ) < 19 ) { continue ; }
         // -------------------- x
         string posSymbol = "|" + UT ( goCleanString ( safSplit [ 2 ] ) ) + "|" ;
         if ( !sFind ( safOpenCurr , posSymbol ) ) { safOpenCurr += posSymbol ; safOpenCount += 1 ; }}
      // -------------------- Check here
      if ( safOpenCount >= safAllowedPairs ) { return false ; }
      if ( sFind ( safOpenCurr , UT ( goCleanString ( safPair2Check ) ) ) ) { return false ; }
      // -------------------- return pass
      return true ; }

   bool goLimit_SingleCurrencyExposure ( string safPair2Check , int safAllowedNumber=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      if ( PositionsTotal() < 1 ) { return ( true ) ; }
      // -------------------- Variables
      int safCurr01Count = 0 , safCurr02Count = 0 ;
      // -------------------- Get open positions
      string PositionLines[] ; goPositions_Retreive ( PositionLines ) ;
      if ( ArraySize ( PositionLines ) < 1 ) { return false ; }
      // -------------------- Split pair 2 check into 2
      safPair2Check = goCleanString ( UT ( safPair2Check ) ) ;
      string safCurr01 = StringSubstr ( safPair2Check , 0 , 3 ) ;
      string safCurr02 = StringSubstr ( safPair2Check , 3 , 3 ) ;
      // -------------------- Go thru positions one by one
      for ( int i=0 ; i < ArraySize ( PositionLines ) ; i++ ) {
         string safSplit[] ; StringSplit ( PositionLines [ i ] , 124 , safSplit ) ;
         if ( ArraySize ( safSplit ) < 19 ) { continue ; }
         // -------------------- x
         string posSymbol = "|" + UT ( goCleanString ( safSplit [ 2 ] ) ) + "|" ;
         // -------------------- Check count of search currency
         if ( sFind ( posSymbol , safCurr01 ) ) { safCurr01Count += 1 ; }
         if ( sFind ( posSymbol , safCurr02 ) ) { safCurr02Count += 1 ; }}
      // -------------------- Check if count is smaller than allowed
      if ( safCurr01Count < safAllowedNumber ) { if ( safCurr02Count < safAllowedNumber ) { return true ; }}
      // -------------------- return fail
      return false ; }

   //===========================================================================================================
   //=====                                           AUTO DEPLOY                                           =====
   //===========================================================================================================

/*

   string goAutoDeploy_ConstructFileName ( string safFileNameSuffix="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ( "" ) ; }
      // -------------------- x
      string sFN = goCleanString ( AccountInfoString ( ACCOUNT_SERVER ) ) + "-" ;
      sFN += goCleanString ( string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ) + "-" ;
      sFN += goCleanString ( glb_EAS ) ;
      if ( StringLen ( safFileNameSuffix ) > 0 ) { sFN += "-" + goCleanString ( safFileNameSuffix ) ; }
      sFN += ".txt" ; return ( sFN ) ; }

   void goAutoDeploy_Write ( string safText2Write , string safFileNameSuffix="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- Set filename
      static string sFN ; if ( StringLen ( sFN ) < 1 ) { sFN = goAutoDeploy_ConstructFileName ( safFileNameSuffix ) ; }
      // -------------------- Set timestamp and string to write
      string safTimeStamp = StringSubstr ( goGetDateTime() , 0 , 12 ) ;
      string result = safTimeStamp + ": " + safText2Write ;
      // -------------------- Write here
      goLocalFile_Write ( sFN , result ) ; }

   void goAutoDeploy_LogBuyTrade ( double safATR , string safComment , string BotMagicSuffix , double safATRFactor=1.5 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      string safTarget = string ( ND ( sAsk() + ( safATR * safATRFactor ) ) ) ;
      goAutoDeploy_Write ( "|AUTODEPLOY|B|" + safTarget + "|" + string ( glb_PI[0].time ) + "&" + safComment , BotMagicSuffix ) ; }

   void goAutoDeploy_LogSellTrade ( double safATR , string safComment , string BotMagicSuffix , double safATRFactor=1.5 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      string safTarget = string ( ND ( sBid() - ( safATR * safATRFactor ) ) ) ;
      goAutoDeploy_Write ( "|AUTODEPLOY|S|" + safTarget + "|" + string ( glb_PI[0].time ) + "&" + safComment , BotMagicSuffix ) ; }

   void goAutoDeploy_Check ( string BotMagicSuffix , string BotConfigString , int MinTradeCount=3 , int MaxHoursOpen=3 , int MaxFailCount=3 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- Return if beacon already not a test
      if ( !sFind ( UT ( glb_Magic ) , "TEST" ) ) { return ; }
      // -------------------- Variables
      string FileContent[] ;
      int safSuccessCounter = 0 ;
      int safFailedCounter = 0 ;
      int safOpenCounter = 0 ;
      // -------------------- Set filename
      static string sFN ; if ( StringLen ( sFN ) < 1 ) { sFN = goAutoDeploy_ConstructFileName ( BotMagicSuffix ) ; }
      // -------------------- Read all log file data
      if ( !goLocalFile_Read ( sFN , FileContent ) ) { return ; }
      // -------------------- Go thru file content line by line
      for ( int i=0 ; i < ArraySize ( FileContent ) ; i ++ ) {
         // -------------------- If already deployed then silent quit
         if ( sFind ( FileContent [i] , "|DEPLOYED|" ) ) {
            StringReplace ( glb_Magic , "TEST" , "" ) ;
            glb_BroadID = glb_Magic ;
            goPrint ( ( glb_EAS + BotMagicSuffix ) + " - REDEPLOYED" ) ;
            return ; }
         // -------------------- If already rejected then quit
         if ( sFind ( FileContent [i] , "|FAILEDAUTODEPLOY|" ) ) {
            goPrint ( ( glb_EAS + BotMagicSuffix ) + " - DEPLOY FAILED" ) ;
            ExpertRemove () ; }
         // -------------------- If found an autodeploy then check if already closed
         if ( sFind ( FileContent [i] , "|AUTODEPLOY|" ) ) {
            // -------------------- Variables
            bool AlreadyClosed = false ;
            string LineSplits [] ;
            // -------------------- Split line to extract magic for comparison
            StringSplit ( FileContent [i] , StringGetCharacter ( "&" , 0 ) , LineSplits ) ;
            string TradeMagic = LineSplits[1] ;
            // -------------------- Go thru rest of file to look for close
            for ( int j=i ; j < ArraySize ( FileContent ) ; j ++ ) {
               // -------------------- Check if magix exists with suffic success
               if ( sFind ( FileContent [j] , TradeMagic + "-SUCCESS" ) ) {
                  // -------------------- Change variables and quit loop if found
                  AlreadyClosed = true ;
                  safSuccessCounter += 1 ;
                  break ; } // close SUCCESS check
               if ( sFind ( FileContent [j] , TradeMagic + "-FAILED" ) ) {
                  // -------------------- Change variables and quit loop if found
                  AlreadyClosed = true ;
                  safFailedCounter += 1 ;
                  break ; }}
            // -------------------- If trade is still open, then get last candles and check for close
            if ( AlreadyClosed == false ) {
               // -------------------- Get last 65 candle prices
               MqlRates sPI [] ; ArraySetAsSeries ( sPI , true ) ;
               CopyRates ( glb_EAS , glb_EAP , 0 , 65 , sPI ) ;
               // -------------------- Get trade direction
               string TradeInfo [] ;
               StringSplit ( LineSplits[0] , 124 , TradeInfo ) ;
               string TradeType = TradeInfo [2] ;
               double TradeCloseTrigger = double ( TradeInfo [3] ) ;
               string TradeOpentime = TradeInfo [4] ;
               // -------------------- go thru candles and see if price closed
               bool TradeClosed = false ;
               for ( int j=0 ; j < ArraySize ( sPI ) ; j ++ ) {
                  // -------------------- break if u r past the trade candle
                  if ( sPI[j].time <= datetime ( TradeOpentime ) ) { break ; }
                  if ( TradeType == "B" ) {
                     if ( sPI[j].high >= TradeCloseTrigger ) {
                        TradeClosed = true ;
                        break ; }
                  } else {
                     if ( sPI[j].low <= TradeCloseTrigger ) {
                        TradeClosed = true ;
                        break ; }}}
               // -------------------- Denote open trade if still open to stop autodeploy
               if ( TradeClosed == false ) { safOpenCounter += 1 ; }
               // -------------------- Write to file if trade was closed in last hour
               if ( TradeClosed == true ) {
                  double safElapsedTime = goCalc_HoursBetweenDates ( datetime ( TradeOpentime ) , sPI[0].time ) ;
                  if ( safElapsedTime <= MaxHoursOpen ) {
                     goAutoDeploy_Write ( ( TradeMagic + "-SUCCESS (" + string ( safElapsedTime ) + ")" ) , BotMagicSuffix ) ;
                     safSuccessCounter += 1 ;
                  } else {
                     goAutoDeploy_Write ( ( TradeMagic + "-FAILED (" + string ( safElapsedTime ) + ")" ) , BotMagicSuffix ) ;
                     safFailedCounter += 1 ; }}}}}
      if ( safFailedCounter >= MaxFailCount ) {
         goBroadcast_OPS ( goTele_PrepMsg ( glb_Magic , "BEACON" , "FAILEDAUTODEPLOY" , ( glb_EAS + BotMagicSuffix + "|" + BotConfigString ) ) ) ;
         goAutoDeploy_Write ( "|FAILEDAUTODEPLOY|" , BotMagicSuffix ) ;
         ExpertRemove () ; }
      if ( ( safSuccessCounter >= MinTradeCount ) && ( safOpenCounter == 0 ) ) {
         StringReplace ( glb_Magic , "TEST" , "" ) ;
         glb_BroadID = glb_Magic ;
         goBroadcast_OPS ( goTele_PrepMsg ( glb_Magic , "BEACON" , "DEPLOYED" , ( glb_EAS + BotMagicSuffix + "|" + BotConfigString ) ) ) ;
         goAutoDeploy_Write ( "|DEPLOYED|" , BotMagicSuffix ) ; }}

*/

   //===========================================================================================================
   //=====                                            DASHBOARD                                            =====
   //===========================================================================================================

   void goDashboard_WriteConfigStringFile () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- Variables
      string safResults [] ;
      // -------------------- Destination info
      glb_ServerPath = "/PERFHIST/" ;
      glb_ServerFileName = "ConfigStrings.txt" ;
      // -------------------- Read file content
      string sFN = glb_ServerIP + "SNRobotiX/operations.txt" ;
      string safMessage[] ; goServer_ReadOperationsFile ( sFN , safMessage ) ;
      if ( ArraySize ( safMessage ) < 2 ) { return ; }
      // -------------------- Write file header / also to delete old data
      goServer_Write_String ( "ConfigString" , "w" ) ;
      // -------------------- Go thru OPS lines
      for ( int i = 0 ; i < ArraySize ( safMessage ) ; i++ ) {
         // -------------------- UT line
         string safLine = UT ( safMessage [ i ] ) ;
         safMessage [ i ] = "" ;
         // -------------------- Check if beacon start of beacon auto deploy
         if ( !sFind ( safLine , "|BEACON|STARTED|" ) ) {
            if ( !sFind ( safLine , "|BEACON|ADJUST|" ) ) {
               if ( !sFind ( safLine , "|BEACON|DEPLOYED|" ) ) {
               continue ; }}}
         // -------------------- Disregard if beacon was a test
         if ( sFind ( safLine , "TEST|" ) ) { continue ; }
         // -------------------- Split line into bits
         string LineBits [] ; StringSplit ( safLine , 124 , LineBits ) ;
         if ( ArraySize ( LineBits ) < 25 ) { continue ; }
         // -------------------- Construct string to write to server
         string S2W = "|" ;
         for ( int x = ArraySize ( LineBits ) - 3 ; x > 2 ; x-- ) { // remove end checksum, botname and date
            if ( sFind ( LineBits [ x ] , " VERSION" ) ) { continue ; } // Remove libver and botver bits
            if ( S2W == "|" ) { if ( StringLen ( goTrim ( LineBits [ x ] ) ) == 0 ) { continue ; }} // remove empty bits at end
            S2W = "|" + goTrim ( LineBits [ x ] ) + S2W ; } // remove spaces before and after
         // -------------------- Some formatting of output
         StringReplace ( S2W , "..." , "" ) ;
         StringReplace ( S2W , "FALSE" , "" ) ;
         StringReplace ( S2W , "TRUE" , "true" ) ;
         StringReplace ( S2W , "BEACON|STARTED|" , "" ) ;
         StringReplace ( S2W , "BEACON|ADJUST|" , "" ) ;
         StringReplace ( S2W , "BEACON|DEPLOYED|" , "" ) ;
         S2W = goURLEncode ( S2W ) ;
         // -------------------- Add to results array here
         goArray_Add ( S2W , safResults ) ; }
      // -------------------- x
      goArray_RemoveDuplicates ( safResults ) ;
      // -------------------- x
      for ( int x = 0 ; x < ArraySize ( safResults ) ; x++ ) {
         goServer_Write_String ( safResults [ x ] ) ; Sleep ( 100 ) ; }}

   void goDashboard_WriteBalanceReport ( string safMainURL="PERFHIST/RAW/" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- Destination info
      glb_ServerPath = "/PERFHIST/" ;
      glb_ServerFileName = "BalanceReport.csv" ;
      // -------------------- Variables
      string safFC[] ;
      safMainURL = glb_ServerIP + safMainURL ;
      // -------------------- Get file list on server
      string safFileNameArray [] ; goServer_GetFileList ( safMainURL , safFileNameArray ) ;
      if ( ArraySize ( safFileNameArray ) < 1 ) { return ; }
      // -------------------- start output file
      goServer_Write_String ( goURLEncode ( "AccountNo,Balance,Equity,Lots,Net Profit,Broker" ) , "w" ) ;
      // -------------------- Go thru files one by one
      for ( int x = 0 ; x < ArraySize ( safFileNameArray ) ; x++ ) {
         // -------------------- Read contents
         goServer_ReadSimpleTextFile ( ( safMainURL + safFileNameArray [ x ] ) , safFC ) ;
         if ( ArraySize ( safFC ) < 2 ) { continue ; }
         // -------------------- Variables
         string safBalance = "" , safEquity = "" , safBroker = "" , safLots = "" , safNetProfit = "" ;
         // -------------------- Go thru file content line by line
         for ( int y = 0 ; y < ArraySize ( safFC ) ; y++ ) {
            // -------------------- x
            if ( sFind ( safFC [ y ] , "|BAL|" ) ) {
               safBalance = safFC [ y ] ;
               StringReplace ( safBalance , "|BAL|" , "" ) ; }
            // -------------------- x
            if ( sFind ( safFC [ y ] , "|EQU|" ) ) {
               safEquity = safFC [ y ] ;
               StringReplace ( safEquity , "|EQU|" , "" ) ; }
            // -------------------- x
            if ( sFind ( safFC [ y ] , "|BN|" ) ) {
               safBroker = safFC [ y ] ;
               StringReplace ( safBroker , "|BN|" , "" ) ; }
            // -------------------- x
            if ( sFind ( safFC [ y ] , "|PNL|" ) ) {
               safNetProfit = safFC [ y ] ;
               StringReplace ( safNetProfit , "|PNL|" , "" ) ; }
            // -------------------- x
            if ( sFind ( safFC [ y ] , "|LOT|" ) ) {
               safLots = safFC [ y ] ;
               StringReplace ( safLots , "|LOT|" , "" ) ; }}
         // -------------------- x
         StringReplace ( safFileNameArray [ x ] , ".raw" , "" ) ;
         // -------------------- x
         string S2W = safFileNameArray [ x ] + "," + string ( double ( safBalance ) ) + "," + string ( double ( safEquity ) ) ;
         S2W += "," + string ( double ( safLots ) ) + "," + string ( double ( safNetProfit ) ) + "," + UT ( safBroker ) ;
         StringReplace ( S2W , "|" , "" ) ;
         // -------------------- x
         goServer_Write_String ( goURLEncode ( S2W ) ) ; }}

   string goDashboard_GetAllConfigStrings ( string safFolder ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return "Error" ; }
      // -------------------- Variables
      string safResultFN = goGetDateTime () + "_" + "AllConfigStrings.txt" ;
      string safFullFolder = glb_ServerIP + safFolder ;
      // -------------------- Open output file
      int f = FileOpen ( safResultFN , FILE_READ | FILE_WRITE | FILE_TXT | FILE_COMMON ) ;
      if ( f == INVALID_HANDLE ) { return "error" ; }
      // -------------------- Read all test filenames in folder
      string sFNArray [] ;
      goServer_GetFileList ( safFullFolder , sFNArray ) ;
      if ( ArraySize ( sFNArray ) < 1 ) { return "error" ; }
      // -------------------- Open test files one by one
      for ( int x = 0 ; x < ArraySize ( sFNArray ) ; x++ ) {
         // -------------------- Read test results from each file
         string safLines [] ;
         goServer_ReadSimpleTextFile ( safFullFolder + "//" + sFNArray [ x ] , safLines ) ;
         if ( ArraySize ( safLines ) < 2 ) { continue ; }
            // -------------------- Write lines to output file
            for ( int y = 0 ; y < ArraySize ( safLines ) ; y++ ) {
               // -------------------- Get config string bit
               string LineBits [] ;
               StringSplit ( safLines [ y ] , StringGetCharacter ( "," , 0 ) , LineBits ) ;
               if ( ArraySize ( LineBits ) < 2 ) { continue ; }
               // -------------------- Do some cleaning first
               string S2W = UT ( LineBits [ ArraySize ( LineBits ) - 1 ] ) ;
               if ( StringLen ( S2W ) < 1 ) { continue ; }
               StringReplace ( S2W , "TRUE" , "true" ) ;
               StringReplace ( S2W , "FALSE" , "" ) ;
               S2W = sFNArray [ x ] + "," + safFolder + "," + S2W ;
               FileWrite ( f , S2W ) ; }}
      // -------------------- close output file
      FileClose ( f ) ;
      // -------------------- return
      return ( safResultFN ) ; }

   string goDashboard_GetAllTestResults ( string safFolder ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return "Error" ; }
      // -------------------- Variables
      string safResultFN = goGetDateTime () + "_" + "AllResults.txt" ;
      string safFullFolder = glb_ServerIP + safFolder ;
      // -------------------- Open output file
      int f = FileOpen ( safResultFN , FILE_READ | FILE_WRITE | FILE_TXT | FILE_COMMON ) ;
      if ( f == INVALID_HANDLE ) { return "error" ; }
      // -------------------- Read all test filenames in folder
      string sFNArray [] ;
      goServer_GetFileList ( safFullFolder , sFNArray ) ;
      if ( ArraySize ( sFNArray ) < 1 ) { return "error" ; }
      // -------------------- Open test files one by one
      for ( int x = 0 ; x < ArraySize ( sFNArray ) ; x++ ) {
         // -------------------- Read test results from each file
         string safLines [] ;
         goServer_ReadSimpleTextFile ( safFullFolder + "//" + sFNArray [ x ] , safLines ) ;
         if ( ArraySize ( safLines ) < 2 ) { continue ; }
            // -------------------- Write lines to output file
            for ( int y = 0 ; y < ArraySize ( safLines ) ; y++ ) {
               // -------------------- Do some cleaning first
               string S2W = UT ( safLines [ y ] ) ;
               if ( StringLen ( S2W ) < 1 ) { continue ; }
               StringReplace ( S2W , "TRUE" , "true" ) ;
               StringReplace ( S2W , "FALSE" , "" ) ;
               FileWrite ( f , S2W ) ; }}
      // -------------------- close output file
      FileClose ( f ) ;
      // -------------------- return
      return ( safResultFN ) ; }

   //===========================================================================================================
   //=====                                             TRIMMER                                             =====
   //===========================================================================================================

   bool goTrimmer_Execute ( string &PotentialTrades[] , double ClosingValueTarget , bool ClosePositions ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
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
            // -------------------- x
            string LineArray[] ; StringSplit ( PotentialTrades [ i ] , 124 , LineArray ) ;
            if ( ArraySize ( LineArray ) < 18 ) { continue ; }
            // -------------------- x
            double posLossPerPercent = double ( LineArray [ 17 ] ) ;
            // -------------------- x
            if ( posLossPerPercent > HighestLossPerPercent ) {
               HighestLossPerPercent = posLossPerPercent ;
               HighestLossNumber = i ; }}
         // -------------------- Add to potential array
         if ( HighestLossNumber > -1 ) {
            goArray_Add ( PotentialTrades [ HighestLossNumber ] , Prioritized ) ;
            PotentialTrades [ HighestLossNumber ] = "" ; }}
      // -------------------- Write potentials in order to output
      int TradesToClose = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < ArraySize ( Prioritized ) ; i++ ) {
         // -------------------- x
         string LineArray[] ; StringSplit ( Prioritized [ i ] , 124 , LineArray ) ;
         if ( ArraySize ( LineArray ) < 18 ) { continue ; }
         // -------------------- x
         string posTicket = LineArray [ 1 ] ;
         double posNetProfit = double ( LineArray [ 12 ] ) ;
         double posLossPerPercent = double ( LineArray [ 17 ] ) ;
         // -------------------- x
         if ( MathAbs ( posNetProfit ) <= MathAbs ( ClosingValueTarget ) ) {
            safPotentialTickets += posTicket + "/" + (string) posLossPerPercent + " , " ;
            // -------------------- x
            if ( ClosePositions == true ) {
               goClose_Ticket ( long ( posTicket ) , "goTrimmer_Execute" ) ;
               goPrint ( "Trimming ticket number: " + posTicket ) ; }
            // -------------------- x
            ClosingValueTarget -= MathAbs ( posNetProfit ) ;
            TradesToClose += 1 ; }}
      // -------------------- Send telegram message here
      if ( ClosePositions == false ) {
         string sCurr_BroadcastID = glb_BroadID ;
         glb_BroadID = IntegerToString ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) ;
            // -------------------- x
            string sMessage2Send = goTele_PrepMsg (
               "Found " + (string) TradesToClose + "/" + (string) ArraySize ( PotentialTrades ) + " trim potentials" ,
               "Total Value: " + (string) ND2 ( OriginalClosingValueTarget ) , safPotentialTickets ) ;
            goBroadcast_OPS ( sMessage2Send ) ;
         glb_BroadID  = sCurr_BroadcastID ; }
      // -------------------- x
      if ( TradesToClose > 0 ) { return true ; } else { return false ; }}

   bool goTrimmer_Check ( double TargetROIPerc=2 , int PeriodInSeconds=2678400 , bool ClosePositions=false ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
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
      string HistoryLines[] ; goHistory_Retreive ( HistoryLines ) ;
      if ( ArraySize ( HistoryLines ) < 1 ) { return false ; }
      // -------------------- Go thru history
      for ( int i=0 ; i < ArraySize ( HistoryLines ) ; i++ ) {
         // -------------------- Split line
         string safSplit[] ; StringSplit ( HistoryLines [ i ] , 124 , safSplit ) ;
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
               safMonthCount += 0.5 ; } else { safMonthCount += 1 ; }}
         // -------------------- Add to ROIs
         if ( ( DealType == "BUY" ) || ( DealType == "SELL" ) ) {
            TotalProfit += DealNet ;
            TotalROI += ( DealNet / TotalDepWith ) * 100 ;
            // -------------------- x
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
      // -------------------- Choose value to use for trimming
      double ClosingValueTarget = MathMax ( PeriodValue , TotalValue ) ;
      if ( ClosingValueTarget <= 0 ) { return false ; }
      // -------------------- Get all open positions
      string AllPositions[] ; goPositions_Retreive( AllPositions ) ;
      if ( ArraySize ( AllPositions ) < 1 ) { return false ; }
      // -------------------- Find potential closures
      string PotentialTrades[] ;
      for ( int i = 0 ; i < ArraySize ( AllPositions ) ; i++ ) {
         // -------------------- Split line into bits
         string LineArray[] ; StringSplit ( AllPositions [ i ] , 124 , LineArray ) ;
         if ( ArraySize ( LineArray ) < 13 ) { continue ; }
         // -------------------- Get pos variables
         string posTime = LineArray [ 6 ] ;
         double posNetProfit = double ( LineArray [ 12 ] ) ;
         // -------------------- Is loss smaller than trim value
         if ( MathAbs ( posNetProfit ) < ClosingValueTarget ) {
            // -------------------- Is position open time within trim period
            if ( StringSubstr ( posTime , 0 , ( StringLen ( ThisPeriodStart ) ) ) < ThisPeriodStart ) {
               // -------------------- Add to potential array
               goArray_Add ( AllPositions [ i ] , PotentialTrades ) ; }}}
      return ( goTrimmer_Execute ( PotentialTrades , ClosingValueTarget , ClosePositions ) ) ; }

   //===========================================================================================================
   //=====                                         ARRAY FUNCTIONS                                         =====
   //===========================================================================================================

   void goArray_Add ( string safNewLine , string &safArray[] ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      int safArraySize = ArraySize ( safArray ) ;
      ArrayResize ( safArray , ( safArraySize + 1 ) ) ;
      safArray [ safArraySize ] = safNewLine ; }

   void goArray_RemoveDuplicates ( string &safArray[] ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      string safResultArray [] ;
      // -------------------- x
      for ( int x = 0 ; x < ArraySize ( safArray ) ; x++ ) {
         string safOriginal = goTrim ( safArray [ x ] ) ; safArray [ x ] = "" ;
         if ( StringLen ( safOriginal ) == 0 ) { continue ; }
         // -------------------- x
         for ( int y = x + 1 ; y < ArraySize ( safArray ) ; y++ ) {
            string safCheck = goTrim ( safArray [ y ] ) ;
            if ( StringLen ( safCheck ) == 0 ) { continue ; }
            // -------------------- x
            if ( safOriginal == safCheck ) { safArray [ y ] = "" ; }}
         // -------------------- x
         goArray_Add ( safOriginal , safResultArray ) ; }
      // -------------------- x
      ArrayResize ( safArray , 0 ) ;
      ArrayCopy ( safArray , safResultArray ) ; }

   void goArray_SortMultiPart (
      int safLoc , string &safArray[] , bool safDescending=true , int safSize=0 , string safDivider="|" ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         // if ( glb_RobotDisabled ) { return ; }
         // -------------------- Variables
         string safResultArray [] ;
         // -------------------- x
         for ( int i = 0 ; i < ArraySize ( safArray ) ; i++ ) {
            // -------------------- Variables
            int safResultIndex = 0 ;
            double safResultValue ;
            if ( safDescending == true ) { safResultValue = 0 ; } else { safResultValue = 999999999999 ; }
            // -------------------- x
            for ( int j = 0 ; j < ArraySize ( safArray ) ; j++ ) {
               // -------------------- X
               string safSplit[] ; StringSplit ( safArray [ j ] , StringGetCharacter ( safDivider , 0 ) , safSplit ) ;
               if ( ArraySize ( safSplit ) < ( safLoc + 1 ) ) { continue ; }
               // -------------------- Compare splits
               if ( safDescending == true ) {
                  if ( double ( safSplit [ safLoc ] ) >= safResultValue ) {
                     safResultIndex = j ;
                     safResultValue = double ( safSplit [ safLoc ] ) ; }
               } else {
                  if ( double ( safSplit [ safLoc ] ) <= safResultValue ) {
                     safResultIndex = j ;
                     safResultValue = double ( safSplit [ safLoc ] ) ; }}}
            // -------------------- add next step to result array
            goArray_Add ( safArray [ safResultIndex ] , safResultArray ) ;
            safArray [ safResultIndex ] = "" ;
            if ( safSize > 0 ) { if ( ArraySize ( safResultArray ) >= safSize ) { break ; }}}
         // -------------------- x
         ArrayResize ( safArray , 0 ) ;
         ArrayCopy ( safArray , safResultArray ) ; }

   //===========================================================================================================
   //=====                                         COUNT FUNCTIONS                                         =====
   //===========================================================================================================

   double sNetProfit ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      double result = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Calc
         result += PositionGetDouble ( POSITION_PROFIT ) ; }
      // -------------------- x
      return ( result ) ; }

   int goCount_PositionsTotal ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( ( sCurr == "" ) && ( sComm == "" ) ) { return ( PositionsTotal() ) ; }
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      int result = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Calculation here
         result += 1 ; }
      // -------------------- x
      return ( result ) ; }

   int goCount_PositionsBuy ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      int result = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- x
         if ( PositionGetInteger ( POSITION_TYPE ) != POSITION_TYPE_BUY ) { continue ; }
         // -------------------- Calculation here
         result += 1 ; }
      // -------------------- x
      return ( result ) ; }

   int goCount_PositionsSell ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      int result = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- x
         if ( PositionGetInteger ( POSITION_TYPE ) != POSITION_TYPE_SELL ) { continue ; }
         // -------------------- Calculation here
         result += 1 ; }
      // -------------------- x
      return ( result ) ; }

   int goCount_NoSLPositions ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      int result = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Calculation here
         if ( PositionGetDouble ( POSITION_SL ) == 0 ) { result += 1 ; }}
      // -------------------- x
      return ( result ) ; }

   int goCount_NoSLBuyPositions ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      int result = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- x
         if ( PositionGetInteger ( POSITION_TYPE ) != POSITION_TYPE_BUY ) { continue ; }
         // -------------------- Calculation here
         if ( PositionGetDouble ( POSITION_SL ) == 0 ) { result += 1 ; }}
      // -------------------- x
      return ( result ) ; }

   int goCount_NoSLSellPositions ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      int result = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- x
         if ( PositionGetInteger ( POSITION_TYPE ) != POSITION_TYPE_SELL ) { continue ; }
         // -------------------- Calculation here
         if ( PositionGetDouble ( POSITION_SL ) == 0 ) { result += 1 ; }}
      // -------------------- x
      return ( result ) ; }

   ulong goFind_BiggestProfitPosition ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      double safBiggestProfit = 0 ;
      ulong safBiggestProfitTicket = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Calc
         double posProfit = PositionGetDouble ( POSITION_PROFIT ) ;
         if ( posProfit <= 0 ) { continue ; }
         // -------------------- x
         if ( posProfit > safBiggestProfit ) {
            safBiggestProfit = posProfit ;
            safBiggestProfitTicket = posTicket ; }}
      // -------------------- x
      return ( safBiggestProfitTicket ) ; }

   ulong goFind_BiggestLossPosition ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      double safBiggestLoss = 0 ;
      ulong safBiggestLossTicket = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Calc
         double posProfit = PositionGetDouble ( POSITION_PROFIT ) ;
         if ( posProfit >= 0 ) { continue ; }
         // -------------------- x
         if ( posProfit < safBiggestLoss ) {
            safBiggestLoss = posProfit ;
            safBiggestLossTicket = posTicket ; }}
      // -------------------- x
      return ( safBiggestLossTicket ) ; }

   int goCount_OrdersTotal ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( ( sCurr == "" ) && ( sComm == "" ) ) { return ( OrdersTotal() ) ; }
      if ( OrdersTotal () < 1 ) { return ( 0 ) ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      int result = 0 ;
      // -------------------- x
      for ( int i = 0 ; i < OrdersTotal() ; i++ ) {
         // -------------------- x
         ulong ordTicket = OrderGetTicket ( i ) ;
         if ( !OrderSelect ( ordTicket ) ) { continue ; }
         // -------------------- Check Symbol
         if ( sCurr != "" ) { if ( UT ( OrderGetString ( ORDER_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( OrderGetString ( ORDER_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Calculation here
         result += 1 ; }
      // -------------------- x
      return ( result ) ; }

   //===========================================================================================================
   //=====                                        MODIFY FUNCTIONS                                         =====
   //===========================================================================================================

   bool goPositionModify ( ulong safTicket , double safSL , double safTP , string sReason ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      goPrint ( "POS Modify: " + sReason ) ;
      // -------------------- x
      // if ( !IsSession_Open() ) { return false ; }
      // -------------------- x
      bool safCloseSuccess = false ;
      int safTriesCount = 0 ;
      // -------------------- x
      while ( safCloseSuccess == false ) {
         // -------------------- x
         safCloseSuccess = trade.PositionModify ( safTicket , ND ( safSL ) , ND ( safTP ) ) ;
         // -------------------- x
         safTriesCount += 1 ; if ( safTriesCount >= glb_MaxTries ) { goPrint ( "Maximum number of tries reached" ) ; break ; }}
      // -------------------- x
      return ( safCloseSuccess ) ; }

   //===========================================================================================================
   //=====                                         CLOSE FUNCTIONS                                         =====
   //===========================================================================================================

   bool goClose_Order ( ulong safTicket , string sReason ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      goPrint ( "ORD Delete: " + sReason ) ;
      // -------------------- x
      // if ( !IsSession_Open() ) { return false ; }
      // -------------------- x
      bool safCloseSuccess = false ;
      int safTriesCount = 0 ;
      // -------------------- x
      while ( safCloseSuccess == false ) {
         // -------------------- x
         safCloseSuccess = trade.OrderDelete ( safTicket ) ;
         // -------------------- x
         safTriesCount += 1 ; if ( safTriesCount >= glb_MaxTries ) { goPrint ( "Maximum number of tries reached" ) ; break ; }}
      // -------------------- x
      return ( safCloseSuccess ) ; }

   bool goClose_Ticket ( ulong safTicket , string sReason ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      goPrint ( "POS Close: " + sReason ) ;
      // -------------------- x
      // if ( !IsSession_Open() ) { return false ; }
      // -------------------- x
      bool safCloseSuccess = false ;
      int safTriesCount = 0 ;
      // -------------------- x
      while ( safCloseSuccess == false ) {
         // -------------------- x
         safCloseSuccess = trade.PositionClose ( safTicket ) ;
         // -------------------- x
         safTriesCount += 1 ; if ( safTriesCount >= glb_MaxTries ) { goPrint ( "Maximum number of tries reached" ) ; break ; }}
      // -------------------- x
      return ( safCloseSuccess ) ; }

   void goClose_AllBuyPositions ( double safMinProfit=-999999 , string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Calculation here
         if ( PositionGetInteger ( POSITION_TYPE ) != POSITION_TYPE_BUY  ) { continue ; }
         if ( PositionGetDouble ( POSITION_PROFIT ) < safMinProfit ) { continue ; }
         goClose_Ticket ( posTicket , "goClose_AllBuyPositions" ) ; }}

   void goClose_AllSellPositions ( double safMinProfit=-999999 , string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Calculation here
         if ( PositionGetInteger ( POSITION_TYPE ) != POSITION_TYPE_SELL  ) { continue ; }
         if ( PositionGetDouble ( POSITION_PROFIT ) < safMinProfit ) { continue ; }
         goClose_Ticket ( posTicket , "goClose_AllSellPositions" ) ; }}

   void goClose_PositivePositions ( double safMinProfit=0 , string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Do
         if ( PositionGetDouble ( POSITION_PROFIT ) < safMinProfit ) { continue ; }
         goClose_Ticket ( posTicket , "goClose_PositivePositions" ) ; }}

   void goClose_PositionWithComment ( string sComm , double safMinProfit=-999999 , string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      if ( sComm == "" ) { return ; }
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Do
         if ( PositionGetDouble ( POSITION_PROFIT ) < safMinProfit ) { continue ; }
         // -------------------- x
         goClose_Ticket ( posTicket , "goClose_PositionWithComment" ) ; }}

   void goClose_AllPositions ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      // -------------------- Get open positions
      do { for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
            // -------------------- x
            ulong posTicket = PositionGetTicket ( i ) ;
            if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
            // -------------------- x
            if ( sCurr != "" ) { if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }}
            if ( sComm != "" ) { if ( !sFind ( UT ( PositionGetString ( POSITION_COMMENT ) ) , sComm ) ) { continue ; }}
            // -------------------- Do
            goClose_Ticket ( posTicket , "goClose_AllPositions" ) ; }
         } while ( goCount_PositionsTotal ( sCurr , sComm ) > 0 ) ; }

   void goClose_BiggestProfitPosition () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; }
      // goBroadcast_SIG ( goTele_PrepMsg ( "CBPP" ) ) ;
      goClose_Ticket ( goFind_BiggestProfitPosition () , "goClose_BiggestProfitPosition" ) ; }

   void goClose_BiggestLossPosition () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; }
      // goBroadcast_SIG ( goTele_PrepMsg ( "CBLP" ) ) ;
      goClose_Ticket ( goFind_BiggestLossPosition () , "goClose_BiggestLossPosition" ) ; }

   void goClose_OldPositions ( long safTicket , int safVal01 , double safVal02 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( safVal01 > 0 ) {
         MqlDateTime safDateTime ;
         string result = "" ;
         TimeToStruct ( ( TimeGMT () - PositionGetInteger ( POSITION_TIME ) ) , safDateTime ) ;
         int safCalcMinutes = ( ( safDateTime.day - 1 ) * 1440 ) + ( safDateTime.hour * 60 ) + safDateTime.min ;
         if ( safCalcMinutes >= ( safVal01 * 1440 ) ) { result += "Y" ; }
         if ( safVal02 > 0 ) { if ( sProfit() >= safVal02 ) { result += "Y" ; } else { result += "X" ; } }
         if ( ( result == "Y" ) || ( result == "YY" ) || ( result == "YYY" ) ) {
            goClose_Ticket ( safTicket , "goClose_OldPositions" ) ; }}} // missing broadcast message

   void goClose_OnRSI ( string safRules="1" , double safMinProfit=-999999 , double safBTrigger=55 , int safPeriod=2 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
         if ( ( sFind ( safRules , "1" ) ) ) {
            if ( ( ( RSI_C > safBTrigger ) && ( RSI_L < safBTrigger ) ) ||
            ( ( RSI_C < safSTrigger ) && ( RSI_L > safSTrigger ) ) ) { goClose_PositivePositions ( safMinProfit ) ; }}
         // -------------------- RULE 2
         if ( ( sFind ( safRules , "2" ) ) ) {
            if ( ( RSI_C > safBTrigger ) && ( RSI_L < safBTrigger ) ) { goClose_AllSellPositions ( safMinProfit ) ; }
            if ( ( RSI_C < safSTrigger ) && ( RSI_L > safSTrigger ) ) { goClose_AllBuyPositions ( safMinProfit ) ; }}}}

   void goClose_AllOrders ( string sCurr="" , string sComm="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      // if ( !IsSession_Open() ) { return ; }
      // -------------------- x
      if ( OrdersTotal () < 1 ) { return ; } else { sCurr = UT ( sCurr ) ; sComm = UT ( sComm ) ; }
      do { for ( int i = 0 ; i < OrdersTotal() ; i++ ) {
         // -------------------- x
         ulong ordTicket = OrderGetTicket ( i ) ;
         if ( !OrderSelect ( ordTicket ) ) { continue ; }
         // -------------------- Check Symbol
         if ( sCurr != "" ) { if ( UT ( OrderGetString ( ORDER_SYMBOL ) ) != sCurr ) { continue ; }}
         if ( sComm != "" ) { if ( !sFind ( UT ( OrderGetString ( ORDER_COMMENT ) ) , sComm ) ) { continue ; }}
         // -------------------- Calculation here
         goClose_Order ( ordTicket , "goClose_AllOrders" ) ; }
      } while ( goCount_OrdersTotal ( sCurr , sComm ) > 0 ) ; }

   //===========================================================================================================
   //=====                                      FORCE CLOSE FUNCTIONS                                      =====
   //===========================================================================================================

   void goClose_AllPositionsByForce ( string sReason ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      goPrint ( "POS: Close all by force - " + sReason ) ;
      // -------------------- x
      // if ( !IsSession_Open() ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; }
      // goBroadcast_SIG ( goTele_PrepMsg ( "FCAP" ) ) ;
      do { for ( int i = PositionsTotal () - 1 ; i >= 0 ; i-- ) {
         ulong safTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( safTicket ) ) { continue ; }
         goClose_Ticket ( safTicket , "goClose_AllPositionsByForce" ) ; }
      } while ( PositionsTotal () > 0 ) ; }

   void goClose_AllOrdersByForce ( string sReason ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      goPrint ( "ORD: Delete all by force - " + sReason ) ;
      // -------------------- x
      // if ( !IsSession_Open() ) { return ; }
      // -------------------- x
      if ( OrdersTotal () < 1 ) { return ; }
      // goBroadcast_SIG ( goTele_PrepMsg ( "FCAO" ) ) ;
      do { for ( int i = OrdersTotal () - 1 ; i >= 0 ; i-- ) {
         ulong safTicket = OrderGetTicket ( i ) ;
         if ( !OrderSelect ( safTicket ) ) { continue ; }
         goClose_Order ( safTicket , "goClose_AllOrdersByForce" ) ; }
      } while ( OrdersTotal () > 0 ) ; }

   //===========================================================================================================
   //=====                                        MAIN SIGNALS                                             =====
   //===========================================================================================================

   string goCheckTrending ( int safTrending=1 , string safGoingUp="B" , string safGoingDown="S" , string safOther="X" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      string result = "" ;
      if ( safTrending < 1 ) { return result ; }
      for ( int i = 0 ; i < safTrending ; i++ ) {
         if ( B0 [ glb_FC + i ] > B0 [ glb_FC + i + 1 ] ) { result += safGoingUp ; }
         else if ( B0 [ glb_FC + i ] < B0 [ glb_FC + i + 1 ] ) { result += safGoingDown ; }
         else { return safOther ; }} return result ; }

   string goSignal_Trend ( string safRules="1" , string safType="EMA" , int safPeriod=20 , int safTrending=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      // RULE 1: Buy if price above MA
      // RULE 2: Price cross MA
      // -------------------- x
      if ( safPeriod <= 0 ) { return ( "X" ) ; }
      // -------------------- x
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending ) ;
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; } // <<<<<<<<<< LEAVE
         // -------------------- Set Trend buffers
         if ( !ind_TREND ( safType , safPeriod ) ) { glb_BD = sCurr_BufferDepth ; return "X" ; }
         // -------------------- Variables
         string result = "" ;
         double safCurrentPrice  = glb_PI[ glb_FC ].close ;
         double safLastPrice     = glb_PI[ glb_FC + 1 ].close ;
         double safCurrentMA     = B0 [ glb_FC ] ;
         double safLastMA        = B0 [ glb_FC + 1 ] ;
         // -------------------- RULE 1
         if ( ( sFind ( safRules , "1" ) ) ) {
            if       ( safCurrentPrice > safCurrentMA  ) { result += "B" ; }
            else if  ( safCurrentPrice < safCurrentMA  ) { result += "S" ; }
            else                                         { result += "X" ; }
            if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "B" , "S" , "X" ) ; } }
         // -------------------- RULE 2
         if ( ( sFind ( safRules , "2" ) ) ) {
            if       ( ( safCurrentPrice > safCurrentMA  ) && ( safLastPrice < safLastMA  ) ) { result += "B" ; }
            else if  ( ( safCurrentPrice < safCurrentMA  ) && ( safLastPrice > safLastMA  ) ) { result += "S" ; }
            else                                                                              { result += "X" ; } }
      // -------------------- x
      glb_BD = sCurr_BufferDepth ;
      // -------------------- x
      return ( result ) ; }

   string goSignal_Osci (
      string sRules="1" , string sType="RSI" , int sPeriod=5 , int sTrending=1 ,
      double sBStart=51 , double sSStart=49 , double sBEnd=75 , double sSEnd=25 ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- x
         // RULE 1: Cross above
         // -------------------- x
         string result = "" ;
         // -------------------- x
         if ( sPeriod <= 0 ) { return "X" ; }
         // -------------------- x
         int sCurr_BufferDepth = glb_BD ;
         glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + sTrending ) ;
         if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; } // <<<<<<<<<< LEAVE
            // -------------------- x
            string sBuy = "B" , sSell = "S" ;
            // -------------------- Set Osci buffers
            if ( !ind_OSCI ( sType , sPeriod ) ) { glb_BD = sCurr_BufferDepth ; return "X" ; }
            if ( sType == "BULLS" ) { sSell = "X" ; }
            if ( sType == "BEARS" ) { sBuy = "X" ; }
            // -------------------- Get Osci buffer values
            double sCurrent = B0 [ glb_FC ] ;
            double sLast    = B0 [ glb_FC + 1 ] ;
            // -------------------- RULE 1
            if ( ( sFind ( sRules , "1" ) ) ) {
               // -------------------- x
               if ( sCurrent > sBStart )       { result += sBuy ; }
               else if ( sCurrent < sSStart )  { result += sSell ; }
               else                                { result += "X" ; }
               // -------------------- x
               if ( sBEnd > 0 ) { if ( sCurrent > sBEnd ) { result += "X" ; } }
               if ( sSEnd > 0 ) { if ( sCurrent < sSEnd ) { result += "X" ; } }
               if ( sTrending > 0 ) { result += goCheckTrending ( sTrending , sBuy , sSell  , "X" ) ; } }
         // -------------------- x
         glb_BD = sCurr_BufferDepth ;
         // -------------------- x
         return result ; }

   string goSignal_ADX ( string safRules="1" , string safType="ADX" , int safPeriod=5 , int safTrending=1 , int safStart=25 , int safEnd=75 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      string result = "" ;
      // RULE 1: Main line rules / ADX above trade trigger
      // RULE 2: D+/D- rules
      if ( safPeriod <= 0 ) { return "X" ; }
      if ( safStart <= 0  ) { return "X" ; }
      // -------------------- x
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending ) ;
         // -------------------- x
         if ( safType == "ADX" )  { if ( !ind_ADX  ( safPeriod ) ) { glb_BD = sCurr_BufferDepth ; return "X" ; }}
         if ( safType == "ADXW" ) { if ( !ind_ADXW ( safPeriod ) ) { glb_BD = sCurr_BufferDepth ; return "X" ; }}
         // -------------------- RULE 1
         if ( sFind ( safRules , "1" ) ) {
            if ( B0 [ glb_FC ] >= safStart ) { result += "Y" ; } else { result += "X" ; }
            if ( safEnd > 0 ) { if ( B0 [ glb_FC ] > safEnd   ) { result += "X" ; }}
            if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "Y" , "X" , "X" ) ; } }
         // -------------------- RULE 2
         if ( sFind ( safRules , "2" ) ) {
            if       ( B1 [ glb_FC ] > B2 [ glb_FC ] ) { result += "B" ; }
            else if  ( B1 [ glb_FC ] < B2 [ glb_FC ] ) { result += "S" ; }
            else                                       { result += "X" ; }}
      // -------------------- x
      glb_BD = sCurr_BufferDepth ;
      // -------------------- x
      return result ; }

   //===========================================================================================================
   //=====                                        OTHER SIGNALS                                            =====
   //===========================================================================================================

   string goCheck_SARChange () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- handle indicator here
      if ( !ind_SAR () ) { return "X" ; }
      // -------------------- x
      double CurrentSAR = B0 [ glb_FC ] ;
      double LastSAR = B0 [ glb_FC + 1 ] ;
      double CurrentPrice = glb_PI[ glb_FC ].close ;
      double LastPrice = glb_PI[ glb_FC + 1 ].close ;
      // -------------------- x
      if ( ( CurrentSAR < CurrentPrice ) && ( LastSAR > LastPrice ) ) { return "B" ; }
      else if ( ( CurrentSAR > CurrentPrice ) && ( LastSAR < LastPrice ) ) { return "S" ; }
      else { return "X" ; }}

   string goCheck_Daily200MA ( string safType , string safSymbol ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      string result = "" ;
      // -------------------- x
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      string sCurr_Symbol = glb_EAS ;
         // -------------------- x
         glb_EAP = PERIOD_D1 ;
         glb_EAS = safSymbol ;
         // -------------------- x
         CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; // <<<<<<<<<< LEAVE
         result = goSignal_Trend ( "1" , safType , 200 , 1 ) ;
      // -------------------- x
      glb_EAP = sCurr_Period ;
      glb_EAS = sCurr_Symbol ;
      // -------------------- x
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      // -------------------- x
      return result ; }

   string goSignal_Ichimoku ( string safRules="12345678" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
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
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; } // <<<<<<<<<< LEAVE
      // -------------------- handle indicator here
      if ( !ind_Ichimoku () ) { glb_BD = sCurr_BufferDepth ; return "X" ; }
      // -------------------- x
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
      if ( sFind ( safRules , "1" ) ) {
         if ( CurrentPrice > MathMax ( CurrentCloudA , CurrentCloudB ) ) { result += "B" ; }
         else if ( CurrentPrice < MathMin ( CurrentCloudA , CurrentCloudB ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 2
      if ( sFind ( safRules , "2" ) ) {
         if ( FutureCloudA > FutureCloudB ) { result += "B" ; }
         else if ( FutureCloudB > FutureCloudA ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 3
      if ( sFind ( safRules , "3" ) ) {
         if ( ( CurrentPrice > MathMax ( CurrentCloudA , CurrentCloudB ) ) && ( LastPrice < MathMax ( LastCloudA , LastCloudB ) ) ) { result += "B" ; }
         else if ( ( CurrentPrice < MathMin ( CurrentCloudA , CurrentCloudB ) ) && ( LastPrice > MathMin ( LastCloudA , LastCloudB ) ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 4
      if ( sFind ( safRules , "4" ) ) {
         if ( CurrentPrice > MathMax ( CurrentRed , CurrentBlue ) ) { result += "B" ; }
         else if ( CurrentPrice < MathMin ( CurrentRed , CurrentBlue ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 5
      if ( sFind ( safRules , "5" ) ) {
         if ( CurrentRed > CurrentBlue ) { result += "B" ; }
         else if ( CurrentRed < CurrentBlue ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 6
      if ( sFind ( safRules , "6" ) ) {
         if ( ( CurrentRed > CurrentBlue ) && ( LastRed < LastBlue ) ) { result += "B" ; }
         else if ( ( CurrentRed < CurrentBlue ) && ( LastRed > LastBlue ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 7
      if ( sFind ( safRules , "7" ) ) {
         if ( PastSpan > MathMax ( PastCloudA , PastCloudB ) ) { result += "B" ; }
         else if ( PastSpan < MathMin ( PastCloudA , PastCloudB ) ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE 8
      if ( sFind ( safRules , "8" ) ) {
         if ( PastSpan > PastPrice ) { result += "B" ; }
         else if ( PastSpan < PastPrice ) { result += "S" ; }
         else { result += "X" ; } }
      // -------------------- RULE A
      if ( sFind ( safRules , "A" ) ) {
         if ( ( PastSpan < PastPrice ) && ( BeforePastSpan > BeforePastPrice ) ) { result += "C" ; }
         if ( ( PastSpan > PastPrice ) && ( BeforePastSpan < BeforePastPrice ) ) { result += "T" ; } }
      // -------------------- RULE B
      if ( sFind ( safRules , "B" ) ) {
         if ( ( CurrentPrice > CurrentBlue ) && ( LastPrice < LastBlue ) ) { result += "T" ; }
         if ( ( CurrentPrice < CurrentBlue ) && ( LastPrice > LastBlue ) ) { result += "C" ; } }
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_MACD ( string safRules="12" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      // 0 - MAIN_LINE (not smooth) , 1 - SIGNAL_LINE (smooth)
      string result = "" ;
      // RULE 1: Buy if MACD crosses above signal
      // RULE 2: Buy if lines are in right order and when last one crosses above zero
      // -------------------- handle indicator here
      if ( !ind_MACD () ) { return "X" ; }
      // -------------------- x
      double CurrentMACD   = B0 [ glb_FC ] ;
      double LastMACD      = B0 [ glb_FC + 1 ] ;
      double CurrentSignal = B1 [ glb_FC ] ;
      double LastSignal    = B1 [ glb_FC + 1 ] ;
      // -------------------- RULE 1
      if ( sFind ( safRules , "1" ) ) {
         if ( ( CurrentMACD > CurrentSignal ) && ( LastMACD < LastSignal ) ) { result += "B" ; }
         else if ( ( CurrentMACD < CurrentSignal ) && ( LastMACD > LastSignal ) ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 2
      if ( sFind ( safRules , "2" ) ) {
         if ( ( CurrentMACD > CurrentSignal ) && ( LastSignal < 0 ) && ( CurrentSignal > 0 ) ) { result += "B" ; }
         else if ( ( CurrentMACD < CurrentSignal ) && ( LastSignal > 0 ) && ( CurrentSignal < 0 ) ) { result += "S" ; }
         else { return "X" ; } }
      return result ; }

   string goSignal_SOC ( string safRules="13" , int safBStart=20 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      // 0 - MAIN LINE , 1 - SIGNAL LINE
      string result = "" ;
      // RULE 1: Buy when %K crosses to above %D
      // RULE 2: Buy when both lines are below buy target
      // RULE 3: Buy when both lines cross back above buy target
      // -------------------- handle indicator here
      if ( !ind_Stochastic () ) { return "X" ; }
      // -------------------- x
      double CurrentK   = B0 [ glb_FC ] ;
      double LastK      = B0 [ glb_FC + 1 ] ;
      double CurrentD   = B1 [ glb_FC ] ;
      double LastD      = B1 [ glb_FC + 1 ] ;
      int safSStart     = 100 - safBStart ;
      // -------------------- RULE 1
      if ( sFind ( safRules , "1" ) ) {
         if ( ( CurrentK > CurrentD ) && ( LastK < LastD ) ) { result += "B" ; }
         else if ( ( CurrentK < CurrentD ) && ( LastK > LastD ) ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 2
      if ( ( sFind ( safRules , "2" ) ) ) {
         if ( ( CurrentK < safBStart ) && ( CurrentD < safBStart ) ) { result += "B" ; }
         else if ( ( CurrentK > safSStart ) && ( CurrentD > safSStart ) ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 3
      if ( ( sFind ( safRules , "3" ) ) ) {
         if ( ( CurrentK > safBStart ) && ( CurrentD > safBStart ) && ( LastK < safBStart ) && ( LastD < safBStart ) ) { result += "B" ; }
         else if ( ( CurrentK < safSStart ) && ( CurrentD < safSStart ) && ( LastK > safSStart ) && ( LastD > safSStart ) ) { result += "S" ; }
         else { return "X" ; } }
      return result ; }

   string goSignal_Channel ( string safRules="2" , string safType="BOL" , int safTrending=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      // BOL: 0 - BASE LINE , 1 - UPPER BAND , 2 - LOWER BAND
      // ENV: 0 - UPPER LINE , 1 - LOWER LINE
      // RULE 1: Trade if you cross out of bands
      // RULE 2: Trade if you cross back into bands
      // RULE 3: Use middle line as filter - buy if below and sell if above
      // -------------------- x
      string result = "" ;
      // -------------------- x
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending ) ;
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; } // <<<<<<<<<< LEAVE
         // -------------------- x
         double CurrentPrice     = glb_PI [ glb_FC ].close ;
         double LastPrice        = glb_PI [ glb_FC + 1 ].close ;
         double CurrentUpper = 0 , LastUpper = 0 , CurrentMiddle = 0 , LastMiddle = 0 , CurrentLower = 0 , LastLower = 0 ;
         // -------------------- BOLLINGER BANDS HERE
         if ( StringSubstr ( safType , 0 , 3 ) == "BOL" ) {
            StringReplace ( safType , "BOL" , "" ) ;
            // -------------------- handle indicator here
            if ( !ind_Band ( 20 , 0 , double ( safType ) ) ) { glb_BD = sCurr_BufferDepth ; return "X" ; }
            CurrentUpper  = B1 [ glb_FC ] ;
            LastUpper     = B1 [ glb_FC + 1 ] ;
            CurrentMiddle = B0 [ glb_FC ] ;
            LastMiddle    = B0 [ glb_FC + 1 ] ;
            CurrentLower  = B2 [ glb_FC ] ;
            LastLower     = B2 [ glb_FC + 1 ] ;
            // -------------------- x
            if ( safTrending > 0 ) { result += goCheckTrending ( safTrending , "B" , "S"  , "X" ) ; }}
         // -------------------- ENVELOPES HERE
         else if ( safType == "ENV" ) {
            // -------------------- handle indicator here
            if ( !ind_Envelopes () ) { glb_BD = sCurr_BufferDepth ; return "X" ; }
            CurrentUpper  = B0 [ glb_FC ] ;
            LastUpper     = B0 [ glb_FC + 1 ] ;
            CurrentLower  = B1 [ glb_FC ] ;
            LastLower     = B1 [ glb_FC + 1 ] ; }
         // -------------------- RULE 1
         if ( sFind ( safRules , "1" ) ) {
            if ( ( CurrentPrice < CurrentLower ) && ( LastPrice > LastLower ) ) { result += "B" ; }
            else if ( ( CurrentPrice > CurrentUpper ) && ( LastPrice < LastUpper ) ) { result += "S" ; }
            else { result += "X" ; }}
         // -------------------- RULE 2
         if ( sFind ( safRules , "2" ) ) {
            if ( ( CurrentPrice > CurrentLower ) && ( LastPrice < LastLower ) ) { result += "B" ; }
            else if ( ( CurrentPrice < CurrentUpper ) && ( LastPrice > LastUpper ) ) { result += "S" ; }
            else { result += "X" ; }}
         // -------------------- RULE 3
         if ( sFind ( safRules , "3" ) ) {
            if ( CurrentPrice < CurrentMiddle ) { result += "B" ; }
            else if ( CurrentPrice > CurrentMiddle ) { result += "S" ; }
            else { result += "X" ; }}
      // -------------------- x
      glb_BD = sCurr_BufferDepth ;
      // -------------------- x
      return result ; }

   string goSignal_Fractal () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      string result = "X" ;
      // -------------------- handle indicator here
      if ( !ind_Fractals () ) { return "X" ; }
      double safUpper      = B0 [ glb_FC + 1 ] ;
      double safLower      = B1 [ glb_FC + 1 ] ;
      double CurrentHigh   = glb_PI [ glb_FC ].high ;
      double CurrentLow    = glb_PI [ glb_FC ].low ;
      if ( ( safUpper != EMPTY_VALUE ) && ( safUpper > CurrentHigh ) ) { result = "S" ; }
      else if ( ( safLower != EMPTY_VALUE ) && ( safLower < CurrentLow ) ) { result = "B" ; }
      return result ; }

   string goSignal_Alligator ( string safRules="124" , int safTrending=1 , double safFan=0.8 , double safMinProfit=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      string result = "" ;
      static string LastResult ;
      // RULE 1: Price above/below alligator
      // RULE 2: Alligator are in right order
      // RULE 3: Price above/below for 5 candles
      // RULE 4: MAs fanned out equally ( 80% to 1/80% )
      // RULE 5: Alligators are in right order for 5 candles
      // RULE 6: return when signal changes only
      int sCurr_BufferDepth = glb_BD ;
      glb_BD = MathMax ( sCurr_BufferDepth , glb_FC + 1 + safTrending + 5 ) ;
      if ( glb_BD > sCurr_BufferDepth ) { CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ; } // <<<<<<<<<< LEAVE
      // 0 - GATOR JAW LINE ( lower ) , 1 - GATOR TEETH LINE , 2 - GATOR LIPS LINE ( upper )
      // -------------------- handle indicator here
      if ( !ind_Alligator () ) { glb_BD = sCurr_BufferDepth ; return "X" ; }
      // -------------------- x
      double safCurrentPrice = glb_PI[ glb_FC ].close ;
      double safUpper = MathMax ( MathMax ( B0 [ glb_FC ] , B1 [ glb_FC ] ) , B2 [ glb_FC ] ) ;
      double safLower = MathMin ( MathMin ( B0 [ glb_FC ] , B1 [ glb_FC ] ) , B2 [ glb_FC ] ) ;
      // -------------------- Trending
      if ( safTrending > 0 ) {
         for ( int i = glb_FC ; i < glb_FC + safTrending ; i++ ) {
            if      ( ( B0 [ i ] > B0 [ i + 1 ] ) && ( B1 [ i ] > B1 [ i + 1 ] ) && ( B2 [ i ] > B2 [ i + 1 ] ) ) { result += "B" ; }
            else if ( ( B0 [ i ] < B0 [ i + 1 ] ) && ( B1 [ i ] < B1 [ i + 1 ] ) && ( B2 [ i ] < B2 [ i + 1 ] ) ) { result += "S" ; }
            else { result += "X" ; }}}
      // -------------------- RULE 1
      if ( ( sFind ( safRules , "1" ) ) ) {
         if ( safCurrentPrice > safUpper ) { result += "B" ; }
         else if ( safCurrentPrice < safLower ) { result += "S" ; }
         else { result += "X" ; }}
      // -------------------- RULE 2
      if ( ( sFind ( safRules , "2" ) ) ) {
         if      ( ( B2 [ glb_FC ] > B1 [ glb_FC ] ) && ( B1 [ glb_FC ] > B0 [ glb_FC ] ) ) { result += "B" ; }
         else if ( ( B2 [ glb_FC ] < B1 [ glb_FC ] ) && ( B1 [ glb_FC ] < B0 [ glb_FC ] ) ) { result += "S" ; }
         else { result += "X" ; }}
      // -------------------- RULE 3
      if ( ( sFind ( safRules , "3" ) ) ) {
         for ( int i = glb_FC ; i < glb_FC + 5 ; i++ ) {
            if      ( glb_PI[ i ].close > MathMax ( MathMax ( B0 [ i ] , B1 [ i ] ) , B2 [ i ] ) ) { result += "B" ; }
            else if ( glb_PI[ i ].close < MathMin ( MathMin ( B0 [ i ] , B1 [ i ] ) , B2 [ i ] ) ) { result += "S" ; }
            else { result += "X" ; }}}
      // -------------------- RULE 4
      if ( ( sFind ( safRules , "4" ) ) ) {
         double safDist01 = MathAbs ( B0 [ glb_FC ] - B1 [ glb_FC ] ) ;
         double safDist02 = MathAbs ( B1 [ glb_FC ] - B2 [ glb_FC ] ) ;
         if ( ( safDist01 / safDist02 >= safFan ) && ( safDist01 / safDist02 <= ( 1 / safFan ) ) ) {
            result += "Y" ; } else { result += "X" ; }}
      // -------------------- RULE 5
      if ( ( sFind ( safRules , "5" ) ) ) {
         for ( int i = glb_FC ; i < glb_FC + 5 ; i++ ) {
            if      ( ( B2 [ i ] > B1 [ i ] ) && ( B1 [ i ] > B0 [ i ] ) ) { result += "B" ; }
            else if ( ( B2 [ i ] < B1 [ i ] ) && ( B1 [ i ] < B0 [ i ] ) ) { result += "S" ; }
            else { result += "X" ; }}}
      // -------------------- RULE 6
      if ( ( sFind ( safRules , "6" ) ) ) {
         if ( result == LastResult ) { result += "X" ; } else { LastResult = result ; }}
      // -------------------- x
      glb_BD = sCurr_BufferDepth ;
      // -------------------- x
      return result ; }

   string goSignal_AwesomeOscillator ( string safRules="123" , int NoOfCandles=1440 , double safPercent=25 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
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
      if ( !ind_AO () ) { glb_BD = sCurr_BufferDepth ; return "X" ; }
      // -------------------- x
      double AO_C = B0 [ glb_FC ] ; double AO_L = B0 [ glb_FC + 1 ] ; double AO_P = B0 [ glb_FC + 2 ] ;
      // -------------------- RULE 1
      if ( ( sFind ( safRules , "1" ) ) ) {
         if ( AO_C > 0 ) { result += "B" ; }
         else if ( AO_C < 0 ) { result += "S" ; }
         else { result += "X" ; }}
      // -------------------- RULE 2
      if ( ( sFind ( safRules , "2" ) ) ) {
         if ( ( ( AO_P > AO_L ) && ( AO_C > AO_L ) ) && ( AO_C > 0 ) ) { result += "B" ; }
         else if ( ( ( AO_P < AO_L ) && ( AO_C < AO_L ) ) && ( AO_C < 0 ) ) { result += "S" ; }
         else { result += "X" ; }}
      // -------------------- RULE 3
      if ( ( sFind ( safRules , "3" ) ) ) {
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
      if ( ( sFind ( safRules , "4" ) ) ) {
         if ( ( AO_C > 0 ) && ( AO_L < 0 ) ) { result += "B" ; }
         else if ( ( AO_C < 0 ) && ( AO_L > 0 ) ) { result += "S" ; }
         else { result += "X" ; }}
      // -------------------- RULE 5
      if ( ( sFind ( safRules , "5" ) ) ) {
         if ( ( ( AO_P > AO_L ) && ( AO_C > AO_L ) ) && ( AO_C < 0 ) ) { result += "B" ; }
         else if ( ( ( AO_P < AO_L ) && ( AO_C < AO_L ) ) && ( AO_C > 0 ) ) { result += "S" ; }
         else { result += "X" ; }}
      glb_BD = sCurr_BufferDepth ;
      return result ; }

   string goSignal_SWAP ( double safTrigger=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      string result = "X" ;
      // -------------------- x
      double safSWAP_Short = SymbolInfoDouble ( glb_EAS , SYMBOL_SWAP_SHORT ) ;
      double safSWAP_Long = SymbolInfoDouble ( glb_EAS , SYMBOL_SWAP_LONG ) ;
      // -------------------- x
      if ( ( safSWAP_Short > safTrigger ) && ( safSWAP_Long > safTrigger ) ) { result = "Y" ; }
      else if ( safSWAP_Short > safTrigger ) { result = "S" ; }
      else if ( safSWAP_Long > safTrigger ) { result = "B" ; }
      // -------------------- x
      return result ; }

   string goSignal_MarkovChain ( int safNoOfCandles , int safTarget , string &safResult[] , string safRules="1" , ENUM_TIMEFRAMES safTF=PERIOD_CURRENT ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- Reset result
      ArrayResize ( safResult , 0 ) ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- Get price data
      MqlRates sPI[] ; ArraySetAsSeries ( sPI , true ) ;
      CopyRates ( glb_EAS , safTF , 0 , safNoOfCandles + 5 , sPI ) ;
      // -------------------- Variables
      int safUaU=0 , safDaU=0 , safUaD=0 , safDaD=0 ;
      // -------------------- Add last candle type
      string safLastCandle = "UP" ;
      if ( sPI [ glb_FC ].close < sPI [ glb_FC ].open ) { safLastCandle = "DOWN" ; }
      string safPreviousCandle = "UP" ;
      if ( sPI [ glb_FC + 1 ].close < sPI [ glb_FC + 1 ].open ) { safPreviousCandle = "DOWN" ; }
      string safBeforePreviousCandle = "UP" ;
      if ( sPI [ glb_FC + 2 ].close < sPI [ glb_FC + 2 ].open ) { safBeforePreviousCandle = "DOWN" ; }
      // -------------------- x
      goArray_Add ( safLastCandle , safResult ) ;
      goArray_Add ( safPreviousCandle , safResult ) ;
      goArray_Add ( safBeforePreviousCandle , safResult ) ;
      // -------------------- calculations
      for ( int i = 1 ; i < ( safNoOfCandles - 1 ) ; i++ ) {
         // -------------------- Clasify candle type
         string saf_C  ="UP" ; if ( sPI [ i + 0 ].close < sPI [ i + 0 ].open ) { saf_C  = "DOWN" ; }
         string saf_L  ="UP" ; if ( sPI [ i + 1 ].close < sPI [ i + 1 ].open ) { saf_L  = "DOWN" ; }
         string saf_P  ="UP" ; if ( sPI [ i + 2 ].close < sPI [ i + 2 ].open ) { saf_P  = "DOWN" ; }
         string saf_BP ="UP" ; if ( sPI [ i + 3 ].close < sPI [ i + 3 ].open ) { saf_BP = "DOWN" ; }
         // -------------------- RULE 1
         if ( sFind ( safRules , "1" ) ) {
            if ( ( saf_C == "UP"   ) && ( saf_L == "UP"   ) ) { safUaU += 1 ; }
            if ( ( saf_C == "DOWN" ) && ( saf_L == "UP"   ) ) { safDaU += 1 ; }
            if ( ( saf_C == "UP"   ) && ( saf_L == "DOWN" ) ) { safUaD += 1 ; }
            if ( ( saf_C == "DOWN" ) && ( saf_L == "DOWN" ) ) { safDaD += 1 ; }}
         // -------------------- RULE 2
         if ( sFind ( safRules , "2" ) ) {
            if ( ( saf_C == "UP"   ) && ( saf_L == "UP"   ) && ( saf_P == saf_L ) ) { safUaU += 1 ; }
            if ( ( saf_C == "DOWN" ) && ( saf_L == "UP"   ) && ( saf_P == saf_L ) ) { safDaU += 1 ; }
            if ( ( saf_C == "UP"   ) && ( saf_L == "DOWN" ) && ( saf_P == saf_L ) ) { safUaD += 1 ; }
            if ( ( saf_C == "DOWN" ) && ( saf_L == "DOWN" ) && ( saf_P == saf_L ) ) { safDaD += 1 ; }}
         // -------------------- RULE 3
         if ( sFind ( safRules , "3" ) ) {
            if ( ( saf_C == "UP"   ) && ( saf_L == "UP"   ) && ( saf_P == saf_L ) && ( saf_BP == saf_L ) ) { safUaU += 1 ; }
            if ( ( saf_C == "DOWN" ) && ( saf_L == "UP"   ) && ( saf_P == saf_L ) && ( saf_BP == saf_L ) ) { safDaU += 1 ; }
            if ( ( saf_C == "UP"   ) && ( saf_L == "DOWN" ) && ( saf_P == saf_L ) && ( saf_BP == saf_L ) ) { safUaD += 1 ; }
            if ( ( saf_C == "DOWN" ) && ( saf_L == "DOWN" ) && ( saf_P == saf_L ) && ( saf_BP == saf_L ) ) { safDaD += 1 ; }}
      } // ----- next i
      // -------------------- Calculation here
      double safUaU_P = ND2 ( ( double ( safUaU ) / ( double ( safUaU ) + double ( safDaU ) ) * 100 ) ) ;
      double safDaU_P = ND2 ( ( double ( safDaU ) / ( double ( safUaU ) + double ( safDaU ) ) * 100 ) ) ;
      double safUaD_P = ND2 ( ( double ( safUaD ) / ( double ( safUaD ) + double ( safDaD ) ) * 100 ) ) ;
      double safDaD_P = ND2 ( ( double ( safDaD ) / ( double ( safUaD ) + double ( safDaD ) ) * 100 ) ) ;
      // -------------------- Write calculations
      goArray_Add ( string ( safUaU ) , safResult ) ;
      goArray_Add ( string ( safDaU ) , safResult ) ;
      goArray_Add ( string ( safUaU_P ) , safResult ) ;
      goArray_Add ( string ( safDaU_P ) , safResult ) ;
      goArray_Add ( string ( safUaD ) , safResult ) ;
      goArray_Add ( string ( safDaD ) , safResult ) ;
      goArray_Add ( string ( safUaD_P ) , safResult ) ;
      goArray_Add ( string ( safDaD_P ) , safResult ) ;
      // -------------------- Write signal
      string safSignal = "X" ;
      // -------------------- RULE 1
      if ( sFind ( safRules , "1" ) ) {
         if ( safLastCandle == "UP" ) {
            if ( safUaU_P >= safTarget ) { safSignal = "B" ; }
            if ( safDaU_P >= safTarget ) { safSignal = "S" ; }
            if ( ( safUaU_P >= safTarget ) && ( safDaU_P >= safTarget ) ) { safSignal = "Y" ; }}
         else if ( safLastCandle == "DOWN" ) {
            if ( safUaD_P >= safTarget ) { safSignal = "B" ; }
            if ( safDaD_P >= safTarget ) { safSignal = "S" ; }
            if ( ( safUaD_P >= safTarget ) && ( safDaD_P >= safTarget ) ) { safSignal = "Y" ; }}}
      // -------------------- RULE 2
      if ( sFind ( safRules , "2" ) ) {
         if ( ( safLastCandle == "UP" ) && ( safPreviousCandle == "UP" ) ) {
            if ( safUaU_P >= safTarget ) { safSignal = "B" ; }
            if ( safDaU_P >= safTarget ) { safSignal = "S" ; }
            if ( ( safUaU_P >= safTarget ) && ( safDaU_P >= safTarget ) ) { safSignal = "Y" ; }}
         else if ( ( safLastCandle == "DOWN" ) && ( safPreviousCandle == "DOWN" ) ) {
            if ( safUaD_P >= safTarget ) { safSignal = "B" ; }
            if ( safDaD_P >= safTarget ) { safSignal = "S" ; }
            if ( ( safUaD_P >= safTarget ) && ( safDaD_P >= safTarget ) ) { safSignal = "Y" ; }}}
      // -------------------- RULE 3
      if ( sFind ( safRules , "3" ) ) {
         if ( ( safLastCandle == "UP" ) && ( safPreviousCandle == "UP" ) && ( safBeforePreviousCandle == "UP" ) ) {
            if ( safUaU_P >= safTarget ) { safSignal = "B" ; }
            if ( safDaU_P >= safTarget ) { safSignal = "S" ; }
            if ( ( safUaU_P >= safTarget ) && ( safDaU_P >= safTarget ) ) { safSignal = "Y" ; }}
         else if ( ( safLastCandle == "DOWN" ) && ( safPreviousCandle == "DOWN" ) && ( safBeforePreviousCandle == "DOWN" ) ) {
            if ( safUaD_P >= safTarget ) { safSignal = "B" ; }
            if ( safDaD_P >= safTarget ) { safSignal = "S" ; }
            if ( ( safUaD_P >= safTarget ) && ( safDaD_P >= safTarget ) ) { safSignal = "Y" ; }}}
      goArray_Add ( safSignal , safResult ) ;
      // -------------------- return value
      return ( safSignal ) ; }

   //===========================================================================================================
   //=====                                      MULTI TF SIGNALS                                           =====
   //===========================================================================================================

   string goSignal_RSI_2_3 ( ENUM_TIMEFRAMES safTF , int safTrigger=55 , int safCandle=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      ENUM_TIMEFRAMES sCurr_TF = glb_EAP ;
      glb_EAP = safTF ;
         // -------------------- Variables
         string result = "" ;
         // -------------------- Get RSI values
         if ( !ind_RSI ( 2 ) ) { glb_EAP = sCurr_TF ; return "X" ; }
         double RSI_2 = B0 [ safCandle ] ;
         if ( !ind_RSI ( 3 ) ) { glb_EAP = sCurr_TF ; return "X" ; }
         double RSI_3 = B0 [ safCandle ] ;
         // -------------------- Calc signal here
         if ( ( RSI_2 > RSI_3 ) && ( RSI_2 > safTrigger ) ) { result += "B" ; }
         else if ( ( RSI_2 < RSI_3 ) && ( RSI_2 < ( 100 - safTrigger ) ) ) { result += "S" ; }
         else { result = "X" ; }
      glb_EAP = sCurr_TF ;
      // -------------------- Return result
      return result ; }

   string goSignal_MFI_2_3 ( ENUM_TIMEFRAMES safTF , int safTrigger=55 , int safCandle=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      ENUM_TIMEFRAMES sCurr_TF = glb_EAP ;
      glb_EAP = safTF ;
         // -------------------- Variables
         string result = "" ;
         // -------------------- Get RSI values
         if ( !ind_MFI ( 2 ) ) { glb_EAP = sCurr_TF ; return "X" ; }
         double MFI_2 = B0 [ safCandle ] ;
         if ( !ind_MFI ( 3 ) ) { glb_EAP = sCurr_TF ; return "X" ; }
         double MFI_3 = B0 [ safCandle ] ;
         // -------------------- Calc signal here
         if ( ( MFI_2 > MFI_3 ) && ( MFI_2 > safTrigger ) ) { result += "B" ; }
         else if ( ( MFI_2 < MFI_3 ) && ( MFI_2 < ( 100 - safTrigger ) ) ) { result += "S" ; }
         else { result = "X" ; }
      glb_EAP = sCurr_TF ;
      // -------------------- Return result
      return result ; }

   string goSignal_RVI_2_3 ( ENUM_TIMEFRAMES safTF , double safTrigger=0.01 , int safCandle=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      ENUM_TIMEFRAMES sCurr_TF = glb_EAP ;
      glb_EAP = safTF ;
         // -------------------- Variables
         string result = "" ;
         // -------------------- Get RSI values
         if ( !ind_RVI ( 2 ) ) { glb_EAP = sCurr_TF ; return "X" ; }
         double RVI_2 = B0 [ safCandle ] ;
         if ( !ind_RVI ( 3 ) ) { glb_EAP = sCurr_TF ; return "X" ; }
         double RVI_3 = B0 [ safCandle ] ;
         // -------------------- Calc signal here
         if ( ( RVI_2 > RVI_3 ) && ( RVI_2 > safTrigger ) ) { result += "B" ; }
         else if ( ( RVI_2 < RVI_3 ) && ( RVI_2 < ( safTrigger * -1 ) ) ) { result += "S" ; }
         else { result = "X" ; }
      glb_EAP = sCurr_TF ;
      // -------------------- Return result
      return result ; }

   string goSignalTF_TREND ( ENUM_TIMEFRAMES safTF=1 , int safPeriod=200 , string safType="EMA" , string safRules="1" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      // RULE 1: Above or below MA buy/sell signal
      // RULE 2: Current candle versus last candle buy/sell signal
      // -------------------- Variables
      string result = "" ;
      // -------------------- Save timeframe for future
      ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
      glb_EAP = safTF ;
         // -------------------- Main logic
         if ( !ind_TREND ( safType , safPeriod ) ) { glb_EAP = sCurr_Period ; return ( "X" ) ; }
         // -------------------- Get MA Value
         double safMA = B0 [ glb_FC ] ;
         double safMA_L = B0 [ glb_FC + 1 ] ;
         // -------------------- RULE 1
         if ( sFind ( safRules , "1" ) ) {
            // -------------------- Check signal
            if ( sBid() > safMA ) { result += "B" ; }
            else if ( sAsk() < safMA ) { result += "S" ; }
            else { result = "X" ; }}
         // -------------------- RULE 2
         if ( sFind ( safRules , "2" ) ) {
            // -------------------- Check signal
            if ( safMA > safMA_L ) { result += "B" ; }
            else if ( safMA < safMA_L ) { result += "S" ; }
            else { result = "X" ; }}
      // -------------------- Return timeframe
      glb_EAP = sCurr_Period ;
      // -------------------- Return result
      return ( result ) ; }

   string goSignalTF_OSCI (
      ENUM_TIMEFRAMES safTF=1 ,
      int safPeriod=14 ,
      string safType="RSI" ,
      double safTriggerBuyStart=55 ,
      double safTriggerBuyEnd=75 ,
      double safTriggerSellStart=45 ,
      double safTriggerSellEnd=25 ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- Variables
         string result = "" ;
         // -------------------- Save timeframe for future
         ENUM_TIMEFRAMES sCurr_Period = glb_EAP ;
         glb_EAP = safTF ;
            // -------------------- Main logic
            if ( !ind_OSCI ( safType , safPeriod ) ) { glb_EAP = sCurr_Period ; return ( "X" ) ; }
            // -------------------- Get MA Value
            double safOSCI = B0 [ glb_FC ] ;
            // -------------------- Check signal
            if ( ( safOSCI >= safTriggerBuyStart ) && ( safOSCI <= safTriggerBuyEnd ) ) { result += "B" ; }
            else if ( ( safOSCI <= safTriggerSellStart ) && ( safOSCI >= safTriggerSellEnd ) ) { result += "S" ; }
            else { result = "X" ; }
         // -------------------- Return timeframe
         glb_EAP = sCurr_Period ;
         // -------------------- Return result
         return ( result ) ; }

   //===========================================================================================================
   //=====                                           CANDLES                                               =====
   //===========================================================================================================

   bool IsNewCandle () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      CopyRates ( glb_EAS , glb_EAP , 0 , glb_BD , glb_PI ) ;
      static datetime safLastCandle ;
      if ( safLastCandle == glb_PI [ glb_FC ].time ) { return false ; }
      safLastCandle = glb_PI [ glb_FC ].time ;
      return true ; }

   string IsCandle_Engulfing ( string safRules="12345" , double safMinSize=0 , int safCandle=1 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
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
      if ( sFind ( safRules , "1" ) ) {
         if ( MathAbs ( safCurrC - safCurrO ) >= safMinSize ) { result += "Y" ; } else { return "X" ; } }
      // -------------------- RULE 2
      if ( sFind ( safRules , "2" ) ) {
         if ( safCurrO < safCurrC ) { result += "B" ; }
         else if ( safCurrO > safCurrC ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 3
      if ( sFind ( safRules , "3" ) ) {
         if ( safLastO > safLastC ) { result += "B" ; }
         else if ( safLastO < safLastC ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 4
      if ( sFind ( safRules , "4" ) ) {
         if ( safCurrC >= safLastO ) { result += "B" ; }
         else if ( safCurrC <= safLastO ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 5
      if ( sFind ( safRules , "5" ) ) {
         if ( safCurrO <= safLastC ) { result += "B" ; }
         else if ( safCurrO >= safLastC ) { result += "S" ; }
         else { return "X" ; } }
      // -------------------- RULE 6
      if ( sFind ( safRules , "6" ) ) {
         if ( ( safCurrH > safLastH ) && ( safCurrL < safLastL ) ) { result += "Y" ; } else { return "X" ; } }
      return result ; }

   string goCandle_Clasify () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      double CurrentHigh   = glb_PI[ glb_FC ].high ;
      double CurrentLow    = glb_PI[ glb_FC ].low ;
      double LastHigh      = glb_PI[ glb_FC + 1 ].high ;
      double LastLow       = glb_PI[ glb_FC + 1 ].low ;
      if ( ( CurrentHigh >= LastHigh ) && ( CurrentLow >= LastLow ) ) { return "Up Candle" ; }
      if ( ( CurrentHigh <= LastHigh ) && ( CurrentLow <= LastLow ) ) { return "Down Candle" ; }
      if ( ( CurrentHigh >= LastHigh ) && ( CurrentLow <= LastLow ) ) { return "Outside Candle" ; }
      if ( ( CurrentHigh <= LastHigh ) && ( CurrentLow >= LastLow ) ) { return "Inside Candle" ; }
      return "Unclassified Candle" ; }

   string IsCandle_45PercentShadow ( string safRules="23" , double safMinSize=0 , int safCandle=1 , double safPercent=45 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
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
      if ( sFind ( safRules , "1" ) ) {
         if ( ( safHigh - safLow ) >= safMinSize ) { result += "Y" ; } else { return "X" ; } }
      // -------------------- RULE 2
      if ( sFind ( safRules , "2" ) ) {
         if ( ( ( safHigh - safMax ) >= safFullSize * safPercent2Use ) && ( safMin == safLow ) ) { result += "Y" ; resultOther = "S" ; }
         else if ( ( ( safMin - safLow ) >= safFullSize * safPercent2Use ) && ( safHigh == safMax ) ) { result += "Y" ; resultOther = "B" ; }
         else { return "X" ; }}
      // -------------------- RULE 3
      if ( sFind ( safRules , "3" ) ) { result = result + resultOther ; }
      return result ; }

   string IsCandle_EngulphingAfterXInRow ( int safStart , int safNumber ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      string result = "" ;
      // -------------------- Declarations and variables
      MqlRates sPI[] ; ArraySetAsSeries ( sPI , true ) ;
      CopyRates ( glb_EAS , glb_EAP , 0 , ( safStart + safNumber + 1 ) , sPI ) ;
      // ------------------------------ VARIABLES
      double C0_O = sPI[ safStart ].open ;
      double C0_C = sPI[ safStart ].close ;
      double safHigh = 0 ;
      double safLow = 9999999 ;
      // ------------------------------ X Candle checks here
      for ( int i = safStart + 1 ; i <= ( safStart + safNumber ) ; i ++ ) {
         // ------------------------------ check that candles trend
         if ( i != ( safStart + safNumber ) ) {
            if ( sPI[ i ].close > sPI[ i + 1 ].close ) { result += "S" ; }
            else if ( sPI[ i ].close < sPI[ i + 1 ].close ) { result += "B" ; }
            else { result = "X" ; }}
         // ------------------------------ check candles direction
         if ( sPI[ i ].open < sPI[ i ].close ) { result += "S" ; }
         else if ( sPI[ i ].open > sPI[ i ].close ) { result += "B" ; }
         else { result = "X" ; }
         // ------------------------------ find highest and lowest points
         if ( sPI[ i ].high > safHigh ) { safHigh = sPI[ i ].high ; }
         if ( sPI[ i ].low < safLow ) { safLow = sPI[ i ].low ; }}
      // ------------------------------ Check if last candle engulphs the rest
      if ( sPI[ safStart ].high > safHigh ) { result += "Y" ; } else { result = "X" ; }
      if ( sPI[ safStart ].low < safLow ) { result += "Y" ; } else { result = "X" ; }
      // ------------------------------ Check last candle direction
      if ( C0_O > C0_C ) { result += "S" ; }
      else if ( C0_O < C0_C ) { result += "B" ; }
      else { result = "X" ; }
      // ------------------------------ return result
      return ( result ) ; }

   string prvCandle_Analytics ( string safRules="AB" , int safCandle=1 , double safMultiple=1 , int safATRPeriod=1440 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
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
      // -------------------- Last Candle
      double lHigh         = glb_PI [ safCandle + 1 ].high ;
      double lLow          = glb_PI [ safCandle + 1 ].low ;
      double lOpen         = glb_PI [ safCandle + 1 ].open ;
      double lClose        = glb_PI [ safCandle + 1 ].close ;
      double lMax          = MathMax ( lOpen , lClose ) ;
      double lMin          = MathMin ( lOpen , lClose ) ;
      // -------------------- RULE A / Is Range more that ATR Multiple
      if ( sFind ( safRules , "A" ) ) {
         if ( ind_ATR ( safATRPeriod ) == false ) { return "X" ; }
         double cATR = B0 [ safCandle ] ;
         if ( cRange >= ( cATR * safMultiple ) ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE B / Is candle body equal to zero
      if ( sFind ( safRules , "B" ) ) {
         if ( cBody == 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE C / Is candle bearish
      if ( sFind ( safRules , "C" ) ) {
         if ( cOpen > cClose ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE D / Is candle bullish
      if ( sFind ( safRules , "D" ) ) {
         if ( cOpen < cClose ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE E / Is current body max higher than last body max
      if ( sFind ( safRules , "E" ) ) {
         if ( cMax > lMax ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE F / Is current body min lower than last body min
      if ( sFind ( safRules , "F" ) ) {
         if ( cMin < lMin ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE G / Is current high higher than last high
      if ( sFind ( safRules , "G" ) ) {
         if ( cHigh > lHigh ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE H / Is current low lower than last low
      if ( sFind ( safRules , "H" ) ) {
         if ( cLow < lLow ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE I / upper wick equals zero
      if ( sFind ( safRules , "I" ) ) {
         if ( cUpperWick == 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE J / lower wick equals zero
      if ( sFind ( safRules , "J" ) ) {
         if ( cLowerWick == 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE K / upper wick not equal to zero
      if ( sFind ( safRules , "K" ) ) {
         if ( cUpperWick > 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE L / lower wick not equal to zero
      if ( sFind ( safRules , "L" ) ) {
         if ( cLowerWick > 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE M / Is candle body not equal to zero
      if ( sFind ( safRules , "M" ) ) {
         if ( cBody > 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE N / upper wick bigger than range multiple
      if ( sFind ( safRules , "N" ) ) {
         if ( cUpperWick >= ( cRange * safMultiple ) ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE O / lower wick bigger than range multiple
      if ( sFind ( safRules , "O" ) ) {
         if ( cLowerWick >= ( cRange * safMultiple ) ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE P / Wicks are within multiple of each other
      if ( sFind ( safRules , "P" ) ) {
         if ( ( cUpperWick >= ( cLowerWick * safMultiple ) ) &&
            ( cLowerWick >= ( cUpperWick * safMultiple ) ) ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE Q / Are candle bodies matching tops
      if ( sFind ( safRules , "Q" ) ) {
         if ( cMax == lMax ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE R / Are candle bodies matching bottoms
      if ( sFind ( safRules , "R" ) ) {
         if ( cMin == lMin ) { result += "Y" ; } else { return "X" ; }}
      return result ; }

      string IsCandle_Dogi ( string CandleRules="BKLP" , double WickRatio=0.8 ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- x
         // RULE B / Is Open and Close the same
         // RULE K / upper wick not equal to zero
         // RULE L / lower wick not equal to zero
         // RULE P / Wicks are within 80% of each other
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC , WickRatio ) ;
         return ( result ) ; }

      string IsCandle_Dragonfly_Dogi ( string CandleRules="BIL" ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- x
         // RULE B / Is Open and Close the same
         // RULE I / upper wick equals zero
         // RULE L / lower wick not equal to zero
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC ) ;
         return ( result ) ; }

      string IsCandle_Gravestone_Dogi ( string CandleRules="BJK" ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- x
         // RULE B / Is Open and Close the same
         // RULE J / lower wick equals zero
         // RULE K / upper wick not equal to zero
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC ) ;
         return ( result ) ; }

      string IsCandle_Bullish_Engulfing ( string FirstCandleRules="DEF" , string SecondCandleRules="C" ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- x
         string result = "" ;
         // RULE D / Is candle bullish ( Current )
         // RULE E / Is current body max higher than last body max
         // RULE F / Is current body min lower than last body min
         result += prvCandle_Analytics ( FirstCandleRules , glb_FC ) ;
         // RULE C / Is candle bearish ( Last )
         result += prvCandle_Analytics ( SecondCandleRules , ( glb_FC + 1 ) ) ;
         if ( sFind ( result , "X" ) ) { return "X" ; }
         return ( result ) ; }

      string IsCandle_Bearish_Engulfing ( string FirstCandleRules="CEF" , string SecondCandleRules="D" ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- x
         string result = "" ;
         // RULE C / Is candle bearish ( Current )
         // RULE E / Is current body max higher than last body max
         // RULE F / Is current body min lower than last body min
         result += prvCandle_Analytics ( FirstCandleRules , glb_FC ) ;
         // RULE D / Is candle bullish ( Last )
         result += prvCandle_Analytics ( SecondCandleRules , ( glb_FC + 1 ) ) ;
         if ( sFind ( result , "X" ) ) { return "X" ; }
         return ( result ) ; }

      string IsCandle_Hammer ( string CandleRules="DIO", double WickRatio=0.5 ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- x
         // RULE D / Is candle bullish
         // RULE I / upper wick equals zero
         // RULE O / lower wick bigger than 50%
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC , WickRatio ) ;
         return ( result ) ; }

      string IsCandle_Hangingman ( string CandleRules="CIO" , double WickRatio=0.5 ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- x
         // RULE C / Is candle bearish
         // RULE I / upper wick equals zero
         // RULE O / lower wick bigger than 50%
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC , WickRatio ) ;
         return ( result ) ; }

      string IsCandle_Marubozu ( string CandleRules="AMIJ" , double ATRFactor=1.25 ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- x
         // RULE A / Is Range more that 1.25 ATR Multiple
         // RULE M / Is candle body not equal to zero
         // RULE I / upper wick equals zero
         // RULE J / lower wick equals zero
         string result = "" ;
         result += prvCandle_Analytics ( CandleRules , glb_FC , ATRFactor ) ;
         return ( result ) ; }

      string IsCandle_Tweezer_Tops ( string FirstCandleRules="ILMQ" , string SecondCandleRules="ILM" ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- x
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
         if ( sFind ( result , "X" ) ) { return "X" ; }
         return ( result ) ; }

      string IsCandle_Tweezer_Bottoms ( string FirstCandleRules="JKMR" , string SecondCandleRules="JKM" ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         if ( glb_RobotDisabled ) { return ( "X" ) ; }
         // -------------------- x
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
         if ( sFind ( result , "X" ) ) { return "X" ; }
         return ( result ) ; }

   //===========================================================================================================
   //=====                                        SNR HTML TEMPLATE                                        =====
   //===========================================================================================================

   void goSNR_HTML_Header ( string safRules="3" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
      if ( sFind ( safRules , "A" ) ) {
         prvA2H ( ".perf-section{width:55%;float:left;}" ) ;
         prvA2H ( ".perf-header{float:left;display:flex;justify-content: center;font-size: 1.5em;color:var(--clr5)}" ) ;
         prvA2H ( ".perf-main{float:left;display:flex;justify-content: center;font-size: 6em;margin-top: 20px;}" ) ;
         prvA2H ( ".perf-submain{float:left;display:flex;justify-content: center;font-size: 3.5em;}" ) ;
         prvA2H ( ".perf-table-text{margin-bottom: 12px;font-size: 1.3em;}" ) ;
         prvA2H ( ".perf-table-number{margin-bottom: 12px;font-size: 1.3em;text-align:right;}" ) ; }
      if ( sFind ( safRules , "B" ) ) {
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
      if ( sFind ( safRules , "5" ) ) { prvA2H ( "<a id='backbutton'>BACK</a>" ) ; }
      if ( sFind ( safRules , "1" ) ) { prvA2H ( "<a href='http://snrpro.dk/'>SEARCH</a>" ) ; }
      if ( sFind ( safRules , "2" ) ) { prvA2H ( "<a href='https://snrobotix.com'>HOME</a>" ) ; }
      if ( sFind ( safRules , "3" ) ) { prvA2H ( "<a href='mailto:hello@snrobotix.com'>CONTACT US</a>" ) ; }
      prvA2H ( "</div>" ) ; // End of Links
      prvA2H ( "</div>" ) ; // End of NavBar
      prvA2H ( "</div>" ) ; // End of NavBarBox
      if ( sFind ( safRules , "4" ) ) {
         prvA2H ( "<div class='contentbox h80'>" ) ; // Start of ContentBox
      } else {
         prvA2H ( "<div class='contentbox'>" ) ; }} // Start of ContentBox all screen height

   void goSNR_HTML_Footer ( string safRules="1" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      // RULE 1: Add Last Update footer
      // RULE 2: Add copyright footer
      prvA2H ( "</div>" ) ; // End of ContentBox
      prvA2H ( "<div class='footerbox'>" ) ; // Start of Footer
      if ( sFind ( safRules , "1" ) ) {
         prvA2H ( "Last updated: " + string ( TimeGMT() ) + " GMT" ) ; }
      else if ( sFind ( safRules , "2" ) ) {
         string safThisYear = StringSubstr ( goGetDateTime() , 0 , 2 ) ;
         string safCopyRight = "\x00A9" ;
         prvA2H ( "<p>" + safCopyRight + " 2022-20" + safThisYear + " SNRobotiX ApS. All Rights Reserved. | Applebys Pl. 7, 1411 København | Email:<a href='mailto:hello@snrobotix.com'>hello@snrobotix.com</a></p>" ) ; }
      prvA2H ( "</div>" ) ; // End of Footer
      prvA2H ( "</body>" ) ; // End of Body
      prvA2H ( "</html>" ) ; // End of HTML
      // -------------------- Write remaining data before closing here
      goPrint ( "Data sent to server in " + string ( prvA2H ( "--FLUSH--" ) ) + " bits " ) ; }

   //===========================================================================================================
   //=====                                        SNR WEBSITE PAGES                                        =====
   //===========================================================================================================

   void goSNR_HTML_SearchPage () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
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
   //=====                                      GENERAL FUNCTIONS                                          =====
   //===========================================================================================================

   void goClearBuffers () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      ArrayResize ( B0 , 0 , 0 ) ;
      ArrayResize ( B1 , 0 , 0 ) ;
      ArrayResize ( B2 , 0 , 0 ) ;
      ArrayResize ( B3 , 0 , 0 ) ;
      ArrayResize ( B4 , 0 , 0 ) ; }

   void goOnInit ( string sBotType ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      //// if ( glb_RobotDisabled ) { return ; }
      // -------------------- Decide if LIVE or TESTER/OPTIMZER
      if ( MQLInfoInteger ( MQL_TESTER ) ) { glb_IsThisLive = false ; }
      if ( MQLInfoInteger ( MQL_OPTIMIZATION ) ) { glb_IsThisLive = false ; }
      // -------------------- Expiry date check
      if ( goSecurity_CheckExpiryDate ( datetime("2025.01.01") , 180 ) == false ) {
         glb_RobotDisabled = true ;
         goPrint ( "Trading disabled due to expiry check" ) ;
         return ; }
      // -------------------- Check version for bots in LIVE mode
      if ( glb_IsThisLive == true ) {
         if ( goSecurity_VersionCheck ( sBotType ) == false ) {
            glb_RobotDisabled = true ;
            goPrint ( "Trading disabled due to version check" ) ;
            return ; }}
      // -------------------- If checks passed then activate robot
      glb_RobotDisabled = false ;
      // -------------------- Set some variables
      glb_StartBalance = sBal() ;
      // -------------------- Initialize if chart changed
      glb_EAS = _Symbol ;
      glb_EAP = _Period ;
      // -------------------- Order price array correctly
      ArraySetAsSeries ( glb_PI , true ) ;
      ArraySetAsSeries ( B0 , true ) ;
      ArraySetAsSeries ( B1 , true ) ;
      ArraySetAsSeries ( B2 , true ) ;
      ArraySetAsSeries ( B3 , true ) ;
      ArraySetAsSeries ( B4 , true ) ;
      // -------------------- Prep Symbol array
      string safSymbols =  "EURUSD|GBPUSD|EURGBP|USDJPY|CHFJPY|EURCHF|EURJPY|GBPCHF|GBPJPY|USDCHF|" ;
             safSymbols += "AUDCAD|AUDCHF|AUDJPY|AUDUSD|CADCHF|CADJPY|EURAUD|EURCAD|GBPAUD|GBPCAD|USDCAD" ;
             // safSymbols += "|NZDCAD|NZDCHF|EURNZD|AUDNZD|GBPNZD|NZDJPY|NZDUSD" ;
      StringSplit ( safSymbols , 124 , glb_SymbolArray ) ; }

   bool goOnTick (
      double &safATR ,
      double safATRFactor=0.5 ,
      int safATRPeriod=14 ,
      int safMonStartHour=8 ,
      int safFriEndHour=14 ,
      int safMarginCutOff=500 ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- Abort checks
         // if ( glb_RobotDisabled ) { return false ; }
         // -------------------- x
         glb_MinsSinceTrade += 1 ;
         // -------------------- Set ATR
         if ( safATRPeriod > 0 ) {
            // -------------------- x
            if ( !ind_ATR ( safATRPeriod ) ) { return false ; }
            safATR = B0 [ glb_FC ] ;
            // -------------------- Spread / ATR check
            if ( safATRFactor > 0 ) {
               if ( ( sAsk() - sBid() ) > ( safATR * safATRFactor ) ) {
                  // goPrint ( "Spread too big" ) ;
                  return false ; }}}
         // -------------------- Non indicator filters
         if ( safMonStartHour > 0 ) { if ( goDelayMondayStart ( safMonStartHour ) == "X" ) { return false ; }}
         if ( safFriEndHour > 0 ) { if ( goEndFridayEarly ( ( safFriEndHour ) ) == "X" ) { return false ; }}
         if ( IsDay_NoTradeDay () ) { return false ; }
         // -------------------- check margin level
         if ( safMarginCutOff > 0 ) {
            if ( sMarginLevel() < safMarginCutOff ) {
               // goPrint ( "Insufficient margin" ) ;
               return false ; }}
         // -------------------- x
         return true ; }

   string UT ( string safInput ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      goTrim ( safInput ) ;
      StringToUpper ( safInput ) ;
      return safInput ; }

   string goTrim ( string safInput ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      StringTrimLeft ( safInput ) ;
      StringTrimRight ( safInput ) ;
      return safInput ; }

   string goCleanSignal ( string safSignal ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- Variable
      string result = "" ;
      // -------------------- x
      if ( sFind ( safSignal , "X" ) ) { return "X" ; }
      // -------------------- Processing happens here
      StringReplace ( safSignal , "Y" , "" ) ;
      StringReplace ( safSignal , "C" , "" ) ;
      StringReplace ( safSignal , "T" , "" ) ;
      // -------------------- Buy signal
      string goBuy = safSignal ; StringReplace ( goBuy , "B" , "" ) ; if ( goBuy == "" ) { result += "B" ; }
      // -------------------- Sell signal
      string goSel = safSignal ; StringReplace ( goSel , "S" , "" ) ; if ( goSel == "" ) { result += "S" ; }
      // -------------------- Confused signal
      if ( ( goBuy == "" ) && ( goSel == "" ) ) { return "X" ; }
      // -------------------- x
      return result ; }

   string goReverseSignal ( string safString ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ( "X" ) ; }
      // -------------------- x
      StringReplace ( safString , "B" , "A" ) ;
      StringReplace ( safString , "S" , "B" ) ;
      StringReplace ( safString , "A" , "S" ) ;
      return safString ; }

   bool GCS ( string safSignal ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return false ; }
      // -------------------- if there is an x then return false
      if ( sFind ( safSignal , "X" ) ) { return false ; }
      // -------------------- if there is a b and s at the same time then also return false
      if ( sFind ( safSignal , "B" ) ) {
         if ( sFind ( safSignal , "S" )  ) { return false ; }}
      // -------------------- finally if its only b or s only then return true
      return true ; }

   double ND ( double safInput ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return NormalizeDouble ( MathRound ( safInput , sDigits() ) , sDigits() ) ; }

   double ND2 ( double safInput ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      string result = string ( NormalizeDouble ( MathRound ( safInput , 2 ) , 2 ) ) ;
      int safLoc = StringFind ( result , "." ) ;
      if ( safLoc == -1 ) { return double ( result ) ; }
      int safLength = StringLen ( result ) ;
      if ( safLength > safLoc + 3 ) { result = StringSubstr ( result , 0 , ( safLoc + 3 ) ) ; }
      return double ( result ) ; }

   double sAsk ( string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( sCurr == "" ) { sCurr = glb_EAS ; }
      return ND ( SymbolInfoDouble ( sCurr , SYMBOL_ASK ) ) ; }

   double sBid ( string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( sCurr == "" ) { sCurr = glb_EAS ; }
      return ND ( SymbolInfoDouble ( sCurr , SYMBOL_BID ) ) ; }

   double sBal () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return AccountInfoDouble ( ACCOUNT_BALANCE ) ; }

   double sEqu () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return AccountInfoDouble ( ACCOUNT_EQUITY ) ; }

   double sMax ( string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( sCurr == "" ) { sCurr = glb_EAS ; }
      return ND2 ( SymbolInfoDouble ( sCurr , SYMBOL_VOLUME_MAX ) ) ; }

   double sMin ( string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( sCurr == "" ) { sCurr = glb_EAS ; }
      return ND2 ( SymbolInfoDouble ( sCurr ,SYMBOL_VOLUME_MIN ) ) ; }

   double sProfit () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return PositionGetDouble ( POSITION_PROFIT ) + PositionGetDouble ( POSITION_SWAP ) ; }

   double sFreeMargin () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      return AccountInfoDouble ( ACCOUNT_MARGIN_FREE ) ; }

   double sMarginLevel () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      double safEquity = sEqu() ;
      // double safUsedMargin = safEquity - sFreeMargin() ;
      // double safMarginLevel = ( safEquity / safUsedMargin ) * 100 ;
      // double safMarginLevel = AccountInfoDouble ( ACCOUNT_MARGIN_LEVEL ) ;
      return ( ( safEquity / ( safEquity - sFreeMargin() ) ) * 100 ) ; }

   void goPrint ( string safString ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( glb_VerboseMode ) { Print ( ">   >   >   >   > " + safString ) ; }}

   int sPow ( double safInput ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
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

   double sSpread ( string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( sCurr == "" ) { sCurr = glb_EAS ; }
      return ( SymbolInfoInteger ( sCurr , SYMBOL_SPREAD ) * sPoint() ) ; }

   int sDigits ( string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( sCurr == "" ) { sCurr = glb_EAS ; }
      return int ( SymbolInfoInteger ( sCurr , SYMBOL_DIGITS ) ) ; }

   double sPoint ( string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      if ( sCurr == "" ) { sCurr = glb_EAS ; }
      return SymbolInfoDouble ( sCurr , SYMBOL_POINT ) ; }

   bool sFind ( string sFindIn , string sFindThis ) {
      if ( StringFind ( sFindIn , sFindThis , 0 ) >= 0 ) { return ( true ) ; }
      return ( false ) ; }

   int sRandomNumber ( int safMinValue, int safMaxValue ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
      double safRand = double ( MathRand() ) / 32767 ;
      return int ( MathMin ( safMaxValue , safMinValue + ( ( safMaxValue + 1 - safMinValue ) * safRand ) ) ) ; }

   void goSunsetRobot ( string safSunsetDate , string safSettings ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( StringLen ( safSunsetDate ) < 1 ) { return ; }
      if ( long ( StringSubstr ( goGetDateTime () , 0 , 6 ) ) > long ( safSunsetDate ) ) {
         goBroadcast_OPS ( goTele_PrepMsg ( glb_Magic , "BEACON" , "SUNSET" , safSettings ) ) ;
         ExpertRemove () ; }}

   string goCleanString ( string safInput ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      string safAllowedCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890" ;
      string result = "";
      // -------------------- x
      for ( int i = 0 ; i < StringLen ( safInput ) ; i++ ) {
         string safLetter = StringSubstr ( safInput , i , 1 ) ;
         if ( sFind ( safAllowedCharacters , safLetter ) ) { result += safLetter ; }}
      // -------------------- x
      return result ; }

   bool goCheck_ConfigString ( string safConfigString ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- Variables
      safConfigString = UT ( safConfigString ) ;
      // -------------------- Config String symbol check
      string Symbol2Use = glb_EAS ;
      StringReplace ( Symbol2Use , "." , "" ) ;
      if ( !sFind ( safConfigString , UT ( Symbol2Use ) ) ) {
         goPrint ( " Incorrect Config String versus Chart !" ) ;
         glb_RobotDisabled = true ;
         return false ; }
      // -------------------- Config String broker check
      if ( sFind ( safConfigString , goTranslate_Broker() ) ) { return ( true ) ; }
      goPrint ( " Incorrect broker for Config String !" ) ;
      glb_RobotDisabled = true ;
      return false ; }

   bool goExtract_ConfigString ( string safConfigString , string &safSplit[] ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      ArrayResize ( safSplit , 0 ) ;
      safConfigString = UT ( safConfigString ) ;
      // -------------------- Temp remove SOS
      StringReplace ( safConfigString , "|SOS|" , "" ) ;
      // -------------------- x
      int safLoc = StringFind ( safConfigString , "|EOS|" , 0 ) ;
      if ( safLoc < 0 ) {
         goPrint ( "Old config string format!" ) ;
         glb_RobotDisabled = true ;
         return ( false ) ; }
      // -------------------- x
      safConfigString = StringSubstr ( safConfigString , 0 , safLoc ) ;
      StringSplit ( safConfigString , 124 , safSplit ) ;
      // -------------------- x
      return ( true ) ; }

   string goTranslate_Broker () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      string safBroker = UT ( AccountInfoString ( ACCOUNT_COMPANY ) ) ;
      if ( sFind ( safBroker , "BLUEBERRY" ) ) { return "BB" ; }
      else if ( sFind ( safBroker , "EIGHTCAP" ) ) {
         if ( sFind ( UT ( AccountInfoString ( ACCOUNT_SERVER ) ) , "GLOBAL" ) ) { return "8CAPG" ; } return "8CAP" ; }
      else if ( sFind ( safBroker , "MEX" ) ) { return "MB" ; }
      else if ( sFind ( safBroker , "VANTAGE" ) ) { return "VAN" ; }
      else if ( sFind ( safBroker , "TRADEVIEW" ) ) { return "TVM" ; }
      else if ( sFind ( safBroker , "METAQUOTE" ) ) { return "MQ" ; }
      return ( safBroker ) ; }

   string goCleanFileName ( string safFN ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      string result = safFN ;
      StringReplace ( result , "XL" , "" ) ;
      StringReplace ( result , ".mq5" , "" ) ;
      StringReplace ( result , ".mqh" , "" ) ;
      StringReplace ( result , ".ex5" , "" ) ;
      return ( result ) ; }

   string goFind_BotType ( string safInput2Check ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
      // -------------------- x
      string safBotType = "TR3" , safAddOn = "" ;
      // -------------------- x
      if ( sFind ( UT ( safInput2Check ) , "TR4" ) ) { safBotType = "TR4" ; }
      if ( sFind ( UT ( safInput2Check ) , "TR5" ) ) { safBotType = "TR5" ; }
      if ( sFind ( UT ( safInput2Check ) , "TRA" ) ) { safBotType = "TRA" ; }
      if ( sFind ( UT ( safInput2Check ) , "NSSR" ) ) { safBotType = "nSSR" ; }
      // -------------------- x
      if ( sFind ( UT ( safInput2Check ) , "_SL" ) ) { safAddOn = "-SL" ; }
      if ( sFind ( UT ( safInput2Check ) , "-SL" ) ) { safAddOn += "-SL" ; }
      // -------------------- x
      return ( safBotType + safAddOn ) ; }

   string goFormat_NumberWithCommas ( string safInput ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( "ROBOT_DISABLED" ) ; }
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

   //===========================================================================================================
   //=====                                           APP HISTORY                                           =====
   //===========================================================================================================

   void goHistory_Send2Server () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- Date for telegram deposit / withdraw messages
      string safYesterday = StringSubstr ( goGetDateTime ( ( 1 * 60 * 60 * 24 ) ) , 0 , 6 ) ;
      // -------------------- Get history for period
      string HistoryLines[] ;
      string AppHistoryLines[] ;
      string AppMonthlyLines[] ;
      goHistory_Retreive ( HistoryLines ) ;
      if ( ArraySize ( HistoryLines ) < 1 ) { return ; }
      // -------------------- Variables
      string LastMonth = "" , DealTypeTrans = "" , oTradedCurr = "" , mTradedCurr = "" ;
      double LastLot = 0  , LastProfit = 0  , LastSwap = 0  , LastFee = 0  , LastComm = 0  , LastNetProfit = 0  , LastBalance = 0  ;
      double totalLot = 0 , totalProfit = 0 , totalSwap = 0 , totalFee = 0 , totalComm = 0 , totalNetProfit = 0 , totalBalance = 0 ;
      double totalDeposit = 0 , totalWithdrawal = 0 , totalCredit = 0 , totalAdjust = 0 ;
      int LastTrades = 0 , totalTrades = 0 , totTradedCurr = 0 , monTradedCurr = 0 ;
      double DailyROI = 0 , MonthROI = 0 , LOKAAdjust = 0 , AccountNetDeposit = 0 ;
      // -------------------- x
      static string LastComsMessage ;
      // -------------------- Start details file here
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
         string FinalMonthForApp = "" ;
         // -------------------- Go thru history line by line
         for ( int i=0 ; i < ArraySize ( HistoryLines ) ; i++ ) {
            string safSplit[] ; StringSplit ( HistoryLines [ i ] , 124 , safSplit ) ;
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
            string TodaysMonth = StringSubstr ( DealTimeTrans , 0 , 4 ) ; FinalMonthForApp = TodaysMonth ;
            // -------------------- LOKA SKIP
            if ( string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) == "6001227" ) {
               if ( TodaysDay == "220922" ) { LOKAAdjust = 602.18 ; continue ; }}
            // -------------------- Write Month Change data here
            if ( LastMonth != TodaysMonth ) {
               string TodaysMonthForApp = LastMonth ;
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
                  double safMonthlyProfit = ND2 ( totalNetProfit - LastNetProfit ) ;
                  prvA2H ( "<div class='field wp100 mobile'>" + string ( safMonthlyProfit ) + "</div>" ) ; LastNetProfit = totalNetProfit ;
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
                  prvA2H ( "</div>" ) ;
                  // -------------------- Add App month results
                  goArray_Add ( ( "|MV|" + TodaysMonthForApp + "|" + string ( safMonthlyProfit ) ) , AppMonthlyLines ) ;
                  goArray_Add ( ( "|MR|" + TodaysMonthForApp + "|" + string ( ND2 ( MonthROI ) ) ) , AppMonthlyLines ) ;
                  MonthROI = 0 ; }}
            // -------------------- Curr count
            if ( DealCurr != "" ) {
               // -------------------- Overall Curr
               if ( !sFind ( oTradedCurr , "|"+ DealCurr + "|" ) ) {
                  oTradedCurr +=  "|"+ DealCurr + "|" ; totTradedCurr += 1 ; }
               // -------------------- Month Curr
               if ( !sFind ( mTradedCurr , "|"+ DealCurr + "|" ) ) {
                  mTradedCurr +=  "|"+ DealCurr + "|" ; monTradedCurr += 1 ; }
               // -------------------- Calc profits
               totalProfit += DealProfit ;
               totalLot += DealLot ;
               totalSwap += DealSwap ;
               totalFee += DealFee ;
               totalComm += DealComm ;
               totalNetProfit += DealNetProfit ;
               totalTrades += 1 ; }
            // -------------------- Calculate total balance
            totalBalance += DealNetProfit ;
            // -------------------- Calculate Trade ROI
            double TradeROI = 0 ;
            if ( AccountNetDeposit > 0 ) {
               TradeROI = DealNetProfit / AccountNetDeposit * 100 ;
            } else {
               if ( totalCredit > 0 ) {
                  TradeROI = DealNetProfit / totalCredit * 100 ; }}
            // -------------------- Calculate commision trigger
            double safCommTrigger = totalBalance * 1.5 / 100 ;
            // -------------------- Clasification here
               // -------------------- BUY LINES HERE
               if ( DealType == "BUY" ) {
                  DealTypeTrans = "Buy" ;
                  DailyROI += TradeROI ;
                  MonthROI += TradeROI ; }
               // -------------------- SELL LINES HERE
               else if ( DealType == "SELL" ) {
                  DealTypeTrans = "Sell" ;
                  DailyROI += TradeROI ;
                  MonthROI += TradeROI ; }
               // -------------------- BALANCE LINES HERE
               else if ( DealType == "BALANCE" ) {
                  // -------------------- Positive Balance line
                  if ( DealProfit > 0 ) {
                     // -------------------- Commision threshold
                     if ( DealProfit < safCommTrigger ) {
                        totalComm += DealProfit ;
                        DealTypeTrans = "Commission" ;
                        DailyROI += TradeROI ;
                        MonthROI += TradeROI ;
                        totalNetProfit += DealNetProfit ; }
                     // -------------------- DEPOSIT
                     else {
                        totalDeposit += DealProfit ;
                        DealTypeTrans = "Deposit" ;
                        // -------------------- Send telegram message
                        if ( TodaysDay >= safYesterday ) {
                           string S2W = TodaysDay + ": " + AccountInfoString ( ACCOUNT_NAME ) + " (" ;
                           S2W += string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) + ") - Deposit: " + string ( DealProfit ) ;
                           if ( S2W != LastComsMessage ) { goBroadcast_COM ( S2W ) ; LastComsMessage = S2W ; }}
                        AccountNetDeposit += DealNetProfit ; }
                  // -------------------- Negative Balance line
                  } else {
                     // -------------------- Commision threshold
                     if ( DealProfit > ( -1 * safCommTrigger ) ) {
                        totalComm += DealProfit ;
                        DealTypeTrans = "Commission" ;
                        DailyROI += TradeROI ;
                        MonthROI += TradeROI ;
                        totalNetProfit += DealNetProfit ; }
                     // -------------------- WITHDRAW
                     else {
                        totalWithdrawal += DealProfit ;
                        DealTypeTrans = "Withdraw" ;
                        // -------------------- Send telegram message
                        if ( TodaysDay >= safYesterday ) {
                           string S2W = TodaysDay + ": " + AccountInfoString ( ACCOUNT_NAME ) + " (" ;
                           S2W += string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) + ") - Withdraw: " + string ( DealProfit ) ;
                           if ( S2W != LastComsMessage ) { goBroadcast_COM ( S2W ) ; LastComsMessage = S2W ; }}
                        AccountNetDeposit += DealNetProfit ; }}}
               // -------------------- CREDIT LINES HERE
               else if ( DealType == "CREDIT" ) {
                  totalCredit += DealProfit ;
                  DealTypeTrans = "Credit" ; }
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
            goArray_Add ( AppResult , AppHistoryLines ) ; } // next i
         // -------------------- Last Month result
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
         // -------------------- Add App last month results
         goArray_Add ( "|MV|" + FinalMonthForApp + "|" + string ( ND2 ( totalNetProfit - LastNetProfit ) ) , AppMonthlyLines ) ;
         goArray_Add ( "|MR|" + FinalMonthForApp + "|" + string ( ND2 ( MonthROI ) ) , AppMonthlyLines ) ;
         // -------------------- Write overall totals here
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
      string safBroker = goTranslate_Broker () ;
      if ( safBroker == "BB"   ) { safBrokerLink = "https://portal.blueberrymarkets.com/en/sign-in" ; }
      if ( safBroker == "8CAP" ) { safBrokerLink = "https://portal.eightcap.com/en-US/auth/login" ; }
      if ( safBroker == "8CAPG" ) { safBrokerLink = "https://portal.eightcap.com/en-US/auth/login" ; }
      if ( safBroker == "MB"   ) { safBrokerLink = "https://my.multibankfx.com/en/traders/login" ; }
      if ( safBroker == "VAN"  ) { safBrokerLink = "https://secure.vantagemarkets.com/login" ; }
      if ( safBroker == "TVM"  ) { safBrokerLink = "https://www.tradeviewforex.com/cabinet/mt5" ; }
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
         prvA2H ( "                  <div class='perf-table-text'>Available:</div>" ) ;
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
         double safAVAEquity = sEqu() + LOKAAdjust ;
         double safAVABalance = totalBalance ;
         double safAvailable =  safAVAEquity - ( ( safAVABalance - safAVAEquity ) * 3 ) ;
         safAvailable = MathMin ( safAvailable , ( safAVAEquity - totalCredit ) ) ;
         safToolTip = "Available to withdraw: Suggested safe mount available to take out, while leaving room for open trades to breath" ;
         prvA2H ( "                  <div class='perf-table-number' title='" + safToolTip + "'>" + goFormat_NumberWithCommas ( string ( ND2 ( safAvailable ) ) ) + "</div>" ) ;
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
      string AllPositions[] ; goPositions_Retreive( AllPositions ) ;
      // -------------------- Write App file
      glb_ServerPath = "/PERFHIST/RAW/" ;
      glb_ServerFileName = string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) + ".raw" ;
      prvA2H ( "--NEWFILE--" ) ;
      // -------------------- x
      for ( int appC = 0 ; appC < ArraySize ( AppHistoryLines ) ; appC++ ) {
         // -------------------- Split line into bits
         string posArray[] ;
         StringSplit ( AppHistoryLines [ appC ] , 124 , posArray ) ;
         if ( ArraySize ( posArray ) < 10 ) { continue ; }
         string safTradeType = UT ( posArray [ 2 ] ) ;
         if ( safTradeType == "BUY" ) { safTradeType = "S" ; }
         if ( safTradeType == "SELL" ) { safTradeType = "B" ; }
         string S2W = "|HL|" + posArray [ 1 ] + "|" + safTradeType + "|" + posArray [ 4 ] + "|" + posArray [ 3 ] + "|" + posArray [ 9 ] + "|" ;
         prvA2H ( S2W ) ; }
      // -------------------- x
      for ( int appC = 0 ; appC < ArraySize ( AllPositions ) ; appC++ ) {
         // -------------------- Split line into bits
         string posArray[] ;
         StringSplit ( AllPositions [ appC ] , 124 , posArray ) ;
         if ( ArraySize ( posArray ) < 13 ) { continue ; }
         string safTradeType = UT ( posArray [ 3 ] ) ;
         if ( safTradeType == "BUY" ) { safTradeType = "B" ; }
         if ( safTradeType == "SELL" ) { safTradeType = "S" ; }
         string S2W = "|OP|" + safTradeType + "|" + posArray [ 2 ] + "|" ;
         S2W += string ( ND2 ( double ( posArray [ 4 ] ) ) ) + "|" + string ( ND2 ( double ( posArray [ 12 ] ) ) ) + "|" ;
         prvA2H ( S2W ) ; }
      // -------------------- x
      for ( int appC = 0 ; appC < ArraySize ( AppMonthlyLines ) ; appC++ ) {
         prvA2H ( AppMonthlyLines [ appC ] + "|" ) ; }
      // -------------------- x
      string safBrokerName = AccountInfoString ( ACCOUNT_COMPANY ) ;
      if ( sFind ( UT ( safBrokerName ) , "MEX" ) ) { safBrokerName = "Multibank Group" ; }
      prvA2H ( "|BN|" + safBrokerName + "|" ) ;
      prvA2H ( "|BL|" + safBrokerLink + "|" ) ;
      prvA2H ( "|BC|" + UT ( AccountInfoString ( ACCOUNT_CURRENCY ) ) + "|" ) ;
      prvA2H ( "|BAL|" + string ( ND2 ( totalBalance - totalCredit ) ) + "|" ) ;
      prvA2H ( "|ROI|" + string ( ND2 ( DailyROI ) ) + "|" ) ;
      prvA2H ( "|PNL|" + string ( ND2 ( totalNetProfit ) ) + "|" ) ;
      prvA2H ( "|DP|" + string ( ND2 ( totalDeposit ) ) + "|" ) ;
      prvA2H ( "|WD|" + string ( ND2 ( totalWithdrawal ) ) + "|" ) ;
      prvA2H ( "|CR|" + string ( ND2 ( totalCredit + totalAdjust ) ) + "|" ) ;
      prvA2H ( "|EQU|" + string ( ND2 ( sEqu() + LOKAAdjust ) ) + "|" ) ;
      prvA2H ( "|SWP|" + string ( ND2 ( totalSwap ) ) + "|" ) ;
      prvA2H ( "|FEE|" + string ( ND2 ( totalFee ) ) + "|" ) ;
      prvA2H ( "|COM|" + string ( ND2 ( totalComm ) ) + "|" ) ;
      prvA2H ( "|LOT|" + string ( ND2 ( totalLot ) ) + "|" ) ;
      prvA2H ( "|AVA|" + string ( ND2 ( safAvailable ) ) + "|" ) ;
      prvA2H ( "|LUT|" + string ( TimeGMT() ) + " GMT|" ) ;
      // prvA2H ( "|xxx|" + string ( xxx ) + "|" ) ;
      // -------------------- x
      goPrint ( "Data sent to server in " + string ( prvA2H ( "--FLUSH--" ) ) + " bits " ) ; }

   void goHistory_Send2App () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- Date for telegram deposit / withdraw messages
      string safYesterday = StringSubstr ( goGetDateTime ( ( 1 * 60 * 60 * 24 ) ) , 0 , 6 ) ;
      // -------------------- Get history for period
      string HistoryLines[] , AppHistoryLines[] , AppMonthlyLines[] ;
      // -------------------- x
      goHistory_Retreive ( HistoryLines ) ;
      if ( ArraySize ( HistoryLines ) < 1 ) { return ; }
      // -------------------- Variables
      string LastMonth = "" , DealTypeTrans = "" , FinalMonthForApp = "" ;
      double LastNetProfit = 0 , totalDeposit = 0 , totalWithdrawal = 0 , totalCredit = 0 , totalAdjust = 0 ;
      double totalLot = 0 , totalProfit = 0 , totalSwap = 0 , totalFee = 0 , totalComm = 0 , totalNetProfit = 0 ;
      double totalBalance = 0 , DailyROI = 0 , MonthROI = 0 , LOKAAdjust = 0 , AccountNetDeposit = 0 ;
      // -------------------- x
      static string LastComsMessage ;
         // -------------------- Go thru history line by line
         for ( int i=0 ; i < ArraySize ( HistoryLines ) ; i++ ) {
            // -------------------- x
            string safSplit[] ; StringSplit ( HistoryLines [ i ] , 124 , safSplit ) ;
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
            string TodaysMonth = StringSubstr ( DealTimeTrans , 0 , 4 ) ; FinalMonthForApp = TodaysMonth ;
            // -------------------- LOKA SKIP
            if ( string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) == "6001227" ) {
               if ( TodaysDay == "220922" ) { LOKAAdjust = 602.18 ; continue ; }}
            // -------------------- Write Month Change data here
            if ( LastMonth != TodaysMonth ) {
               string TodaysMonthForApp = LastMonth ;
               LastMonth = TodaysMonth ;
               if ( i != 0 ) {
                  double safMonthlyProfit = ND2 ( totalNetProfit - LastNetProfit ) ;
                  LastNetProfit = totalNetProfit ;
                  // -------------------- Add App month results
                  goArray_Add ( ( "|MV|" + TodaysMonthForApp + "|" + string ( safMonthlyProfit ) ) , AppMonthlyLines ) ;
                  goArray_Add ( ( "|MR|" + TodaysMonthForApp + "|" + string ( ND2 ( MonthROI ) ) ) , AppMonthlyLines ) ;
                  MonthROI = 0 ; }}
            // -------------------- Curr count
            if ( DealCurr != "" ) {
               // -------------------- Calc profits
               totalProfit += DealProfit ;
               totalLot += DealLot ;
               totalSwap += DealSwap ;
               totalFee += DealFee ;
               totalComm += DealComm ;
               totalNetProfit += DealNetProfit ; }
            // -------------------- Calculate total balance
            totalBalance += DealNetProfit ;
            // -------------------- Calculate Trade ROI
            double TradeROI = 0 ;
            if ( AccountNetDeposit > 0 ) {
               TradeROI = DealNetProfit / AccountNetDeposit * 100 ;
            } else {
               if ( totalCredit > 0 ) {
                  TradeROI = DealNetProfit / totalCredit * 100 ; }}
            // -------------------- Calculate commision trigger
            double safCommTrigger = totalBalance * 1.5 / 100 ;
            // -------------------- Clasification here
               // -------------------- BUY LINES HERE
               if ( DealType == "BUY" ) {
                  DealTypeTrans = "Buy" ;
                  DailyROI += TradeROI ;
                  MonthROI += TradeROI ; }
               // -------------------- SELL LINES HERE
               else if ( DealType == "SELL" ) {
                  DealTypeTrans = "Sell" ;
                  DailyROI += TradeROI ;
                  MonthROI += TradeROI ; }
               // -------------------- BALANCE LINES HERE
               else if ( DealType == "BALANCE" ) {
                  // -------------------- Positive Balance line
                  if ( DealProfit > 0 ) {
                     // -------------------- Commision threshold
                     if ( DealProfit < safCommTrigger ) {
                        totalComm += DealProfit ;
                        DealTypeTrans = "Commission" ;
                        DailyROI += TradeROI ;
                        MonthROI += TradeROI ;
                        totalNetProfit += DealNetProfit ; }
                     // -------------------- DEPOSIT
                     else {
                        totalDeposit += DealProfit ;
                        DealTypeTrans = "Deposit" ;
                        // -------------------- Send telegram message
                        if ( TodaysDay >= safYesterday ) {
                           string S2W = TodaysDay + ": " + AccountInfoString ( ACCOUNT_NAME ) + " (" ;
                           S2W += string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) + ") - Deposit: " + string ( DealProfit ) ;
                           if ( S2W != LastComsMessage ) { goBroadcast_COM ( S2W ) ; LastComsMessage = S2W ; }}
                        AccountNetDeposit += DealNetProfit ; }
                  // -------------------- Negative Balance line
                  } else {
                     // -------------------- Commision threshold
                     if ( DealProfit > ( -1 * safCommTrigger ) ) {
                        totalComm += DealProfit ;
                        DealTypeTrans = "Commission" ;
                        DailyROI += TradeROI ;
                        MonthROI += TradeROI ;
                        totalNetProfit += DealNetProfit ; }
                     // -------------------- WITHDRAW
                     else {
                        totalWithdrawal += DealProfit ;
                        DealTypeTrans = "Withdraw" ;
                        // -------------------- Send telegram message
                        if ( TodaysDay >= safYesterday ) {
                           string S2W = TodaysDay + ": " + AccountInfoString ( ACCOUNT_NAME ) + " (" ;
                           S2W += string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) + ") - Withdraw: " + string ( DealProfit ) ;
                           if ( S2W != LastComsMessage ) { goBroadcast_COM ( S2W ) ; LastComsMessage = S2W ; }}
                        AccountNetDeposit += DealNetProfit ; }}}
               // -------------------- CREDIT LINES HERE
               else if ( DealType == "CREDIT" ) {
                  totalCredit += DealProfit ;
                  DealTypeTrans = "Credit" ; }
            // -------------------- Write for app raw data
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
            goArray_Add ( AppResult , AppHistoryLines ) ; } // next i
         // -------------------- Add App month results
         goArray_Add ( ( "|MV|" + FinalMonthForApp + "|" + string ( ND2 ( totalNetProfit - LastNetProfit ) ) ) , AppMonthlyLines ) ;
         goArray_Add ( ( "|MR|" + FinalMonthForApp + "|" + string ( ND2 ( MonthROI ) ) ) , AppMonthlyLines ) ;
      // -------------------- Set broker login link
      string safBrokerLink = "https://snrobotix.com/get-started/" ;
      string safBroker = goTranslate_Broker () ;
      if ( safBroker == "BB"   ) { safBrokerLink = "https://portal.blueberrymarkets.com/en/sign-in" ; }
      if ( safBroker == "8CAP" ) { safBrokerLink = "https://portal.eightcap.com/en-US/auth/login" ; }
      if ( safBroker == "8CAPG" ) { safBrokerLink = "https://portal.eightcap.com/en-US/auth/login" ; }
      if ( safBroker == "MB"   ) { safBrokerLink = "https://my.multibankfx.com/en/traders/login" ; }
      if ( safBroker == "VAN"  ) { safBrokerLink = "https://secure.vantagemarkets.com/login" ; }
      if ( safBroker == "TVM"  ) { safBrokerLink = "https://www.tradeviewforex.com/cabinet/mt5" ; }
      // -------------------- x
      double safAVAEquity = sEqu() + LOKAAdjust ;
      double safAvailable =  safAVAEquity - ( ( totalBalance - safAVAEquity ) * 3 ) ;
      safAvailable = MathMin ( safAvailable , ( safAVAEquity - totalCredit ) ) ;
      // -------------------- Write App file
      glb_ServerPath = "/PERFHIST/RAW/" ;
      glb_ServerFileName = string ( AccountInfoInteger ( ACCOUNT_LOGIN ) ) + ".raw" ;
      prvA2H ( "--NEWFILE--" ) ;
      // -------------------- x
      for ( int appC = 0 ; appC < ArraySize ( AppHistoryLines ) ; appC++ ) {
         // -------------------- Split line into bits
         string posArray[] ; StringSplit ( AppHistoryLines [ appC ] , 124 , posArray ) ;
         if ( ArraySize ( posArray ) < 10 ) { continue ; }
         // -------------------- x
         string safTradeType = UT ( posArray [ 2 ] ) ;
         if ( safTradeType == "BUY" ) { safTradeType = "S" ; }
         if ( safTradeType == "SELL" ) { safTradeType = "B" ; }
         string S2W = "|HL|" + posArray [ 1 ] + "|" + safTradeType + "|" + posArray [ 4 ] + "|" + posArray [ 3 ] + "|" + posArray [ 9 ] + "|" ;
         prvA2H ( S2W ) ; }
      // -------------------- Get open positions for app
      string AllPositions[] ; goPositions_Retreive( AllPositions ) ;
      for ( int appC = 0 ; appC < ArraySize ( AllPositions ) ; appC++ ) {
         // -------------------- Split line into bits
         string posArray[] ;
         StringSplit ( AllPositions [ appC ] , 124 , posArray ) ;
         if ( ArraySize ( posArray ) < 13 ) { continue ; }
         string safTradeType = UT ( posArray [ 3 ] ) ;
         if ( safTradeType == "BUY" ) { safTradeType = "B" ; }
         if ( safTradeType == "SELL" ) { safTradeType = "S" ; }
         string S2W = "|OP|" + safTradeType + "|" + posArray [ 2 ] + "|" ;
         S2W += string ( ND2 ( double ( posArray [ 4 ] ) ) ) + "|" + string ( ND2 ( double ( posArray [ 12 ] ) ) ) + "|" ;
         prvA2H ( S2W ) ; }
      // -------------------- x
      for ( int appC = 0 ; appC < ArraySize ( AppMonthlyLines ) ; appC++ ) {
         prvA2H ( AppMonthlyLines [ appC ] + "|" ) ; }
      // -------------------- x
      string safBrokerName = AccountInfoString ( ACCOUNT_COMPANY ) ;
      if ( sFind ( UT ( safBrokerName ) , "MEX" ) ) { safBrokerName = "Multibank Group" ; }
      prvA2H ( "|BN|" + safBrokerName + "|" ) ;
      prvA2H ( "|BL|" + safBrokerLink + "|" ) ;
      prvA2H ( "|BC|" + UT ( AccountInfoString ( ACCOUNT_CURRENCY ) ) + "|" ) ;
      prvA2H ( "|BAL|" + string ( ND2 ( totalBalance - totalCredit ) ) + "|" ) ;
      prvA2H ( "|ROI|" + string ( ND2 ( DailyROI ) ) + "|" ) ;
      prvA2H ( "|PNL|" + string ( ND2 ( totalNetProfit ) ) + "|" ) ;
      prvA2H ( "|DP|" + string ( ND2 ( totalDeposit ) ) + "|" ) ;
      prvA2H ( "|WD|" + string ( ND2 ( totalWithdrawal ) ) + "|" ) ;
      prvA2H ( "|CR|" + string ( ND2 ( totalCredit + totalAdjust ) ) + "|" ) ;
      prvA2H ( "|EQU|" + string ( ND2 ( sEqu() + LOKAAdjust ) ) + "|" ) ;
      prvA2H ( "|SWP|" + string ( ND2 ( totalSwap ) ) + "|" ) ;
      prvA2H ( "|FEE|" + string ( ND2 ( totalFee ) ) + "|" ) ;
      prvA2H ( "|COM|" + string ( ND2 ( totalComm ) ) + "|" ) ;
      prvA2H ( "|LOT|" + string ( ND2 ( totalLot ) ) + "|" ) ;
      prvA2H ( "|AVA|" + string ( ND2 ( safAvailable ) ) + "|" ) ;
      prvA2H ( "|LUT|" + string ( TimeGMT() ) + " GMT|" ) ;
      // -------------------- x
      goPrint ( "Data sent to server in " + string ( prvA2H ( "--FLUSH--" ) ) + " bits " ) ; }

   int prvA2H ( string safInput , int safMaxLength=500 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ( -1 ) ; }
      // -------------------- x
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
         goServer_Write_String ( goURLEncode ( safString2Write ) , safWriteType ) ; Sleep ( 25 ) ;
         if ( safInput == "--FLUSH--" ) { safString2Write = "" ; } else { safString2Write = safInput ; }
         safCount += 1 ; } return safCount ; }

   //===========================================================================================================
   //=====                                          COUNTER TRADE                                          =====
   //===========================================================================================================

   bool goCheck_PositionsExists ( string sType="" , string sCurr="" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      if ( sType == "" ) { return ( false ) ; }
      if ( sCurr == "" ) { return ( false ) ; }
      if ( PositionsTotal () < 1 ) { return ( false ) ; } else { sCurr = UT ( sCurr ) ; sType = UT ( sType ) ; }
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- x
         if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }
         // -------------------- Calculation here
         if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_BUY ) {
            if ( sType == "B" ) { return ( true ) ; }}
         else if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_SELL ) {
            if ( sType == "S" ) { return ( true ) ; }}}
      // -------------------- x
      return ( false ) ; }

   void goCounterTrade_Check ( double sPerc=1 , bool sPositiveSwapOnly=true , int sCounterType=No_Counter , int sCounterSL=No_Counter_SL ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- Return checks
      if ( PositionsTotal () < 1 ) { return ; }
      if ( sCounterType == No_Counter ) { return ; }
      if ( sPerc == 0 ) { return ; }
      // -------------------- Capture current symbol
      string sCurr_Symbol = glb_EAS ;
         // -------------------- Set trigger to counter
         double safTrigger = sBal() * 0.01 * sPerc * -1 ;
         // -------------------- Go thru positions one by one
         for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
            // -------------------- Select by ticket or else move on
            ulong posTicket = PositionGetTicket ( i ) ;
            if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
            // -------------------- Check for V2 = Countertrade ok
            if ( !sFind ( PositionGetString ( POSITION_COMMENT ) , "/V2/" ) ) { continue ; }
            // -------------------- Get position loss, if no loss move on
            double posLoss = PositionGetDouble ( POSITION_PROFIT ) + PositionGetDouble ( POSITION_SWAP ) ;
            if ( posLoss >= 0 ) { continue ; }
            // -------------------- If loss is not above trigger then move on
            if ( posLoss > safTrigger ) { continue ; }
            // -------------------- Get symbol
            string posCurr = PositionGetString ( POSITION_SYMBOL ) ;
            glb_EAS = posCurr ;
            // -------------------- Get type neede for counter
            string posType2Check = "" ;
            if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_BUY ) { posType2Check = "S" ; }
            else if ( PositionGetInteger ( POSITION_TYPE ) == POSITION_TYPE_SELL ) { posType2Check = "B" ; }
            if ( posType2Check == "" ) { continue ; }
            // -------------------- Check and skip if counter exists
            if ( goCheck_PositionsExists ( posType2Check , posCurr ) == true ) { continue ; }
            // -------------------- total move
            double safMove = MathAbs ( PositionGetDouble ( POSITION_PRICE_OPEN ) - PositionGetDouble ( POSITION_PRICE_CURRENT ) ) ;
            // -------------------- check that counter has positive swaps
            if ( posType2Check == "B" ) {
               if ( sPositiveSwapOnly ) { if ( SymbolInfoDouble ( posCurr , SYMBOL_SWAP_LONG ) < 0 ) { continue ; }}
                  double posLots = PositionGetDouble ( POSITION_VOLUME ) ;
                  goCounterTrade_Execute ( posCurr , posType2Check , posLots , sCounterType , sCounterSL , safMove ) ; }
            else if ( posType2Check == "S" ) {
               if ( sPositiveSwapOnly ) { if ( SymbolInfoDouble ( posCurr , SYMBOL_SWAP_SHORT ) < 0 ) { continue ; }}
                  double posLots = PositionGetDouble ( POSITION_VOLUME ) ;
                  goCounterTrade_Execute ( posCurr , posType2Check , posLots , sCounterType , sCounterSL , safMove ) ; }}
      // -------------------- Revert to bot symbol
      glb_EAS = sCurr_Symbol ; }

   void goCounterTrade_Execute (
      string posCurr , string posType2Check , double posLots , int sCounterType=No_Counter , int sCounterSL=No_Counter_SL , double safMove=0 ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         // if ( glb_RobotDisabled ) { return ; }
         // -------------------- Return checks
         if ( sCounterType == No_Counter ) { return ; }
         // -------------------- Variables
         double safMin = sMin ( posCurr ) ;
         double safMax = sMax ( posCurr ) ;
         // -------------------- Calc size here
         double sLot2Use = 0 ;
         if       ( sCounterType == Counter_Min )     { sLot2Use = safMin ; }
         else if  ( sCounterType == Counter_50 )      { sLot2Use = posLots * 0.5 ; }
         else if  ( sCounterType == Counter_75 )      { sLot2Use = posLots * 0.75 ; }
         else if  ( sCounterType == Counter_Equal )   { sLot2Use = posLots ; }
         else if  ( sCounterType == Counter_125 )     { sLot2Use = posLots * 1.25 ; }
         // -------------------- Lot checks
         if ( sLot2Use < safMin ) { sLot2Use = safMin ; }
         if ( sLot2Use > safMax ) { sLot2Use = safMax ; }
         sLot2Use = ND2 ( sLot2Use ) ;
         // -------------------- comment
         string safComment = "Counter/" ;
         if ( sCounterSL != No_Counter_SL ) { safComment += "NO-SL/" ; }
         // -------------------- SLV
         double safSLV = 0 ;
         if ( sCounterSL == Counter_SL_10 ) { safSLV = safMove * 0.10 ; }
         else if ( sCounterSL == Counter_SL_25 ) { safSLV = safMove * 0.25 ; }
         else if ( sCounterSL == Counter_SL_50 ) { safSLV = safMove * 0.50 ; }
         else if ( sCounterSL == Counter_SL_75 ) { safSLV = safMove * 0.75 ; }
         else if ( sCounterSL == Counter_SL_90 ) { safSLV = safMove * 0.90 ; }
         // -------------------- Buy counter
         if ( posType2Check == "B" ) { sBuy ( safSLV , 0 , 0 , sLot2Use , safComment + "B" ) ; }
         // -------------------- Sell counter
         else if ( posType2Check == "S" ) { sSell ( safSLV , 0 , 0 , sLot2Use , safComment + "S" ) ; }}

   //===========================================================================================================
   //=====                                      NEW ONTESTER FUNCTION                                      =====
   //===========================================================================================================

   void goTest_End () {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      Sleep ( 10000 ) ; goLocalFile_Write ( "restart.me" , "restart" , true ) ; }

   void goTest_WriteNextTestConfigFile ( string safBot , string safSetFile , string safFromDate ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      string S2W = "[Common]" + "\n" ;
      // S2W += "Login=" + "\n" ;
      // S2W += "Server=" + "\n" ;
      // S2W += "Password=" + "\n" ;
      // S2W += "KeepPrivate=1" + "\n" ;
      S2W += "NewsEnable=0" + "\n" ;
      S2W += "CertInstall=0" + "\n" ;
      S2W += "ExpertsFilesAccess=2" + "\n" ;
      // S2W += "[Experts]" + "\n" ;
      // S2W += "WebRequest=1" + "\n" ;
      // S2W += "WebRequestUrl=C7BA38A83DECE79D86E95DFD9951A4547D70EB6E9443B86EA00322C224DCE191F5E84ACD37E6DA9047AAC161F1A9F7A7CFC277FA3EEDE89E98FB53F3C57D4DFD877AA72AEF9EFFB577DA6C0C9E569848483BF57886358C42CE314FEF833BC777FEF127AA6716AB61A5082ACAD68E2CDCAA9D84074FFEE69C92F54DEDC27A32E29C8FCB4ECF7E5E14CC2F1BBBDC9415C5ADA0C84B8C3B6117C12446E6853DBC6C6659981B25D431E766C9BF5FFDB5" + "\n" ;
      S2W += "[Tester]" + "\n" ;
      S2W += "Expert=" + goCleanFileName ( safBot ) + "\n" ;
      S2W += "ExpertParameters=" + safSetFile + ".set" + "\n" ;
      S2W += "Symbol=" + goSymbols_GetNext() + "\n" ;
      S2W += "Period=M1" + "\n" ;
      // -------------------- 0-Every tick, 1-1 minute OHLC, 2-Open price only, 3-Math calculations, 4-Every tick based on real ticks
      S2W += "Model=4" + "\n" ;
      S2W += "ExecutionMode=150" + "\n" ;
      // -------------------- 0-optimization disabled, 1-Slow complete algorithm, 2-Fast genetic based algorithm, 3-All symbols selected in Market Watch
      S2W += "Optimization=2" + "\n" ;
      S2W += "OptimizationCriterion=0" + "\n" ;
      S2W += "FromDate=" + safFromDate + "\n" ;
      S2W += "ToDate=2038.01.01" + "\n" ;
      S2W += "ForwardMode=0" + "\n" ;
      S2W += "Deposit=10000" + "\n" ;
      // S2W += "Currency=USD" + "\n" ;
      S2W += "Currency=" + AccountInfoString ( ACCOUNT_CURRENCY ) + "\n" ;
      S2W += "Leverage=1:100" + "\n" ;
      S2W += "Visual=0" + "\n" ;
      // -------------------- 0-No shutdown after test, 1-shutdown after test
      S2W += "ShutdownTerminal=0" + "\n" ;
      goLocalFile_Write ( "snrconfig.ini" , S2W , true ) ; }

   double goTest_During ( string ConfigString , string sFilters ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return 0 ; }
      // -------------------- x
      string safArray[] ; StringSplit ( sFilters , 124 , safArray ) ;
      if ( ArraySize ( safArray ) < 5 ) { return -1 ; }
      // -------------------- x
      double filter_Profit = double ( safArray [ 0 ] ) ;
      double filter_RF     = double ( safArray [ 1 ] ) ;
      double filter_SR     = double ( safArray [ 2 ] ) ;
      int    filter_Trades = int    ( safArray [ 3 ] ) ;
      double filter_DD     = double ( safArray [ 4 ] ) ;
      // -------------------- x
      double test_Profit   = ND2 ( TesterStatistics ( STAT_PROFIT ) ) ;
      double test_RF       = ND2 ( TesterStatistics ( STAT_RECOVERY_FACTOR ) ) ;
      double test_SR       = ND2 ( TesterStatistics ( STAT_SHARPE_RATIO ) ) ;
      int test_Trades      = int ( TesterStatistics ( STAT_TRADES ) ) ;
      double test_DD       = ND2 ( MathMax ( TesterStatistics ( STAT_EQUITYDD_PERCENT ) ,
         TesterStatistics ( STAT_EQUITY_DDREL_PERCENT ) ) ) ;
      // -------------------- x
      if ( test_Profit <= filter_Profit ) { return -1 ; }
      if ( test_RF < filter_RF ) { return -1 ; }
      if ( test_SR < filter_SR ) { return -1 ; }
      if ( test_Trades < filter_Trades ) { return -1 ; }
      if ( test_DD > filter_DD ) { return -1 ; }
      // -------------------- x
      double test_PF       = ND2 ( TesterStatistics ( STAT_PROFIT_FACTOR ) ) ;
      double test_Result   = ND2 ( TesterStatistics ( STAT_INITIAL_DEPOSIT ) + test_Profit ) ;
      double test_EPO      = ND2 ( TesterStatistics ( STAT_EXPECTED_PAYOFF ) ) ;
      // -------------------- x
      double test_Criterion = ND2 ( test_Profit / test_DD ) ;
      // -------------------- x
      StringToLower ( ConfigString ) ;
      StringReplace ( ConfigString , "false" , "" ) ;
      // --------------------- x
      string safBroker     = goCleanString ( goTranslate_Broker() ) ;
      string safCurr       = goCleanString ( glb_EAS ) ;
      // -------------------- x
      // string S2W = glb_Magic + "_" + safBroker + "_" + safCurr + "," ; // Key of filename for end result
      string S2W = glb_Magic + "_" + safCurr + "," ; // Key of filename for end result
      S2W += (string) test_Result + "," + (string) test_Profit + "," + (string) test_EPO + "," ;
      S2W += (string) test_PF + "," + (string) test_RF + "," + (string) test_SR + "," + (string) test_Criterion ;
      S2W += "," + (string) test_DD + "," + (string) test_Trades + "," ;
      // -------------------- x
      S2W += "|SOS|" + ConfigString + "|EOS|" ; // ConfigString variables
      S2W += (string) test_Trades + "|" +  (string) test_DD + "|" + (string) test_RF + "|" + (string) test_SR ;
      S2W += "|" + safBroker + "_" + safCurr + "_" + UT ( AccountInfoString ( ACCOUNT_CURRENCY ) ) + "_" ;
      S2W += StringSubstr ( goGetDateTime() , 0 , 6 ) + "_" + string ( filter_DD ) + "_" + glb_Magic + "|" ;
      // -------------------- x
      goLocalFile_Write ( "RESULTS.txt" , S2W ) ;
      return ( test_Criterion ) ; }

   bool goTest_CheckRunTime ( long sMaxTime ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      string safFC [] ; goLocalFile_Read ( "TIME.txt" , safFC ) ;
      if ( ArraySize ( safFC ) < 1 ) { return true ; }
      // -------------------- x
      if ( long ( GetTickCount() ) - long ( safFC [ 0 ] ) > sMaxTime ) {
         goLocalFile_Write ( "restart.me" , "restart" , true ) ;
         return false ; }
      // -------------------- x
      return true ; }

   bool goTest_Start ( string safFN , string sBotName , string safSetFN , string safStartDate , string safFolder ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      goSymbols_CloseAllChartsExceptCurrent () ;
      // -------------------- x
      glb_BroadID = "SNR" ;
      // -------------------- x
      if ( !goSecurity_VersionCheck ( safFN ) ) {
         glb_RobotDisabled = true ;
         ExpertRemove () ;
         return ( false ) ; }
      // -------------------- x
      bool safSuccess = false ;
      int safTriesCount = 1 ;
      string safFC [] = {} ;
      // -------------------- x
      while ( safSuccess == false ) {
         // -------------------- x
         safSuccess = goLocalFile_Read ( "TIME.txt" , safFC ) ;
         // -------------------- x
         if ( ArraySize ( safFC ) > 3 ) {
            if ( ( safFC [ 3 ] ) != "SNR" ) { safSuccess = false ; }}
         else { safSuccess = false ; }
         // -------------------- x
         Sleep ( 5000 ) ; safTriesCount += 1 ; if ( safTriesCount >= 10 ) { return ( false ) ; }}
      // -------------------- x
      goTest_WriteResultsToServer ( safFolder , safStartDate ) ;
      // -------------------- x
      // if ( sFind ( UT ( glb_EAS ) , "EURUSD" ) ) { goTest_PrepSymbolWindow () ; }
      // -------------------- x
      string safTestTitle = sBotName + "_" + goCleanString ( goTranslate_Broker() ) + "_" + goCleanString ( glb_EAS ) ;
      // -------------------- x
      goLocalFile_Write ( "TIME.txt" , string ( GetTickCount() ) , true ) ;
      goLocalFile_Write ( "TIME.txt" , string ( TimeGMT() ) , false ) ;
      goLocalFile_Write ( "TIME.txt" , safTestTitle , false ) ;
      goLocalFile_Write ( "TIME.txt" , "SNR" , false ) ;
      // -------------------- x
      goLocalFile_Write ( "RESULTS.txt" , "ID,Result,Profit,Payoff,PF,RF,SR,Custom,DD%,Trades,ConfigString" , true ) ;
      // -------------------- x
      goTest_WriteNextTestConfigFile ( safFN , safSetFN , safStartDate ) ;
      // -------------------- x
      // goBroadcast_OTP ( safTestTitle + ": Started" ) ;
      // -------------------- x
      return true ; }

   void goTest_WriteResultsToServer ( string sFolder , string safFromDate ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( !glb_IsThisLive ) { return ; }
      // -------------------- x
      glb_BroadID = "SNR" ;
      // -------------------- Globals
      glb_ServerPath  = sFolder ;
      StringReplace ( safFromDate , "." , "-" ) ;
      // -------------------- Variables
      string safTestDuration = "" ;
      string safTestTitle = "" ;
      // -------------------- x
      string safFC [] = {} ;
      // -------------------- x
      ArrayFree ( safFC ) ; goLocalFile_Read ( "TIME.txt" , safFC ) ;
      // -------------------- x
      if ( ArraySize ( safFC ) > 2 ) {
         safTestDuration = string ( int ( goCalc_MinutesBetweenDates ( datetime ( safFC [ 1 ] ) , TimeGMT() ) ) + 1 ) ;
         safTestTitle = safFC [ 2 ] ; }
      // -------------------- x
      ArrayFree ( safFC ) ; goLocalFile_Read ( "RESULTS.txt" , safFC ) ;
      // -------------------- If there are NO results
      if ( ArraySize ( safFC ) < 2 ) {
         // goBroadcast_OTP ( safTestTitle + ": Finished - Zero results in " + safTestDuration + " minutes" ) ;
      // -------------------- If there ARE results
      } else {
         // -------------------- x
         for ( int i = 1 ; i < ArraySize ( safFC ) ; i++ ) {
            // -------------------- x
            string safLineBits [] ; StringSplit ( safFC [ i ] , StringGetCharacter ( "," , 0 ) , safLineBits ) ;
            // -------------------- x
            glb_ServerFileName = safLineBits [ 0 ] + "_" + safFromDate ;
            // -------------------- x
            if ( i == 1 ) { goServer_Write_String ( safFC [ 0 ] ) ; }
            // -------------------- x
            goServer_Write_String ( safFC [ i ] ) ; }
         // -------------------- x
         StringToLower ( glb_ServerFileName ) ;
         // -------------------- x
         string safFileURL = glb_ServerIP + glb_ServerPath + glb_ServerFileName ;
         // -------------------- x
         string safMessage = safTestTitle + ": Finished - <a href='" + safFileURL + "'>" + string ( ArraySize ( safFC ) - 1 ) ;
         safMessage += " results" + "</a>" + " in " + safTestDuration + " minute(s)" ;
         // -------------------- x
         goBroadcast_TST ( safMessage ) ;
         // -------------------- x
         FileCopy ( "RESULTS.txt" , FILE_COMMON , ( goGetDateTime() + "-" + glb_ServerFileName + ".txt" ) , FILE_COMMON ) ; }}

   void goTest_PrepSymbolWindow ( string safFileName="BroSym.txt" ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      Sleep ( 2000 ) ;
      // -------------------- x
      string safSymbols = goSymbols_GetAllInDataWindow () ;
      // -------------------- x
      string safSymbolsSplit [] ; StringSplit ( safSymbols , 124 , safSymbolsSplit ) ;
      // -------------------- x
      for ( int i = 1 ; i < ArraySize ( safSymbolsSplit ) - 1 ; i++ ) {
         goSymbol_RemoveFromDataWindow ( safSymbolsSplit [ i ] ) ; Sleep ( 100 ) ; }
      // -------------------- x
      Sleep ( 2000 ) ;
      // -------------------- x
      string safURL = "https://sherifawzi.github.io/Tools/" + safFileName ;
      string safArray [] ; goServer_ReadSimpleTextFile ( safURL , safArray ) ;
      // -------------------- x
      Sleep ( 2000 ) ;
      // -------------------- x
      string safBroker = UT ( goTranslate_Broker () ) ;
      // -------------------- x
      for ( int i = 0 ; i < ArraySize ( safArray ) - 1 ; i++ ) {
         string LineBits [] ; StringSplit ( safArray [ i ] , 124 , LineBits ) ;
         if ( ArraySize ( LineBits ) > 1 ) {
            if ( UT ( LineBits [ 1 ] ) == safBroker ) {
               goSymbol_AddToDataWindow ( LineBits [ 2 ] ) ; Sleep ( 100 ) ; }}}}

   void goTest_FilterResults2Server (
      // -------------------- x
      string safResultsFolder="nTESTS/nRML3" ,
      string safFilters="9000|3|3|0|10" ,
      string safServerFolder="nTESTS/" ,
      string safServerFN="best.txt" ) {
         // -------------------- x
         glb_TickLock = true ;
         // -------------------- x
         // if ( glb_RobotDisabled ) { return ; }
         // -------------------- x
         if ( !glb_IsThisLive ) { return ; }
         // -------------------- x
         StringToLower ( safServerFN ) ;
         // -------------------- Define server variables
         glb_ServerPath  = safServerFolder ;
         glb_ServerFileName = safServerFN ;
         // -------------------- Define arrays to use
         string safLines [] , safLineBits [] , safArray [] ;
         // -------------------- Read results from server and save locally
         goLocalFile_Read ( goDashboard_GetAllTestResults ( safResultsFolder ) , safLines ) ; Sleep ( 30000 ) ;
         goPrint ( "Number of raw results: " + string ( ArraySize ( safLines ) ) ) ;
         if ( ArraySize ( safLines ) < 1 ) { return ; }
         // -------------------- Populate filter variables
         StringSplit ( safFilters , 124 , safArray ) ;
         if ( ArraySize ( safArray ) < 5 ) { return ; }
         // -------------------- x
         double filter_Profit = double ( safArray [ 0 ] ) ;
         double filter_RF     = double ( safArray [ 1 ] ) ;
         double filter_SR     = double ( safArray [ 2 ] ) ;
         int    filter_Trades = int    ( safArray [ 3 ] ) ;
         double filter_DD     = double ( safArray [ 4 ] ) ;
         // -------------------- Read results already analysed earlier from server
         goServer_ReadSimpleTextFile ( glb_ServerIP + glb_ServerPath + glb_ServerFileName , safArray ) ; Sleep ( 30000 ) ;
         goPrint ( "Number of filtered results: " + string ( ArraySize ( safArray ) ) ) ;
         // -------------------- Go thru local file line by line
         for ( int i=0 ; i < ArraySize ( safLines ) ; i++ ) {
            // -------------------- Remove headers here
            if ( sFind ( UT ( safLines [ i ] ) , "CONFIGSTRING" ) ) { safLines [ i ] = "" ; continue ; }
            // -------------------- Split line into bits
            StringSplit ( safLines [ i ] , StringGetCharacter ( "," , 0 ) , safLineBits ) ;
            if ( ArraySize ( safLineBits ) < 10 ) { safLines [ i ] = "" ; continue ; }
            // -------------------- Apply filter to line
            if ( double ( safLineBits [ 2 ] ) <= filter_Profit ) { safLines [ i ] = "" ; continue ; }
            if ( double ( safLineBits [ 5 ] ) <= filter_RF ) { safLines [ i ] = "" ; continue ; }
            if ( double ( safLineBits [ 6 ] ) <= filter_SR ) { safLines [ i ] = "" ; continue ; }
            if ( double ( safLineBits [ 9 ] ) <= filter_Trades ) { safLines [ i ] = "" ; continue ; }
            if ( double ( safLineBits [ 8 ] ) > filter_DD ) { safLines [ i ] = "" ; continue ; }
            // -------------------- Check if result already on server
            for ( int j=0 ; j < ArraySize ( safArray ) ; j++ ) {
               if ( UT ( safArray [ j ] ) == UT ( safLines [ i ] ) ) { safLines [ i ] = "" ; break ; }}
            // -------------------- Write new results to server
            if ( StringLen ( safLines [ i ] ) > 0 ) {
               goServer_Write_String ( safLines [ i ] ) ; Sleep ( 100 ) ;
               goArray_Add ( safLines [ i ] , safArray ) ; }}}

   //===========================================================================================================
   //=====                                              TEMPS                                              =====
   //===========================================================================================================

   void zen_Trail ( int safTrailDelayMin , double safBuySL , double safSellSL , double safBEDist=0 ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; }
      // -------------------- x
      safBuySL = ND ( safBuySL ) ;
      safSellSL = ND ( safSellSL ) ;
      long serverTime = TimeTradeServer () ;
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- Check profit first
         if ( PositionGetDouble ( POSITION_PROFIT ) <= 0 ) { continue ; }
         // -------------------- x
         long posOpenTime = PositionGetInteger ( POSITION_TIME ) ;
         if ( ( serverTime - posOpenTime ) < ( 60 * safTrailDelayMin ) ) { continue ; }
         // -------------------- x
         if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != UT ( glb_EAS ) ) { continue ; }
         // -------------------- x
         long posType = PositionGetInteger ( POSITION_TYPE ) ;
         double posOpenPrice = PositionGetDouble ( POSITION_PRICE_OPEN ) ;
         double posSL = PositionGetDouble ( POSITION_SL ) ;
         double posTP = PositionGetDouble ( POSITION_TP ) ;
         if ( posSL == 0 ) { posSL = posOpenPrice ; }
         posSL = ND ( posSL ) ;
         // -------------------- Set BE here
         if ( safBEDist > 0 ) {
            if ( posType == POSITION_TYPE_BUY ) {
               if ( posSL <= posOpenPrice ) {
                  if ( sBid() > ( posOpenPrice + safBEDist ) ) {
                     goPositionModify ( posTicket , ND ( posOpenPrice + ( 3 * _Point ) ) , posTP , "ZenBuyBE" ) ; }}}
            else if ( posType == POSITION_TYPE_SELL ) {
               if ( posSL >= posOpenPrice ) {
                  if ( sAsk() < ( posOpenPrice - safBEDist ) ) {
                     goPositionModify ( posTicket , ND ( posOpenPrice - ( 3 * _Point ) ) , posTP , "ZenSellBE" ) ; }}}}
         // -------------------- Trail calculation here
         if ( posType == POSITION_TYPE_BUY ) {
            if ( safBuySL > posSL ) { goPositionModify ( posTicket , safBuySL , posTP , "ZenBuyTrail" ) ; }}
         else if ( posType == POSITION_TYPE_SELL ) {
            if ( safSellSL < posSL ) { goPositionModify ( posTicket , safSellSL , posTP , "ZenSellTrail" ) ; }}}}

   string zen_VirtualPriceCorner ( string &OrdersArray[] , string &TakeProfitArray[] ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- Escape checks
      if ( ArraySize ( OrdersArray ) < 1 ) { return ( "" ) ; }
      // -------------------- Variables
      long serverTime = TimeTradeServer () ;
      string safReturnString = "" ;
      int safActiveCounter = 0 ;
      // -------------------- Go thru Order array one by one
      for ( int i=0 ; i < ArraySize ( OrdersArray ) ; i++ ) {
         // -------------------- If line is empty then skip
         if ( StringLen ( OrdersArray [ i ] ) < 1 ) { continue ; }
         // -------------------- Add to empty check string to reset whole arry in the end
         safReturnString += OrdersArray [ i ] + "  /  " + TakeProfitArray [ i ] + "\r\n" ;
         safActiveCounter += 1 ;
         // -------------------- Escape if order deactivated
         if ( sFind ( OrdersArray [ i ] , "*" ) ) { continue ; }
         // -------------------- Split line into components
         string safSplit [] ;
         StringSplit ( OrdersArray [ i ] , 124 , safSplit ) ;
         if ( ArraySize ( safSplit ) < 14 ) { continue ; }
         // -------------------- First time clean and UT the OrderString
         if ( safSplit [ 0 ] == "" ) {
            OrdersArray [ i ] = UT ( "-" + OrdersArray [ i ] ) ;
            StringReplace ( OrdersArray [ i ] , " " , "" ) ;
            goBroadcast_ZEN_OPS ( "OrderPlaced: " + OrdersArray [ i ] ) ;                                                                             // DELETE
            continue ; }
         // -------------------- |Type|Curr|Lot|Price|SLDist|Tries|TrailCandle|Duration|MaxLosscount|Maxlossamount|TP|BE|FirstOpen|
         string   safOrderType      = safSplit [ 1 ] ;
         string   safCurrency       = safSplit [ 2 ] ;
         double   safLotSize        = ND2 ( double ( safSplit [ 3 ] ) ) ;
         double   safPriceHook      = ND ( double ( safSplit [ 4 ] ) ) ; string safComment = "|CP|" + string ( safPriceHook ) ;
         int      safSLDistMin      = int ( safSplit [ 5 ] ) ; safComment += "-" + string ( safSLDistMin ) ;
         int      safSLDistMax      = int ( safSplit [ 6 ] ) ; safComment += "-" + string ( safSLDistMax ) + "|" ;
         // int      safTrailCandles   = int ( safSplit [ 7 ] ) ;
         int      safOrderDuration  = int ( safSplit [ 8 ] ) ;
         // int      safMaxTradeCount  = int ( safSplit [ 9 ] ) ;
         // int      safMaxTradeLoss   = int ( safSplit [ 10 ] ) ;
         string   safTP             = safSplit [ 11 ] ;
         int      safBE             = int ( safSplit [ 12 ] ) ;
         long     safFirstOpen      = long ( safSplit [ 13 ] ) ;
         // -------------------- Check elapsed time and end if passed
         if ( safFirstOpen != 0 ) {
            if ( ( serverTime - safFirstOpen ) >= ( safOrderDuration * 60 ) ) {
               goBroadcast_ZEN_OPS ( "OrderEnded: " + safCurrency + " " + OrdersArray [ i ] ) ;                                                       // DELETE
               // OrdersArray [ i ] = "" ; TakeProfitArray [ i ] = "" ; continue ; }}
               OrdersArray [ i ] = "*" + OrdersArray [ i ] ; continue ; }}
         // -------------------- Skip if order already has a position open
         if ( zenCheck_PositionOpen ( safCurrency , OrdersArray [ i ] ) ) { continue ; }
         // -------------------- Calc price levels
         double safBuyPriceMax      = safPriceHook + ( safSLDistMax * _Point ) ;
         double safBuyPrice         = safPriceHook + ( safSLDistMin * _Point ) ;
         double safSellPriceMin     = safPriceHook - ( safSLDistMax * _Point ) ;
         double safSellPrice        = safPriceHook - ( safSLDistMin * _Point ) ;
         // -------------------- Get current prices
         double safAsk = sAsk() ;
         double safBid = sBid() ;
         // -------------------- Ensure price touches the hook first
         if ( ( safPriceHook <= safAsk ) && ( safPriceHook >= safBid ) ) {
            if ( !sFind ( safSplit [ 0 ] , "+" ) ) {
               OrdersArray [ i ] = "+" + OrdersArray [ i ] ;
               safSplit [ 0 ] = "+" + safSplit [ 0 ] ; }}
         // -------------------- Check if touched hook yet here
         if ( !sFind ( safSplit [ 0 ] , "+" ) ) { continue ; }
         // -------------------- Variables
         int safCount = 0 ; bool safTradeSuccess = false ;
         // -------------------- Buy Trade
         if ( ( safAsk < safBuyPriceMax ) && ( safAsk >= safBuyPrice ) && ( safBid > safPriceHook ) ) {
            if ( sFind ( safOrderType , "B" ) ) {
               while ( safTradeSuccess == false ) {
                  safTradeSuccess = trade.Buy ( safLotSize , safCurrency , sAsk() , safPriceHook , 0 , safComment ) ; Sleep ( 2000 ) ;
                  if ( safTradeSuccess == true ) {
                     OrdersArray [ i ] += string ( serverTime ) + "|-" + string ( trade.ResultOrder() ) + "-|" ;
                     TakeProfitArray [ i ] = "" ; } safCount += 1 ; if ( safCount >= glb_MaxTries ) { break ; }}}}
         // -------------------- Sell Trade
         else if ( ( safBid > safSellPriceMin ) && ( safBid <= safSellPrice ) && ( safAsk < safPriceHook ) ) {
            if ( sFind ( safOrderType , "S" ) ) {
               while ( safTradeSuccess == false ) {
                  safTradeSuccess = trade.Sell ( safLotSize , safCurrency , sBid() , safPriceHook , 0 , safComment ) ; Sleep ( 2000 ) ;
                  if ( safTradeSuccess == true ) {
                     OrdersArray [ i ] += string ( serverTime ) + "|-" + string ( trade.ResultOrder() ) + "-|" ;
                     TakeProfitArray [ i ] = "" ; } safCount += 1 ; if ( safCount >= glb_MaxTries ) { break ; }}}}}
         // -------------------- x
         // if ( safActiveCounter == 0 ) {
         //    ArrayResize ( OrdersArray , 0 ) ;
         //   ArrayResize ( TakeProfitArray , 0 ) ; }
         // -------------------- x
         return ( safReturnString ) ; }

   bool zenCheck_PositionOpen ( string sCurr , string sOrderData ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return false ; }
      // -------------------- x
      if ( PositionsTotal() < 1 ) { return false ; } else { sCurr = UT ( sCurr ) ; sOrderData = UT ( sOrderData ) ; }
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { return true ; }
         // -------------------- x
         if ( UT ( PositionGetString ( POSITION_SYMBOL ) ) != sCurr ) { continue ; }
         // -------------------- x
         if ( sFind ( sOrderData , "|-" + string ( posTicket ) + "-|" ) ) { return true ; }}
      // -------------------- x
      return false ; }

   void zenCreate_DonchianChannel ( string &sResult [] , int NoOfCandles  , ENUM_TIMEFRAMES sTF ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      ArrayResize ( sResult , 0 ) ;
      // -------------------- x
      double sHigh = 0 , sLow = 999999999 ;
      // -------------------- Declarations and variables
      MqlRates sPI[] ; ArraySetAsSeries ( sPI , true ) ;
      CopyRates ( glb_EAS , sTF , 0 , NoOfCandles + 2 , sPI ) ;
      // -------------------- x
      for ( int i=2 ; i <= ( NoOfCandles + 1 ) ; i++ ) {
         sHigh = MathMax ( sPI [ i ].high , sHigh ) ;
         sLow  = MathMin ( sPI [ i ].low  , sLow  ) ; }
      // -------------------- x
      goArray_Add ( string ( sHigh ) , sResult ) ;
      goArray_Add ( string ( sLow ) , sResult ) ; }

   void zenAnalyze_History ( string &OrdersArray[] , string &TakeProfitArray[] ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- Escape checks
      if ( ArraySize ( OrdersArray ) < 1 ) { return ; }
      // -------------------- Go thru Order array one by one
      for ( int i=0 ; i < ArraySize ( OrdersArray ) ; i++ ) {
         // -------------------- If line is empty then skip
         if ( StringLen ( OrdersArray [ i ] ) < 1 ) { continue ; }
         // -------------------- x
         if ( sFind ( OrdersArray [ i ] , "*" ) ) { continue ; }
         // -------------------- Split line into components
         string safSplit [] ;
         StringSplit ( OrdersArray [ i ] , 124 , safSplit ) ;
         if ( ArraySize ( safSplit ) < 14 ) { continue ; }
         // -------------------- |Type|Curr|Lot|Price|SLDist|Tries|TrailCandle|Duration|MaxLosscount|Maxlossamount|TP|BE|FirstOpen|
         string   safCurrency       = safSplit [ 2 ] ;
         string   safPriceHook      = safSplit [ 4 ] ; string safComment = "|CP|" + safPriceHook ;
         string   safSLDistMin      = safSplit [ 5 ] ; safComment += "-" + safSLDistMin ;
         string   safSLDistMax      = safSplit [ 6 ] ; safComment += "-" + safSLDistMax + "|" ;
         int      safMaxTradeCount  = int ( safSplit [ 9 ] ) ;
         int      safMaxTradeLoss   = int ( safSplit [ 10 ] ) ;
         long     safFirstOpen      = long ( safSplit [ 13 ] ) ;
         // -------------------- x
         if ( ( safMaxTradeCount > 0 ) || ( safMaxTradeLoss > 0 ) ) {
            // -------------------- Get history for period
            if ( !HistorySelect ( datetime ( safFirstOpen - 55 ) , datetime ( "01-01-2070" ) ) ) { continue ; }
            // -------------------- Check max loss or trade amount
            int safTradeCount = 0 ;
            double safTradeProfit = 0 ;
            // -------------------- Go thru history line by line
            for ( int j=0 ; j < HistoryDealsTotal() ; j++ ) {
               // -------------------- Check
               ulong DealTicket = HistoryDealGetTicket ( j ) ;
               if ( !DealTicket ) { continue ; }
               // -------------------- History line data here
               if ( UT ( HistoryDealGetString  ( DealTicket , DEAL_SYMBOL ) ) != safCurrency ) { continue ; }
               // -------------------- x
               bool ContinueOrder = false ;
               if ( sFind ( OrdersArray [ i ] , "|-" + string ( DealTicket ) + "-|" ) ) { ContinueOrder = true ; }
               if ( sFind ( HistoryDealGetString ( DealTicket , DEAL_COMMENT ) , safComment ) ) { ContinueOrder = true ; }
               if ( ContinueOrder == false ) { continue ; }
               // -------------------- x
               double ThisTradeProfit = 0 ;
               ThisTradeProfit +=  HistoryDealGetDouble  ( DealTicket , DEAL_PROFIT ) ;
               ThisTradeProfit +=  HistoryDealGetDouble  ( DealTicket , DEAL_SWAP ) ;
               ThisTradeProfit +=  HistoryDealGetDouble  ( DealTicket , DEAL_FEE ) ;
               ThisTradeProfit +=  HistoryDealGetDouble  ( DealTicket , DEAL_COMMISSION ) ;
               // -------------------- x
               safTradeCount += 1 ;
               safTradeProfit += ThisTradeProfit ; }
            // -------------------- x
            if ( ( safMaxTradeCount > 0 ) && ( safTradeCount >= safMaxTradeCount ) ) {
               goBroadcast_ZEN_OPS ( "OrderFailed (Max trade count reached): " + OrdersArray [ i ] ) ;                                                // DELETE
               // OrdersArray [ i ] = "" ; TakeProfitArray [ i ] = "" ; continue ; }
               OrdersArray [ i ] = "*" + OrdersArray [ i ] ; continue ; }
            // -------------------- x
            if ( ( safMaxTradeLoss > 0 ) && ( safTradeProfit <= ( safMaxTradeLoss * -1 ) ) ) {
               goBroadcast_ZEN_OPS ( "OrderFailed (Max trade loss reached): " + OrdersArray [ i ] ) ;                                                 // DELETE
               // OrdersArray [ i ] = "" ; TakeProfitArray [ i ] = "" ; continue ; }}}}
               OrdersArray [ i ] = "*" + OrdersArray [ i ] ; continue ; }}}}

   void zen_TakeMultipleProfits ( string &OrdersArray[] , string &TakeProfitArray[] , double sOneATR ) {
      // -------------------- x
      glb_TickLock = true ;
      // -------------------- x
      // if ( glb_RobotDisabled ) { return ; }
      // -------------------- x
      if ( PositionsTotal () < 1 ) { return ; }
      // -------------------- x
      for ( int i = 0 ; i < PositionsTotal() ; i++ ) {
         // -------------------- x
         ulong posTicket = PositionGetTicket ( i ) ;
         if ( !PositionSelectByTicket ( posTicket ) ) { continue ; }
         // -------------------- Check profit first
         if ( PositionGetDouble ( POSITION_PROFIT ) <= 0 ) { continue ; }
         // -------------------- x
         string posCurr = UT ( PositionGetString ( POSITION_SYMBOL ) ) ;
         if ( posCurr != UT ( glb_EAS ) ) { continue ; }
         // -------------------- x
         long posType = PositionGetInteger ( POSITION_TYPE ) ;
         double posOpenPrice = PositionGetDouble ( POSITION_PRICE_OPEN ) ;
         // -------------------- x
         for ( int j=0 ; j < ArraySize ( OrdersArray ) ; j++ ) {
            // -------------------- Split line into components
            string safSplit [] ;
            StringSplit ( OrdersArray [ j ] , 124 , safSplit ) ;
            if ( ArraySize ( safSplit ) < 14 ) { continue ; }
            // -------------------- x
            string   safCurrency       = safSplit [ 2 ] ;
            double   safLotSize        = double ( safSplit [ 3 ] ) ;
            double   safPriceHook      = double ( safSplit [ 4 ] ) ;
            string   safTP             = safSplit [ 11 ] ;
            // -------------------- x
            if ( safTP == "" ) { continue ; }
            if ( posCurr != safCurrency ) { continue ; }
            if ( !sFind ( OrdersArray [ j ] , "|-" + string ( posTicket ) + "-|" ) ) { continue ; }
            // -------------------- x
            string safTPSplit [] ;
            StringSplit ( safTP , StringGetCharacter ( "," , 0 ) , safTPSplit ) ;
            if ( ArraySize ( safTPSplit ) < 1 ) { continue ; }
            // -------------------- x
            double safLot2USe = ND2 ( safLotSize / ( ArraySize ( safTPSplit ) + 1 ) ) ;
            // -------------------- x
            int safTPNumber = int ( TakeProfitArray [ j ] ) ;
            if ( safTPNumber > ArraySize ( safTPSplit ) - 1 ) { continue ; }
            // -------------------- x
            int safTPFromTPArray = int ( safTPSplit [ safTPNumber ] ) ;
            double safTPOffset = double ( safTPFromTPArray ) * sOneATR ;
            if ( safTPOffset == 0 ) { continue ; }
            // -------------------- x
            if ( posType == POSITION_TYPE_BUY ) {
               if ( sBid() >= ( posOpenPrice + safTPOffset ) ) {
                  if ( trade.PositionClosePartial ( posTicket , safLot2USe ) ) {
                     TakeProfitArray [ j ] = string ( int ( TakeProfitArray [ j ] ) + 1 ) ; break ; }}}
            else if ( posType == POSITION_TYPE_SELL ) {
               if ( sAsk() <= ( posOpenPrice - safTPOffset ) ) {
                  if ( trade.PositionClosePartial ( posTicket , safLot2USe ) ) {
                     TakeProfitArray [ j ] = string ( int ( TakeProfitArray [ j ] ) + 1 ) ; break ; }}}}}}