const SNRHeaderTemplateCTA = document.createElement('Template');

SNRHeaderTemplateCTA.innerHTML = `

<div id="NavbarDIV" class="sBgClr06 sTxtClr03 sFontB">
<div class="sContentW" >
	<div class="w7 FL" >
		<a href = "index.html" >
			<img style="max-width:90% ; padding-top:5px ; " src="Pics/MainLogoPNG.png" >
		</a>
	</div>
	<div class="w15 FR" style="margin-top: 10px;">
		<a href="Bots.html" >
			<button class="w100 sButton01" >GET STARTED</button>
		</a>
	</div>
	<div class="w12 FR JM sNavItem">
		<a href = "FAQ.html" class="sLink" >
			FAQ
		</a>
	</div>
	<div class="w12 FR JM sNavItem" >
		<a href = "index.html#WHYSNR" class="sLink" >
			WHY SNR_?
		</a>
	</div>
	<div class="w12 FR JM sNavItem" >
		<a href = "Bots.html" class="sLink" >
			OUR BOTS
		</a>
	</div>
</div>
</div>

` ; document.body.appendChild(SNRHeaderTemplateCTA.content) ;