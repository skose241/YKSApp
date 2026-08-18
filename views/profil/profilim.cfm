<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

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

    <cfset eskiSifre=trim(form.eskiSifre)>
    <cfset yeniSifre=trim(form.yeniSifre)>
    <cfset yeniSifreTekrar=trim(form.yeniSifreTekrar)>

    <cfif eskiSifre EQ "" OR yeniSifre EQ "" OR yeniSifreTekrar EQ "">
        <cfset sifreHata="Lütfen tüm alanları doldurunuz.">
    <cfelseif len(yeniSifre) LT 6>
        <cfset sifreHata="Şifre en az 6 haneli olmalıdır.">
    <cfelseif yeniSifre NEQ yeniSifreTekrar>
        <cfset sifreHata="Şifreler eşleşmiyor.">
    <cfelseif compare(eskiSifre,yeniSifre) EQ 0>
        <cfset sifreHata="Yeni şifreniz mevcut şifrenizden farklı olmalıdır.">
    <cfelse>
        <cfset eskiSifreHash=hash(eskiSifre,"SHA-256")>

        <cfquery name="qSifre" datasource="DSN">
            SELECT id
            FROM Kullanici
            WHERE id=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
            AND sifre=<cfqueryparam value="#eskiSifreHash#" cfsqltype="cf_sql_varchar">
        </cfquery>

        <cfif qSifre.recordCount EQ 0>
            <cfset sifreHata="Mevcut şifrenizi yanlış girdiniz.">
            <cfset sleep(600)>
        <cfelse>
            <cftry>
                <cfset yeniSifreHash=hash(yeniSifre,"SHA-256")>

                <cftransaction>
                    <cfquery datasource="DSN">
                        UPDATE Kullanici
                        SET sifre=<cfqueryparam value="#yeniSifreHash#" cfsqltype="cf_sql_varchar">
                        WHERE id=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
                    </cfquery>

                    <cfquery datasource="DSN">
                        UPDATE Oturum
                        SET aktiflik=0
                        WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
                        AND aktiflik=1
                    </cfquery>
                </cftransaction>

                <cfcookie name="beniHatirla" value="" expires="now">

                <cfset sifreBasari="Şifreniz başarıyla güncellendi. Diğer cihazlardaki oturumlarınız kapatıldı.">

                <cfcatch type="any">
                    <cfset sifreHata="Şifre güncellenirken bir hata oluştu.">
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
    <div class="container mt-4">
        <div class="card shadow mb-4">
            <div class="card-body">
                <div class="d-flex align-items-center gap-3">
                    <img src="#application.avatarURL##urlEncodedFormat(qProfil.ad)#&size=80"
                        class="rounded-circle" width="80" height="80" alt="">

                    <div class="flex-grow-1">
                        <h4 class="mb-1">#encodeForHTML(qProfil.ad)#</h4>

                        <span class="badge bg-dark me-1">
                            #qProfil.rol EQ 3 ? 'Admin':qProfil.rol EQ 2 ? 'Moderatör':'Kullanıcı'#
                        </span>

                        <span class="badge bg-warning text-dark">
                            <i class="bi bi-star"></i>#qProfil.xp# XP
                        </span>

                        <p class="text-muted mt-1 mb-0 small">
                            <i class="bi bi-calendar"></i>
                            Kayıt:#dateFormat(qProfil.kayitTarihi,'dd.mm.yyyy')#
                        </p>
                    </div>

                    <cfif benimProfil>
                        <button type="button" class="btn btn-outline-dark btn-sm" data-bs-toggle="modal" data-bs-target="##sifreModal">
                            <i class="bi bi-key"></i>Şifre Değiştir
                        </button>
                    </cfif>
                </div>
            </div>
        </div>

        <cfif benimProfil AND len(sifreBasari)>
            <div class="alert alert-success">
                <i class="bi bi-check-circle"></i>#encodeForHTML(sifreBasari)#
            </div>
        </cfif>

        <div class="row g-3 mb-4">
            <div class="col-6 col-md-3">
                <div class="card text-center shadow-sm">
                    <div class="card-body py-3">
                        <h4 class="mb-0 text-dark">#qIstatistik.soruAdet#</h4>
                        <small class="text-muted">Eklenen Soru</small>
                    </div>
                </div>
            </div>

            <div class="col-6 col-md-3">
                <div class="card text-center shadow-sm">
                    <div class="card-body py-3">
                        <h4 class="mb-0 text-success">#qIstatistik.dogruAdet#</h4>
                        <small class="text-muted">Doğru Cevap</small>
                    </div>
                </div>
            </div>

            <div class="col-6 col-md-3">
                <div class="card text-center shadow-sm">
                    <div class="card-body py-3">
                        <h4 class="mb-0 text-primary">#qIstatistik.yorumAdet#</h4>
                        <small class="text-muted">Yapılan Yorum</small>
                    </div>
                </div>
            </div>

            <div class="col-6 col-md-3">
                <div class="card text-center shadow-sm">
                    <div class="card-body py-3">
                        <h4 class="mb-0 text-danger">#qIstatistik.favoriAdet#</h4>
                        <small class="text-muted">Favori</small>
                    </div>
                </div>
            </div>
        </div>

        <ul class="nav nav-tabs mb-3">
            <li class="nav-item">
                <a class="nav-link active" data-bs-toggle="tab" href="##sorular">
                    <i class="bi bi-question-circle"></i>Sorular
                    <span class="badge bg-secondary ms-1">#qIstatistik.soruAdet#</span>
                </a>
            </li>

            <li class="nav-item">
                <a class="nav-link" data-bs-toggle="tab" href="##cevaplar">
                    <i class="bi bi-check-circle"></i>Çözümler
                    <span class="badge bg-secondary ms-1">#qCevap.recordCount#</span>
                </a>
            </li>

            <cfif benimProfil>
                <li class="nav-item">
                    <a class="nav-link" data-bs-toggle="tab" href="##favoriler">
                        <i class="bi bi-heart"></i>Favorilerim
                        <span class="badge bg-secondary ms-1">#qIstatistik.favoriAdet#</span>
                    </a>
                </li>
            </cfif>
        </ul>

        <div class="tab-content">
            <div class="tab-pane fade show active" id="sorular">
                <cfif qSoru.recordCount EQ 0>
                    <div class="alert alert-info">
                        <i class="bi bi-info-circle"></i>Henüz soru eklenmemiş.
                    </div>
                <cfelse>
                    <div class="row row-cols-2 row-cols-md-4 g-3">
                        <cfloop query="qSoru">
                            <div class="col">
                                <div class="card h-100 shadow-sm">
                                    <a href="/YKSSite/views/soru/soruDetay.cfm?id=#qSoru.id#">
                                        <cfif len(trim(qSoru.soruResmi))>
                                            <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qSoru.soruResmi)#"
                                                class="card-img-top" style="height:140px; object-fit:cover;" alt="Soru">
                                        <cfelse>
                                            <div class="card-img-top bg-light p-2 small text-dark" style="height:140px; overflow:hidden;">
                                                #encodeForHTML(left(qSoru.soruMetni,160))#
                                            </div>
                                        </cfif>
                                    </a>

                                    <div class="card-body p-2">
                                        <span class="badge bg-dark">#encodeForHTML(qSoru.dersAd)#</span>
                                        <span class="badge bg-secondary">#encodeForHTML(qSoru.alanAd)#</span>

                                        <div class="mt-1">
                                            <small class="text-muted">
                                                <i class="bi bi-eye"></i>#qSoru.goruntulenmeSayisi# . #dateFormat(qSoru.eklenmeTarihi,'dd.mm.yyyy')#
                                            </small>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </cfloop>
                    </div>
                </cfif>
            </div>

            <div class="tab-pane fade" id="cevaplar">
                <cfif qCevap.recordCount EQ 0>
                    <div class="alert alert-info">
                        <i class="bi bi-info-circle"></i>Henüz çözüm eklenmemiş.
                    </div>
                <cfelse>
                    <div class="row row-cols-2 row-cols-md-4 g-3">
                        <cfloop query="qCevap">
                            <div class="col">
                                <div class="card h-100 shadow-sm">
                                    <a href="/YKSSite/views/soru/soruDetay.cfm?id=#qCevap.id#">
                                        <cfif len(trim(qCevap.soruResmi))>
                                            <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qCevap.soruResmi)#"
                                                class="card-img-top" style="height:140px; object-fit:cover;" alt="Soru">
                                        <cfelse>
                                            <div class="card-img-top bg-light p-2 small text-dark" style="height:140px; overflow:hidden;">
                                                #encodeForHTML(left(qCevap.soruMetni,160))#
                                            </div>
                                        </cfif>
                                    </a>

                                    <div class="card-body p-2">
                                        <span class="badge bg-dark">#encodeForHTML(qCevap.dersAd)#</span>
                                        <span class="badge bg-secondary">#encodeForHTML(qCevap.alanAd)#</span>

                                        <div class="mt-1">
                                            <span class="badge #qCevap.onay EQ 1 ? 'bg-success':qCevap.onay EQ 0 ? 'bg-danger':'bg-secondary'#">
                                                #qCevap.onay EQ 1 ? 'Doğru':qCevap.onay EQ 0 ? 'Yanlış':'Belirsiz'#
                                            </span>

                                            <small class="text-muted d-block mt-1">
                                                #dateFormat(qCevap.eklenmeTarihi,'dd.mm.yyyy')#
                                            </small>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </cfloop>
                    </div>
                </cfif>
            </div>

            <cfif benimProfil>
                <div class="tab-pane fade" id="favoriler">
                    <cfif qFavori.recordCount EQ 0>
                        <div class="alert alert-info">
                            <i class="bi bi-info-circle"></i>Henüz favori eklenmemiş.
                        </div>
                    <cfelse>
                        <div class="row row-cols-2 row-cols-md-4 g-3">
                            <cfloop query="qFavori">
                                <div class="col">
                                    <div class="card h-100 shadow-sm">
                                        <a href="/YKSSite/views/soru/soruDetay.cfm?id=#qFavori.id#">
                                            <cfif len(trim(qFavori.soruResmi))>
                                                <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qFavori.soruResmi)#"
                                                    class="card-img-top" style="height:140px; object-fit:cover;" alt="Soru">
                                            <cfelse>
                                                <div class="card-img-top bg-light p-2 small text-dark" style="height:140px; overflow:hidden;">
                                                    #encodeForHTML(left(qFavori.soruMetni,160))#
                                                </div>
                                            </cfif>
                                        </a>

                                        <div class="card-body p-2">
                                            <span class="badge bg-dark">#encodeForHTML(qFavori.dersAd)#</span>
                                            <span class="badge bg-secondary">#encodeForHTML(qFavori.alanAd)#</span>

                                            <div class="mt-1">
                                                <small class="text-muted">
                                                    <i class="bi bi-eye"></i>#qFavori.goruntulenmeSayisi#
                                                </small>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </cfloop>
                        </div>
                    </cfif>
                </div>
            </cfif>
        </div>
    </div>

    <cfif benimProfil>
        <div class="modal fade" id="sifreModal" tabindex="-1">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header bg-dark text-white">
                        <h5 class="modal-title"><i class="bi bi-key"></i>Şifre Değiştir</h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                    </div>

                    <div class="modal-body">
                        <cfif len(sifreHata)>
                            <div class="alert alert-danger">
                                <i class="bi bi-exclamation-circle"></i>#encodeForHTML(sifreHata)#
                            </div>
                        </cfif>

                        <form method="POST">
                            <div class="mb-3">
                                <label class="form-label">Mevcut Şifre:</label>
                                <input type="password" name="eskiSifre" class="form-control" autocomplete="current-password" required>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Yeni Şifre:</label>
                                <input type="password" name="yeniSifre" class="form-control" minlength="6" autocomplete="new-password" required>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Yeni Şifre Tekrarı:</label>
                                <input type="password" name="yeniSifreTekrar" class="form-control" minlength="6" autocomplete="new-password" required>
                            </div>

                            <div class="d-grid">
                                <button type="submit" name="sifreDegistir" value="1" class="btn btn-dark">
                                    <i class="bi bi-check-lg"></i>Güncelle
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <cfif len(sifreHata)>
            <script>
                document.addEventListener('DOMContentLoaded',function(){
                    new bootstrap.Modal(document.getElementById('sifreModal')).show();
                });
            </script>
        </cfif>
    </cfif>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">