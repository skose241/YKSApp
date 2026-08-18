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
        <cfset hata="Kullanıcı adı yalnızca harf,rakam ve alt çizgi içerebilir.">
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
            <cfset hata="Bu kullanıcı adı,zaten alınmış.">
        <cfelse>
            <cftry>
                <cfset sifreHash=hash(sifre,"SHA-256")>
                <cfset cevapHash=hash(gizliCevap,"SHA-256")>

                <cfquery datasource="DSN">
                    INSERT INTO Kullanici(rol,ad,sifre,gizliSoruID,gizliCevap,xp,kayitTarihi,aktiflik)
                    VALUES(
                        1,
                        <cfqueryparam value="#kullaniciAd#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#sifreHash#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#gizliSoruID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#cevapHash#" cfsqltype="cf_sql_varchar">,
                        0,
                        GETDATE(),
                        1
                    )
                </cfquery>

                <cfset basari="Kayıt,başarıyla oluşturuldu.">

                <cfcatch type="database">
                    <cfset hata="Bu kullanıcı adı,zaten alınmış.">
                </cfcatch>

                <cfcatch type="any">
                    <cfset hata="Kayıt sırasında bir hata oluştu.">
                </cfcatch>
            </cftry>
        </cfif>
    </cfif>
</cfif>

<cfoutput>
    <div class="container mt-5">
        <div class="row justify-content-center">
            <div class="col-md-6">
                <div class="card shadow">
                    <div class="card-header bg-dark text-white text-center">
                        <h4 class="mb-0"><i class="bi bi-person-plus"></i>Kayıt Ol</h4>
                    </div>

                    <div class="card-body">
                        <cfif len(hata)>
                            <div class="alert alert-danger">
                                <i class="bi bi-exclamation-circle"></i>#encodeForHTML(hata)#
                            </div>
                        </cfif>

                        <cfif len(basari)>
                            <div class="alert alert-success">
                                <i class="bi bi-check-circle"></i>#encodeForHTML(basari)#
                                <a href="/YKSSite/views/kimlik/giris.cfm" class="alert-link">Giriş Yap</a>
                            </div>
                        </cfif>

                        <cfif NOT len(basari)>
                            <form method="POST">
                                <div class="mb-3">
                                    <label class="form-label">Kullanıcı Adı:</label>
                                    <input type="text" name="kullaniciAd" class="form-control" maxlength="15" value="#encodeForHTMLAttribute(structKeyExists(form,'kullaniciAd') ? form.kullaniciAd:'')#" autocomplete="username" required>
                                    <small class="text-muted">3-15 hane aralığında olmalıdır.</small>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label">Şifre:</label>
                                    <input type="password" name="sifre" class="form-control" minlength="6" autocomplete="new-password" required>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label">Şifre Tekrarı:</label>
                                    <input type="password" name="sifreTekrar" class="form-control" minlength="6" autocomplete="new-password" required>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label">Gizli Soru:</label>
                                    <select name="gizliSoruID" class="form-select" required>
                                        <option value="">Soru seçiniz.</option>
                                        <cfloop query="qGirisSoru">
                                            <option value="#qGirisSoru.id#">#encodeForHTML(qGirisSoru.soruMetni)#</option>
                                        </cfloop>
                                    </select>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label">Gizli Soru Cevabı:</label>
                                    <input type="text" name="gizliCevap" class="form-control" maxlength="100" required>
                                    <small class="text-muted">Büyük/Küçük harf sıkıntısı yaşanmayacaktır.</small>
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
                                    <a href="/YKSSite/views/kimlik/giris.cfm">Giriş Yap</a>
                                </small>
                            </div>
                        </cfif>
                    </div>
                </div>
            </div>
        </div>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">