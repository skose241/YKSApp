<cfinclude template="/YKSSite/views/includes/baslik.cfm">

<cfif isDefined("SESSION.kullaniciID")>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfparam name="hata" default="">

<cfif structKeyExists(form,"girisYap")>
    <cfset kullaniciAd=trim(form.kullaniciAd)>
    <cfset sifre=trim(form.sifre)>
    <cfset beniHatirla=structKeyExists(form,"beniHatirla")>

    <cfif kullaniciAd EQ "" OR sifre EQ "">
        <cfset hata="Lütfen tüm alanları doldurunuz.">
    <cfelse>
        <cfset sifreHash=hash(sifre,"SHA-256")>

        <cfquery name="qGiris" datasource="DSN">
            SELECT id,ad,rol,xp
            FROM Kullanici 
            WHERE ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_varchar">
            AND sifre=<cfqueryparam value="#sifreHash#" cfsqltype="cf_sql_varchar">
            AND aktiflik=1
        </cfquery>

        <cfif qGiris.recordCount EQ 1>
            <cfset SESSION.kullaniciID=val(qGiris.id)>
            <cfset SESSION.kullaniciAd=qGiris.ad>
            <cfset SESSION.rol=qGiris.rol>
            <cfset SESSION.xp=qGiris.xp>

            <cfquery datasource="DSN">
                UPDATE Kullanici 
                SET sonGirisTarihi=<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
                WHERE id=<cfqueryparam value="#qGiris.id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset token=hash(qGiris.id & now() & createUUID(),"SHA-256")>

            <cfquery datasource="DSN">
                INSERT INTO Oturum(kullaniciID,sessionToken,girisTarihi,aktiflik)
                VALUES(
                    <cfqueryparam value="#qGiris.id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#token#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    1
                )
            </cfquery>

            <cfif beniHatirla>
                <cfcookie name="beniHatirla" value="#token#" expires="30">
            <cfelse>
                <cfcookie name="beniHatirla" value="" expires="now">
            </cfif> 

            <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
        <cfelse>
            <cfset hata="Kullanıcı adı veya şifre hatalı.">
        </cfif>
    </cfif>
</cfif>

<cfoutput>
    <div class="container mt-5">
        <div class="row justify-content-center">
            <div class="col-md-5">
                <div class="card shadow">
                    <div class="card-header bg-dark text-white text-center">
                        <h4><i class="bi bi-box-arrow-in-right"></i>Giriş Yap</h4>
                    </div>

                    <div class="card-body">
                        <cfif hata NEQ "">
                            <div class="alert alert-danger">
                                <i class="bi bi-exclamation-circle"></i>#hata#
                            </div>
                        </cfif>

                        <form method="POST">
                            <div class="mb-3">
                                <label class="form-label">Kullanıcı Adı:</label>
                                <input type="text" name="kullaniciAd" class="form-control" maxlength="15" required>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Şifre:</label>
                                <input type="password" name="sifre" class="form-control" minlength="6" required> 
                            </div>

                            <div class="mb-3 d-flex justify-content-between align-items-center">
                                <div class="form-check">
                                    <input type="checkbox" name="beniHatirla" id="beniHatirla" class="form-check-input">
                                    <label class="form-check-label" for="beniHatirla">Beni Hatırla</label>
                                </div>

                                <a href="/YKSSite/views/kimlik/sifreSifirlama.cfm" class="text-muted small">Şifremi Unuttum</a>
                            </div>

                            <div class="d-grid">
                                <button type="submit" name="girisYap" value="1" class="btn btn-dark">
                                    <i class="bi bi-box-arrow-in-right"></i>Giriş Yap
                                </button>
                            </div>
                        </form>

                        <hr>

                        <div class="text-center">
                            <small>Hesabınız yok mu?
                                <a href="/YKSSite/views/kimlik/kayit.cfm">Kayıt Ol</a>
                            </small>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">