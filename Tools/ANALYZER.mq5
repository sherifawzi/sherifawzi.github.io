   #include <newFunctions.mqh>

   #define SNR_BOTVER      "Bot Version: 23.12.23"

   #property copyright     SNR_COPYRIGHT
   #property link          SNR_WEBSITE
   #property description   SNR_LIBVER
   #property description   SNR_BOTVER

   string AllSymbols[] ;
   MqlRates Symbol_PriceInfo [] ;
   string safLastDay2[] ;
   string safStarRating ;

   void OnInit () {
      goOnInit ( __FILE__ ) ;
      // if ( glb_DebugMode ) { goDebug ( "OnInit" ) ; }
      goLocalFile_Write ( "Analyzer started" ) ;
      ArraySetAsSeries ( Symbol_PriceInfo , true ) ;
      StringSplit ( goSymbols_GetAllInDataWindow () , StringGetCharacter ( "|" , 0 ) , AllSymbols ) ;
      glb_BroadID = "ANALYZER01" ;
      glb_BD = 3 ;
      ArrayResize ( safLastDay2 , (ArraySize ( AllSymbols ) + 3 ) ) ;
      for ( int i = 1 ; i < ArraySize ( AllSymbols ) - 1 ; i++ ) {
         goSymbols_OpenChartWithTimeFrame ( AllSymbols [ i ] , PERIOD_D1 ) ; }
      goBroadcast_OPS ( goTele_PrepMsg ( "ANALYZER" , "STARTED" , SNR_LIBVER , SNR_BOTVER ) ) ; }

   void OnTick () {
      // if ( glb_DebugMode ) { goDebug ( "OnTick" ) ; }
      static string safLast10Mins ;
      string safMinsNow = StringSubstr ( goGetDateTime() , 0 , 9 ) ;
      if ( safMinsNow == safLast10Mins ) { return ; }
      safLast10Mins = safMinsNow ;
      // goPrint ( safMinsNow ) ;
      string sCurr_glb_EAS = glb_EAS ;
         glb_EAP = PERIOD_D1 ;
         goAnalyze () ;
      glb_EAS = sCurr_glb_EAS ; }

   bool IsNewDay2 (int i ) {
      // if ( glb_DebugMode ) { goDebug ( "IsNewDay2" ) ; }
      bool safSkip = false ;
      string safDay2Check = string ( Symbol_PriceInfo [ glb_FC ].time ) ;
      if ( safDay2Check == safLastDay2[i] ) { return false ; }
      if ( StringLen( safLastDay2[i] ) == 0 ) { safSkip = true ; }
      safLastDay2[i] = safDay2Check ;
      if ( safSkip == true ) {
         goPrint ( "Skipped: " + glb_EAS ) ;
         return false ; }
      return true ; }

   void goAnalyze () {
      // if ( glb_DebugMode ) { goDebug ( "goAnalyze" ) ; }
      for ( int i = 1 ; i < ArraySize ( AllSymbols ) - 1 ; i++ ) {
         // -------------------- Variables here
         glb_EAS = AllSymbols [ i ] ;
         CopyRates ( glb_EAS , PERIOD_D1 , 0 , glb_BD , Symbol_PriceInfo ) ;
         if ( !IsNewDay2(i) ) { continue ; }
         string OverallString = "" ;
         safStarRating = "" ;
         // goPrint ( "Checking: " + glb_EAS ) ;
         double Price_C = Symbol_PriceInfo [ glb_FC ].close ;
         double Price_L = Symbol_PriceInfo [ glb_FC + 1 ].close ;
         // -------------------- Analysis here
         OverallString += goAnalyze_200EMA        ( Price_C , Price_L ) ;
         OverallString += goAnalyze_BollingerBand ( Price_C , Price_L ) ;
         OverallString += goAnalyze_MFI () ;
         OverallString += goAnalyze_RSI () ;
         OverallString += goAnalyze_Candle () ;
         string safStar = "" ;
         if ( StringFind ( safStarRating , "-******-" , 1 ) > 0 ) { safStar = " - ******" ; }
         else if ( StringFind ( safStarRating , "-*****-" , 1 ) > 0 ) { safStar = " - *****" ; }
         else if ( StringFind ( safStarRating , "-****-" , 1 ) > 0 ) { safStar = " - ****" ; }
         else if ( StringFind ( safStarRating , "-***-" , 1 ) > 0 ) { safStar = " - ***" ; }
         else if ( StringFind ( safStarRating , "-**-" , 1 ) > 0 ) { safStar = " - **" ; }
         if ( StringLen ( OverallString ) > 0 ) {
            OverallString = "Analysis for: " + glb_EAS + safStar + "%0A%0A" + OverallString ;
            goSay ( OverallString ) ; }}}

   void goSay ( string safText="" ) {
      // if ( glb_DebugMode ) { goDebug ( "goSay" ) ; }
      if ( StringLen ( safText ) < 1 ) { return ; }
      // goTele_SendAnalysis ( safText ) ;
      goBroadcast_ANA ( safText ) ;
      Sleep ( 3500 ) ; }

   string goAnalyze_200EMA ( double Price_C , double Price_L ) {
      // if ( glb_DebugMode ) { goDebug ( "goAnalyze_200EMA" ) ; }
      // -------------------- Variables here
      string result = "" ;
      bool safOK = false ;
      bool safDoMore = false ;
      // -------------------- Indicator
      if ( ind_MA ( "EMA" , 200 ) == false ) { return "error in MA" ; }
         double MA_C = B0 [ glb_FC ] ;
         double MA_L = B0 [ glb_FC + 1 ] ;
         // -------------------- Check here
         if ( Price_C == 0 ) { return "" ; }
         if ( Price_L == 0 ) { return "" ; }
         if ( MA_C == 0 ) { return "" ; }
         if ( MA_L == 0 ) { return "" ; }
         // -------------------- Analysis here
         if ( ( Price_C > MA_C ) && ( Price_L < MA_L ) ) { result += "* Price crossed over 200 EMA" ; safOK = true ; safDoMore = true ; }
         if ( ( Price_C < MA_C ) && ( Price_L > MA_L ) ) { result += "* Price crossed below 200 EMA" ; safOK = true ; safDoMore = true ; }
         if ( safOK ) {
            if ( MA_C < MA_L ) { result += " - with MA decending slope" ; }
            if ( MA_C > MA_L ) { result += " - with MA ascending slope" ; }}
         if ( safDoMore == true ) {
            glb_BD = 103 ;
            CopyRates ( glb_EAS , PERIOD_D1 , 0 , glb_BD , Symbol_PriceInfo ) ;
            if ( ind_MA ( "EMA" , 200 ) == false ) { return "error in MA" ; }
            string result2 = "" ;
            for ( int i = glb_FC + 1 ; i < 101 ; i ++ ) {
               double P_C = Symbol_PriceInfo [ i ].close ;
               double P_L = Symbol_PriceInfo [ i + 1 ].close ;
               double M_C = B0 [ i ] ;
               double M_L = B0 [ i + 1 ] ;
               if ( ( P_C > M_C ) && ( P_L < M_L ) ) { result2 = string ( i ) ; break ; }
               if ( ( P_C < M_C ) && ( P_L > M_L ) ) { result2 = string ( i ) ; break ; }}
            if ( StringLen ( result2) > 0 ) {
               result += " - last cross was " + result2 + " trading days ago" ;
               if ( int( result2 ) > 50 ) { safStarRating += "--*****-" ; }
               else if ( int( result2 ) > 40 ) { safStarRating += "--****-" ; }
               else if ( int( result2 ) > 30 ) { safStarRating += "--***-" ; }
               else if ( int( result2 ) > 20 ) { safStarRating += "--**-" ; }
               else { safStarRating += "" ; }
            } else {
               result += " - last cross was more than 100 trading days ago" ;
               safStarRating += "--******-" ; }
            glb_BD = 3 ; }
         if ( StringLen ( result ) > 0 ) { return ( result + "%0A%0A" ) ; } else { return ( "" ) ; }}

   string goAnalyze_BollingerBand ( double Price_C , double Price_L ) {
      // if ( glb_DebugMode ) { goDebug ( "goAnalyze_BollingerBand" ) ; }
      // -------------------- Variables here
      string result = "" ;
      bool safOK = false ;
      // -------------------- Indicator
      if ( ind_Band ( 20 , 0 , 2 ) == false ) { return "Error in Bands" ;}
         double BBU_C = B1 [ glb_FC ] ;
         double BBU_L = B1 [ glb_FC + 1 ] ;
         double BBL_C = B2 [ glb_FC ] ;
         double BBL_L = B2 [ glb_FC + 1 ] ;
         double BBM_C = B0 [ glb_FC ] ;
         double BBM_L = B0 [ glb_FC + 1 ] ;
         // -------------------- Check here
         if ( Price_C == 0 ) { return "" ; }
         if ( Price_L == 0 ) { return "" ; }
         if ( BBU_C == 0 ) { return "" ; }
         if ( BBU_L == 0 ) { return "" ; }
         if ( BBL_C == 0 ) { return "" ; }
         if ( BBL_L == 0 ) { return "" ; }
         if ( BBM_C == 0 ) { return "" ; }
         if ( BBM_L == 0 ) { return "" ; }
         // -------------------- Analysis here
         if ( ( Price_C > BBU_C ) && ( Price_L < BBU_L ) ) { result += "* Price crossed out of upper Bollinger band" ; safOK = true ; }
         if ( ( Price_C < BBU_C ) && ( Price_L > BBU_L ) ) { result += "* Price crossed back into the upper Bollinger band" ; safOK = true ; }
         if ( ( Price_C < BBL_C ) && ( Price_L > BBL_L ) ) { result += "* Price crossed out of lower Bollinger band" ; safOK = true ; }
         if ( ( Price_C > BBL_C ) && ( Price_L < BBL_L ) ) { result += "* Price crossed back into the lower Bollinger band" ; safOK = true ; }
         if ( safOK ) {
            if ( BBM_C < BBM_L ) { result += " - with decending middle slope" ; }
            if ( BBM_C > BBM_L ) { result += " - with ascending middle slope" ; }}
         if ( StringLen ( result ) > 0 ) { return ( result + "%0A%0A" ) ; } else { return ( "" ) ; }}

   string goAnalyze_MFI () {
      // if ( glb_DebugMode ) { goDebug ( "goAnalyze_MFI" ) ; }
      // -------------------- Variables here
      string result = "" ;
      bool safDoMore = false ;
      // -------------------- Indicator
      if ( ind_MFI ( 5 ) == false ) { return "Error in MFI" ; }
         double MFI_C = B0 [ glb_FC ] ;
         double MFI_L = B0 [ glb_FC + 1 ] ;
         // -------------------- Check here
         if ( MFI_C == 0 ) { return "" ; }
         if ( MFI_L == 0 ) { return "" ; }
         // -------------------- Analysis here
         if ( ( MFI_C > 50 ) && ( MFI_L < 50 ) ) { result += "* 5 day Money Flow Index crosses above 50" ; safDoMore = true ; }
         if ( ( MFI_C < 50 ) && ( MFI_L > 50 ) ) { result += "* 5 day Money Flow Index drops below 50" ; safDoMore = true ; }
         if ( safDoMore == true ) {
            glb_BD = 103 ;
            if ( ind_MFI ( 5 ) == false ) { return "Error in MFI" ; }
            string result2 = "" ;
            for ( int i = glb_FC + 1 ; i < 101 ; i ++ ) {
               MFI_C = B0 [ i ] ;
               MFI_L = B0 [ i + 1 ] ;
               if ( ( MFI_C > 50 ) && ( MFI_L < 50 ) ) { result2 = string ( i ) ; break ; }
               if ( ( MFI_C < 50 ) && ( MFI_L > 50 ) ) { result2 = string ( i ) ; break ; }}
            if ( StringLen ( result2) > 0 ) {
               result += " - last cross was " + result2 + " trading days ago" ;
               if ( int( result2 ) > 50 ) { safStarRating += "--*****-" ; }
               else if ( int( result2 ) > 40 ) { safStarRating += "--****-" ; }
               else if ( int( result2 ) > 30 ) { safStarRating += "--***-" ; }
               else if ( int( result2 ) > 20 ) { safStarRating += "--**-" ; }
               else { safStarRating += "" ; }
            } else {
               result += " - last cross was more than 100 trading days ago" ;
               safStarRating += "--******-" ; }
            glb_BD = 3 ; }
         if ( StringLen ( result ) > 0 ) { return ( result + "%0A%0A" ) ; } else { return ( "" ) ; }}

   string goAnalyze_RSI () {
      // if ( glb_DebugMode ) { goDebug ( "goAnalyze_RSI" ) ; }
      // -------------------- Variables here
      string result = "" ;
      bool safDoMore = false ;
      // -------------------- Indicator
      if ( ind_RSI ( 5 ) == false ) { return "Error in RSI" ; }
         double RSI_C = B0 [ glb_FC ] ;
         double RSI_L = B0 [ glb_FC + 1 ] ;
         // -------------------- Check here
         if ( RSI_C == 0 ) { return "" ; }
         if ( RSI_L == 0 ) { return "" ; }
         // -------------------- Analysis here
         if ( ( RSI_C > 50 ) && ( RSI_L < 50 ) ) { result += "* 5 day Relative Strength Index crosses above 50" ; safDoMore = true ; }
         if ( ( RSI_C < 50 ) && ( RSI_L > 50 ) ) { result += "* 5 day Relative Strength Index drops below 50" ; safDoMore = true ; }
         if ( safDoMore == true ) {
            glb_BD = 103 ;
            if ( ind_RSI ( 5 ) == false ) { return "Error in RSI" ; }
            string result2 = "" ;
            for ( int i = glb_FC + 1 ; i < 101 ; i ++ ) {
               RSI_C = B0 [ i ] ;
               RSI_L = B0 [ i + 1 ] ;
               if ( ( RSI_C > 50 ) && ( RSI_L < 50 ) ) { result2 = string ( i ) ; break ; }
               if ( ( RSI_C < 50 ) && ( RSI_L > 50 ) ) { result2 = string ( i ) ; break ; }}
            if ( StringLen ( result2) > 0 ) {
               result += " - last cross was " + result2 + " trading days ago" ;
               if ( int( result2 ) > 50 ) { safStarRating += "--*****-" ; }
               else if ( int( result2 ) > 40 ) { safStarRating += "--****-" ; }
               else if ( int( result2 ) > 30 ) { safStarRating += "--***-" ; }
               else if ( int( result2 ) > 20 ) { safStarRating += "--**-" ; }
               else { safStarRating += "" ; }
            } else {
               result += " - last cross was more than 100 trading days ago" ;
               safStarRating += "--******-" ; }
            glb_BD = 3 ; }
         if ( StringLen ( result ) > 0 ) { return ( result + "%0A%0A" ) ; } else { return ( "" ) ; }}

   string goAnalyze_Candle () {
       // if ( glb_DebugMode ) { goDebug ( "goAnalyze_Candle" ) ; }
       // -------------------- Variables here
       string result = "" ;
       // -------------------- Indicator
       if ( IsCandle_Template2 ( "ECI" , 1 ) == "YYY" ) {
         result += "* Daily bearish englufing candle detected" ; }
       else if ( IsCandle_Template2 ( "EDH" , 1 ) == "YYY" ) {
         result += "* Daily bullish englufing candle detected" ; }
       if ( StringLen ( result ) > 0 ) { return ( result + "%0A%0A" ) ; } else { return ( "" ) ; }}

   string IsCandle_Template2 ( string safRules="AB" , int safCandle=1 ) {
      // if ( glb_DebugMode ) { goDebug ( "IsCandle_Template2" ) ; }
      string result = "" ;
      // RULE C: Is current Bearish
      // RULE D: Is current Bullish
      // RULE E: Body 2 Body Engluphing
      // RULE F: Body 2 wick Engluphing
      // RULE G: Wick 2 Wick Engluphing
      // RULE H: Is last Bearish
      // RULE I: Is last Bullish
      // RULE J: No current upper Wick
      // RULE K: No current lower Wick
      // RULE L: No last upper Wick
      // RULE M: No last lower Wick
      // -------------------- Current Candle
      double cHigh         = Symbol_PriceInfo [ safCandle ].high ;
      double cLow          = Symbol_PriceInfo [ safCandle ].low ;
      double cOpen         = Symbol_PriceInfo [ safCandle ].open ;
      double cClose        = Symbol_PriceInfo [ safCandle ].close ;
      double cRange        = cHigh - cLow ;
      double cBody         = MathAbs ( cOpen - cClose ) ;
      double cMax          = MathMax ( cOpen , cClose ) ;
      double cMin          = MathMin ( cOpen , cClose ) ;
      double cUpperWick    = cHigh - cMax ;
      double cLowerWick    = cMin - cLow ;
      double cMiddle       = cLow + ( cRange / 2 ) ;
      // -------------------- Last Candle
      double lHigh         = Symbol_PriceInfo [ safCandle + 1 ].high ;
      double lLow          = Symbol_PriceInfo [ safCandle + 1 ].low ;
      double lOpen         = Symbol_PriceInfo [ safCandle + 1 ].open ;
      double lClose        = Symbol_PriceInfo [ safCandle + 1 ].close ;
      double lRange        = lHigh - lLow ;
      double lBody         = MathAbs ( lOpen - lClose ) ;
      double lMax          = MathMax ( lOpen , lClose ) ;
      double lMin          = MathMin ( lOpen , lClose ) ;
      double lUpperWick    = lHigh - lMax ;
      double lLowerWick    = lMin - lLow ;
      double lMiddle       = lLow + ( lRange / 2 ) ;
      // -------------------- RULE C / Is current Bearish
      if ( StringFind ( safRules , "C" , 0 ) >= 0 ) {
         if ( cOpen > cClose ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE D / Is current Bullish
      if ( StringFind ( safRules , "D" , 0 ) >= 0 ) {
         if ( cOpen < cClose ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE E / Body 2 Body Engluphing
      if ( StringFind ( safRules , "E" , 0 ) >= 0 ) {
         if ( ( cMax > lMax ) && ( cMin < lMin ) ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE F / Body 2 wick Engluphing
      if ( StringFind ( safRules , "F" , 0 ) >= 0 ) {
         if ( ( cMax > lHigh ) && ( cMin < lLow ) ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE G / Wick 2 Wick Engluphing
      if ( StringFind ( safRules , "G" , 0 ) >= 0 ) {
         if ( ( cHigh > lHigh ) && ( cLow < lLow ) ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE H / Is last Bearish
      if ( StringFind ( safRules , "H" , 0 ) >= 0 ) {
         if ( lOpen > lClose ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE I / Is last Bullish
      if ( StringFind ( safRules , "I" , 0 ) >= 0 ) {
         if ( lOpen < lClose ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE J / no current upper wick
      if ( StringFind ( safRules , "J" , 0 ) >= 0 ) {
         if ( cUpperWick == 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE K / no current lower wick
      if ( StringFind ( safRules , "K" , 0 ) >= 0 ) {
         if ( cLowerWick == 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE L / no last upper wick
      if ( StringFind ( safRules , "L" , 0 ) >= 0 ) {
         if ( lUpperWick == 0 ) { result += "Y" ; } else { return "X" ; }}
      // -------------------- RULE M / no last lower wick
      if ( StringFind ( safRules , "M" , 0 ) >= 0 ) {
         if ( lLowerWick == 0 ) { result += "Y" ; } else { return "X" ; }}
      return result ; }