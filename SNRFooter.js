const SNRFooterTemplate = document.createElement('Template');

SNRFooterTemplate.innerHTML = `

			<div id="SUBSCRIBE"></div>
			<div id="SectionDIV" class ="sBgClr05 sTxtClr03">
				<div class="sContentW" >
					<div class="h50"></div>
					<p class="sTxtClr03 w100 FM JM sSectionTitle02">STAY UPDATED WITH OUR LATEST DEVELOPMENTS</p>
					<div class="Divider"></div>
					<div class="w40 FM JM">
						<input type="text" id="email" name="email" class="sTxtBox01 JM" placeholder="Enter your email here">
					</div>
					<div class="Divider"></div>
					<p class="sTxtClr04 JM w100 sFontXS">*By submitting your information, you are granting us permission to email you, you may unsubscribe at any time</p>
					<div class="Divider"></div>
					<div class="w20 FM">
						<a href="" >
							<button class="w100 FM sButton01" >SUBSCRIBE NOW</button>
						</a>
					</div>
				</div>
				<div class="Divider"></div>
				<div class="h50"></div>
			</div>

			<div id="FooterDIV" class="sBgClr06 sTxtClr03">
				<div class="sContentW" >
					<div class="h30"></div>
					<div class="w90 FM" >
						<div class="Divider"></div>
						<div class="FL w40 JL">
							<p class="sFontB">COMPANY INFORMATION</p>
							<div class="Divider"></div>
							<p class="sFontM sTxtClr04">SNRobotiX Aps</p>
							<div class="h3"></div>
							<a href="https://goo.gl/maps/P3oWtd69eZsi5STQ7" class="sLink" target="_blank"><p class="sFontS sTxtClr04 h20">Skolegade, Valby</p></a>
							<div class="h3"></div>
							<p class="sFontS sTxtClr04 h20">Copenhagen, Denmark</p>
							<div class="h3"></div>
							<p class="sFontS sTxtClr04 h20">CVR: 43344943</p>
							<div class="Divider"></div>
							<div class="Divider"></div>
							<p class="sFontB">SOCIAL MEDIA</p>
							<div class="Divider"></div>
							<div class="w7 FL" ><a href = "https://www.instagram.com/snrobotix/" target="_blank"><img src="Pics/Instagram.svg" style="width:60%"></a></div>
							<div class="w7 FL" ><a href = "https://twitter.com/snrobotix/" target="_blank"><img src="Pics/Twitter.svg" style="width:60%"></a></div>
							<div class="w7 FL" ><a href = "https://dk.linkedin.com/company/snrobotix/" target="_blank"><img src="Pics/LinkedIn.svg" style="width:60%"></a></div>
							<div class="w7 FL" ><a href = "https://www.facebook.com/SNRobotiX-110072341725308/" target="_blank"><img src="Pics/facebook.png" style="width:60%"></a></div>
						</div>
						<div class="FR w50 JR">
							<p class="sFontB">LINKS</p>

							<div class="h10"></div>
							<a href="Blog.html" class="sLink"><p class="sFontM sTxtClr04 h20">Our Blog</p></a>
							
							<div class="h7"></div>
							<a href="Privacy.html" class="sLink"><p class="sFontM sTxtClr04 h20">Privacy Policy</p></a>
							
							<div class="h7"></div>
							<a href="Cookies.html" class="sLink"><p class="sFontM sTxtClr04 h20">Cookies</p></a>
							
							<div class="h7"></div>
							<a href="DataPolicy.html" class="sLink"><p class="sFontM sTxtClr04 h20">Data Policy</p></a>
							
							<div class="h7"></div>
							<a href="FAQ.html" class="sLink"><p class="sFontM sTxtClr04 h20">FAQs</p></a>

							<div class="h7"></div>
							<a href="AboutUS.html" class="sLink"><p class="sFontM sTxtClr04 h20">About Us</p></a>

							</div>
					</div>
					<div class="Divider"></div>
					<div class="Divider"></div>
					<div class="Divider"></div>
					<div class="FM JM sTxtClr04 sFontXS">
						SNRobotiX is a software development company and does not provide any financial, investment, brokerage, nor is it involved in any commission-based payments concerning any trading operations
					</div>
					<div class="FM JM sTxtClr04 sFontXS">
						Risk Warning: Margin trading involves a high level of risk and is not suitable for all investors. You should carefully consider your objectives, financial situation, needs and level of experience before entering any margined transactions, and seek independent advice if necessary. FOREX and CFDs are highly leveraged products, which means both gains and losses are magnified. You should only trade in these products if you fully understand the risks involved and can afford to incur losses that will not adversely affect your lifestyle
					</div>
					<div class="Divider"></div>
					<div class="w47 FL JR sTxtClr03">
						(c) Copyright SNRobotiX ApS
					</div>
					<div class="w47 FR JL sTxtClr03">Contact Us: 
						<a href="mailto:hello@snrobotix.com" class="sLink sTxtClr03">
							hello@snrobotix.com
						</a>
					</div>
				</div>
				<div class="Divider"></div>
				<div class="h30"></div>
			</div>

` ; document.body.appendChild(SNRFooterTemplate.content) ;