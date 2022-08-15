
	const SNRHeaderTemplateCTA = document.createElement('Template');

	SNRHeaderTemplateCTA.innerHTML = `

	<div id="NavbarDIV" class="sSectionDIVDark">
		<div class="sContentW" >

			<div class="w7 FL" >
				<a href = "index.html" >
					<img style="max-width:90% ; padding-top:5px ; " src="Pics/MainLogoPNG.png" >
				</a>
			</div>

			<div class="w15 FR" style="margin-top: 10px;">
				<a href="Bots.html" >
					<button class="w100 sButtonLight" >GET STARTED</button>
				</a>
			</div>

			<div class="sNavItem" > <a href="FAQ.html" class="sLinkLight"> FAQ </a> </div>
			<div class="sNavItem" > <a href="index.html#WHYSNR" class="sLinkLight"> WHY SNR_? </a> </div>
			<div class="sNavItem" > <a href="Bots.html" class="sLinkLight"> OUR BOTS </a> </div>
	
		</div>
	</div>

	` ; 
	document.body.appendChild(SNRHeaderTemplateCTA.content) ;