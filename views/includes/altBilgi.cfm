            </main>
		</div>
 
		<cfparam name="oturumKontrol" default="#structKeyExists(SESSION,'kullaniciID') AND val(SESSION.kullaniciID) GT 0#">
 
		<cfif oturumKontrol>
			<nav class="alt-tab" aria-label="Alt Menü">
				<a class="tab" href="/YKSSite/anaSayfa.cfm">
					<svg class="simge simge--buyuk"><use href="#chr(35)#s-akis"></use></svg>Akış
				</a>
				<a class="tab" href="/YKSSite/views/profil/liderlikTablosu.cfm">
					<svg class="simge simge--buyuk"><use href="#chr(35)#s-kupa"></use></svg>Liderlik Tablosu
				</a>
				<a class="tab tab--ekle" href="/YKSSite/views/soru/soruEkle.cfm">
					<span class="tab__daire">
						<svg class="simge simge--buyuk"><use href="#chr(35)#s-artik"></use></svg>
					</span>
					<span class="gizli-metin">Soru Ekle</span>
				</a>
				<a class="tab" href="/YKSSite/views/bildirim/bildirimler.cfm">
					<svg class="simge simge--buyuk"><use href="#chr(35)#s-zil"></use></svg>Bildirim
				</a>
				<a class="tab" href="/YKSSite/views/profil/profilim.cfm">
					<svg class="simge simge--buyuk"><use href="#chr(35)#s-kisi"></use></svg>Profilim
				</a>
			</nav>
		</cfif>
 
		<cfoutput>
			<script src="/YKSSite/assets/vendor/katex/katex.min.js?v=#application.varlikSurum#" defer></script>
			<script src="/YKSSite/assets/vendor/katex/auto-render.min.js?v=#application.varlikSurum#" defer></script>
			<script src="/YKSSite/assets/js/custom.js?v=#application.varlikSurum#" defer></script>
		</cfoutput>
 
		<cfoutput>
			<script>
				if("serviceWorker" in navigator){
					window.addEventListener("load", function(){
						navigator.serviceWorker.register("/YKSSite/service-worker.js?v=#application.varlikSurum#");
					});
				}
			</script>
		</cfoutput>
	</body>
</html>