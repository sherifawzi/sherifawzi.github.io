   
   #include <newFunctions.mqh>
   
   #define SNR_BOTVER      "Bot Version: 24.01.03"
   
   #property copyright     SNR_COPYRIGHT
   #property link          SNR_WEBSITE
   #property description   SNR_LIBVER
   #property description   SNR_BOTVER
   
   enum IchiType { sNoIchi = 0 , sBoth = 1 , sFirst = 2 , sSecond = 3 , sNone = 4 } ;
   
   input group "Main Settings:"
   string            myMagic                 = "TEST"       ; // EA Magic Number
   string            myMagicSuffix         = ""           ; // EA Magic Suffix
   bool              iUseSL                  = false        ; // Use SL
   
   enumRiskLevel     RiskLevel               = Highest         ; // Risk appetite
   
   double            myMaxCapitalPerc        = 0            ; // Max capital percent to use [0=Disabled]
   double            myMaxLotPerK            = 0            ; // Max lot per 1K to use [0=Disabled]
   bool              myBeaconMode            = true         ; // Beacon mode activated
   input string            mySettings              = ""           ; // EA Config String
   string            mySunsetDate            = ""           ; // EA Sunset Date [empty=Disabled]
   double            iGlobalLotSize          = 1            ; // Global Lot Size
   int               iDelayHour              = 8            ; // Monday delayed start and Friday early finish [0=Disabled]
   enumTradeCount    iUseMultiTrade          = Single_Trade ; // Split trade
   bool              isMinTradeMode          = false        ;
   bool              OK2OnTrade              = false        ;
   
   int TPMultiple , SMAPeriod , SMATrend , RSIPeriod , RSITrend , ADXPeriod , ADXTrend , ADXTarget , UseIchi ;
   bool UseEquBal , UseSession , UseDaily , useSMA , useEMA , useSMMA , useDEMA , useTEMA , useSAR , useFrama ;
   bool useVidya , useAMA , useRSI , useChaikin , useCCI , useDemarker , useForce , useMomentum , useWPR ;
   bool useRVI , useMFI , useAO , useTrix , useADX , useADXW , UseCloseBiggest , UseRSIClose ;
   bool UseSNREntry = false ;
   double ATR_C=0 , myTPV=0 , myTPV2=0 , mySLV=0 , myLotSLV=0 ;
   enumTradeType sCurr_AllowedTrade = glb_AllowedTrade ;
   
   void OnInit () {
      goOnInit ( __FILE__ ) ;
      if ( !goCheck_ConfigString ( mySettings ) ) { ExpertRemove () ; return ; }
      glb_Magic = myMagic ;
      glb_SunsetDate = mySunsetDate ;
      glb_BroadID = glb_Magic ;
      glb_MaxCapitalPerc = myMaxCapitalPerc ;
      glb_MaxLotPerK = myMaxLotPerK ;
      glb_BeaconMode = myBeaconMode ;
      glb_LotSize = iGlobalLotSize ;
      glb_MinTradeMode = isMinTradeMode ;
      glb_SilentMode = false ;
      string mySettings2Use = UT ( mySettings ) ;
         string safSplit[] ;
         StringSplit ( mySettings2Use , StringGetCharacter ( "|" , 0 ) , safSplit ) ;
         if ( ArraySize ( safSplit ) < 42 ) {
            goPrint ( "Incorrect Config String" ) ;
            ExpertRemove() ;
            return ; }
         if ( UT ( safSplit[1] ) == "TR4" ) { UseSNREntry = true ; }
         if ( UseSNREntry == false ) { TPMultiple = (int) safSplit[0] ; } else { TPMultiple = 0 ; }
         SMAPeriod = (int) safSplit[1] ;
         SMATrend = (int) safSplit[2] ;
         RSIPeriod = (int) safSplit[3] ;
         RSITrend = (int) safSplit[4] ;
         ADXPeriod = (int) safSplit[5] ;
         ADXTrend = (int) safSplit[6] ;
         ADXTarget = (int) safSplit[7] ;
         if ( ( UT ( safSplit [ 8 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { UseEquBal = true ; } else { UseEquBal = false ; }
         if ( ( UT ( safSplit [ 9 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { UseSession = true ; } else { UseSession = false ; }
         if ( ( UT ( safSplit [ 10 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { UseDaily = true ; } else { UseDaily = false ; }
         if ( ( UT ( safSplit [ 11 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useSMA = true ; } else { useSMA = false ; }
         if ( ( UT ( safSplit [ 12 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useEMA = true ; } else { useEMA = false ; }
         if ( ( UT ( safSplit [ 13 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useSMMA = true ; } else { useSMMA = false ; }
         if ( ( UT ( safSplit [ 14 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useDEMA = true ; } else { useDEMA = false ; }
         if ( ( UT ( safSplit [ 15 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useTEMA = true ; } else { useTEMA = false ; }
         if ( ( UT ( safSplit [ 16 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useSAR = true ; } else { useSAR = false ; }
         if ( ( UT ( safSplit [ 17 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useFrama = true ; } else { useFrama = false ; }
         if ( ( UT ( safSplit [ 18 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useVidya = true ; } else { useVidya = false ; }
         if ( ( UT ( safSplit [ 19 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useAMA = true ; } else { useAMA = false ; }
         if ( UT ( safSplit [ 20 ] ) == "TRUE" ) { useRSI = true ; } else { useRSI = false ; }
         if ( UT ( safSplit [ 21 ] ) == "TRUE" ) { useChaikin = true ; } else { useChaikin = false ; }
         if ( UT ( safSplit [ 22 ] ) == "TRUE" ) { useCCI = true ; } else { useCCI = false ; }
         if ( UT ( safSplit [ 23 ] ) == "TRUE" ) { useDemarker = true ; } else { useDemarker = false ; }
         if ( UT ( safSplit [ 24 ] ) == "TRUE" ) { useForce = true ; } else { useForce = false ; }
         if ( UT ( safSplit [ 25 ] ) == "TRUE" ) { useMomentum = true ; } else { useMomentum = false ; }
         if ( UT ( safSplit [ 26 ] ) == "TRUE" ) { useWPR = true ; } else { useWPR = false ; }
         if ( UT ( safSplit [ 27 ] ) == "TRUE" ) { useRVI = true ; } else { useRVI = false ; }
         if ( UT ( safSplit [ 28 ] ) == "TRUE" ) { useMFI = true ; } else { useMFI = false ; }
         if ( UT ( safSplit [ 29 ] ) == "TRUE" ) { useAO = true ; } else { useAO = false ; }
         if ( UT ( safSplit [ 30 ] ) == "TRUE" ) { useTrix = true ; } else { useTrix = false ; }
         if ( ( UT ( safSplit [ 31 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useADX = true ; } else { useADX = false ; }
         if ( ( UT ( safSplit [ 32 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { useADXW = true ; } else { useADXW = false ; }
         if ( UseSNREntry == false ) { UseIchi = (int) safSplit[33] ; }
         if ( ( UT ( safSplit [ 34 ] ) == "TRUE" ) && ( UseSNREntry == false ) ) { UseCloseBiggest = true ; } else { UseCloseBiggest = false ; }
         if ( UT ( safSplit [ 35 ] ) == "TRUE" ) { UseRSIClose = true ; } else { UseRSIClose = false ; }
         if ( StringFind ( UT ( safSplit [ 41 ] ) , "_SL" , 0 ) > 1 ) {
            iUseSL = true ;
            goPrint ( "SL Activated for this beacon" ) ;
            Comment ( "SL Activated for this beacon" ) ;
         } else { iUseSL = false ; }}
         
   void OnTick () {
      if ( !IsNewCandle() ) { return ; }
      OK2OnTrade = false ;
      goCheckEntry () ;
      if ( glb_BeaconMode == false ) { if ( PositionsTotal() > 0 ) { goCheckExit () ; }}
      OK2OnTrade = true ; }

   void goCheckEntry() {
      string mySig = "" ;
      if ( ind_ATR ( 14 ) == false ) { return ; }
      ATR_C = B0 [ glb_FC ] ;
      if ( UseSNREntry == true ) {
         mySig += goSignal_EntrySNR() ;
      }
      if ( ( iDelayHour > 0 ) && ( UseSNREntry == false ) ) {
         if ( goDelayMondayStart ( iDelayHour ) == "X" ) { return ; }
         if ( goEndFridayEarly ( ( 24 - iDelayHour - 2 ) ) == "X" ) { return ; }}
      if ( ( IsDay_NoTradeDay () ) && ( UseSNREntry == false ) ) { return ; }
      if ( ( ( sAsk() - sBid() ) > ATR_C * 0.5 ) && ( UseSNREntry == false ) ) { return ; }
      if ( UseEquBal == true ) { if ( sEqu() < sBal() ) { return ; }}
      mySig += goCalc_TradeRange ( "1" , 120 , 90 ) ; if ( !GCS ( mySig ) ) { return ; }
      if ( UseSession == true ) { mySig += IsSession_Auto () ; if ( !GCS ( mySig ) ) { return ; }}
      if ( UseDaily == true ) { mySig += goCheck_Daily200MA ( "EMA" , glb_EAS , 0 ) ; if ( !GCS ( mySig ) ) { return ; }}
      if ( useSMA == true ) { mySig += goSignal_Trend ( "1" , "SMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
      if ( useEMA == true ) { mySig +=  goSignal_Trend ( "1" , "EMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
      if ( useSMMA == true ) { mySig += goSignal_Trend ( "1" , "SMMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
      if ( useDEMA == true ) { mySig += goSignal_Trend ( "1" , "DEMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
      if ( useTEMA == true ) { mySig += goSignal_Trend ( "1" , "TEMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
      if ( useSAR == true ) { mySig += goSignal_Trend ( "1" , "SAR" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
      if ( useFrama == true ) { mySig += goSignal_Trend ( "1" , "FRAMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
      if ( useVidya == true ) { mySig += goSignal_Trend ( "1" , "VIDYA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
      if ( useAMA == true ) { mySig += goSignal_Trend ( "1" , "AMA" , SMAPeriod , SMATrend ) ; if ( !GCS ( mySig ) ) { return ; }}
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
      string ADXMethod = "1" ;
      if ( useADX == true ) { mySig += goSignal_ADX ( ADXMethod , "ADX" , ADXPeriod , ADXTrend , ADXTarget , 0 ) ; if ( !GCS ( mySig ) ) { return ; }}
      if ( useADXW == true ) { mySig += goSignal_ADX ( ADXMethod , "ADXW" , ADXPeriod , ADXTrend , ADXTarget , 0 ) ; if ( !GCS ( mySig ) ) { return ; }}
      if ( UseIchi > 0 ) {
         if ( UseIchi == 1 ) { mySig += goSignal_Ichimoku( "12345678" ) ; if ( !GCS ( mySig ) ) { return ; }}
         if ( UseIchi == 2 ) { mySig += goSignal_Ichimoku( "1234578" ) ; if ( !GCS ( mySig ) ) { return ; }}
         if ( UseIchi == 3 ) { mySig += goSignal_Ichimoku( "1245678" ) ; if ( !GCS ( mySig ) ) { return ; }}
         if ( UseIchi == 4 ) { mySig += goSignal_Ichimoku( "124578" ) ; if ( !GCS ( mySig ) ) { return ; }}}
      mySig = goCleanSignal ( mySig ) ;
      if ( mySig == "B" ) {
         if ( UseCloseBiggest == true ) { goClose_BiggestProfitPosition () ; }
         BuyButton () ; }
      else if ( mySig == "S" ) {
         if ( UseCloseBiggest == true ) { goClose_BiggestProfitPosition () ; }
         SellButton () ; }}

   void goCheckExit () {
      if ( UseSNREntry == true ) {
         Trail_After_XATR ( 14 , 2 , 1 ) ;
      } else {
         goTrail_AfterBE_SLV ( ATR_C ) ;
      }
      if ( UseRSIClose == true ) { goClose_OnRSI ( "2" , 0.1 , 50 ) ; }}

   void BuyButton () {
      goCalcStops () ; if ( glb_AllowedTrade == No_Trade ) { return ; }
      string safComment = glb_Magic + "|B/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + glb_EAS ;
      if ( myMagicSuffix != "" ) { safComment += ( "/" + myMagicSuffix ) ; }
      sBuy ( iUseMultiTrade , 1 , mySLV , myTPV , ( 2 * myLotSLV ) , 0.5 , -1 , "B" , 0 , safComment ) ; }
   void SellButton () {
      goCalcStops () ; if ( glb_AllowedTrade == No_Trade ) { return ; }
      string safComment = glb_Magic + "|S/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + glb_EAS ;
      if ( myMagicSuffix != "" ) { safComment += ( "/" + myMagicSuffix ) ; }
      sSell ( iUseMultiTrade , 1 , mySLV , myTPV , ( 2 * myLotSLV ) , 0.5 , -1 , "S" , 0 , safComment ) ; }

   void goCalcStops () {
      if ( RiskLevel == LYDR3 ) {
         myLotSLV = goCalc_LastYearDayRange() * 0.5 ;
      } else {
         string myRiskString = goTranslate_RiskLevel ( RiskLevel ) ;
         int myDiv = 1 ; if ( RiskLevel == Lowest ) { myDiv = 50 ; }
         else if ( RiskLevel == Lower ) { myDiv = 20 ; }
         else if ( RiskLevel == Low ) { myDiv = 3 ; }
         myLotSLV = goCalc_PercentSLV ( "" , myRiskString , myDiv ) ; }
      if ( iUseSL == true ) { mySLV = myLotSLV ; }
      if ( TPMultiple > 0 ) { myTPV = ATR_C * TPMultiple ; } else {
         if ( UseSNREntry == false ) {
            myTPV = ATR_C ;
         } else {
            myTPV = 0 ; }
         }}

   void OnTrade () {
      if ( OK2OnTrade == false ) { return ; }
      if ( UseSNREntry == true ) {
         Trail_After_XATR ( 14 , 2 , 1 ) ;
      } else {
         goTrail_AfterBE_SLV ( ATR_C ) ; }
      }