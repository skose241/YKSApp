<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfquery name="qLiderlik" datasource="DSN">
    SELECT TOP 50
        id,ad,xp,rol,kayitTarihi,
        ROW_NUMBER() OVER (ORDER BY xp DESC,kayitTarihi ASC) AS siralama
    FROM Kullanici
    WHERE aktiflik=1
    AND id<><cfqueryparam value="#val(application.aiKullaniciID)#" cfsqltype="cf_sql_integer">
    ORDER BY xp DESC,kayitTarihi ASC
</cfquery>

<cfquery name="qSira" datasource="DSN">
    SELECT COUNT(*)+1 AS siralama
    FROM Kullanici
    WHERE aktiflik=1
    AND id<><cfqueryparam value="#val(application.aiKullaniciID)#" cfsqltype="cf_sql_integer">
    AND xp>(
        SELECT xp
        FROM Kullanici
        WHERE id=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    )
</cfquery>

<cfoutput>
    <div class="container mt-4">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card shadow">
                    <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center">
                        <h5 class="mb-0"><i class="bi bi-trophy"></i>Liderlik Tablosu</h5>

                        <span class="badge bg-warning text-dark">
                            Sizin sıranız:#qSira.siralama#
                        </span>
                    </div>

                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover mb-0 align-middle">
                                <thead class="table-dark">
                                    <tr>
                                        <th width="60" class="text-center">Sıra</th>
                                        <th>Kullanıcı</th>
                                        <th>Rol</th>
                                        <th class="text-end">XP</th>
                                    </tr>
                                </thead>

                                <tbody>
                                    <cfloop query="qLiderlik">
                                        <tr class="#qLiderlik.id EQ val(SESSION.kullaniciID) ? 'table-warning':''#">
                                            <td class="text-center">
                                                <cfif qLiderlik.siralama EQ 1>
                                                    <i class="bi bi-trophy-fill text-warning fs-5"></i>
                                                <cfelseif qLiderlik.siralama EQ 2>
                                                    <i class="bi bi-trophy-fill text-secondary fs-5"></i>
                                                <cfelseif qLiderlik.siralama EQ 3>
                                                    <i class="bi bi-trophy-fill text-danger fs-5"></i>
                                                <cfelse>
                                                    #qLiderlik.siralama#
                                                </cfif>
                                            </td>

                                            <td>
                                                <div class="d-flex align-items-center gap-2">
                                                    <img src="#application.avatarURL##urlEncodedFormat(qLiderlik.ad)#"
                                                        class="rounded-circle" width="32" height="32" alt="">

                                                    <a href="/YKSSite/views/profil/profilim.cfm?id=#qLiderlik.id#" class="text-decoration-none text-dark fw-bold">
                                                        #encodeForHTML(qLiderlik.ad)#

                                                        <cfif qLiderlik.id EQ val(SESSION.kullaniciID)>
                                                            <span class="badge bg-warning text-dark ms-1">Siz</span>
                                                        </cfif>
                                                    </a>
                                                </div>
                                            </td>

                                            <td>
                                                <span class="badge #qLiderlik.rol EQ 3 ? 'bg-danger':qLiderlik.rol EQ 2 ? 'bg-warning text-dark':'bg-secondary'#">
                                                    #qLiderlik.rol EQ 3 ? 'Admin':qLiderlik.rol EQ 2 ? 'Moderatör':'Kullanıcı'#
                                                </span>
                                            </td>

                                            <td class="text-end">
                                                <span class="fw-bold text-warning">
                                                    <i class="bi bi-star-fill"></i>#qLiderlik.xp#
                                                </span>
                                            </td>
                                        </tr>
                                    </cfloop>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <div class="card-footer text-muted text-center small">
                        İlk 50 kullanıcı gösterilmektedir.
                    </div>
                </div>
            </div>
        </div>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">