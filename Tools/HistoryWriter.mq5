
   #include <newFunctions.mqh>

   #define SNR_BOTVER      "Bot Version: 24.01.03"

   #property copyright     SNR_COPYRIGHT
   #property link          SNR_WEBSITE
   #property description   SNR_LIBVER
   #property description   SNR_BOTVER

   void OnInit () {
      goOnInit ( __FILE__ ) ; }

   void OnTick () {
      if ( IsNewDay() ) {
         int safDelay = sRandomNumber ( 1 , 120000 ) ;
         Sleep ( safDelay ) ;
         goHistory_Send2Server() ; }}