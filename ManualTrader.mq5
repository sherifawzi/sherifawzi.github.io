
   //===========================================================================================================
   //=====                                          INCLUDES                                               =====
   //===========================================================================================================

   #include <newFunctions.mqh>

   #define SNR_BOTVER      "Bot Version: 24.07.03"

   #property copyright     SNR_COPYRIGHT
   #property link          SNR_WEBSITE
   #property description   SNR_LIBVER
   #property description   SNR_BOTVER

   //===========================================================================================================
   //=====                                           INPUTS                                                =====
   //===========================================================================================================

   input group "Beacon Settings:"
   input string      robo_Magic        = "SNR"       ; // EA Magic Number
   enumRiskLevel     robo_RiskLevel    = High            ; // Risk appetite

   //===========================================================================================================
   //=====                                          VARIABLES                                              =====
   //===========================================================================================================

   double robo_ATR=0 , robo_LotSLV=0 ;
   bool TickLock=false ;

   //===========================================================================================================
   //=====                                       INITIALIZATION                                            =====
   //===========================================================================================================

   void OnInit () {
      goOnInit ( __FILE__ ) ;
      // -------------------- Bot Magic
      glb_Magic = robo_Magic ;
      glb_BroadID = glb_Magic ;
      glb_BeaconMode = true ;
      glb_LotSize = 1 ;
      goDraw_ControlPanel ( "1" ) ; }

   //===========================================================================================================
   //=====                                         MAIN FUNCTIONS                                          =====
   //===========================================================================================================

   void OnTick () {
      if ( TickLock ) { return ; }
      // -------------------- Abort checks
      if ( !IsNewCandle() ) { return ; }
      // -------------------- x
      TickLock = true ;
         // -------------------- Set ATR
         if ( !ind_ATR ( 14 ) ) { TickLock = false ; return ; }
         robo_ATR = B0 [ glb_FC ] ;
      TickLock = false ; }

   //===========================================================================================================
   //=====                                         BUTTON FUNCTION                                         =====
   //===========================================================================================================

////   void goDraw_ControlPanel (
////      int safY = 50 , int safX = 175 , int safYAdd = 50 , double BigButton = 160 , int SmallButton = 75 , int ItemHeight = 30 ) {
////         goDraw_Button ( "BuyButton" , safX , safY  , SmallButton , ItemHeight , clrBlue , clrWhite , "Buy" ) ;
////         goDraw_Button ( "SellButton" , 90 , safY , SmallButton , ItemHeight , clrRed , clrWhite , "Sell" ) ;
////         safY += safYAdd ; }
            
   void OnChartEvent ( const int id , const long &lparam , const double &dparam , const string &sparam ) {
      if ( id == CHARTEVENT_OBJECT_CLICK ) {
         goDraw_ButtonPress ( sparam , "DOWN" ) ;
            if ( sparam == "BuyButton" ) { goExecute_Buy() ; }
            if ( sparam == "SellButton" ) { goExecute_Sell() ; }
         goDraw_ButtonPress ( sparam , "UP" ) ; }}

   //===========================================================================================================
   //=====                                         TRADE FUNCTIONS                                         =====
   //===========================================================================================================

   void goExecute_Buy () {
      // -------------------- Set comment
      string safComment = glb_Magic + "|B/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + glb_EAS ;
      // -------------------- Calc trade stops and execute
      goCalcStops () ; sBuy ( 0 , 0 , ( 2 * robo_LotSLV ) , -1 , safComment ) ; }

   void goExecute_Sell () {
      // -------------------- Set comment
      string safComment = glb_Magic + "|S/" + string ( StringSubstr ( goGetDateTime () , 0 , 12 ) ) + "/" + glb_EAS ;
      // -------------------- Calc trade stops and execute
      goCalcStops () ; sSell ( 0 , 0 , ( 2 * robo_LotSLV ) , -1 , safComment ) ; }

   void goCalcStops () {
      // -------------------- Set divider value
      int myDiv = 1 ; if ( robo_RiskLevel == Lowest ) { myDiv = 50 ; }
      else if ( robo_RiskLevel == Lower ) { myDiv = 20 ; }
      else if ( robo_RiskLevel == Low ) { myDiv = 3 ; }
      // -------------------- Translate risk level
      string myRiskString = goTranslate_RiskLevel ( robo_RiskLevel ) ;
      robo_LotSLV = goCalc_PercentSLV ( "" , myRiskString , myDiv ) ; }