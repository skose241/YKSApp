<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">
<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfif structKeyExists(url,"id") AND isNumeric(url.id) AND val(url.id) GT 0>
    <cfset profilID=val(url.id)>
<cfelse>
    <cfset profilID=val(SESSION.kullaniciID)>
</cfif>

<cfset benimProfil=profilID EQ val(SESSION.kullaniciID)>
<cfparam name="sifreHata" default="">
<cfparam name="sifreBasari" default="">

<cfif benimProfil AND structKeyExists(form,"sifreDegistir")>
    <cfparam name="form.eskiSifre" default="">
    <cfparam name="form.yeniSifre" default="">
    <cfparam name="form.yeniSifreTekrar" default="">
    <cfparam name="form.csrf" default="">
    <cfset eskiSifre=trim(form.eskiSifre)>
    <cfset yeniSifre=trim(form.yeniSifre)>
    <cfset yeniSifreTekrar=trim(form.yeniSifreTekrar)>

    <cfif compare(form.csrf,SESSION.csrf) NEQ 0>
        <cfset sifreHata="Oturum doğrulaması başarısız.Sayfayı yenileyip tekrar deneyiniz.">
    <cfelseif eskiSifre EQ "" OR yeniSifre EQ "" OR yeniSifreTekrar EQ "">
        <cfset sifreHata="Lütfen tüm alanları doldurunuz.">
    <cfelseif len(yeniSifre) LT 6>
        <cfset sifreHata="Şifre en az 6 haneli olmalıdır.">
    <cfelseif yeniSifre NEQ yeniSifreTekrar>
        <cfset sifreHata="Şifreler eşleşmiyor.">
    <cfelseif compare(eskiSifre,yeniSifre) EQ 0>
        <cfset sifreHata="Yeni şifreniz mevcut şifrenizden farklı olmalıdır.">
    <cfelse>
        <cfset sifreleme=createObject("component","YKSSite.views.includes.sifreleme")>
        <cfquery name="qSifre" datasource="DSN">
            SELECT sifre,tuz,hashSurum
            FROM Kullanici
            WHERE id=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfset eskiSifreDogruMu=false>
        <cfif qSifre.recordCount GT 0>
            <cfset eskiSifreDogruMu=sifreleme.sifreDogrulama(
                sifre=eskiSifre,
                sifreHash=qSifre.sifre,
                tuz=qSifre.tuz,
                hashSurum=val(qSifre.hashSurum)
                )>
        </cfif>

        <cfif NOT eskiSifreDogruMu>
            <cfset sifreHata="Mevcut şifrenizi yanlış girdiniz.">
            <cfset sleep(600)>
        <cfelse>
            <cftry>
                <cfset yeniSifreSonuc=sifreleme.sifreUretme(sifre=yeniSifre,tuz=qSifre.tuz)>
                <cftransaction>
                    <cfquery datasource="DSN">
                        UPDATE Kullanici
                        SET sifre=<cfqueryparam value="#yeniSifreSonuc.hash#" cfsqltype="cf_sql_varchar">,
                        tuz=<cfqueryparam value="#yeniSifreSonuc.tuz#" cfsqltype="cf_sql_varchar">,
                        hashSurum=<cfqueryparam value="#yeniSifreSonuc.hashSurum#" cfsqltype="cf_sql_integer">
                        WHERE id=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
                    </cfquery>
                    <cfquery datasource="DSN">
                        UPDATE Oturum
                        SET aktiflik=0
                        WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
                        AND aktiflik=1
                    </cfquery>
                </cftransaction>
                <cfcookie name="beniHatirla" value="" expires="now" httponly="true" secure="true">
                <cfset sifreBasari="Şifreniz başarıyla güncellendi.Diğer cihazlardaki oturumlarınız kapatılmıştır.">
                <cfcatch type="any">
                    <cfset sifreHata="Şifre güncellenirken bir hata oluştu.">
                    <cfset aiHata=createObject("component","YKSSite.views.includes.ai")>
                    <cfset aiHata.hataYazma(
                        sayfa="/YKSSite/views/profil/profilim.cfm",
                        islem="sifreDegistir",
                        mesaj=cfcatch.message,
                        detay=cfcatch.detail
                        )>
                </cfcatch>
            </cftry>
        </cfif>
    </cfif>
</cfif>
<cfquery name="qProfil" datasource="DSN">
    SELECT id,ad,rol,xp,kayitTarihi
    FROM Kullanici
    WHERE id=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">
    AND aktiflik=1
</cfquery>

<cfif qProfil.recordCount EQ 0>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfquery name="qIstatistik" datasource="DSN">
    SELECT
    (SELECT COUNT(*) FROM Soru WHERE soranID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer"> AND aktiflik=1) AS soruAdet,
    (SELECT COUNT(*) FROM Cevap WHERE cozenID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer"> AND onay=1 AND aktiflik=1) AS dogruAdet,
    (SELECT COUNT(*) FROM Yorum WHERE yazanID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer"> AND aktiflik=1) AS yorumAdet,
    (SELECT COUNT(*) FROM Favori WHERE kullaniciID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">) AS favoriAdet
</cfquery>

<cfquery name="qSoru" datasource="DSN">
    SELECT TOP 24 s.id,s.soruResmi,s.soruMetni,s.sistemSoru,s.goruntulenmeSayisi,s.eklenmeTarihi,
    d.ad AS dersAd,a.ad AS alanAd
    FROM Soru s
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE s.soranID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">
    AND s.aktiflik=1
    ORDER BY s.eklenmeTarihi DESC
</cfquery>

<cfquery name="qCevap" datasource="DSN">
    SELECT TOP 24 s.id,s.soruResmi,s.soruMetni,s.sistemSoru,c.kullaniciCevabi,c.onay,c.eklenmeTarihi,
    d.ad AS dersAd,a.ad AS alanAd
    FROM Cevap c
    INNER JOIN Soru s ON s.id=c.soruID
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE c.cozenID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">
    AND c.aktiflik=1
    AND s.aktiflik=1
    ORDER BY c.eklenmeTarihi DESC
</cfquery>

<cfif benimProfil>
    <cfquery name="qFavori" datasource="DSN">
        SELECT TOP 24 s.id,s.soruResmi,s.soruMetni,s.sistemSoru,s.goruntulenmeSayisi,f.eklenmeTarihi,
        d.ad AS dersAd,a.ad AS alanAd
        FROM Favori f
        INNER JOIN Soru s ON s.id=f.soruID
        INNER JOIN Ders d ON d.id=s.dersID
        INNER JOIN Alan a ON a.id=d.alanID
        WHERE f.kullaniciID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">
        AND s.aktiflik=1
        ORDER BY f.eklenmeTarihi DESC
    </cfquery>
</cfif>

<cfoutput>
    <div class="yigin">
        <section class="kart">
            <div class="kart__govde">
                <div class="profil-ust">
                    <span class="avatar">#encodeForHTML(uCase(left(qProfil.ad,1)))#</span>
                    <div class="profil-ust__bilgi">
                        <h1 class="profil-ust__ad">#encodeForHTML(qProfil.ad)#</h1>
                        <div class="profil-ust__satir">
                            <span class="rozet">#qProfil.rol EQ 3 ? "Admin":qProfil.rol EQ 2 ? "Moderatör":"Kullanıcı"#</span>
                            <span class="rozet rozet--xp"><span class="veri">#numberFormat(qProfil.xp,',')#</span> XP</span>
                            <span class="sessiz">Kayıt Tarihi:#dateFormat(qProfil.kayitTarihi,'dd.mm.yyyy')#</span>
                        </div>
                    </div>
                    <cfif benimProfil>
                        <button class="dugme dugme--ikincil" type="button" data-pencere-ac="sifrePencere">Şifre Değiştir</button>
                    </cfif>
                </div>
            </div>
        </section>
        <cfif benimProfil AND len(sifreBasari)>
            <div class="bildirim bildirim--basarili" role="status">#encodeForHTML(sifreBasari)#</div>
        </cfif>
        <div class="istatistik">
            <div class="istatistik__kutu">
                <span class="istatistik__sayi">#qIstatistik.soruAdet#</span>
                <span class="istatistik__ad">Eklenen Soru Sayısı:</span>
            </div>
            <div class="istatistik__kutu istatistik__kutu--dogru">
                <span class="istatistik__sayi">#qIstatistik.dogruAdet#</span>
                <span class="istatistik__ad">Doğru Cevap Sayısı:</span>
            </div>
            <div class="istatistik__kutu">
                <span class="istatistik__sayi">#qIstatistik.yorumAdet#</span>
                <span class="istatistik__ad">Yorum:</span>
            </div>
            <div class="istatistik__kutu istatistik__kutu--favori">
                <span class="istatistik__sayi">#qIstatistik.favoriAdet#</span>
                <span class="istatistik__ad">Favori:</span>
            </div>
        </div>
        <div class="sekmeler" role="tablist">
            <button class="sekme" type="button" role="tab" aria-selected="true" aria-controls="panelSorular">Sorular:<span class="sekme__sayi">#qIstatistik.soruAdet#</span></button>
            <button class="sekme" type="button" role="tab" aria-selected="false" aria-controls="panelCevaplar">Çözümler:<span class="sekme__sayi">#qCevap.recordCount#</span></button>
            <cfif benimProfil>
                <button class="sekme" type="button" role="tab" aria-selected="false" aria-controls="panelFavoriler">Favorilerim:<span class="sekme__sayi">#qIstatistik.favoriAdet#</span></button>
            </cfif>
        </div>
        <div class="sekme-panel" id="panelSorular" role="tabpanel">
            <cfif qSoru.recordCount EQ 0>
                <div class="bos-durum">
                    <span class="bos-durum__daire" aria-hidden="true"></span>
                    <h3>Henüz soru yok,ilk soruyu siz ekleyin</h3>
                    <p>Eklediğiniz sorular burada listelenir</p>
                </div>
            <cfelse>
                <div class="soru-izgara">
                    <cfloop query="qSoru">
                        <article class="soru-kutu">
                            <a class="soru-kutu__ust" href="/YKSSite/views/soru/soruDetay.cfm?id=#qSoru.id#">
                                <cfif len(trim(qSoru.soruResmi))>
                                    <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qSoru.soruResmi)#"
                                        class="soru-kutu__gorsel" alt="Soru görseli">
                                <cfelse>
                                    <div class="soru-kutu__onizleme">#encodeForHTML(left(qSoru.soruMetni,160))#</div>
                                </cfif>
                            </a>
                            <div class="soru-kutu__govde">
                                <div class="soru-kutu__etiket">
                                    <span class="rozet rozet--sinav">#encodeForHTML(qSoru.alanAd)#</span>
                                    <span class="rozet rozet--ders">#encodeForHTML(qSoru.dersAd)#</span>
                                </div>
                                <div class="soru-kutu__sayac">
                                    <span><svg class="simge"><use href="##s-goz"></use></svg> #qSoru.goruntulenmeSayisi#</span>
                                    <span>#dateFormat(qSoru.eklenmeTarihi,'dd.mm.yyyy')#</span>
                                </div>
                            </div>
                        </article>
                    </cfloop>
                </div>
            </cfif>
        </div>
        <div class="sekme-panel" id="panelCevaplar" role="tabpanel" hidden>
            <cfif qCevap.recordCount EQ 0>
                <div class="bos-durum">
                    <span class="bos-durum__daire" aria-hidden="true"></span>
                    <h3>Henüz çözüm yok,ilk çözümü siz ekleyin</h3>
                    <p>Cevapladığınız sorular burada görüntülenir</p>
                </div>
            <cfelse>
                <div class="soru-izgara">
                    <cfloop query="qCevap">
                        <article class="soru-kutu">
                            <a class="soru-kutu__ust" href="/YKSSite/views/soru/soruDetay.cfm?id=#qCevap.id#">
                                <cfif len(trim(qCevap.soruResmi))>
                                    <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qCevap.soruResmi)#"
                                        class="soru-kutu__gorsel" alt="Soru görseli">
                                <cfelse>
                                    <div class="soru-kutu__onizleme">#encodeForHTML(left(qCevap.soruMetni,160))#</div>
                                </cfif>
                            </a>
                            <div class="soru-kutu__govde">
                                <div class="soru-kutu__etiket">
                                    <span class="rozet rozet--ders">#encodeForHTML(qCevap.dersAd)#</span>
                                    <cfif qCevap.onay EQ 1>
                                        <span class="rozet rozet--dogru">Doğru</span>
                                    <cfelseif qCevap.onay EQ 0>
                                        <span class="rozet rozet--yanlis">Yanlış</span>
                                    <cfelse>
                                        <span class="rozet">Belirsiz</span>
                                    </cfif>
                                </div>
                                <div class="soru-kutu__sayac">
                                    <span>#dateFormat(qCevap.eklenmeTarihi,'dd.mm.yyyy')#</span>
                                </div>
                            </div>
                        </article>
                    </cfloop>
                </div>
            </cfif>
        </div>
        <cfif benimProfil>
            <div class="sekme-panel" id="panelFavoriler" role="tabpanel" hidden>
                <cfif qFavori.recordCount EQ 0>
                    <div class="bos-durum">
                        <span class="bos-durum__daire" aria-hidden="true"></span>
                        <h3>Favoriniz bulunmamaktadır</h3>
                        <p>Zorlandığınız soruyu favorinize ekleyin,daha sonra hepsini listeden seçerek çözünüz</p>
                        <a class="dugme dugme--ikincil" href="/YKSSite/anaSayfa.cfm">Ana sayfaya dön</a>
                    </div>
                <cfelse>
                    <div class="soru-izgara">
                        <cfloop query="qFavori">
                            <article class="soru-kutu">
                                <a class="soru-kutu__ust" href="/YKSSite/views/soru/soruDetay.cfm?id=#qFavori.id#">
                                    <cfif len(trim(qFavori.soruResmi))>
                                        <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qFavori.soruResmi)#"
                                            class="soru-kutu__gorsel" alt="Soru görseli">
                                    <cfelse>
                                        <div class="soru-kutu__onizleme">#encodeForHTML(left(qFavori.soruMetni,160))#</div>
                                    </cfif>
                                </a>
                                <div class="soru-kutu__govde">
                                    <div class="soru-kutu__etiket">
                                        <span class="rozet rozet--sinav">#encodeForHTML(qFavori.alanAd)#</span>
                                        <span class="rozet rozet--ders">#encodeForHTML(qFavori.dersAd)#</span>
                                    </div>
                                    <div class="soru-kutu__sayac">
                                        <span><svg class="simge"><use href="##s-goz"></use></svg> #qFavori.goruntulenmeSayisi#</span>
                                    </div>
                                </div>
                            </article>
                        </cfloop>
                    </div>
                </cfif>
            </div>
        </cfif>
    </div>
    <cfif benimProfil>
        <dialog class="pencere" id="sifrePencere">
            <div class="kart__baslik">
                <span>Şifre Değiştir</span>
                <button class="simge-dugme" type="button" data-pencere-kapat aria-label="Kapat">✕</button>
            </div>
            <div class="pencere__govde">
                <cfif len(sifreHata)>
                    <div class="bildirim bildirim--hata ust-bosluk" role="alert">#encodeForHTML(sifreHata)#</div>
                </cfif>
                <form method="POST">
                    <cfinclude template="/YKSSite/views/includes/csrfAlan.cfm">
                    <div class="alan">
                        <label for="eskiSifre">Mevcut Şifre:</label>
                        <input class="girdi" type="password" name="eskiSifre" id="eskiSifre" autocomplete="current-password" required>
                    </div>
                    <div class="alan">
                        <label for="yeniSifre">Yeni Şifre:</label>
                        <input class="girdi" type="password" name="yeniSifre" id="yeniSifre" minlength="6" autocomplete="new-password" required>
                        <span class="alan__ipucu">Şifreniz en az 6 karakter uzunluğunda olmalıdır</span>
                    </div>
                    <div class="alan">
                        <label for="yeniSifreTekrar">Yeni Şifre Tekrarı:</label>
                        <input class="girdi" type="password" name="yeniSifreTekrar" id="yeniSifreTekrar" minlength="6" autocomplete="new-password" required>
                    </div>
                    <button class="dugme dugme--ana dugme--tam" type="submit" name="sifreDegistir" value="1">Güncelle</button>
                </form>
            </div>
        </dialog>
        <cfif len(sifreHata)>
            <script>
                document.getElementById("sifrePencere").showModal();
            </script>
        </cfif>
    </cfif>
</cfoutput>
<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">