<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfquery datasource="DSN">
    UPDATE Bildirim
    SET goruldu=1
    WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    AND goruldu=0
</cfquery>

<cfquery name="qBildirim" datasource="DSN">
    SELECT id,islemTipi,mesaj,goruldu,hedefURL,tarih
    FROM Bildirim
    WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    ORDER BY tarih DESC
</cfquery>

<cfoutput>
    <div class="container mt-4">
        <div class="row justify-content-center">
            <div class="col-md-7">
                <div class="card shadow">
                    <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center">
                        <h5 class="mb-0"><i class="bi bi-bell"></i>Bildirimler</h5>
                        <span class="badge bg-secondary">#qBildirim.recordCount# bildirim</span>
                    </div>

                    <div class="card-body p-0">
                        <cfif qBildirim.recordCount EQ 0>
                            <div class="p-4 text-center text-muted">
                                <i class="bi bi-bell-slash fs-3 d-block mb-2"></i>
                                Henüz bildiriminiz bulunmamaktadır.
                            </div>
                        <cfelse>
                            <div class="list-group list-group-flush">
                                <cfloop query="qBildirim">
                                    <a href="#hedefURL NEQ '' ? hedefURL:'##'#" class="list-group-item list-group-item-action d-flex gap-3 py-3">
                                        <div class="flex-shrink-0">
                                            <span class="rounded-circle p-2 d-inline-flex
                                                #islemTipi EQ 'sistem' ? 'bg-primary':
                                                islemTipi EQ 'kullanici' ? 'bg-success':
                                                'bg-warning'# bg-opacity-10">
                                                <i class="bi bi-
                                                    #islemTipi EQ 'sistem' ? 'gear':
                                                    islemTipi EQ 'kullanici' ? 'person':
                                                    'robot'#
                                                    text-#islemTipi EQ 'sistem' ? 'primary':
                                                        islemTipi EQ 'kullanici' ? 'success':
                                                        'warning'#">
                                                </i>
                                            </span>
                                        </div>

                                        <div class="flex-grow-1">
                                            <p class="mb-0 #goruldu EQ 0 ? 'fw-bold':'text-muted'#">#mesaj#</p>
                                            <small class="text-muted">
                                                <i class="bi bi-clock"></i>
                                                #dateFormat(tarih,'dd.mm.yyyy')#
                                                #timeFormat(tarih,'HH:mm')#
                                            </small>
                                        </div>

                                        <cfif hedefURL NEQ "">
                                            <div class="flex-shrink-0 align-self-center">
                                                <i class="bi bi-chevron-right text-muted"></i>
                                            </div>
                                        </cfif>
                                    </a>
                                </cfloop>
                            </div>
                        </cfif>
                    </div>
                </div>
            </div>
        </div>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">