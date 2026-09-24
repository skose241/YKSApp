<cfif structKeyExists(SESSION,"kullaniciID") AND val(SESSION.kullaniciID)>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfinclude template="/YKSSite/views/includes/baslik.cfm">

<cfquery name="qGirisSoru" datasource="DSN">
    SELECT id,soruMetni
    FROM GirisSoru
    ORDER BY id
</cfquery>

<cfparam name="hata" default="">
<cfparam name="basari" default="">

<cfif structKeyExists(form,"kayitOl")>
    <cfparam name="form.kullaniciAd" default="">
    <cfparam name="form.sifre" default="">
    <cfparam name="form.sifreTekrar" default="">
    <cfparam name="form.gizliSoruID" default="">
    <cfparam name="form.gizliCevap" default="">

    <cfset kullaniciAd=trim(form.kullaniciAd)>
    <cfset sifre=trim(form.sifre)>
    <cfset sifreTekrar=trim(form.sifreTekrar)>
    <cfset gizliSoruID=val(form.gizliSoruID)>
    <cfset gizliCevap=lCase(trim(form.gizliCevap))>

    <cfquery name="qSoruKontrol" datasource="DSN">
        SELECT id
        FROM GirisSoru
        WHERE id=<cfqueryparam value="#gizliSoruID#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif kullaniciAd EQ "" OR sifre EQ "" OR sifreTekrar EQ "" OR gizliCevap EQ "">
        <cfset hata="Lütfen tüm alanları doldurunuz.">
    <cfelseif len(kullaniciAd) LT 3 OR len(kullaniciAd) GT 15>
        <cfset hata="Kullanıcı adınız 3-15 hane aralığında olmalıdır.">
    <cfelseif NOT reFind("^[a-zA-Z0-9çğıöşüÇĞİÖŞÜ_]+$",kullaniciAd)>
        <cfset hata="Kullanıcı adınız yalnızca harf,rakam ve alt çizgi içerebilir.">
    <cfelseif sifre NEQ sifreTekrar>
        <cfset hata="Şifreler eşleşmiyor.">
    <cfelseif len(sifre) LT 6>
        <cfset hata="Şifre en az 6 haneli olmalıdır.">
    <cfelseif len(gizliCevap) LT 2>
        <cfset hata="Gizli soru cevabı en az 2 haneli olmalıdır.">
    <cfelseif qSoruKontrol.recordCount EQ 0>
        <cfset hata="Lütfen geçerli bir gizli soru seçiniz.">
    <cfelse>
        <cfquery name="qKontrol" datasource="DSN">
            SELECT id
            FROM Kullanici
            WHERE ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_varchar">
        </cfquery>

        <cfif qKontrol.recordCount GT 0>
            <cfset hata="Bu kullanıcı adı alınmış.">
        <cfelse>
            <cftry>
                <cfset tuz=hash(createUUID() & getTickCount(),"SHA-256")>
                <cfset sifreHash=hash(tuz & sifre,"SHA-512")>
                <cfloop from="1" to="20000" index="d">
                    <cfset sifreHash=hash(tuz & sifreHash,"SHA-512")>
                </cfloop>
                
                <cfset cevapHash=hash(tuz & gizliCevap,"SHA-512")>
                <cfloop from="1" to="20000" index="d">
                    <cfset cevapHash=hash(tuz & cevapHash,"SHA-512")>
                </cfloop>

                <cfquery datasource="DSN">
                    INSERT INTO Kullanici(rol,ad,sifre,tuz,hashSurum,gizliSoruID,gizliCevap,,xp,kayitTarihi,aktiflik)
                    VALUES(
                        1,
                        <cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#sifreHash#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#tuz#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="2" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#gizliSoruID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#cevapHash#" cfsqltype="cf_sql_varchar">,
                        0,
                        GETDATE(),
                        1
                    )
                </cfquery>

                <cfset basari="Kayıt başarıyla oluşturuldu.">

                <cfcatch type="database">
                    <cfset hata="Bu kullanıcı adı alınmış.">
                </cfcatch>

                <cfcatch type="any">
                    <cfset hata="Kayıt sırasında bir hata oluştu.">
                </cfcatch>
            </cftry>
        </cfif>
    </cfif>
</cfif>

<cfoutput>
    <div class="dar dar--genis">
        <section class="kart">
            <div class="kart__baslik">Kayıt Ol</div>

            <div class="kart__govde">
                <cfif len(hata)>
                    <div class="bildirim bildirim--hata ust-bosluk" role="alert">#encodeForHTML(hata)#</div>
                </cfif>

                <cfif len(basari)>
                    <div class="bildirim bildirim--basarili ust-bosluk" role="status">#encodeForHTML(basari)#
                        <a class="bag" href="/YKSSite/views/kimlik/giris.cfm">Giriş Yap</a>
                    </div>
                <cfelse>
                    <form method="POST">
                        <div class="alan ust-bosluk">
                            <label for="kullaniciAd">Kullanıcı Adı:</label>
                            <input class="girdi" type="text" name="kullaniciAd" id="kullaniciAd" maxlength="15" value="#encodeForHTMLAttribute(structKeyExists(form,'kullaniciAd') ? form.kullaniciAd : '')#" autocomplete="username" autocapitalize="none" required>
                            <span class="alan__ipucu">Kullanıcı adınız 3-15 hane aralığında olmalıdır.</span>
                        </div>

                        <div class="alan">
                            <label for="sifre">Şifre:</label>
                            <input class="girdi" type="password" name="sifre" id="sifre" minlength="6" autocomplete="new-password" required>
                            <span class="alan__ipucu">Şifre en az 6 haneli olmalıdır.</span>
                        </div>

                        <div class="alan">
                            <label for="sifreTekrar">Şifre Tekrarı:</label>
                            <input class="girdi" type="password" name="sifreTekrar" id="sifreTekrar" minlength="6" autocomplete="new-password" required>
                        </div>

                        <div class="alan">
                            <label for="gizliSoruID">Gizli Soru:</label>
                    
                            <select class="secim" name="gizliSoruID" id="gizliSoruID" required>
                                <option value="">Soru Seç:</option>
                                <cfloop query="qGirisSoru">
                                    <option value="#qGirisSoru.id#">#encodeForHTML(qGirisSoru.soruMetni)#</option>
                                </cfloop>
                            </select>

                            <span class="alan__ipucu">Şifrenizi sıfırlarken bu soru ile işlem yapacaksınız.</span>
                        </div>
                        
                        <div class="alan">
                            <label for="gizliCevap">Gizli Soru Cevabı:</label>
                            <input class="girdi" type="text" name="gizliCevap" id="gizliCevap" maxlength="100" required>
                            <span class="alan__ipucu">Büyük,küçük harf sıkıntısı yaşanmayacaktır.</span>
                        </div>

                        <button class="dugme dugme--ana dugme--tam" type="submit" name="kayitOl" value="1">Kayıt Ol</button>
                    </form>

                    <p class="ayrac-metin">veya</p>

                    <p class="sessiz" style="text-align:center">Zaten üye misin? <a class="bag" href="/YKSSite/views/kimlik/giris.cfm">Giriş Yap</a></p>
                </cfif>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">