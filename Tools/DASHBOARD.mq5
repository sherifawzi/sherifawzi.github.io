
   #include <newFunctions.mqh>

   #define SNR_BOTVER      "Bot Version: 23.12.23"

   #property copyright     SNR_COPYRIGHT
   #property link          SNR_WEBSITE
   #property description   SNR_LIBVER
   #property description   SNR_BOTVER

   void OnInit () {
      goOnInit ( __FILE__ ) ;
      glb_SilentMode = false ;
      goCheck () ; }

   void OnTick() {
      if ( !IsNewHour() ) { return ; }
      Sleep ( 30000 ) ;
      goCheck () ; }

   bool goProcessLine ( string safLine , string &AllLiveBots[] , int safLoc ) {
      string LineBits [] ;
      StringSplit ( safLine , StringGetCharacter ( "|" , 0 ) , LineBits ) ;
      if ( ArraySize ( LineBits ) < (safLoc+42) ) { return ( false ) ; }
      string safString2Use = LineBits [0] + "|" + LineBits [ safLoc ] ;
      for ( int j=(safLoc+1) ; j <= (safLoc+42) ; j++ ) { safString2Use += "|" + LineBits [ j ] ; }
      int sArrSize = ArraySize ( AllLiveBots ) ;
      ArrayResize ( AllLiveBots , ( sArrSize + 1 ) ) ;
      AllLiveBots [ sArrSize ] = safString2Use ;
      // goPrint ( safString2Use ) ;
      return ( true ) ; }

   bool goCheck () {

   //===========================================================================================================
   //=====                                         OPS CHECKS                                              =====
   //===========================================================================================================

      string AllMessages[] , AllLiveBots[] ;
      string safLastSAT = goFindLastDayNameString ( "SAT" ) + "140000" ;
      // -------------------- Get OPS log
      goServer_ReadFile ( glb_ServerIP + "SNRobotiX/operations.txt" , AllMessages , safLastSAT ) ;
      // -------------------- Variables
      int sSunset=0 , sFailed=0 , sDeployed=0 , sLive=0 , sLastWeek=0 , sTesting=0 , sRadio=0 ;
      int sSunsetBB=0 , sFailedBB=0 , sDeployedBB=0 , sLiveBB=0 , sLastWeekBB=0 , sTestingBB=0 , sRadioBB=0 ;
      int sSunsetMB=0 , sFailedMB=0 , sDeployedMB=0 , sLiveMB=0 , sLastWeekMB=0 , sTestingMB=0 , sRadioMB=0 ;
      int sSunsetTVM=0 , sFailedTVM=0 , sDeployedTVM=0 , sLiveTVM=0 , sLastWeekTVM=0 , sTestingTVM=0 , sRadioTVM=0 ;
      int sSunsetVAN=0 , sFailedVAN=0 , sDeployedVAN=0 , sLiveVAN=0 , sLastWeekVAN=0 , sTestingVAN=0 , sRadioVAN=0 ;
      int sSunset8CAP=0 , sFailed8CAP=0 , sDeployed8CAP=0 , sLive8CAP=0 , sLastWeek8CAP=0 , sTesting8CAP=0 , sRadio8CAP=0 ;

      // -------------------- BOTS live from last week here
      for ( int i=0 ; i<ArraySize ( AllMessages ) ; i++ ) {
         if ( StringFind ( AllMessages [ i ] , "|BEACON|STARTED|" , 0 ) >= 0 ) {
            if ( StringFind ( AllMessages [ i ] , "TEST|" , 0 ) >= 0 ) {
               sTesting += 1 ;
               if ( StringFind ( AllMessages [ i ] , "BBTEST" , 0 ) >= 0 ) { sTestingBB += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "MBTEST" , 0 ) >= 0 ) { sTestingMB += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "TVMTEST" , 0 ) >= 0 ) { sTestingTVM += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "VANTEST" , 0 ) >= 0 ) { sTestingVAN += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "8CAPTEST" , 0 ) >= 0 ) { sTesting8CAP += 1 ; }
               else { Print ( "error in: " + AllMessages [ i ] ) ; }
            } else {
               if ( goProcessLine ( AllMessages [ i ] , AllLiveBots , 4 ) == true ) {
                  sLive += 1 ; sLastWeek += 1 ;
               if ( StringFind ( AllMessages [ i ] , "BB|" , 0 ) >= 0 ) { sLiveBB += 1 ; sLastWeekBB += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "MB|" , 0 ) >= 0 ) { sLiveMB += 1 ; sLastWeekMB += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "TVM|" , 0 ) >= 0 ) { sLiveTVM += 1 ; sLastWeekTVM += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "VAN|" , 0 ) >= 0 ) { sLiveVAN += 1 ; sLastWeekVAN += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "8CAP|" , 0 ) >= 0 ) { sLive8CAP += 1 ; sLastWeek8CAP += 1 ; }
               else { Print ( "error in: " + AllMessages [ i ] ) ; }}}}}
      // -------------------- BOTS DEPLOYED this week here
      for ( int i=0 ; i<ArraySize ( AllMessages ) ; i++ ) {
         if ( StringFind ( AllMessages [ i ] , "|BEACON|DEPLOYED|" , 0 ) >= 0 ) {
            if ( goProcessLine ( AllMessages [ i ] , AllLiveBots , 5 ) == true ) {
               sLive += 1 ; sDeployed += 1 ;
               if ( StringFind ( AllMessages [ i ] , "BB|" , 0 ) >= 0 ) { sLiveBB += 1 ; sDeployedBB += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "MB|" , 0 ) >= 0 ) { sLiveMB += 1 ; sDeployedMB += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "TVM|" , 0 ) >= 0 ) { sLiveTVM += 1 ; sDeployedTVM += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "VAN|" , 0 ) >= 0 ) { sLiveVAN += 1 ; sDeployedVAN += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "8CAP|" , 0 ) >= 0 ) { sLive8CAP += 1 ; sDeployed8CAP += 1 ; }
               else { Print ( "error in: " + AllMessages [ i ] ) ; }}}}
      // -------------------- BOTS FAILED this week here
      for ( int i=0 ; i<ArraySize ( AllMessages ) ; i++ ) {
         if ( StringFind ( AllMessages [ i ] , "|BEACON|FAILEDAUTODEPLOY|" , 0 ) >= 0 ) {
            sFailed += 1 ;
            if ( StringFind ( AllMessages [ i ] , "BBTEST|" , 0 ) >= 0 ) { sFailedBB += 1 ; }
            else if ( StringFind ( AllMessages [ i ] , "MBTEST|" , 0 ) >= 0 ) { sFailedMB += 1 ; }
            else if ( StringFind ( AllMessages [ i ] , "TVMTEST|" , 0 ) >= 0 ) { sFailedTVM += 1 ; }
            else if ( StringFind ( AllMessages [ i ] , "VANTEST|" , 0 ) >= 0 ) { sFailedVAN += 1 ; }
            else if ( StringFind ( AllMessages [ i ] , "8CAPTEST|" , 0 ) >= 0 ) { sFailed8CAP += 1 ; }
            else { Print ( "error in: " + AllMessages [ i ] ) ; }}
         if ( StringFind ( AllMessages [ i ] , "|RADIO|STARTED|" , 0 ) >= 0 ) { sRadio += 1 ; }}
      // -------------------- BOTS SUNSET this week here
      for ( int i=0 ; i<ArraySize ( AllMessages ) ; i++ ) {
         if ( StringFind ( AllMessages [ i ] , "|BEACON|SUNSET|" , 0 ) >= 0 ) {
            sSunset += 1 ;
            if ( StringFind ( AllMessages [ i ] , "BB" , 0 ) >= 0 ) { sSunsetBB += 1 ; }
            else if ( StringFind ( AllMessages [ i ] , "MB" , 0 ) >= 0 ) { sSunsetMB += 1 ; }
            else if ( StringFind ( AllMessages [ i ] , "TVM" , 0 ) >= 0 ) { sSunsetTVM += 1 ; }
            else if ( StringFind ( AllMessages [ i ] , "VAN" , 0 ) >= 0 ) { sSunsetVAN += 1 ; }
            else if ( StringFind ( AllMessages [ i ] , "8CAP" , 0 ) >= 0 ) { sSunset8CAP += 1 ; }
            else { Print ( "error in: " + AllMessages [ i ] ) ; }
            bool sFound = false ;
            string LineBits [] ;
            StringSplit ( AllMessages [ i ] , StringGetCharacter ( "|" , 0 ) , LineBits ) ;
            if ( ArraySize ( LineBits ) < 47 ) { break ; }
            string safString2Use = LineBits [0] + "|" + LineBits [ 5 ] ;
            for ( int j=6 ; j <= 47 ; j++ ) { safString2Use += "|" + LineBits [ j ] ; }
            for ( int k=0 ; k < ArraySize ( AllLiveBots ) ; k++ ) {
               if ( StringFind ( AllLiveBots [ k ] , safString2Use , 0 ) >=0 ) {
                  // Print ( AllLiveBots [ k ] ) ;
                  // Print ( safString2Use ) ;
                  sLive -= 1 ;
                  if ( StringFind ( AllMessages [ i ] , "BB|" , 0 ) >= 0 ) { sLiveBB -= 1 ; }
                  else if ( StringFind ( AllMessages [ i ] , "MB|" , 0 ) >= 0 ) { sLiveMB -= 1 ; }
                  else if ( StringFind ( AllMessages [ i ] , "TVM|" , 0 ) >= 0 ) { sLiveTVM -= 1 ; }
                  else if ( StringFind ( AllMessages [ i ] , "VAN|" , 0 ) >= 0 ) { sLiveVAN -= 1 ; }
                  else if ( StringFind ( AllMessages [ i ] , "8CAP|" , 0 ) >= 0 ) { sLive8CAP -= 1 ; }
                  else { Print ( "error in: " + AllMessages [ i ] ) ; }
                  sFound = true ;
                  AllLiveBots [ k ] = "" ; }}
            if ( sFound == false ) {
               sTesting -= 1 ;
               if ( StringFind ( AllMessages [ i ] , "BBTEST" , 0 ) >= 0 ) { sTestingBB -= 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "MBTEST" , 0 ) >= 0 ) { sTestingMB -= 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "TVMTEST" , 0 ) >= 0 ) { sTestingTVM -= 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "VANTEST" , 0 ) >= 0 ) { sTestingVAN -= 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "8CAPTEST" , 0 ) >= 0 ) { sTesting8CAP -= 1 ; }
               else { Print ( "error in: " + AllMessages [ i ] ) ; }}}}

   //===========================================================================================================
   //=====                                         SIG CHECKS                                              =====
   //===========================================================================================================

      // -------------------- Get OPS log
      goServer_ReadFile ( glb_ServerIP + "SNRobotiX/signals.txt" , AllMessages , safLastSAT ) ;
      // -------------------- Variables
      int sLiveSIG=0 , sTestSIG=0 ;
      int sLiveSIGBB=0 , sTestSIGBB=0 ;
      int sLiveSIGMB=0 , sTestSIGMB=0 ;
      int sLiveSIGTVM=0 , sTestSIGTVM=0 ;
      int sLiveSIGVAN=0 , sTestSIGVAN=0 ;
      int sLiveSIG8CAP=0 , sTestSIG8CAP=0 ;
      // -------------------- BOTS live from last week here
      for ( int i=0 ; i<ArraySize ( AllMessages ) ; i++ ) {
         if ( ( StringFind ( AllMessages [ i ] , "|S|" , 0 ) >= 0 ) || ( StringFind ( AllMessages [ i ] , "|B|" , 0 ) >= 0 ) ) {
            if ( StringFind ( AllMessages [ i ] , "TEST|" , 0 ) >= 0 ) {
               sTestSIG += 1 ;
               if ( StringFind ( AllMessages [ i ] , "BBTEST" , 0 ) >= 0 ) { sTestSIGBB += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "MBTEST" , 0 ) >= 0 ) { sTestSIGMB += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "TVMTEST" , 0 ) >= 0 ) { sTestSIGTVM += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "VANTEST" , 0 ) >= 0 ) { sTestSIGVAN += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "8CAPTEST" , 0 ) >= 0 ) { sTestSIG8CAP += 1 ; }
               else { Print ( "error in: " + AllMessages [ i ] ) ; }
            } else {
               sLiveSIG += 1 ;
               if ( StringFind ( AllMessages [ i ] , "BB" , 0 ) >= 0 ) { sLiveSIGBB += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "MB" , 0 ) >= 0 ) { sLiveSIGMB += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "TVM" , 0 ) >= 0 ) { sLiveSIGTVM += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "VAN" , 0 ) >= 0 ) { sLiveSIGVAN += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "8CAP" , 0 ) >= 0 ) { sLiveSIG8CAP += 1 ; }
               else { Print ( "error in: " + AllMessages [ i ] ) ; }}}}

   //===========================================================================================================
   //=====                                       ALL SIG CHECKS                                            =====
   //===========================================================================================================

      // -------------------- Get OPS log
      goServer_ReadFile ( glb_ServerIP + "SNRobotiX/signals.txt" , AllMessages ) ;
      // -------------------- Variables
      int sLiveSIG_All=0 , sTestSIG_All=0 ;
      int sLiveSIGBB_All=0 , sTestSIGBB_All=0 ;
      int sLiveSIGMB_All=0 , sTestSIGMB_All=0 ;
      int sLiveSIGTVM_All=0 , sTestSIGTVM_All=0 ;
      int sLiveSIGVAN_All=0 , sTestSIGVAN_All=0 ;
      int sLiveSIG8CAP_All=0 , sTestSIG8CAP_All=0 ;
      // -------------------- BOTS live from last week here
      for ( int i=0 ; i<ArraySize ( AllMessages ) ; i++ ) {
         if ( ( StringFind ( AllMessages [ i ] , "|S|" , 0 ) >= 0 ) || ( StringFind ( AllMessages [ i ] , "|B|" , 0 ) >= 0 ) ) {
            if ( StringFind ( AllMessages [ i ] , "TEST|" , 0 ) >= 0 ) {
               sTestSIG_All += 1 ;
               if ( StringFind ( AllMessages [ i ] , "BBTEST" , 0 ) >= 0 ) { sTestSIGBB_All += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "MBTEST" , 0 ) >= 0 ) { sTestSIGMB_All += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "TVMTEST" , 0 ) >= 0 ) { sTestSIGTVM_All += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "VANTEST" , 0 ) >= 0 ) { sTestSIGVAN_All += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "8CAPTEST" , 0 ) >= 0 ) { sTestSIG8CAP_All += 1 ; }
               else { Print ( AllMessages [ i ] ) ; }
            } else {
               sLiveSIG_All += 1 ;
               if ( StringFind ( AllMessages [ i ] , "BB" , 0 ) >= 0 ) { sLiveSIGBB_All += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "MB" , 0 ) >= 0 ) { sLiveSIGMB_All += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "TVM" , 0 ) >= 0 ) { sLiveSIGTVM_All += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "VAN" , 0 ) >= 0 ) { sLiveSIGVAN_All += 1 ; }
               else if ( StringFind ( AllMessages [ i ] , "8CAP" , 0 ) >= 0 ) { sLiveSIG8CAP_All += 1 ; }
               else { Print ( "error in: " + AllMessages [ i ] ) ; }}}}

   //===========================================================================================================
   //=====                                           CHECKS                                                =====
   //===========================================================================================================

   string sCheckLastWeek="" , sCheckDeployed="" , sCheckSunset="" , sCheckFailed="" , sCheckLive="" , sCheckTesting="" ;
   string sCheckLiveSIG="" , sCheckTestSIG="" , sCheckLiveSIG_All="" , sCheckTestSIG_All="" ;
   if ( sLastWeekBB + sLastWeekMB + sLastWeekTVM + sLastWeekVAN + sLastWeek8CAP == sLastWeek ) { sCheckLastWeek = "" ; } else { sCheckLastWeek = "error" ; }
   if ( sDeployedBB + sDeployedMB + sDeployedTVM + sDeployedVAN + sDeployed8CAP == sDeployed ) { sCheckDeployed = "" ; } else { sCheckDeployed = "error" ; }
   if ( sSunsetBB + sSunsetMB + sSunsetTVM + sSunsetVAN + sSunset8CAP == sSunset ) { sCheckSunset = "" ; } else { sCheckSunset = "error" ; }
   if ( sFailedBB + sFailedMB + sFailedTVM + sFailedVAN + sFailed8CAP == sFailed ) { sCheckFailed = "" ; } else { sCheckFailed = "error" ; }
   if ( sLiveBB + sLiveMB + sLiveTVM + sLiveVAN + sLive8CAP == sLive ) { sCheckLive = "" ; } else { sCheckLive = "error" ; }
   if ( sTestingBB + sTestingMB + sTestingTVM + sTestingVAN + sTesting8CAP == sTesting ) { sCheckTesting = "" ; } else { sCheckTesting = "error" ; }

   if ( sLiveSIGBB + sLiveSIGMB + sLiveSIGTVM + sLiveSIGVAN + sLiveSIG8CAP == sLiveSIG ) { sCheckLiveSIG = "" ; } else { sCheckLiveSIG = "error" ; }
   if ( sTestSIGBB + sTestSIGMB + sTestSIGTVM + sTestSIGVAN + sTestSIG8CAP == sTestSIG ) { sCheckTestSIG = "" ; } else { sCheckTestSIG = "error" ; }

   if ( sLiveSIGBB_All + sLiveSIGMB_All + sLiveSIGTVM_All + sLiveSIGVAN_All + sLiveSIG8CAP_All == sLiveSIG_All ) {
      sCheckLiveSIG_All = "" ; } else { sCheckLiveSIG_All = "error" ; }
   if ( sTestSIGBB_All + sTestSIGMB_All + sTestSIGTVM_All + sTestSIGVAN_All + sTestSIG8CAP_All == sTestSIG_All ) {
      sCheckTestSIG_All = "" ; } else { sCheckTestSIG_All = "error" ; }

   //===========================================================================================================
   //=====                                       WRITE 2 SERVER                                            =====
   //===========================================================================================================

      glb_ServerPHP = "saveeofn.php" ;
      glb_ServerPath = "/PERFHIST/" ;
      glb_ServerFileName = "dashboard.html" ;

      goSNR_HTML_Header ( "34" ) ;

      // ----------------------------------------------------------------------------------CONTENT START HERE

         prvA2H ( "<div class='line'></div>" ) ;

         // -------------------- Write line here
         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile'>Stats Since:</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( StringSubstr ( safLastSAT , 0 , 6 ) ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line mobile'></div>" ) ;

         prvA2H ( "<div class='line'>" ) ;
         prvA2H ( "<div class='field wp200 '></div>" ) ;
         prvA2H ( "<div class='field wp100 '>ALL</div>" ) ;
         prvA2H ( "<div class='field wp75 '>BB</div>" ) ;
         prvA2H ( "<div class='field wp75 '>MB</div>" ) ;
         prvA2H ( "<div class='field wp75 '>TVM</div>" ) ;
         prvA2H ( "<div class='field wp75 '>VAN</div>" ) ;
         prvA2H ( "<div class='field wp75 '>8CAP</div>" ) ;
         prvA2H ( "<div class='field wp75 '></div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line'></div>" ) ;

         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile' style='justify-content: left'>Live from last week</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( sLastWeek ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLastWeekBB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLastWeekMB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLastWeekTVM ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLastWeekVAN ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLastWeek8CAP ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sCheckLastWeek ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile' style='justify-content: left'>Deployed this week</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( sDeployed ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sDeployedBB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sDeployedMB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sDeployedTVM ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sDeployedVAN ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sDeployed8CAP ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sCheckDeployed ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile' style='justify-content: left;'>Sunset this week</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( sSunset ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sSunsetBB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sSunsetMB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sSunsetTVM ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sSunsetVAN ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sSunset8CAP ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sCheckSunset ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile' style='justify-content: left'>Failed this week</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( sFailed ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sFailedBB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sFailedMB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sFailedTVM ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sFailedVAN ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sFailed8CAP ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sCheckFailed ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line mobile'></div>" ) ;

         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile' style='justify-content: left'>Live BOTS</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( sLive ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveBB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveMB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveTVM ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveVAN ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLive8CAP ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sCheckLive ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile' style='justify-content: left'>Testing BOTS</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( sTesting ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestingBB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestingMB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestingTVM ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestingVAN ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTesting8CAP ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sCheckTesting ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line mobile'></div>" ) ;

         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile' style='justify-content: left'>Live signals this week</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( sLiveSIG ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveSIGBB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveSIGMB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveSIGTVM ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveSIGVAN ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveSIG8CAP ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sCheckLiveSIG ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile' style='justify-content: left'>Test signals this week</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( sTestSIG ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestSIGBB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestSIGMB ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestSIGTVM ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestSIGVAN ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestSIG8CAP ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sCheckTestSIG ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line mobile'></div>" ) ;

         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile' style='justify-content: left'>Live signals all time</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( sLiveSIG_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveSIGBB_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveSIGMB_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveSIGTVM_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveSIGVAN_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sLiveSIG8CAP_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sCheckLiveSIG_All ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile' style='justify-content: left'>Test signals all time</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( sTestSIG_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestSIGBB_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestSIGMB_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestSIGTVM_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestSIGVAN_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sTestSIG8CAP_All ) + "</div>" ) ;
         prvA2H ( "<div class='field wp75 '>" + string ( sCheckTestSIG_All ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

         prvA2H ( "<div class='line mobile'></div>" ) ;

         prvA2H ( "<div class='line mobile'>" ) ;
         prvA2H ( "<div class='field wp200 mobile'>Receivers</div>" ) ;
         prvA2H ( "<div class='field wp100 mobile'>" + string ( sRadio ) + "</div>" ) ;
         prvA2H ( "</div>" ) ;

      // ----------------------------------------------------------------------------------CONTENT END HERE

      goSNR_HTML_Footer ( "1" ) ;

      goServer_WriteExcel () ;
      return true ; }

   bool goServer_WriteExcel () {
      //// if ( glb_DebugMode ) { goDebug ( "goServer_WriteExcel" ) ; }
      if ( glb_SilentMode == true ) { return false ; }
      // -------------------- Destination info
      glb_ServerPHP = "saveeofn.php" ;
      glb_ServerPath = "/PERFHIST/" ;
      glb_ServerFileName = "ConfigStrings.csv" ;
      // -------------------- Read file content
      string safURL = glb_ServerIP + "SNRobotiX/operations.txt" ;
      string safHTML = goRead_Website ( safURL , safURL ) ;
      if ( StringLen ( safHTML ) < 1 ) { return false ; }
      // -------------------- Split message by start and clear html
      string Result1[] , Result2[] ;
      StringReplace ( safHTML , glb_MsgStart , CharToString ( 1 ) ) ;
      StringSplit ( safHTML , 1 , Result1 ) ;
      safHTML = "" ;
      // -------------------- Start new file
      string safHeader = ",,,=AVERAGE(D3:D100000),=AVERAGE(E3:E100000),=AVERAGE(F3:F100000),=AVERAGE(G3:G100000),,,,,,,,," ;
      safHeader += "=COUNTIF(P3:P100000;TRUE)/(COUNTIF(P3:P100000;TRUE)+COUNTIF(P3:P100000;FALSE)),,,,,,,,,,,,,,,,,,,,,,,,,,,,";
      safHeader += "=AVERAGE(AR3:AR100000)" ;
      goServer_Write_String ( goURLEncode ( safHeader ) , "w" ) ;
      safHeader = "Instrument,Broker,Config String,Trades,DD,RF,SR," ;
      safHeader += "TP Multiple,MA Period,MA Trend,RSI Period,RSI Trend,ADX Period,ADX Trend,ADX Target," ;
      safHeader += "EquBal,Session,Daily,SMA,EMA,SMMA,DEMA,TEMA,SAR,Frama,Vidya,AMA," ;
      safHeader += "RSI,Chaikan,CCI,Demarker,Force,Momentum,WPR,RVI,MFI,AO,TRIX,ADX,ADXW," ;
      safHeader += "Ichimoku,Biggest,RSI Close, True Count" ;
      goServer_Write_String ( goURLEncode ( safHeader ) ) ;
      // --------------------
      string AllConfigStrings[] ;
      string AllWrite2FileStrings[] ;
      // -------------------- Go thru message and split by end
      for ( int i=1 ; i<ArraySize ( Result1 ) ; i++ ) {
         StringReplace ( Result1 [ i ] , glb_MsgEnd , CharToString ( 1 ) ) ;
         StringSplit ( Result1 [ i ] , 1 , Result2 ) ;
         // -------------------- select only config strings here
         int safMinLength = 200 ;
         if ( StringLen ( Result2 [ 0 ] ) < safMinLength ) { continue ; }
         // -------------------- dismantle and recombine here
         string sTxt = "" ;
         sTxt = "SUNSET|" ; if ( StringFind ( Result2 [ 0 ] , sTxt , 0 ) >= 0 ) { StringReplace ( Result2 [ 0 ] , sTxt , CharToString ( 1 ) ) ; }
         sTxt = "DEPLOYED|" ; if ( StringFind ( Result2 [ 0 ] , sTxt , 0 ) >= 0 ) { StringReplace ( Result2 [ 0 ] , sTxt , CharToString ( 1 ) ) ; }
         sTxt = "FAILEDAUTODEPLOY|" ; if ( StringFind ( Result2 [ 0 ] , sTxt , 0 ) >= 0 ) { StringReplace ( Result2 [ 0 ] , sTxt , CharToString ( 1 ) ) ; }
         sTxt = "STARTED|" ; if ( StringFind ( Result2 [ 0 ] , sTxt , 0 ) >= 0 ) { StringReplace ( Result2 [ 0 ] , sTxt , CharToString ( 1 ) ) ; }
         sTxt = "ADJUST|" ; if ( StringFind ( Result2 [ 0 ] , sTxt , 0 ) >= 0 ) { StringReplace ( Result2 [ 0 ] , sTxt , CharToString ( 1 ) ) ; }
         // --------------------
         string FinalBit[] ;
         StringSplit ( Result2 [ 0 ] , 1 , FinalBit ) ;
         if ( ArraySize ( FinalBit ) < 2 ) { continue ; }
         // -------------------- Get broker here
         string BrokerBits [] ;
         StringSplit ( FinalBit [ 0 ] , StringGetCharacter ( "|" , 0 ) , BrokerBits ) ;
         if ( ArraySize ( BrokerBits ) < 2 ) { continue ; }
         string safBroker = BrokerBits [ 0 ] ;
         StringReplace( safBroker , "TEST" , "" ) ;
         if ( safBroker == "" ) { continue ; }
         // --------------------
         string LineBits [] ;
         StringSplit ( FinalBit [ 1 ] , StringGetCharacter ( "|" , 0 ) , LineBits ) ;
         if ( ArraySize ( LineBits ) < 2 ) { continue ; }
         string safCurrency = StringSubstr ( LineBits [ 0 ] , 0 , 6 ) ;
         // --------------------
         string ConfigString = "|" ;
         for ( int j=1 ; j < 37 ; j++ ) {
            StringToLower ( LineBits [ j ] ) ;
            ConfigString += LineBits [ j ] + "|"; }
         ConfigString += safBroker + "-" + safCurrency + "|" ;
         // --------------------
         int safX = ArraySize ( AllConfigStrings ) ;
         ArrayResize ( AllConfigStrings , ( safX + 1 ) ) ;
         ArrayResize ( AllWrite2FileStrings , ( safX + 1 ) ) ;
         // --------------------
         AllConfigStrings [ safX ] = ConfigString ;
         // --------------------
         string result = safCurrency + "," + safBroker + "," + ConfigString ;
         result += "," + LineBits [ 37 ] + "," ;
         result += (string) ND2 ( (double) LineBits [ 38 ] ) + "," ;
         result += (string) ND2 ( (double) LineBits [ 39 ] ) + "," ;
         result += (string) ND2 ( (double) LineBits [ 40 ] ) ;
         // --------------------
         int safTrueCount = 0 ;
         for ( int j=1 ; j < 37 ; j++ ) {
            result += "," + LineBits [ j ] ;
            if ( ( j >= 12 ) && ( j <= 33 ) ) {
               if ( LineBits [ j ] == "true" ) {
                  safTrueCount += 1 ; }}}
         result += "," + (string) safTrueCount ;
         AllWrite2FileStrings [ safX ] = result ; }
         // --------------------
         for ( int i=0 ; i < ArraySize ( AllConfigStrings ) ; i++ ) {
            if ( StringLen ( AllConfigStrings [ i ] ) < 1 ) { continue ; }
            goServer_Write_String ( goURLEncode ( AllWrite2FileStrings [ i ] ) ) ;
            string safOne = AllConfigStrings [ i ] ;
            for ( int j=i+1 ; j < ArraySize ( AllConfigStrings ) ; j++ ) {
               string safTwo = AllConfigStrings [ j ] ;
               if ( safOne == safTwo ) { AllConfigStrings [ j ] = "" ; }}}
      return true ; }