<cfinclude template="/views/includes.baslik.cfm">

<cfif isDefined("SESSION.kullaniciID")>
    <cflocation url="/anaSayfa.cfm" addtoken="false">
</cfif>

<cfparam name="hata" default="">
<cfparam name="basari" default="">
<cfparam name="adim" default="1">
<cfparam name="gizliSoru" default="">
<cfparam name="kullaniciAd" default="">

<cfif structKeyExists(form,"adim1")>
    <cfset kullaniciAd=trim(form.kullaniciAd)>

    <cfif kullaniciAd EQ "">
        <cfset hata="Lütfen kullanıcı adınızı giriniz.">
    <cfelse>
        <cfquery name="qKullanici" datasource="DSN">
            SELECT k.id,k.ad,g.soruMetni,k.gizliSoruID
            FROM Kullanici k 
            INNER JOIN GirisSoru g ON g.id=k.gizliSoruID
            WHERE k.ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_nvarchar">
            AND aktiflik=1
        </cfquery>

        <cfif qKullanici.recordCount EQ 1>
            <cfset adim=2>
            <cfset gizliSoru=qKullanici.soruMetni>
        <cfelse>
            <cfset hata="Kullanıcı bulunamadı.">
        </cfif>
    </cfif>
</cfif>

<cfif structKeyExists(form,"adim2")>
    <cfset kullaniciAd=trim(form.kullaniciAd)>
    <cfset gizliCevap=lCase(trim(form.gizliCevap))>

    <cfif gizliCevap EQ "">
        <cfset hata="Lütfen soruyu cevaplayınız.">
        <cfset adim=2>

        <cfquery name="qSoru" datasource="DSN">
            SELECT g.soruMetni
            FROM Kullanici k 
            INNER JOIN GirisSoru g ON g.id=k.gizliSoruID
            WHERE k.ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_nvarchar">
        </cfquery>

        <cfset gizliSoru=qSoru.soruMetni>
    <cfelse>
        <cfquery name="qKontrol" datasource="DSN">
            SELECT id 
            FROM Kullanici 
            WHERE ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_nvarchar">
            AND gizliCevap=<cfqueryparam value="#gizliCevap#" cfsqltype="cf_sql_nvarchar">
            AND aktiflik=1
        </cfquery>

        <cfif qKontrol.recordCount EQ 1>
            <cfset adim=3>
        <cfelse>
            <cfset hata="Cevabınız yanlış.">
            <cfset adim=2>

            <cfquery name="qSoru" datasource="DSN">
                SELECT g.soruMetni
                FROM Kullanici k 
                INNER JOIN GirisSoru g ON g.id=k.gizliSoruID
                WHERE k.ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_nvarchar">
            </cfquery>

            <cfset gizliSoru=qSoru.soruMetni>
        </cfif>
    </cfif>
</cfif>

<cfif structKeyExists(form,"adim3")>
    <cfset kullaniciAd=trim(form.kullaniciAd)>
    <cfset yeniSifre=trim(form.yeniSifre)>
    <cfset yeniSifreTekrar=trim(form.yeniSifreTekrar)>

    <cfif yeniSifre EQ "" OR yeniSifreTekrar EQ "">
        <cfset hata="Lütfen tüm alanları doldurunuz.">
    <cfelseif len(yeniSifre) LT 6>
        <cfset hata="Şifre en az 6 haneli olmalıdır.">
        <cfset adim=3>
    <cfelseif yeniSifre NEQ yeniSifreTekrar>
        <cfset hata="Şifreler eşleşmiyor.">
        <cfset adim=3>
    <cfelse>
        <cfset sifreHash=hash(yeniSifre,"SHA-256")>

        <cfquery datasource="DSN">
            UPDATE Kullanici 
            SET sifre=<cfqueryparam value="#sifreHash#" cfsqltype="cf_sql_nvarchar">
            WHERE ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_nvarchar">
        </cfquery>

        <cfquery datasource="DSN">
            UPDATE Oturum
            SET aktiflik=0
            WHERE kullaniciID=(
                SELECT id FROM Kullanici 
                WHERE ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_nvarchar">
            )
        </cfquery>

        <cfset basari="Şifreniz başarıyla güncellendi.">
        <cfset adim=1>
    </cfif>
</cfif>

<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-5">
            <div class="card shadow">
                <div class="card-header bg-dark text-white text-center">
                    <h4><i class="bi bi-key"></i>Şifre Sıfırlama</h4>
                </div>

                <div class="card-body">
                    <cfif hata NEQ "">
                        <div class="alert alert-danger">
                            <i class="bi bi-exclamation-circle"></i>#hata#
                        </div>
                    </cfif>

                    <cfif basari NEQ "">
                        <div class="alert alert-success">
                            <i class="bi bi-check-circle"></i>#basari#
                            <a href="/views/kimlik/giris.cfm">Giriş Yap</a>
                        </div>
                    </cfif>

                    <div class="d-flex justify-content-center mb-4 gap-2">
                        <span class="badge #adim EQ 1 ? 'bg-dark':'bg-secondary'#">Kullanıcı Adı:</span>
                        <span class="badge #adim EQ 2 ? 'bg-dark':'bg-secondary'#">Gizli Soru:</span>
                        <span class="badge #adim EQ 3 ? 'bg-dark':'bg-secondary'#">Yeni Şifre:</span>
                    </div>

                    <cfif adim EQ 1 AND basari EQ "">
                        <form method="POST">
                            <div class="mb-3">
                                <label class="form-label">Kullanıcı Adınız:</label>
                                <input type="text" name="kullaniciAd" class="form-control" maxlength="15" required>
                            </div>

                            <div class="d-grid">
                                <button type="submit" name="adim1" value="1" class="btn btn-dark">
                                    <i class="bi bi-arrow-right"></i>Devam Et
                                </button>
                            </div>
                        </form>
                    </cfif>

                    <cfif adim EQ 2>
                        <form method="POST">
                            <input type="hidden" name="kullaniciAd" value="#kullaniciAd#">
                            <div class="mb-3">
                                <label class="form-label">Gizli Soru:</label>
                                <p class="form-control-plaintext fw-bold">#gizliSoru#</p>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Cevabınız:</label>
                                <input type="text" name="gizliCevap" class="form-control" required>
                                <small class="text-muted">Büyük/Küçük harf sıkıntısı yaşanmayacaktır.</small>
                            </div>

                            <div class="d-grid">
                                <button type="submit" name="adim2" value="1" class="btn btn-dark">
                                    <i class="bi bi-arrow-right"></i>Devam Et
                                </button>
                            </div>
                        </form>
                    </cfif>

                    <cfif adim EQ 3>
                        <form method="POST">
                            <input type="hidden" name="kullaniciAd" value="#kullaniciAd#">
                            <div class="mb-3">
                                <label class="form-label">Yeni Şifre:</label>
                                <input type="password" name="yeniSifre" class="form-control" minlength="6" required>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Yeni Şifre Tekrarı:</label>
                                <input type="password" name="yeniSifreTekrar" class="form-control" minlength="6" required>
                            </div>

                            <div class="d-grid">
                                <button type="submit" name="adim3" value="1" class="btn btn-dark">
                                    <i class="bi bi-check-lg"></i>Şifremi Güncelle
                                </button>
                            </div>
                        </form>
                    </cfif>

                    <hr>

                    <div class="text-center">
                        <small>
                            <a href="/views/kimlik/giris.cfm">Giriş Yap</a>
                        </small>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<cfinclude template="/views/includes/altBilgi.cfm">