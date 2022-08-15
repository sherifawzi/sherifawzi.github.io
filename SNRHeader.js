const SNRHeaderTemplate = document.createElement('Template');

	SNRHeaderTemplate.innerHTML = `

	<div id="NavbarDIV" class="sSectionDIVDark">
		<div class="sContentW" >

			<div class="w7 FL" >
				<a href = "index.html" >
					<img style="max-width:90% ; padding-top:5px ; " src="Pics/MainLogoPNG.png" >
				</a>
			</div>
	
			<div class="sNavItem" > <a href="FAQ.html" class="sLinkLight"> FAQ </a> </div>
			<div class="sNavItem" > <a href="index.html#WHYSNR" class="sLinkLight"> WHY SNR_? </a> </div>
			<div class="sNavItem" > <a href="Bots.html" class="sLinkLight"> OUR BOTS </a> </div>
	
		</div>
	</div>

	` ; 
	document.body.appendChild(SNRHeaderTemplate.content) ;