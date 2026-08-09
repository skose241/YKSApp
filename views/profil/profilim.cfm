<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif structKeyExists(url,"id") AND isNumeric(url.id)>
    <cfset profilID=val(url.id)>
<cfelse>
    <cfset profilID=val(SESSION.kullaniciID)>
</cfif>

<cfset benimProfil=profilID EQ val(SESSION.kullaniciID)>

<cfquery name="qProfil" datasource="DSN">
    SELECT id,ad,rol,xp,kayitTarihi
    FROM Kullanici 
    WHERE id=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">
    AND aktiflik=1
</cfquery>

<cfif qProfil.recordCount EQ 0>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfquery name="qSoruAdet" datasource="DSN">
    SELECT COUNT(*) AS adet 
    FROM Soru
    WHERE soranID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">
    AND aktiflik=1
</cfquery>

<cfquery name="qDogruAdet" datasource="DSN">
    SELECT COUNT(*) AS adet 
    FROM Cevap
    WHERE cozenID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">
    AND onay=1
</cfquery>

<cfquery name="qYorumAdet" datasource="DSN">
    SELECT COUNT(*) AS adet 
    FROM Yorum 
    WHERE yazanID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">
    AND aktiflik=1
</cfquery>

<cfquery name="qFavoriAdet" datasource="DSN">
    SELECT COUNT(*) AS adet 
    FROM Favori 
    WHERE kullaniciID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">
</cfquery>

<cfquery name="qSoru" datasource="DSN">
    SELECT s.id,s.soruResmi,s.goruntulenmeSayisi,s.eklenmeTarihi,
            d.ad AS dersAd,a.ad AS alanAd
    FROM Soru s 
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE soranID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">
    AND s.aktiflik=1
    ORDER BY s.eklenmeTarihi DESC    
</cfquery>

<cfquery name="qCevap" datasource="DSN">
    SELECT s.id,s.soruResmi,c.kullaniciCevabi,c.onay,c.eklenmeTarihi,
            d.ad AS dersAd,a.ad AS alanAd
    FROM Cevap c
    INNER JOIN Soru s ON s.id=c.soruID
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE c.cozenID=<cfqueryparam value="#profilID#" cfsqltype="cf_sql_integer">
    AND s.aktiflik=1
    ORDER BY c.eklenmeTarihi DESC 
</cfquery>

<cfif benimProfil>
    <cfquery name="qFavori" datasource="DSN">
        SELECT s.id,s.soruResmi,s.goruntulenmeSayisi,f.eklenmeTarihi,
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

<cfparam name="sifreHata" default="">
<cfparam name="sifreBasari" default="">

<cfif benimProfil AND structKeyExists(form,"sifreDegistir")>
    <cfset eskiSifre=trim(form.eskiSifre)>
    <cfset yeniSifre=trim(form.yeniSifre)>
    <cfset yeniSifreTekrar=trim(form.yeniSifreTekrar)>

    <cfif eskiSifre EQ "" OR yeniSifre EQ "" OR yeniSifreTekrar EQ "">
        <cfset sifreHata="Lütfen tüm alanları doldurunuz.">
    <cfelseif len(yeniSifre) LT 6>
        <cfset sifreHata="Şifre en az 6 haneli olmalıdır.">
    <cfelseif yeniSifre NEQ yeniSifreTekrar>
        <cfset sifreHata="Şifreler eşleşmiyor.">
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
        <cfelse>
            <cfset yeniSifreHash=hash(yeniSifre,"SHA-256")>

            <cfquery datasource="DSN">
                UPDATE Kullanici 
                SET sifre=<cfqueryparam value="#yeniSifreHash#" cfsqltype="cf_sql_varchar">
                WHERE id=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfquery datasource="DSN">
                UPDATE Oturum 
                SET aktiflik=0
                WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset sifreBasari="Şifreniz başarıyla güncellendi.">
        </cfif>
    </cfif>
</cfif>

<cfoutput>
    <div class="container mt-4">
        <div class="card shadow mb-4">
            <div class="card-body">
                <div class="d-flex align-items-center gap-2">
                    <img src="https://ui-avatars.com/api/?background=random&color=fff&size=80&bold=true&name=#qProfil.ad#"
                        class="rounded-circle" width="80" height="80">

                    <div class="flex-grow-1">
                        <h4 class="mb-1">#qProfil.ad#</h4>
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
                        <button class="btn btn-outline-dark btn-sm" data-bs-toggle="modal" data-bs-target="##sifreModal">
                            <i class="bi bi-key"></i>Şifre Değiştir
                        </button>
                    </cfif>
                </div>
            </div>

            <div class="row g-3 mb-4">
                <div class="col-6 col-md-3">
                    <div class="card text-center shadow-sm">
                        <div class="card-body py-3">
                            <h4 class="mb-0 text-dark">#qSoruAdet.adet#</h4>
                            <small class="text-muted">Eklenen Soru Sayısı:</small>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-md-3">
                    <div class="card text-center shadow-sm">
                        <div class="card-body py-3">
                            <h4 class="mb-0 text-success">#qDogruAdet.adet#</h4>
                            <small class="text-muted">Doğru Cevap Sayısı:</small>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-md-3">
                    <div class="card text-center shadow-sm">
                        <div class="card-body py-3">
                            <h4 class="mb-0 text-primary">#qYorumAdet.adet#</h4>
                            <small class="text-muted">Yapılan Yorum Sayısı:</small>
                        </div>
                    </div>
                </div>

                <div class="col-6 col-md-3">
                    <div class="card text-center shadow-sm">
                        <div class="card-body py-3">
                            <h4 class="mb-0 text-danger">#qFavoriAdet.adet#</h4>
                            <small class="text-muted">Favori Sayısı:</small>
                        </div>
                    </div>
                </div>
            </div>

            <ul class="nav nav-tabs mb-3">
                <li class="nav-item">
                    <a class="nav-link active" data-bs-toggle="tab" href="##sorular">
                        <i class="bi bi-question-circle"></i>Sorular
                        <span class="badge bg-secondary ms-1">#qSoru.recordCount#</span>
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
                            <span class="badge bg-secondary ms-1">#qFavoriAdet.adet#</span>
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
                        <div class="row row-cols-1 row-cols-md-4 g-3">
                            <cfloop query="qSoru">
                                <div class="col">
                                    <div class="card h-100 shadow-sm">
                                        <a href="/YKSSite/views/soru/soruDetay.cfm?id=#id#">
                                            <img src="/YKSSite/assets/images/sorular/#soruResmi#"
                                                class="card-img-top" style="height:140px; object-fit:cover;">
                                        </a>

                                        <div class="card-body p-2">
                                            <span class="badge bg-dark">#dersAd#</span>
                                            <span class="badge bg-secondary">#alanAd#</span>
                                            
                                            <div class="mt-1">
                                                <small class="text-muted">
                                                    <i class="bi bi-eye"></i>#goruntulenmeSayisi# . #dateFormat(eklenmeTarihi,'dd.mm.yyyy')#
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
                        <div class="row row-cols-1 row-cols-md-4 g-3">
                            <cfloop query="qCevap">
                                <div class="col">
                                    <div class="card h-100 shadow-sm">
                                        <a href="/YKSSite/views/soru/soruDetay.cfm?id=#id#">
                                            <img src="/YKSSite/assets/images/sorular/#soruResmi#"
                                                class="card-img-top" style="height:140px; object-fit:cover;">
                                        </a>

                                        <div class="card-body p-2">
                                            <span class="badge bg-dark">#dersAd#</span>
                                            <span class="badge bg-secondary">#alanAd#</span>

                                            <div class="mt-1">
                                                <span class="badge #onay EQ 1 ? 'bg-success':onay EQ 0 ?'bg-danger':'bg-secondary'#">
                                                    #onay EQ 1 ? 'Doğru':onay EQ 2 ? 'Yanlış':'Belirsiz'#
                                                </span>

                                                <small class="text-muted d-block mt-1">
                                                    #dateFormat(eklenmeTarihi,'dd.mm.yyyy')#
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
                            <div class="row row-cols-1 row-cols-md-4 g-3">
                                <cfloop query="qFavori">
                                    <div class="col">
                                        <div class="card h-100 shadow-sm">
                                            <a href="/YKSSite/views/soru/soruDetay.cfm?id=#id#">
                                                <img src="/YKSSite/assets/images/sorular/#soruResmi#"
                                                    class="card-img-top" style="height:140px; object-fit:cover;">
                                            </a>

                                            <div class="card-body p-2">
                                                <span class="badge bg-dark">#dersAd#</span>
                                                <span class="badge bg-secondary">#alanAd#</span>

                                                <div class="mt-1">
                                                    <small class="text-muted">
                                                        <i class="bi bi-eye"></i>#goruntulenmeSayisi#
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
    </div>

    <cfif benimProfil>
        <div class="modal fade" id="sifreModal" tabindex="-1">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header bg-dark text-white">
                        <h5 class="modal-title">
                            <i class="bi bi-key"></i>Şifre Değiştir
                        </h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                    </div>

                    <div class="modal-body">
                        <cfif sifreHata NEQ "">
                            <div class="alert alert-danger">
                                <i class="bi bi-exclamation-circle"></i>#sifreHata#
                            </div>
                        </cfif>

                        <form method="POST">
                            <div class="mb-3">
                                <label class="form-label">Mevcut Şifre:</label>
                                <input type="password" name="eskiSifre" class="form-control" required>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Yeni Şifre:</label>
                                <input type="password" name="yeniSifre" class="form-control" minlength="6" required>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Yeni Şifre Tekrarı:</label>
                                <input type="password" name="yeniSifreTekrar" class="form-control" minlength="6" required>
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
        
        <cfif sifreHata NEQ "" OR sifreBasari NEQ "">
            <script>
                document.addEventListener('DOMContentLoaded',function(){
                    new bootstrap.Modal(document.getElementById('sifreModal')).show();
                });
            </script>
        </cfif>
    </cfif>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">