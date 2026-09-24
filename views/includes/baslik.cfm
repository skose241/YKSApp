<cfset oturumKontrol=structKeyExists(SESSION,"kullaniciID") AND val(SESSION.kullaniciID) GT 0>
 
<cfif oturumKontrol>
	<cfquery name="qOkunmamis" datasource="DSN">
		SELECT COUNT(*) AS adet
		FROM Bildirim
		WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
		AND goruldu=0
	</cfquery>
</cfif>
 
<!DOCTYPE HTML>
<html lang="tr" data-tema="gunduz">
	<head>
		<cfoutput>
			<meta charset="UTF-8">
			<meta name="viewport" content="width=device-width,initial-scale=1.0,viewport-fit=cover">
			<meta name="theme-color" content="##E9EEEE">
 
			<title>Net Peşinde</title>
 
			<link href="/YKSSite/assets/vendor/katex/katex.min.css?v=#application.varlikSurum#" rel="stylesheet">
			<link href="/YKSSite/assets/css/style.css?v=#application.varlikSurum#" rel="stylesheet">
 
			<cfif structKeyExists(request,"ekstraCss")>
				<link href="/YKSSite/assets/css/#request.ekstraCss#?v=#application.varlikSurum#" rel="stylesheet">
			</cfif>
 
			<link href="/YKSSite/manifest.json" rel="manifest">
			<link href="/YKSSite/assets/images/favicon.ico" rel="icon" type="image/png" sizes="192x192">
			<link href="/YKSSite/assets/images/favicon.ico" rel="apple-touch-icon">
		</cfoutput>
 
		<script>
			try{
				document.documentElement.dataset.tema=localStorage.getItem("npTema") || "gunduz";
			}catch(e){}
		</script>
	</head>
 
	<body>
		<svg class="simge-seti" aria-hidden="true" focusable="false">
			<symbol id="s-zil" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M18 8a6 6 0 1 0-12 0c0 6-3 8-3 8h18s-3-2-3-8"/>
				<path d="M13.7 21a2 2 0 0 1-3.4 0"/>
			</symbol>
 
			<symbol id="s-ay" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5z"/>
			</symbol>
 
			<symbol id="s-kisi" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<circle cx="12" cy="8" r="4"/>
				<path d="M4 20a8 8 0 0 1 16 0"/>
			</symbol>
 
			<symbol id="s-kupa" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M5 20V10M12 20V4M19 20v-6"/>
			</symbol>
 
			<symbol id="s-kalkan" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M12 3 5 6v6c0 4.5 3 7.7 7 9 4-1.3 7-4.5 7-9V6l-7-3z"/>
			</symbol>
 
			<symbol id="s-cikis" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M15 17l5-5-5-5"/>
				<path d="M20 12H9"/>
				<path d="M9 4H5v16h4"/>
			</symbol>
 
			<symbol id="s-kalp" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M12 20.5 3.6 12.3a4.8 4.8 0 0 1 6.8-6.8l1.6 1.5 1.6-1.5a4.8 4.8 0 0 1 6.8 6.8Z"/>
			</symbol>
 
			<symbol id="s-kalp-dolu" viewBox="0 0 24 24" fill="currentColor">
				<path d="M12 20.5 3.6 12.3a4.8 4.8 0 0 1 6.8-6.8l1.6 1.5 1.6-1.5a4.8 4.8 0 0 1 6.8 6.8Z"/>
			</symbol>
 
			<symbol id="s-goz" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M2 12s3.6-6 10-6 10 6 10 6-3.6 6-10 6-10-6-10-6Z"/>
				<circle cx="12" cy="12" r="3"/>
			</symbol>
 
			<symbol id="s-sohbet" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M21 12a8 8 0 0 1-8 8H4l2-3a8 8 0 1 1 15-5Z"/>
			</symbol>
 
			<symbol id="s-yorum" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M21 12a8 8 0 0 1-8 8H4l2-3a8 8 0 1 1 15-5Z"/>
				<path d="M9 11h.01M12.5 11h.01M16 11h.01"/>
			</symbol>
 
			<symbol id="s-begeni" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M7 22V10l5-8a2.5 2.5 0 0 1 2.5 3l-1 5H20a2 2 0 0 1 2 2.4l-1.4 7A2 2 0 0 1 18.6 21H7Z"/>
			</symbol>
 
			<symbol id="s-bayrak" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M5 21V4h13l-2.5 4L18 12H5"/>
			</symbol>
 
			<symbol id="s-ayar" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<circle cx="12" cy="12" r="3"/>
				<path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9 7 7M17 17l2.1 2.1M19.1 4.9 17 7M7 17l-2.1 2.1"/>
			</symbol>
 
			<symbol id="s-robot" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<rect x="4" y="8" width="16" height="12" rx="3"/>
				<path d="M12 8V5M9 13v1M15 13v1"/>
				<circle cx="12" cy="4" r="1"/>
			</symbol>
 
			<symbol id="s-ok-sag" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="m9 6 6 6-6 6"/>
			</symbol>
 
			<symbol id="s-yukle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M7 19a4.5 4.5 0 0 1-.6-9A6 6 0 0 1 18 10.5a4 4 0 0 1-.6 8"/>
				<path d="M12 16V9m-3 3 3-3 3 3"/>
			</symbol>
 
			<symbol id="s-artik" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
				<path d="M12 5v14M5 12h14"/>
			</symbol>
 
			<symbol id="s-akis" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
				<path d="M4 6h16M4 12h16M4 18h10"/>
			</symbol>
		</svg>
 
		<a class="atla" href="##icerik">İçeriğe Atla</a>
 
		<cfoutput>
			<header class="ust-bar">
				<div class="ust-bar__ic">
					<a class="logo" href="/YKSSite/anaSayfa.cfm">
						<span class="logo__net">Net</span>
						<span class="logo__ad">Peşinde</span>
					</a>
 
					<span class="ust-bar__bosluk"></span>
 
					<cfif oturumKontrol>
						<span class="rozet rozet--xp"><span class="veri">#val(SESSION.xp ?:0)#</span> XP</span>
 
						<a class="simge-dugme zil" href="/YKSSite/views/bildirim/bildirimler.cfm" aria-label="Bildirimler">
							<svg class="simge simge--buyuk"><use href="##s-zil"></use></svg>
							<cfif qOkunmamis.adet GT 0>
								<span class="zil__sayi veri" aria-hidden="true">#qOkunmamis.adet GT 9 ? "9+":qOkunmamis.adet#</span>
								<span class="gizli-metin">#qOkunmamis.adet# adet okunmamış bildirim</span>
							</cfif>
						</a>
 
						<button class="simge-dugme" id="temaDugme" type="button" aria-label="Gece moduna geç">
							<svg class="simge simge--buyuk"><use href="##s-ay"></use></svg>
						</button>
 
						<details class="hesap">
							<summary class="hesap__dugme" aria-label="Hesap menüsü">
								<span class="hesap__harf">#uCase(left(SESSION.kullaniciAd,2))#</span>
							</summary>
 
							<div class="hesap__liste">
								<p class="hesap__ad">#encodeForHTML(SESSION.kullaniciAd)#</p>
 
								<a class="hesap__satir" href="/YKSSite/views/profil/profilim.cfm">
									<svg class="simge"><use href="##s-kisi"></use></svg>Profilim
								</a>
 
								<a class="hesap__satir" href="/YKSSite/views/profil/liderlikTablosu.cfm">
									<svg class="simge"><use href="##s-kupa"></use></svg>Liderlik Tablosu
								</a>
 
								<cfif val(SESSION.rol) GTE 2>
									<a class="hesap__satir hesap__satir--yonetim" href="/YKSSite/views/yonetim/panel.cfm">
										<svg class="simge"><use href="##s-kalkan"></use></svg>Yönetim Paneli
									</a>
								</cfif>
 
								<a class="hesap__satir hesap__satir--cikis" href="/YKSSite/views/kimlik/cikis.cfm">
									<svg class="simge"><use href="##s-cikis"></use></svg>Çıkış Yap
								</a>
							</div>
						</details>
					<cfelse>
						<button class="simge-dugme" id="temaDugme" type="button" aria-label="Gece moduna geç">
							<svg class="simge simge--buyuk"><use href="##s-ay"></use></svg>
						</button>
 
						<a class="dugme dugme--sade" href="/YKSSite/views/kimlik/giris.cfm">Giriş Yap</a>
						<a class="dugme dugme--ana" href="/YKSSite/views/kimlik/kayit.cfm">Kayıt Ol</a>
					</cfif>
				</div>
			</header>
		</cfoutput>
 
		<div class="kabuk">
			<cfif oturumKontrol>
				<nav class="yan-menu" aria-label="Ana Menü">
					<a class="menu-baglanti" href="/YKSSite/anaSayfa.cfm">
						<svg class="simge simge--buyuk"><use href="##s-akis"></use></svg>Ana Sayfa
					</a>
					<a class="menu-baglanti" href="/YKSSite/views/soru/soruEkle.cfm">
						<svg class="simge simge--buyuk"><use href="##s-artik"></use></svg>Soru Ekle
					</a>
					<a class="menu-baglanti" href="/YKSSite/views/profil/liderlikTablosu.cfm">
						<svg class="simge simge--buyuk"><use href="##s-kupa"></use></svg>Liderlik Tablosu
					</a>
					<p class="menu-baslik">Kayıtlarım</p>
					<a class="menu-baglanti" href="/YKSSite/views/profil/profilim.cfm">
						<svg class="simge simge--buyuk"><use href="##s-kisi"></use></svg>Profilim
					</a>
				</nav>
			</cfif>
 
			<main class="icerik" id="icerik">