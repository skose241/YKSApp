<cfif structKeyExists(SESSION,"kullaniciID") AND val(SESSION.kullaniciID)>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfinclude template="/YKSSite/views/includes/baslik.cfm">

<cfparam name="hata" default="">
<cfparam name="bilgi" default="">

<cfif structKeyExists(url,"durum") AND url.durum EQ "engelli">
    <cfset bilgi="Hesabınız engellenmiştir.Lütfen yönetici ile iletişime geçiniz.">
</cfif>

<cfif structKeyExists(form,"girisYap")>
    <cfparam name="form.kullaniciAd" default="">
    <cfparam name="form.sifre" default="">

    <cfset kullaniciAd=trim(form.kullaniciAd)>
    <cfset sifre=trim(form.sifre)>
    <cfset beniHatirla=structKeyExists(form,"beniHatirla")>

    <cfif kullaniciAd EQ "" OR sifre EQ "">
        <cfset hata="Lütfen tüm alanları doldurunuz.">
    <cfelse>
        <cfset sifreHash=hash(sifre,"SHA-256")>

        <cfquery name="qGiris" datasource="DSN">
            SELECT id,ad,rol,xp,sifre,tuz,hashSurum
            FROM Kullanici
            WHERE ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_varchar">
            AND sifre=<cfqueryparam value="#sifreHash#" cfsqltype="cf_sql_varchar">
            AND aktiflik=1
        </cfquery>

        <cfset dogruMu=false>

        <cfif qGiris.recordCount EQ 1>
            <cfif val(qGiris.hashSurum) GTE 2>
                <cfset denenen=hash(qGiris.tuz & sifre,"SHA-512")>

                <cfloop from="1" to="20000" index="d">
                    <cfset denenen=hash(qGiris.tuz & denenen,"SHA-512")>
                </cfloop>

                <cfset dogruMu=compare(denenen,qGiris.sifre) EQ 0>
            <cfelse>
                <cfset dogruMu=compare(hash(sifre,"SHA-256"),qGiris.sifre) EQ 0>

                <cfif dogruMu>
                    <cfset yeniTuz=hash(createUUID() & getTickCount(),"SHA-256")>
                    <cfset yeniHash=hash(yeniTuz & sifre,"SHA-512")>

                    <cfloop from="1" to="20000" index="d">
                        <cfset yeniHash=hash(yeniTuz & yeniHash,"SHA-512")>
                    </cfloop>

                    <cfquery datasource="DSN">
                        UPDATE Kullanici 
                        SET sifre=<cfqueryparam value="#yeniHash#" cfsqltype="cf_sql_varchar">,
                            tuz=<cfqueryparam value="#yeniTuz#" cfsqltype="cf_sql_varchar">,
                            hashSurum=2
                        WHERE id=<cfqueryparam value="#qGiris.id#" cfsqltype="cf_sql_integer">
                    </cfquery>
                </cfif>
            </cfif>

            <cftry>
                <cfset sessionRotate()>

                <cfset SESSION.kullaniciID=val(qGiris.id)>
                <cfset SESSION.kullaniciAd=qGiris.ad>
                <cfset SESSION.rol=val(qGiris.rol)>
                <cfset SESSION.xp=val(qGiris.xp)>

                <cfquery datasource="DSN">
                    UPDATE Kullanici
                    SET sonGirisTarihi=<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
                    WHERE id=<cfqueryparam value="#qGiris.id#" cfsqltype="cf_sql_integer">
                </cfquery>

                <cfif beniHatirla>
                    <cfset token=hash(qGiris.id & getTickCount() & createUUID(),"SHA-256")>

                    <cfquery datasource="DSN">
                        UPDATE Oturum
                        SET aktiflik=0
                        WHERE kullaniciID=<cfqueryparam value="#qGiris.id#" cfsqltype="cf_sql_integer">
                        AND aktiflik=1
                        AND girisTarihi<DATEADD(DAY,-30,GETDATE())
                    </cfquery>

                    <cfquery datasource="DSN">
                        INSERT INTO Oturum(kullaniciID,sessionToken,girisTarihi,sonGoruldu,aktiflik)
                        VALUES(
                            <cfqueryparam value="#qGiris.id#" cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#token#" cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                            <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                            1
                        )
                    </cfquery>

                    <cfcookie name="beniHatirla" value="#token#" expires="30" httponly="true" secure="true">
                <cfelse>
                    <cfcookie name="beniHatirla" value="" expires="now" secure="true">
                </cfif>

                <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">

                <cfcatch type="any">
                    <cfset hata="Giriş sırasında bir hata oluştu.">
                </cfcatch>
            </cftry>
        <cfelse>
            <cfset hata="Kullanıcı adı veya şifre hatalı.">
            <cfset sleep(600)>
        </cfif>
    </cfif>
</cfif>

<cfoutput>
    <div class="dar">
        <section class="kart">
            <div class="kart__baslik">Giriş Yap</div>

            <div class="kart__govde">
                <cfif len(bilgi)>
                    <div class="bildirim bildirim--hata ust-bosluk" role="alert">#encodeForHTML(bilgi)#</div>
                </cfif>

                <cfif len(hata)>
                    <div class="bildirim bildirim--hata ust-bosluk" role="alert">#encodeForHTML(hata)#</div>
                </cfif>

                <form method="POST">
                    <div class="alan ust-bosluk">
                        <label for="kullaniciAd">Kullanıcı Adı:</label>
                        <input class="girdi" type="text" name="kullaniciAd" id="kullaniciAd" maxlength="15" autocomplete="username" autocapitalize="none" required>
                    </div>

                    <div class="alan">
                        <label for="sifre">Şifre:</label>
                        <input class="girdi" type="password" name="sifre" id="sifre" minlength="6" autocomplete="current-password" required>
                    </div>

                    <div class="alan__satir">
                        <label class="onay" for="beniHatirla">
                            <input type="checkbox" name="beniHatirla" id="beniHatirla">Beni Hatırla
                        </label>

                        <a class="bag" href="/YKSSite/views/kimlik/sifreSifirlama.cfm">Şifremi Unuttum</a>
                    </div>

                    <button class="dugme dugme--ana dugme--tam" type="submit" name="girisYap" value="1">Giriş Yap</button>
                </form>

                <p class="ayrac-metin">veya</p>

                <p class="sessiz" style="text-align:center">Hesabınız yok mu? <a class="bag" href="/YKSSite/views/kimlik/kayit.cfm">Kayıt Ol</a></p>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">