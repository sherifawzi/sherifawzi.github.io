const SNRRobotData = document.createElement('Template');

	SNRRobotData.innerHTML = `

    <div id="SectionDIV" class="sSectionDIVLight">
        <div class="h20"></div>
        <div class="sContentW" >
            <p class="w100 FM JM sSectionTitle01">
                <span>B A C K T E S T I N G - R E S U L T S </span>
            </p>
            <div class="Divider"></div>
            <div class="w30 FL JM sBoxBorderLight">
                <p class="sSectionTitle02" > <span id="CURRENCYPAIR"></span> </p>
                <div class="Divider"></div>
                <p class="w60 FM JM sFontM">INSTRUMENT</p>
            </div>
            <div class="w30 FL JM sBoxBorderLight">
                <p class="sSectionTitle02"> <span id="TRADES"></span> </p>
                <div class="Divider"></div>
                <p class="w60 FM JM sFontM">TRADES PER WEEK</p>
            </div>
            <div class="w30 FL JM sBoxBorderLight">
                <p class="sSectionTitle02"> <span id="DDP"></span> </p>
                <div class="Divider"></div>
                <p class="w60 FM JM sFontM">MAX DRAWDOWN</p>
            </div>
            <div class="Divider"></div>
            <div class="h20"></div>
            <div class="w70 FL JL">
                <p class="sSectionTitle02"> <span class="sFontL">General Description</span> </p>
                <div class="Divider"></div>
                <div class="JL sFontM">
                    <p> <span id="GDESC01"></span> </p> <br>
                    <p> <span id="GDESC02"></span> </p> <br>
                    <p> <span id="GDESC03"></span> </p> <br>
                </div>
                <div class="h20"></div>
                <p class="sSectionTitle02"> <span class="sFontL">Description for traders</span> </p>
                <div class="Divider"></div>
                <div class="JL sFontM">
                    <p> <span id="SDESC01"></span> </p> <br>
                    <p> <span id="SDESC02"></span> </p> <br>
                    <p> <span id="SDESC03"></span> </p> <br>
                </div>
                <div class="h20"></div>
            </div>
            <div class="w25 FR JL">
                <div class="FM" >
                    <a href="https://www.mql5.com/en" >
                        <button class="w70 sButtonDark" >START COPYING</button>
                    </a>
                </div>
                <div class="h40"></div>			
                <div class="JL sFontM">
                    <p class="sSectionTitle02"> <span class="sFontL">Backtesting period</span> </p>
                    <div class="Divider"></div>
                    <p> <span id="PERIOD"></span> </p>
                    <div class="h20"></div>
                    <p class="sSectionTitle02 "> <span class="sFontL">Gain on account</span> </p>
                    <div class="Divider"></div>
                    <p> <span id="GAIN"></span> </p>
                    <div class="h20"></div>
                    <p class="sSectionTitle02 "> <span class="sFontL">Largest drawdown</span> </p>
                    <div class="Divider"></div>
                    <p> <span id="DDP2"></span> </p>						
                    <div class="h20"></div>
                    <p class="sSectionTitle02 "> <span class="sFontL">Recovery factor</span> </p>
                    <div class="Divider"></div>
                    <p> <span id="RECOVERY"></span> </p>						
                    <div class="h20"></div>
                    <p class="sSectionTitle02 "> <span class="sFontL">Sharpie ratio</span> </p>
                    <div class="Divider"></div>
                    <p> <span id="SHARPIE"></span> </p>						
                    <div class="h20"></div>
                </div>
            </div>
        </div>
        <div class="Divider"></div>
        <div class="h50"></div>
    </div>	

	` ; 
	document.body.appendChild(SNRRobotData.content) ;
	document.getElementById("CURRENCYPAIR").innerHTML = CURRENCYPAIR ;
	document.getElementById("GAIN").innerHTML = GAIN ;
	document.getElementById("TRADES").innerHTML = TRADES ;
	document.getElementById("DDP").innerHTML = DDP ;
	document.getElementById("DDP2").innerHTML = DDP2 ;
	document.getElementById("GDESC01").innerHTML = GDESC01 ;
	document.getElementById("GDESC02").innerHTML = GDESC02 ;
	document.getElementById("GDESC03").innerHTML = GDESC03 ;
	document.getElementById("SDESC01").innerHTML = SDESC01 ;
	document.getElementById("SDESC02").innerHTML = SDESC02 ;
	document.getElementById("SDESC03").innerHTML = SDESC03 ;
	document.getElementById("SHARPIE").innerHTML = SHARPIE ;
	document.getElementById("RECOVERY").innerHTML = RECOVERY ;
	document.getElementById("PERIOD").innerHTML = PERIOD ;