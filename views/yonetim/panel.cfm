<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif val(SESSION.rol) LT 2>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfparam name="hata" default="">
<cfparam name="basari" default="">

<cfif structKeyExists(url,"islem")>
    <cfif url.islem EQ "onayla" AND structKeyExists(url,"soruID") AND isNumeric(url.soruID)>
        <cfset soruID=val(url.soruID)>

        <cfquery datasource="DSN">
            UPDATE Soru 
            SET aktiflik=1
            WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfquery name="qKisi" datasource="DSN">
            SELECT soranID
            FROM Soru 
            WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfquery datasource="DSN">
            INSERT INTO Bildirim(kullaniciID,islemTipi,mesaj,goruldu,hedefURL,tarih)
            VALUES(
                <cfqueryparam value="#qKisi.soranID#" cfsqltype="cf_sql_integer">,
                'sistem',
                'Sorunuz moderatör tarafından onaylandı.',
                0,
                '/YKSSite/views/soru/soruDetay.cfm?id=#soruID#',
                GETDATE()
            )
        </cfquery>
        <cfset basari="Soru onaylandı.">
    <cfelseif url.islem EQ "reddet" AND structKeyExists(url,"soruID") AND isNumeric(url.soruID)>
        <cfset soruID=val(url.soruID)>

        <cfquery name="qKisi" datasource="DSN">
            SELECT soranID
            FROM Soru 
            WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfquery datasource="DSN">
            INSERT INTO Bildirim(kullaniciID,islemTipi,mesaj,goruldu,hedefURL,tarih)
            VALUES(
                <cfqueryparam value="#qKisi.soranID#" cfsqltype="cf_sql_integer">,
                'sistem',
                'Sorunuz moderatör tarafından reddedildi.',
                0,
                '/YKSSite/anaSayfa.cfm',
                GETDATE()
            )
        </cfquery>

        <cfquery datasource="DSN">
            DELETE FROM Soru 
            WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
            AND aktiflik=0
        </cfquery>
        <cfset basari="Soru reddedildi ve silindi.">
    <cfelseif url.islem EQ "sikayetCoz" AND structKeyExists(url,"sikayetID") AND isNumeric(url.sikayetID)>
        <cfquery datasource="DSN">
            UPDATE Sikayet 
            SET durum=2 
            WHERE id=<cfqueryparam value="#val(url.sikayetID)#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset basari="Şikayet çözüldü olarak işaretlendi.">
    <cfelseif url.islem EQ "sikayetReddet" AND structKeyExists(url,"sikayetID") AND isNumeric(url.sikayetID)>
        <cfquery datasource="DSN">
            UPDATE Sikayet 
            SET durum=3
            WHERE id=<cfqueryparam value="#val(url.sikayetID)#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset basari="Şikayet reddedildi olarak işaretlendi.">
    <cfelseif url.islem EQ "kullaniciBan" AND structKeyExists(url,"kullaniciID") AND isNumeric(url.kullaniciID)>
        <cfif val(url.kullaniciID) NEQ val(SESSION.kullaniciID)>
            <cfquery datasource="DSN">
                UPDATE Kullanici 
                SET aktiflik=0
                WHERE id=<cfqueryparam value="#val(url.kullaniciID)#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset basari="Kullanıcı engellendi.">
        <cfelse>
            <cfset hata="Kendinizi engelleyemezsiniz.">
        </cfif>
    <cfelseif url.islem EQ "rolDegistir" AND val(SESSION.rol) EQ 3 AND structKeyExists(url,"kullaniciID") AND isNumeric(url.kullaniciID) AND structKeyExists(url,"yeniRol") AND isNumeric(url.yeniRol)>
        <cfset yeniRol=val(url.yeniRol)>

        <cfif listFind("1,2,3",yeniRol) AND val(url.kullaniciID) NEQ val(SESSION.kullaniciID)>
            <cfquery datasource="DSN">
                UPDATE Kullanici 
                SET rol=<cfqueryparam value="#val(yeniRol)#" cfsqltype="cf_sql_integer">
                WHERE id=<cfqueryparam value="#val(url.kullaniciID)#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset basari="Kullanıcı rolü güncellendi.">
        </cfif>
    </cfif>
</cfif>
    
<cfquery name="qKullanici" datasource="DSN">
    SELECT id,ad,rol,xp,aktiflik,kayitTarihi
    FROM Kullanici 
    ORDER BY kayitTarihi DESC
</cfquery>

<cfquery name="qSoru" datasource="DSN">
    SELECT s.id,s.soruResmi,s.eklenmeTarihi,
        d.ad AS dersAd,a.ad AS alanAd,k.ad AS soranAd
    FROM Soru s 
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    INNER JOIN Kullanici k ON k.id=s.soranID
    WHERE s.aktiflik=0
    ORDER BY s.eklenmeTarihi
</cfquery>

<cfquery name="qSikayet" datasource="DSN">
    SELECT s.id,s.hedefTip,s.hedefID,s.sebep,s.durum,s.tarih,
        k.ad AS sikayetciAd
    FROM Sikayet s 
    INNER JOIN Kullanici k ON k.id=s.sikayetciID
    WHERE s.durum=0
    ORDER BY s.tarih DESC 
</cfquery>

<cfoutput>
    <div class="container mt-4">
        <h4 class="mb-4"><i class="bi bi-shield"></i>Yönetim Paneli</h4>

        <cfif hata NEQ "">
            <div class="alert alert-danger">
                <i class="bi bi-exclamation-circle"></i>#hata#
            </div>
        </cfif>

        <cfif basari NEQ "">
            <div class="alert alert-success">
                <i class="bi bi-check-circle"></i>#basari#
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
                <a class="nav-link" data-bs-toggle="tab" href="##kullanici">
                    <i class="bi bi-people"></i>Kullanıcılar
                    <span class="badge bg-secondary ms-1">#qKullanici.recordCount#</span>
                </a>
            </li>

            <li class="nav-item">
                <a class="nav-link" data-bs-toggle="tab" href="##sikayet">
                    <i class="bi bi-flag"></i>Şikayetler
                    <span class="badge bg-danger ms-1">#qSikayet.recordCount#</span>
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
                                    <img src="/YKSSite/assets/images/sorular/#soruResmi#"
                                        class="card-img-top" style="height:200px; object-fit:cover;" alt="Soru">
                                    <div class="card-body">
                                        <div class="mb-2">
                                            <span class="badge bg-dark">#dersAd#</span>
                                            <span class="badge bg-secondary">#alanAd#</span>
                                        </div>

                                        <p class="mb-1">
                                            <small><i class="bi bi-person"></i>#soranAd#</small>
                                        </p>

                                        <p class="mb-0">
                                            <small class="text-muted">
                                                <i class="bi bi-calendar"></i>
                                                #dateFormat(eklenmeTarihi,'dd.mm.yyyy')#
                                            </small>
                                        </p>
                                    </div>

                                    <div class="card-footer d-flex gap-2">
                                        <a href="?islem=onayla&soruID=#id#" class="btn btn-success btn-sm flex-grow-1" onclick="return confirm('Soruyu onaylamak istediğinize emin misiniz?')">
                                            <i class="bi bi-check-lg"></i>Onayla
                                        </a>

                                        <a href="?islem=reddet&soruID=#id#" class="btn btn-danger btn-sm flex-grow-1" onclick="return confirm('Soruyu reddetmek istediğinize emin misiniz?')">
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
                        <table class="table table-hover">
                            <thead class="table-dark">
                                <tr>
                                    <th>Şikayetçi:</th>
                                    <th>Şikayet Türü:</th>
                                    <th>Sebep:</th>
                                    <th>Tarih:</th>
                                    <th>İşlem:</th>
                                </tr>
                            </thead>
                            
                            <tbody>
                                <cfloop query="qSikayet">
                                    <tr>
                                        <td>#sikayetciAd#</td>
                                        <td>
                                            <span class="badge bg-secondary">
                                                #hedefTip EQ 'soru' ? 'Soru':
                                                hedefTip EQ 'cevap' ? 'Cevap':
                                                hedefTip EQ 'yorum' ? 'Yorum':'Kullanıcı'#
                                                #hedefID#
                                            </span>
                                        </td>

                                        <td><small>#sebep#</small></td>
                                        <td><small>#dateFormat(tarih,'dd.mm.yyyy')#</small></td>

                                        <td>
                                            <div class="d-flex gap-1">
                                                <cfif hedefTip EQ "soru">
                                                    <a href="/YKSSite/views/soru/soruDetay.cfm?id=#hedefID#" class="btn btn-outline-dark btn-sm" target="_blank">
                                                        <i class="bi bi-eye"></i>
                                                    </a>
                                                <cfelseif hedefTip EQ "kullanici">
                                                    <a href="/YKSSite/views/profil/profilim.cfm?id=#hedefID#" class="btn btn-outline-dark btn-sm" target="_blank">
                                                        <i class="bi bi-eye"></i>
                                                    </a>
                                                </cfif>

                                                <a href="?islem=sikayetCoz&sikayetID=#id#" class="btn btn-success btn-sm" onclick="return confirm('Şikayeti onaylamak istediğinize emin misiniz?')">
                                                    <i class="bi bi-check-lg"></i>
                                                </a>

                                                <a href="?islem=sikayetReddet&sikayetID=#id#" class="btn btn-danger btn-sm" onclick="return confirm('Şikayeti reddetmek istediğinize emin misiniz?')">
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
                    <table class="table table-hover">
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
                                <tr class="#aktiflik EQ 0 ? 'table-danger':''#">
                                    <td>
                                        <a href="/YKSSite/views/profil/profilim.cfm?id=#id#" class="text-decoration-none text-dark">#ad#</a>
                                    </td>

                                    <td>
                                        <cfif val(SESSION.rol) EQ 3 AND id NEQ val(SESSION.kullaniciID)>
                                            <select class="form-select form-select-sm" style="width:130px" onchange="rolDegistir(#id#,this.value)">
                                                <option value="1" #rol EQ 1 ? 'selected':''#>Kullanıcı</option>
                                                <option value="2" #rol EQ 2 ? 'selected':''#>Moderatör</option>
                                                <option value="3" #rol EQ 3 ? 'selected':''#>Admin</option>
                                            </select>
                                        <cfelse>
                                            <span class="badge #rol EQ 3 ? 'bg-danger':rol EQ 2 ? 'bg-warning text-dark':'bg-secondary'#">
                                                #rol EQ 3 ? 'Admin':rol EQ 2 ? 'Moderatör':'Kullanıcı'#
                                            </span>
                                        </cfif>
                                    </td>

                                    <td>#xp#</td>

                                    <td><small>#dateFormat(kayitTarihi,'dd.mm.yyyy')#</small></td>

                                    <td><span class="badge #aktiflik EQ 1 ? 'bg-success':'bg-danger'#">
                                        #aktiflik EQ 1 ? 'Aktif':'Engelli'#
                                    </span></td>

                                    <td>
                                        <cfif id NEQ val(SESSION.kullaniciID)>
                                            <cfif aktiflik EQ 1>
                                                <a href="?islem=kullaniciBan&kullaniciID=#id#" class="btn btn-danger btn-sm" onclick="return confirm('#ad# kullanıcısını engellemek istediğinize emin misiniz?')">
                                                    <i class="bi bi-slash-circle"></i>Engelle
                                                </a>
                                            <cfelse>
                                                <a href="?islem=kullaniciAktif&kullaniciID=#id#" class="btn btn-success btn-sm" onclick="return confirm('#ad# kullanıcısını aktif etmek istediğinize emin misiniz?')">
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