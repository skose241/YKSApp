<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif val(SESSION.rol) LT 2>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfparam name="hata" default="">
<cfparam name="basari" default="">

<cfset yoneticiID=val(SESSION.kullaniciID)>
<cfset yoneticiRol=val(SESSION.rol)>
<cfset aiHesapID=structKeyExists(application,"aiKullaniciID") ? val(application.aiKullaniciID):0>

<cfif structKeyExists(url,"islem")>
    <cftry>
        <cfswitch expression="#url.islem#">
            <cfcase value="onayla">
                <cfif structKeyExists(url,"soruID") AND isNumeric(url.soruID)>
                    <cfset soruID=val(url.soruID)>

                    <cfquery name="qKisi" datasource="DSN">
                        SELECT soranID
                        FROM Soru
                        WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                        AND aktiflik=0
                    </cfquery>

                    <cfif qKisi.recordCount EQ 0>
                        <cfset hata="Soru bulunamadı veya zaten işlem yapılmış.">
                    <cfelse>
                        <cftransaction>
                            <cfquery datasource="DSN">
                                UPDATE Soru
                                SET aktiflik=1
                                WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                                AND aktiflik=0
                            </cfquery>

                            <cfquery datasource="DSN">
                                INSERT INTO Bildirim(kullaniciID,islemTipi,mesaj,goruldu,hedefURL,tarih)
                                VALUES(
                                    <cfqueryparam value="#qKisi.soranID#" cfsqltype="cf_sql_integer">,
                                    <cfqueryparam value="sistem" cfsqltype="cf_sql_varchar">,
                                    <cfqueryparam value="Sorunuz moderatör tarafından onaylandı." cfsqltype="cf_sql_varchar">,
                                    0,
                                    <cfqueryparam value="/YKSSite/views/soru/soruDetay.cfm?id=#soruID#" cfsqltype="cf_sql_varchar">,
                                    GETDATE()
                                )
                            </cfquery>
                        </cftransaction>

                        <cfset basari="Soru onaylandı.">
                    </cfif>
                </cfif>
            </cfcase>

            <cfcase value="reddet">
                <cfif structKeyExists(url,"soruID") AND isNumeric(url.soruID)>
                    <cfset soruID=val(url.soruID)>

                    <cfquery name="qKisi" datasource="DSN">
                        SELECT soranID,soruResmi
                        FROM Soru
                        WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                        AND aktiflik=0
                    </cfquery>

                    <cfif qKisi.recordCount EQ 0>
                        <cfset hata="Soru bulunamadı veya zaten işlem yapılmış.">
                    <cfelse>
                        <cfset silinecekResim=trim(qKisi.soruResmi)>

                        <cftransaction>
                            <cfquery datasource="DSN">
                                INSERT INTO Bildirim(kullaniciID,islemTipi,mesaj,goruldu,hedefURL,tarih)
                                VALUES(
                                    <cfqueryparam value="#qKisi.soranID#" cfsqltype="cf_sql_integer">,
                                    <cfqueryparam value="sistem" cfsqltype="cf_sql_varchar">,
                                    <cfqueryparam value="Sorunuz moderatör tarafından reddedildi." cfsqltype="cf_sql_varchar">,
                                    0,
                                    <cfqueryparam value="/YKSSite/anaSayfa.cfm" cfsqltype="cf_sql_varchar">,
                                    GETDATE()
                                )
                            </cfquery>

                            <cfquery datasource="DSN">
                                DELETE FROM Sikayet
                                WHERE hedefTip='soru'
                                AND hedefID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                            </cfquery>

                            <cfquery datasource="DSN">
                                DELETE FROM Puan
                                WHERE islemTipi='soru_ekledi'
                                AND referansTip='soru'
                                AND referansID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                            </cfquery>

                            <cfquery datasource="DSN">
                                UPDATE Kullanici
                                SET xp=CASE WHEN xp-3<0 THEN 0 ELSE xp-3 END
                                WHERE id=<cfqueryparam value="#qKisi.soranID#" cfsqltype="cf_sql_integer">
                            </cfquery>

                            <cfquery datasource="DSN">
                                DELETE FROM Favori
                                WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                            </cfquery>

                            <cfquery datasource="DSN">
                                DELETE FROM AI
                                WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                            </cfquery>

                            <cfquery datasource="DSN">
                                DELETE FROM Soru
                                WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                                AND aktiflik=0
                            </cfquery>
                        </cftransaction>

                        <cfif len(silinecekResim)>
                            <cftry>
                                <cfset resimTamYol=expandPath("/YKSSite/assets/images/sorular/#silinecekResim#")>

                                <cfif fileExists(resimTamYol)>
                                    <cffile action="delete" file="#resimTamYol#">
                                </cfif>

                                <cfcatch type="any"></cfcatch>
                            </cftry>
                        </cfif>

                        <cfset basari="Soru reddedildi ve silindi.">
                    </cfif>
                </cfif>
            </cfcase>

            <cfcase value="sikayetCoz">
                <cfif structKeyExists(url,"sikayetID") AND isNumeric(url.sikayetID)>
                    <cfset sikayetID=val(url.sikayetID)>

                    <cfquery name="qHedef" datasource="DSN">
                        SELECT hedefTip,hedefID
                        FROM Sikayet
                        WHERE id=<cfqueryparam value="#sikayetID#" cfsqltype="cf_sql_integer">
                        AND durum=0
                    </cfquery>

                    <cfif qHedef.recordCount EQ 0>
                        <cfset hata="Şikayet bulunamadı veya zaten işlem yapılmış.">
                    <cfelseif qHedef.hedefTip EQ "kullanici" AND val(qHedef.hedefID) EQ yoneticiID>
                        <cfset hata="Kendinizi engelleyemezsiniz.">
                    <cfelse>
                        <cftransaction>
                            <cfswitch expression="#qHedef.hedefTip#">
                                <cfcase value="soru">
                                    <cfquery datasource="DSN">
                                        UPDATE Soru
                                        SET aktiflik=0
                                        WHERE id=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                    </cfquery>
                                </cfcase>

                                <cfcase value="cevap">
                                    <cfquery datasource="DSN">
                                        UPDATE Cevap
                                        SET aktiflik=0
                                        WHERE id=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                    </cfquery>
                                </cfcase>

                                <cfcase value="yorum">
                                    <cfquery datasource="DSN">
                                        UPDATE Yorum
                                        SET aktiflik=0
                                        WHERE id=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                        OR ustYorumID=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                    </cfquery>
                                </cfcase>

                                <cfcase value="kullanici">
                                    <cfquery name="qHedefRol" datasource="DSN">
                                        SELECT rol
                                        FROM Kullanici
                                        WHERE id=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                    </cfquery>

                                    <cfif qHedefRol.recordCount GT 0 AND val(qHedefRol.rol) LT yoneticiRol>
                                        <cfquery datasource="DSN">
                                            UPDATE Kullanici
                                            SET aktiflik=0
                                            WHERE id=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                        </cfquery>

                                        <cfquery datasource="DSN">
                                            UPDATE Oturum
                                            SET aktiflik=0
                                            WHERE kullaniciID=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                            AND aktiflik=1
                                        </cfquery>
                                    </cfif>
                                </cfcase>
                            </cfswitch>

                            <cfquery datasource="DSN">
                                UPDATE Sikayet
                                SET durum=2
                                WHERE id=<cfqueryparam value="#sikayetID#" cfsqltype="cf_sql_integer">
                                AND durum=0
                            </cfquery>

                            <cfquery datasource="DSN">
                                UPDATE Sikayet
                                SET durum=2
                                WHERE hedefTip=<cfqueryparam value="#qHedef.hedefTip#" cfsqltype="cf_sql_varchar">
                                AND hedefID=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                AND durum=0
                            </cfquery>
                        </cftransaction>

                        <cfset basari="Şikayet onaylandı,ilgili içerik yayından kaldırıldı.">
                    </cfif>
                </cfif>
            </cfcase>

            <cfcase value="sikayetReddet">
                <cfif structKeyExists(url,"sikayetID") AND isNumeric(url.sikayetID)>
                    <cfquery datasource="DSN">
                        UPDATE Sikayet
                        SET durum=3
                        WHERE id=<cfqueryparam value="#val(url.sikayetID)#" cfsqltype="cf_sql_integer">
                        AND durum=0
                    </cfquery>

                    <cfset basari="Şikayet reddedildi olarak işaretlendi.">
                </cfif>
            </cfcase>

            <cfcase value="kullaniciBan">
                <cfif structKeyExists(url,"kullaniciID") AND isNumeric(url.kullaniciID)>
                    <cfset hedefKullanici=val(url.kullaniciID)>

                    <cfquery name="qRol" datasource="DSN">
                        SELECT rol
                        FROM Kullanici
                        WHERE id=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                    </cfquery>

                    <cfif hedefKullanici EQ yoneticiID>
                        <cfset hata="Kendinizi engelleyemezsiniz.">
                    <cfelseif hedefKullanici EQ aiHesapID>
                        <cfset hata="Sistem hesabı engellenemez.">
                    <cfelseif qRol.recordCount EQ 0>
                        <cfset hata="Kullanıcı bulunamadı.">
                    <cfelseif val(qRol.rol) GTE yoneticiRol>
                        <cfset hata="Kendinizle eşdeğer veya üst yetkili birini engelleyemezsiniz.">
                    <cfelse>
                        <cftransaction>
                            <cfquery datasource="DSN">
                                UPDATE Kullanici
                                SET aktiflik=0
                                WHERE id=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                            </cfquery>

                            <cfquery datasource="DSN">
                                UPDATE Oturum
                                SET aktiflik=0
                                WHERE kullaniciID=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                                AND aktiflik=1
                            </cfquery>
                        </cftransaction>

                        <cfset basari="Kullanıcı engellendi.">
                    </cfif>
                </cfif>
            </cfcase>

            <cfcase value="kullaniciAktiflestir">
                <cfif structKeyExists(url,"kullaniciID") AND isNumeric(url.kullaniciID)>
                    <cfset hedefKullanici=val(url.kullaniciID)>

                    <cfquery name="qRol" datasource="DSN">
                        SELECT rol
                        FROM Kullanici
                        WHERE id=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                    </cfquery>

                    <cfif qRol.recordCount EQ 0>
                        <cfset hata="Kullanıcı bulunamadı.">
                    <cfelseif val(qRol.rol) GTE yoneticiRol AND hedefKullanici NEQ yoneticiID>
                        <cfset hata="Bu kullanıcı üzerinde işlem yapma yetkiniz yok.">
                    <cfelse>
                        <cfquery datasource="DSN">
                            UPDATE Kullanici
                            SET aktiflik=1
                            WHERE id=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                        </cfquery>

                        <cfset basari="Kullanıcı yeniden aktifleştirildi.">
                    </cfif>
                </cfif>
            </cfcase>

            <cfcase value="rolDegistir">
                <cfif yoneticiRol NEQ 3>
                    <cfset hata="Bu işlem için yetkiniz yok.">
                <cfelseif structKeyExists(url,"kullaniciID") AND isNumeric(url.kullaniciID) AND structKeyExists(url,"yeniRol") AND isNumeric(url.yeniRol)>
                    <cfset hedefKullanici=val(url.kullaniciID)>
                    <cfset yeniRol=val(url.yeniRol)>

                    <cfif hedefKullanici EQ yoneticiID>
                        <cfset hata="Kendi rolünüzü değiştiremezsiniz.">
                    <cfelseif hedefKullanici EQ aiHesapID>
                        <cfset hata="Sistem hesabının rolü değiştirilemez.">
                    <cfelseif NOT listFind("1,2,3",yeniRol)>
                        <cfset hata="Geçersiz rol.">
                    <cfelse>
                        <cfquery datasource="DSN">
                            UPDATE Kullanici
                            SET rol=<cfqueryparam value="#yeniRol#" cfsqltype="cf_sql_integer">
                            WHERE id=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                        </cfquery>

                        <cfset basari="Kullanıcı rolü güncellendi.">
                    </cfif>
                </cfif>
            </cfcase>
        </cfswitch>

        <cfcatch type="any">
            <cfset hata="İşlem sırasında bir hata oluştu.">
            <cfset ai=createObject("component","YKSSite.views.includes.ai")>

            <cfset ai.hataYazma(
                sayfa="/YKSSite/views/yonetim/panel.cfm",
                islem="panel:#url.islem#",
                mesaj=cfcatch.message,
                detay=cfcatch.detail
            )>
        </cfcatch>
    </cftry>
</cfif>

<cfquery name="qKullanici" datasource="DSN">
    SELECT id,ad,rol,xp,aktiflik,kayitTarihi
    FROM Kullanici
    ORDER BY aktiflik ASC,kayitTarihi DESC
</cfquery>

<cfquery name="qSoru" datasource="DSN">
    SELECT s.id,s.soruResmi,s.soruMetni,s.sistemSoru,s.eklenmeTarihi,
        d.ad AS dersAd,a.ad AS alanAd,k.ad AS soranAd
    FROM Soru s
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    INNER JOIN Kullanici k ON k.id=s.soranID
    WHERE s.aktiflik=0
    ORDER BY s.eklenmeTarihi ASC
</cfquery>

<cfquery name="qSikayet" datasource="DSN">
    SELECT s.id,s.hedefID,s.hedefTip,s.sebep,s.durum,s.tarih,
        k.ad AS sikayetciAd,
        CASE
            WHEN s.hedefTip='soru' THEN s.hedefID
            WHEN s.hedefTip='cevap' THEN(
                SELECT c.soruID FROM Cevap c WHERE c.id=s.hedefID
            )
            WHEN s.hedefTip='yorum' THEN(
                SELECT c2.soruID FROM Yorum y INNER JOIN Cevap c2 ON c2.id=y.cevapID WHERE y.id=s.hedefID
            )
            ELSE NULL
        END AS ilgiliSoruID
    FROM Sikayet s
    INNER JOIN Kullanici k ON k.id=s.sikayetciID
    WHERE s.durum=0
    ORDER BY s.tarih DESC
</cfquery>

<cfoutput>
    <div class="container mt-4">
        <h4 class="mb-4"><i class="bi bi-shield"></i>Yönetim Paneli</h4>

        <cfif len(hata)>
            <div class="alert alert-danger">
                <i class="bi bi-exclamation-circle"></i>#encodeForHTML(hata)#
            </div>
        </cfif>

        <cfif len(basari)>
            <div class="alert alert-success">
                <i class="bi bi-check-circle"></i>#encodeForHTML(basari)#
            </div>
        </cfif>

        <ul class="nav nav-tabs mb-4">
            <li class="nav-item">
                <a class="nav-link active" data-bs-toggle="tab" href="##soru">
                    <i class="bi bi-clock"></i>Bekleyen Sorular
                    <span class="badge bg-danger ms-1">#qSoru.recordCount#</span>
                </a>
            </li>

            <li class="nav-item">
                <a class="nav-link" data-bs-toggle="tab" href="##sikayet">
                    <i class="bi bi-flag"></i>Şikayetler
                    <span class="badge bg-danger ms-1">#qSikayet.recordCount#</span>
                </a>
            </li>

            <li class="nav-item">
                <a class="nav-link" data-bs-toggle="tab" href="##kullanici">
                    <i class="bi bi-people"></i>Kullanıcılar
                    <span class="badge bg-secondary ms-1">#qKullanici.recordCount#</span>
                </a>
            </li>
        </ul>

        <div class="tab-content">
            <div class="tab-pane fade show active" id="soru">
                <cfif qSoru.recordCount EQ 0>
                    <div class="alert alert-success">
                        <i class="bi bi-check-circle"></i>Bekleyen soru bulunmamaktadır.
                    </div>
                <cfelse>
                    <div class="row row-cols-1 row-cols-md-3 g-4">
                        <cfloop query="qSoru">
                            <div class="col">
                                <div class="card shadow-sm h-100">
                                    <cfif len(trim(qSoru.soruResmi))>
                                        <a href="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qSoru.soruResmi)#" target="_blank">
                                            <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qSoru.soruResmi)#"
                                                class="card-img-top" style="height:200px; object-fit:cover;" alt="Soru">
                                        </a>
                                    <cfelse>
                                        <div class="p-2 bg-light border-bottom" style="height:200px; overflow:hidden;">
                                            <small>#encodeForHTML(left(qSoru.soruMetni,300))#</small>
                                        </div>
                                    </cfif>

                                    <div class="card-body">
                                        <div class="mb-2">
                                            <span class="badge bg-dark">#encodeForHTML(qSoru.dersAd)#</span>
                                            <span class="badge bg-secondary">#encodeForHTML(qSoru.alanAd)#</span>
                                        </div>

                                        <p class="mb-1">
                                            <small><i class="bi bi-person"></i>#encodeForHTML(qSoru.soranAd)#</small>
                                        </p>

                                        <p class="mb-0">
                                            <small class="text-muted">
                                                <i class="bi bi-calendar"></i>
                                                #dateFormat(qSoru.eklenmeTarihi,'dd.mm.yyyy')#
                                            </small>
                                        </p>
                                    </div>

                                    <div class="card-footer d-flex gap-2">
                                        <a href="?islem=onayla&soruID=#qSoru.id#" class="btn btn-success btn-sm flex-grow-1" onclick="return confirm('Soruyu onaylamak istediğinize emin misiniz?')">
                                            <i class="bi bi-check-lg"></i>Onayla
                                        </a>

                                        <a href="?islem=reddet&soruID=#qSoru.id#" class="btn btn-danger btn-sm flex-grow-1" onclick="return confirm('Soru ve görseli kalıcı olarak silinecek. Emin misiniz?')">
                                            <i class="bi bi-x-lg"></i>Reddet
                                        </a>
                                    </div>
                                </div>
                            </div>
                        </cfloop>
                    </div>
                </cfif>
            </div>

            <div class="tab-pane fade" id="sikayet">
                <cfif qSikayet.recordCount EQ 0>
                    <div class="alert alert-success">
                        <i class="bi bi-check-circle"></i>Bekleyen şikayet bulunmamaktadır.
                    </div>
                <cfelse>
                    <div class="table-responsive">
                        <table class="table table-hover align-middle">
                            <thead class="table-dark">
                                <tr>
                                    <th>Şikayetçi:</th>
                                    <th>Tür:</th>
                                    <th>Sebep:</th>
                                    <th>Tarih:</th>
                                    <th>İşlem:</th>
                                </tr>
                            </thead>

                            <tbody>
                                <cfloop query="qSikayet">
                                    <tr>
                                        <td>#encodeForHTML(qSikayet.sikayetciAd)#</td>

                                        <td>
                                            <span class="badge bg-secondary">
                                                #qSikayet.hedefTip EQ 'soru' ? 'Soru':
                                                qSikayet.hedefTip EQ 'cevap' ? 'Çözüm':
                                                qSikayet.hedefTip EQ 'yorum' ? 'Yorum':'Kullanıcı'#
                                                ###qSikayet.hedefID#
                                            </span>
                                        </td>

                                        <td><small>#encodeForHTML(qSikayet.sebep)#</small></td>
                                        <td><small>#dateFormat(qSikayet.tarih,'dd.mm.yyyy')#</small></td>

                                        <td>
                                            <div class="d-flex gap-1">
                                                <cfif qSikayet.hedefTip EQ "kullanici">
                                                    <a href="/YKSSite/views/profil/profilim.cfm?id=#qSikayet.hedefID#" class="btn btn-outline-dark btn-sm" target="_blank" title="Görüntüle">
                                                        <i class="bi bi-eye"></i>Profili İncele
                                                    </a>
                                                <cfelseif val(qSikayet.ilgiliSoruID) GT 0>
                                                    <a href="/YKSSite/views/soru/soruDetay.cfm?id=#qSikayet.ilgiliSoruID#" class="btn btn-outline-dark btn-sm" target="_blank" title="Görüntüle">
                                                        <i class="bi bi-eye"></i>Şikayeti İncele
                                                    </a>
                                                <cfelse>
                                                    <span class="btn btn-outline-secondary btn-sm disabled">
                                                        <i class="bi bi-eye-slash"></i>İçerik Yok
                                                    </span>
                                                </cfif>

                                                <a href="?islem=sikayetCoz&sikayetID=#qSikayet.id#" class="btn btn-success btn-sm" title="Onayla ve Kaldır" onclick="return confirm('Şikayet onaylanacak ve içerik yayından kaldırılacak. Emin misiniz?')">
                                                    <i class="bi bi-check-lg"></i>
                                                </a>

                                                <a href="?islem=sikayetReddet&sikayetID=#qSikayet.id#" class="btn btn-danger btn-sm" title="Reddet" onclick="return confirm('Şikayeti reddetmek istediğinize emin misiniz?')">
                                                    <i class="bi bi-x-lg"></i>
                                                </a>
                                            </div>
                                        </td>
                                    </tr>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                </cfif>
            </div>

            <div class="tab-pane fade" id="kullanici">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-dark">
                            <tr>
                                <th>Kullanıcı:</th>
                                <th>Rol:</th>
                                <th>XP:</th>
                                <th>Kayıt Tarihi:</th>
                                <th>Durum:</th>
                                <th>İşlem:</th>
                            </tr>
                        </thead>

                        <tbody>
                            <cfloop query="qKullanici">
                                <tr class="#qKullanici.aktiflik EQ 0 ? 'table-danger':''#">
                                    <td>
                                        <a href="/YKSSite/views/profil/profilim.cfm?id=#qKullanici.id#" class="text-decoration-none text-dark">#encodeForHTML(qKullanici.ad)#</a>

                                        <cfif qKullanici.id EQ aiHesapID>
                                            <span class="badge bg-info text-dark ms-1">Sistem</span>
                                        </cfif>
                                    </td>

                                    <td>
                                        <cfif yoneticiRol EQ 3 AND qKullanici.id NEQ yoneticiID AND qKullanici.id NEQ aiHesapID>
                                            <select class="form-select form-select-sm" style="width:130px" onchange="rolDegistir(#qKullanici.id#,this.value)">
                                                <option value="1" #qKullanici.rol EQ 1 ? 'selected':''#>Kullanıcı</option>
                                                <option value="2" #qKullanici.rol EQ 2 ? 'selected':''#>Moderatör</option>
                                                <option value="3" #qKullanici.rol EQ 3 ? 'selected':''#>Admin</option>
                                            </select>
                                        <cfelse>
                                            <span class="badge #qKullanici.rol EQ 3 ? 'bg-danger':qKullanici.rol EQ 2 ? 'bg-warning text-dark':'bg-secondary'#">
                                                #qKullanici.rol EQ 3 ? 'Admin':qKullanici.rol EQ 2 ? 'Moderatör':'Kullanıcı'#
                                            </span>
                                        </cfif>
                                    </td>

                                    <td>#qKullanici.xp#</td>
                                    <td><small>#dateFormat(qKullanici.kayitTarihi,'dd.mm.yyyy')#</small></td>

                                    <td>
                                        <span class="badge #qKullanici.aktiflik EQ 1 ? 'bg-success':'bg-danger'#">
                                            #qKullanici.aktiflik EQ 1 ? 'Aktif':'Engelli'#
                                        </span>
                                    </td>

                                    <td>
                                        <cfif qKullanici.id NEQ yoneticiID AND qKullanici.id NEQ aiHesapID AND val(qKullanici.rol) LT yoneticiRol>
                                            <cfif qKullanici.aktiflik EQ 1>
                                                <a href="?islem=kullaniciBan&kullaniciID=#qKullanici.id#" class="btn btn-danger btn-sm" onclick="return confirm('#jsStringFormat(qKullanici.ad)# kullanıcısını engellemek istediğinize emin misiniz?')">
                                                    <i class="bi bi-slash-circle"></i>Engelle
                                                </a>
                                            <cfelse>
                                                <a href="?islem=kullaniciAktiflestir&kullaniciID=#qKullanici.id#" class="btn btn-success btn-sm" onclick="return confirm('#jsStringFormat(qKullanici.ad)# kullanıcısını aktif etmek istediğinize emin misiniz?')">
                                                    <i class="bi bi-check-circle"></i>Aktif Et
                                                </a>
                                            </cfif>
                                        </cfif>
                                    </td>
                                </tr>
                            </cfloop>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <script>
        function rolDegistir(kullaniciID,yeniRol){
            if(confirm('Kullanıcı rolünü değiştirmek istediğinize emin misiniz?')){
                window.location.href='?islem=rolDegistir&kullaniciID='+kullaniciID+'&yeniRol='+yeniRol;
            }
        }
    </script>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">