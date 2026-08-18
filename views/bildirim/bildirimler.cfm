<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">
<cfinclude template="/YKSSite/views/includes/baslik.cfm">

<cfquery name="qBildirim" datasource="DSN">
    SELECT id,islemTipi,mesaj,goruldu,hedefURL,tarih
    FROM Bildirim
    WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    ORDER BY tarih DESC
</cfquery>

<cfquery datasource="DSN">
    UPDATE Bildirim
    SET goruldu=1
    WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    AND goruldu=0
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
                                    <cfset renk=qBildirim.islemTipi EQ 'sistem' ? 'primary':qBildirim.islemTipi EQ 'yorum' ? 'success':'warning'>
                                    <cfset ikon=qBildirim.islemTipi EQ 'sistem' ? 'gear':qBildirim.islemTipi EQ 'yorum' ? 'chat-dots':'robot'>
                                    <cfset hedef=len(trim(qBildirim.hedefURL)) ? qBildirim.hedefURL:'##'>

                                    <a href="#encodeForHTMLAttribute(hedef)#" class="list-group-item list-group-item-action d-flex gap-3 py-3">
                                        <div class="flex-shrink-0">
                                            <span class="rounded-circle p-2 d-inline-flex bg-#renk# bg-opacity-10">
                                                <i class="bi bi-#ikon# text-#renk#"></i>
                                            </span>
                                        </div>

                                        <div class="flex-grow-1">
                                            <p class="mb-0 #qBildirim.goruldu EQ 0 ? 'fw-bold':'text-muted'#">#encodeForHTML(qBildirim.mesaj)#</p>

                                            <small class="text-muted">
                                                <i class="bi bi-clock"></i>
                                                #dateFormat(qBildirim.tarih,'dd.mm.yyyy')#
                                                #timeFormat(qBildirim.tarih,'HH:mm')#
                                            </small>
                                        </div>

                                        <cfif len(trim(qBildirim.hedefURL))>
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