<cfinclude template="/views/includes/baslik.cfm">

<cfif isDefined("SESSION.kullaniciID")>
    <cflocation url="/anaSayfa.cfm" addtoken="false">
</cfif>

<cfquery name="qGirisSoru" datasource="DSN">
    SELECT id,soruMetni 
    FROM GirisSoru
    ORDER BY id
</cfquery>

<cfquery name="qAlan" datasource="DSN">
    SELECT id,ad
    FROM Alan 
    ORDER BY id
</cfquery>

<cfparam name="hata" default="">
<cfparam name="basari" default="">

<cfif structKeyExists(form,"kayitOl")>
    <cfset kullaniciAd=trim(form.kullaniciAd)>
    <cfset sifre=trim(form.sifre)>
    <cfset sifreTekrar=trim(form.sifreTekrar)>
    <cfset gizliSoruID=trim(form.gizliSoruID)>
    <cfset gizliCevap=lCase(trim(form.gizliCevap))>
    <cfset alanID=trim(form.alanID)>

    <cfif kullaniciAd EQ "" OR sifre EQ "" OR sifreTekrar EQ "" OR gizliCevap EQ "">
        <cfset hata="Lütfen tüm alanları doldurunuz.">
    <cfelseif len(kullaniciAd) LT 3 OR len(kullaniciAd) GT 15>
        <cfset hata="Kullanıcı adınınz,3-15 hane aralığında olmalıdır.">
    <cfelseif sifre NEQ sifreTekrar>
        <cfset hata="Şifreler eşleşmiyor.">
    <cfelseif len(sifre) LT 6>
        <cfset hata="Şifre,en az 6 haneli olmalıdır.">
    <cfelse>
        <cfquery name="qKontrol" datasource="DSN">
            SELECT id 
            FROM Kullanici 
            WHERE ad=<cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_nvarchar">
        </cfquery>

        <cfif qKontrol.recordCount GT 0>
            <cfset hata="Bu kullanıcı adı,zaten alınmış.">
        <cfelse>
            <cfset sifreHash=hash(sifre,"SHA-256")>

            <cfquery datasource="DSN">
                INSERT INTO Kullanici(rol,ad,sifre,gizliSoruID,gizliCevap,xp,kayitTarihi,aktiflik)
                VALUES(
                    1,
                    <cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#sifreHash#" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#gizliSoruID#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#gizliCevap#" cfsqltype="cf_sql_nvarchar">,
                    0,
                    GETDATE(),
                    1
                )
            </cfquery>

            <cfset basari="Kayıt,başarıyla oluşturuldu.">
        </cfif>
    </cfif>
</cfif>

<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-6">
            <div class="card shadow">
                <div class="card-header bg-dark text-white text-center">
                    <h4><i class="bi bi-person-plus"></i>Kayıt Ol</h4>
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

                    <form method="POST">
                        <div class="mb-3">
                            <label class="form-label">Kullanıcı Adı:</label>
                            <input type="text" name="kullaniciAd" class="form-control" maxlength="15" required>
                            <small class="text-muted">3-15 hane aralığında olmalıdır.</small> 
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Şifre:</label>
                            <input type="password" name="sifre" class="form-control" minlength="6" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Şifre Tekrarı:</label>
                            <input type="password" name="sifreTekrar" class="form-control" minlength="6" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Gizli Soru:</label>
                            <select name="gizliSoruID" class="form-select" required>
                                <option value="">Soru seçiniz.</option>
                                <cfoutput query="qGirisSoru">
                                    <option value="#id#">#soruMetni#</option>
                                </cfoutput>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Gizli Soru Cevabı:</label>
                            <input type="text" name="gizliCevap" class="form-control" required>
                            <small class="text-muted">Büyük/Küçük harf sıkıntısı yaşanmayacaktır.</small>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Alanınız:</label>
                            <select name="alanID" class="form-select" required>
                                <option value="">Alanınızı seçiniz.</option>
                                <cfoutput query="qAlan">
                                    <option value="#id#">#ad#</option>
                                </cfoutput>
                            </select>
                        </div>

                        <div class="d-grid">
                            <button type="submit" name="kayitOl" value="1" class="btn btn-dark">
                                <i class="bi bi-person-check"></i>Kayıt Ol
                            </button>
                        </div>
                    </form>

                    <hr>

                    <div class="text-center">
                        <small>Zaten üye misiniz?
                            <a href="/views/kimlik/giris.cfm">Giriş Yap</a>
                        </small>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<cfinclude template="/views/includes/altBilgi.cfm">