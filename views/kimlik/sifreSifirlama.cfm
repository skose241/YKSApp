<cfif structKeyExists(SESSION,"kullaniciID") AND val(SESSION.kullaniciID)>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfparam name="hata" default="">
<cfparam name="basari" default="">
<cfparam name="adim" default="1">
<cfparam name="gizliSoru" default="">
<cfparam name="kullaniciAd" default="">
<cfparam name="dogrulamaKodu" default="">
<cfset sifreleme=createObject("component","YKSSite.views.includes.sifreleme")>
<cfset guvenlik=createObject("component","YKSSite.views.includes.guvenlik")>

<cfif structKeyExists(form,"adim1")>
    <cfparam name="form.kullaniciAd" default="">
    <cfset kullaniciAd=trim(form.kullaniciAd)>
    
    <cfif kullaniciAd EQ "">
        <cfset hata="Lütfen kullanıcı adınızı giriniz.">
    <cfelseif guvenlik.denemeSiniriAsildi(tur="sifirla",anahtar=lCase(kullaniciAd))>
        <cfset hata="Çok fazla deneme yaptınız.Lütfen 15 dakika sonra tekrar deneyiniz.">
    <cfelse>
        <cfquery name="qKullanici" datasource="DSN">
            SELECT k.id,k.ad,g.soruMetni
            FROM Kullanici k
            INNER JOIN GirisSoru g ON g.id=k.gizliSoruID
            WHERE k.ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_varchar">
            AND k.aktiflik=1
        </cfquery>
        <cfif qKullanici.recordCount EQ 1>
            <cfset adim=2>
            <cfset gizliSoru=qKullanici.soruMetni>
        <cfelse>
            <cfset hata="Kullanıcı bulunamadı.">
            <cfset guvenlik.denemeKaydetme(tur="sifirla",anahtar=lCase(kullaniciAd))>
            <cfset sleep(600)>
        </cfif>
    </cfif>
</cfif>

<cfif structKeyExists(form,"adim2")>
    <cfparam name="form.kullaniciAd" default="">
    <cfparam name="form.gizliCevap" default="">
    <cfset kullaniciAd=trim(form.kullaniciAd)>
    <cfset gizliCevap=lCase(trim(form.gizliCevap))>
    
    <cfquery name="qSoru" datasource="DSN">
        SELECT k.id,k.gizliCevap,k.tuz,g.soruMetni
        FROM Kullanici k
        INNER JOIN GirisSoru g ON g.id=k.gizliSoruID
        WHERE k.ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_varchar">
        AND k.aktiflik=1
    </cfquery>

    <cfif qSoru.recordCount EQ 0>
        <cfset hata="Kullanıcı bulunamadı.">
        <cfset adim=1>
    <cfelseif gizliCevap EQ "">
        <cfset hata="Lütfen soruyu cevaplayınız.">
        <cfset adim=2>
        <cfset gizliSoru=qSoru.soruMetni>
    <cfelseif guvenlik.denemeSiniriAsildi(tur="sifirla",anahtar=lCase(kullaniciAd))>
        <cfset hata="Çok fazla deneme yaptınız.Lütfen 15 dakika sonra tekrar deneyiniz.">
        <cfset adim=1>
    <cfelseif sifreleme.cevapDogrulama(cevap=gizliCevap,cevapHash=qSoru.gizliCevap,tuz=qSoru.tuz)>
        <cfset guvenlik.denemeTemizleme(tur="sifirla",anahtar=lCase(kullaniciAd))>
        <cfset adim=3>
        <cfset dogrulamaKodu=hash(createUUID() & getTickCount(),"SHA-256")>
        <cfset SESSION.sifreKodu=dogrulamaKodu>
        <cfset SESSION.sifreKullanici=kullaniciAd>
        <cfset SESSION.sifreKoduZaman=now()>
    <cfelse>
        <cfset hata="Cevabınız yanlış.">
        <cfset adim=2>
        <cfset gizliSoru=qSoru.soruMetni>
        <cfset guvenlik.denemeKaydetme(tur="sifirla",anahtar=lCase(kullaniciAd))>
        <cfset sleep(600)>
    </cfif>
</cfif>

<cfif structKeyExists(form,"adim3")>
    <cfparam name="form.yeniSifre" default="">
    <cfparam name="form.yeniSifreTekrar" default="">
    <cfparam name="form.dogrulamaKodu" default="">
    <cfset yeniSifre=trim(form.yeniSifre)>
    <cfset yeniSifreTekrar=trim(form.yeniSifreTekrar)>
    <cfset gelenKod=trim(form.dogrulamaKodu)>
    <cfset kodGecerli=structKeyExists(SESSION,"sifreKodu") AND len(SESSION.sifreKodu) AND compare(gelenKod,SESSION.sifreKodu) EQ 0 AND dateDiff("n",SESSION.sifreKoduZaman,now()) LT 15>
    
    <cfif NOT kodGecerli>
        <cfset hata="Oturum süreniz dolmuştur.Lütfen işlemi baştan başlatınız.">
        <cfset adim=1>
    <cfelseif yeniSifre EQ "" OR yeniSifreTekrar EQ "">
        <cfset hata="Lütfen tüm alanları doldurunuz.">
        <cfset adim=3>
        <cfset kullaniciAd=SESSION.sifreKullanici>
        <cfset dogrulamaKodu=SESSION.sifreKodu>
    <cfelseif len(yeniSifre) LT 6>
        <cfset hata="Şifreniz en az 6 haneli olmalıdır.">
        <cfset adim=3>
        <cfset kullaniciAd=SESSION.sifreKullanici>
        <cfset dogrulamaKodu=SESSION.sifreKodu>
    <cfelseif yeniSifre NEQ yeniSifreTekrar>
        <cfset hata="Şifreler eşleşmiyor.">
        <cfset adim=3>
        <cfset kullaniciAd=SESSION.sifreKullanici>
        <cfset dogrulamaKodu=SESSION.sifreKodu>
    <cfelse>
        <cftry>
            <cfquery name="qMevcutTuz" datasource="DSN">
                SELECT tuz
                FROM Kullanici
                WHERE ad=<cfqueryparam value="#SESSION.sifreKullanici#" cfsqltype="cf_sql_varchar">
                AND aktiflik=1
            </cfquery>

            <cfset yeniSifreSonuc=sifreleme.sifreUretme(sifre=yeniSifre,tuz=qMevcutTuz.tuz)>
            <cftransaction>
                <cfquery datasource="DSN">
                    UPDATE Kullanici
                    SET sifre=<cfqueryparam value="#yeniSifreSonuc.hash#" cfsqltype="cf_sql_varchar">,
                    tuz=<cfqueryparam value="#yeniSifreSonuc.tuz#" cfsqltype="cf_sql_varchar">,
                    hashSurum=<cfqueryparam value="#yeniSifreSonuc.hashSurum#" cfsqltype="cf_sql_integer">
                    WHERE ad=<cfqueryparam value="#SESSION.sifreKullanici#" cfsqltype="cf_sql_varchar">
                    AND aktiflik=1
                </cfquery>
                
                <cfquery datasource="DSN">
                    UPDATE Oturum
                    SET aktiflik=0
                    WHERE kullaniciID=(
                    SELECT id FROM Kullanici
                    WHERE ad=<cfqueryparam value="#SESSION.sifreKullanici#" cfsqltype="cf_sql_varchar">
                    )
                    AND aktiflik=1
                </cfquery>
            </cftransaction>
            
            <cfset structDelete(SESSION,"sifreKodu")>
            <cfset structDelete(SESSION,"sifreKullanici")>
            <cfset structDelete(SESSION,"sifreKoduZaman")>
            <cfset basari="Şifreniz başarıyla güncellendi.">
            <cfset adim=1>
            <cfcatch type="any">
                <cfset hata="Şifre güncellenirken bir hata oluştu.">
                <cfset adim=1>
                <cfset aiHata=createObject("component","YKSSite.views.includes.ai")>
                <cfset aiHata.hataYazma(
                    sayfa="/YKSSite/views/kimlik/sifreSifirlama.cfm",
                    islem="sifreGuncelle",
                    mesaj=cfcatch.message,
                    detay=cfcatch.detail
                    )>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>
<cfoutput>
    <div class="dar">
        <section class="kart">
            <div class="kart__baslik">Şifre Sıfırlama</div>
            <div class="kart__govde">
                <div class="adimlar">
                    <span class="adim #adim EQ 1 ? "adim--aktif" : "adim--tamam"#">Kullanıcı Adı:</span>
                    <span class="adim #adim EQ 2 ? "adim--aktif" : adim GT 2 ? "adim--tamam" : ""#">Gizli Soru:</span>
                    <span class="adim #adim EQ 3 ? "adim--aktif" : ""#">Yeni Şifre:</span>
                </div>
                <cfif len(hata)>
                    <div class="bildirim bildirim--hata ust-bosluk" role="alert">#encodeForHTML(hata)#</div>
                </cfif>
                <cfif len(basari)>
                    <div class="bildirim bildirim--basarili ust-bosluk" role="status">#encodeForHTML(basari)#
                        <a class="bag" href="/YKSSite/views/kimlik/giris.cfm">Giriş Yap</a>
                    </div>
                </cfif>
                <cfif adim EQ 1 AND NOT len(basari)>
                    <form method="POST">
                        <div class="alan ust-bosluk">
                            <label for="kullaniciAd">Kullanıcı Adı:</label>
                            <input class="girdi" type="text" name="kullaniciAd" id="kullaniciAd" maxlength="15" autocapitalize="none" required>
                        </div>
                        <button class="dugme dugme--ana dugme--tam" type="submit" name="adim1" value="1">Devam Et</button>
                    </form>
                </cfif>
                <cfif adim EQ 2>
                    <form method="POST">
                        <input type="hidden" name="kullaniciAd" value="#encodeForHTMLAttribute(kullaniciAd)#">
                        <div class="alan ust-bosluk">
                            <label>Gizli soru</label>
                            <p class="sabit-metin">#encodeForHTML(gizliSoru)#</p>
                        </div>
                        <div class="alan">
                            <label for="gizliCevap">Cevap:</label>
                            <input class="girdi" type="text" name="gizliCevap" id="gizliCevap" maxlength="100" required>
                            <span class="alan__ipucu">Büyük-küçük harf sorunu yaşanmayacaktır</span>
                        </div>
                        <button class="dugme dugme--ana dugme--tam" type="submit" name="adim2" value="1">Devam Et</button>
                    </form>
                </cfif>
                <cfif adim EQ 3>
                    <form method="POST">
                        <input type="hidden" name="dogrulamaKodu" value="#encodeForHTMLAttribute(dogrulamaKodu)#">
                        <div class="alan ust-bosluk">
                            <label for="yeniSifre">Yeni Şifre:</label>
                            <input class="girdi" type="password" name="yeniSifre" id="yeniSifre" minlength="6" autocomplete="new-password" required>
                            <span class="alan__ipucu">Şifreniz en az 6 karakter uzunluğunda olmalıdır</span>
                        </div>
                        <div class="alan">
                            <label for="yeniSifreTekrar">Yeni Şifre Tekrarı:</label>
                            <input class="girdi" type="password" name="yeniSifreTekrar" id="yeniSifreTekrar" minlength="6" autocomplete="new-password" required>
                        </div>
                        <button class="dugme dugme--ana dugme--tam" type="submit" name="adim3" value="1">Şifremi Güncelle</button>
                    </form>
                </cfif>
                <p class="ayrac-metin">veya</p>
                <p class="sessiz" style="text-align:center"><a class="bag" href="/YKSSite/views/kimlik/giris.cfm">Giriş sayfasına dön</a></p>
            </div>
        </div>
    </section>
</div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">