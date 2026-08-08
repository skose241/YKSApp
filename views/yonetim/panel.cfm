<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif SESSION.rol LT 2>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfif structKeyExists(url,"islem") AND structKeyExists(url,"soruID") AND isNumeric(url.soruID)>
    <cfset soruID=val(url.soruID)>

    <cfif url.islem EQ "onayla">
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
                'Sorunuz moderatör tarafından onaylandı',
                0,
                '/YKSSite/views/soru/soruDetay.cfm?id=#soruID#',
                GETDATE()
            )
        </cfquery>
    <cfelseif url.islem EQ "reddet">
        <cfquery datasource="DSN">
            UPDATE Soru 
            SET aktiflik=0
            WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfquery name="qKisi" datasource="DSN">
            SELECT soranID
            FROM Soru 
            WHERE id=<cfqueryparam value="#qKisi.soranID#" cfsqltype="cf_sql_integer">
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
    </cfif>
</cfif>

<cfquery name="qSoru" datasource="DSN">
    SELECT s.id,s.soruResmi,s.eklenmeTarihi,
        d.ad AS dersAd,a.ad AS alanAd,k.ad AS soranAd
    FROM Soru s
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    INNER JOIN Kullanici k ON k.id=s.soranID
    WHERE s.aktiflik=0
    ORDER BY s.eklenmeTarihi ASC 
</cfquery>

<cfoutput>
    <div class="container mt-4">
        <h4 class="mb-4"><i class="bi bi-shield"></i>Yönetim Paneli</h4>

        <ul class="nav nav-tabs mb-4">
            <li class="nav-item">
                <a class="nav-link active" href="##">
                    <i class="bi bi-clock"></i>Bekleyen Sorular
                    <span class="badge bg-danger ms-1">#qSoru.recordCount#</span>
                </a>
            </li>

            <li class="nav-item">
                <a class="nav-link disabled text-muted" href="##">
                    <i class="bi bi-people"></i>Kullanıcılar
                </a>
            </li>

            <li class="nav-item">
                <a class="nav-link disabled text-muted" href="##">
                    <i class="bi bi-flag"></i>Şikayetler
                </a>
            </li>
        </ul>

        <cfif qSoru.recordCount EQ 0>
            <div class="alert alert-success">
                <i class="bi bi-check-circle"></i>Bekleyen soru bulunmamaktadır.
            </div>
        <cfelse>
            <div class="row row-cols-1 rows-cols-md-3 gp-4">
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
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">