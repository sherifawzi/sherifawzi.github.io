const SNRPageTitle = document.createElement('Template');

	SNRPageTitle.innerHTML = `

	<div id="SectionDIV" class ="sSectionDIVMedium">
		<div class="sContentW" >
			<div class="h100"></div>
			<div class="JM sLandingTitle" >
				<span id="tit01" ></span>
				<span id="tit02" class="sShadow sTxtClrCTA" ></span>
			</div>
			<div class="sLineLight w40 FM h10" ></div>
			<div class="Divider"></div>
		</div>
		<div class="Divider"></div>
		<div class="h100"></div>
	</div>

	` ; 
	document.body.appendChild(SNRPageTitle.content) ;
	document.getElementById("tit01").innerHTML = tit01 ;
	document.getElementById("tit02").innerHTML = tit02 ;