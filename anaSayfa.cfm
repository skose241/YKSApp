<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfparam name="url.alanID" default="0">
<cfparam name="url.dersID" default="0">
<cfparam name="url.siralama" default="yeni">
<cfparam name="url.sayfa" default="1">

<cfset sayfaBasi=20>
<cfset offset=(url.sayfa-1)*sayfaBasi>

<cfquery name="qAlan" datasource="DSN">
    SELECT id,ad
    FROM Alan 
    WHERE 1=1
    <cfif url.alanID GT 0>
        AND id=<cfqueryparam value="#url.alanID#" cfsqltype="cf_sql_integer">
    </cfif>
    ORDER BY ad 
</cfquery>

<cfquery name="qSorular" datasource="DSN">
    SELECT s.id,s.soruResmi,s.goruntulenmeSayisi,s.eklenmeTarihi,
        d.ad AS dersAd,a.ad AS alanAd,k.ad AS soranAd,
        (SELECT COUNT(*) FROM Favori f WHERE f.soruID=s.id) AS favoriSayisi
    FROM Soru s
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    INNER JOIN Kullanici k ON k.id=s.soranID
    WHERE s.aktiflik=1
    AND s.sistemSoru=0
    <cfif url.alanID GT 0>
        AND a.id=<cfqueryparam value="#url.alanID#" cfsqltype="cf_sql_integer">
    </cfif>
    <cfif url.dersID GT 0>
        AND d.id=<cfqueryparam value="#url.dersID#" cfsqltype="cf_sql_integer">
    </cfif>
    <cfif url.siralama EQ "populer">
        ORDER BY s.goruntulenmeSayisi DESC 
    <cfelse>
        ORDER BY s.eklenmeTarihi DESC
    </cfif>
    OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer"> ROWS 
    FETCH NEXT <cfqueryparam value="#sayfaBasi#" cfsqltype="cf_sql_integer"> ROWS ONLY
</cfquery>

<cfquery name="qToplamSoru" datasource="DSN">
    SELECT COUNT(*) AS toplam 
    FROM Soru s 
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE s.aktiflik=1
    AND s.sistemSoru=0
    <cfif url.alanID GT 0>
        AND a.id=<cfqueryparam value="#url.alanID#" cfsqltype="cf_sql_integer">
    </cfif>
    <cfif url.dersID GT 0>
        AND d.id=<cfqueryparam value="#url.dersID#" cfsqltype="cf_sql_integer">
    </cfif>
</cfquery>

<cfset toplamSayfa=ceiling(qToplamSoru.toplam/sayfaBasi)>

<cfquery name="qGunlukSoru" datasource="DSN">
    SELECT TOP 5 
        gs.id,s.id AS soruID,s.soruResmi,s.soruMetni,s.sistemSoru,
        s.sikA,s.sikB,s.sikC,s.sikD,s.sikE,
        d.ad AS dersAd,a.ad AS alanAd
    FROM GunlukSoru gs 
    INNER JOIN Soru s ON s.id=gs.soruID
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE gs.tarih=CAST(GETDATE() AS DATE)
    ORDER BY gs.id DESC
</cfquery>

<cfquery name="qEnPopuler" datasource="DSN">
    SELECT TOP 1 id 
    FROM Soru 
    WHERE aktiflik=1
    AND sistemSoru=0
    ORDER BY goruntulenmeSayisi DESC 
</cfquery>

<cfif qEnPopuler.recordCount GT 0>
    <cfquery name="qYorumlar" datasource="DSN">
        SELECT TOP 5 y.metin,y.eklenmeTarihi,k.ad AS yazar
        FROM Yorum y
        INNER JOIN Cevap c ON c.id=y.cevapID
        INNER JOIN Kullanici k ON k.id=y.yazanID
        WHERE c.soruID=<cfqueryparam value="#qEnPopuler.id#" cfsqltype="cf_sql_integer">
        AND y.aktiflik=1
        AND y.ustYorumID IS NULL
        ORDER BY y.eklenmeTarihi DESC
    </cfquery>
</cfif>

<cfquery name="qFavoriler" datasource="DSN">
    SELECT soruID 
    FROM Favori 
    WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
</cfquery>

<cfset favoriListesi=valueList(qFavoriler.soruID)>

<cfoutput>
    <div class="container-fluid mt-3">
        <div class="row">
            <div class="col-md-9">
                <div class="card mb-3">
                    <div class="card-body py-2">
                        <form method="GET" class="row g-2 align-items-center">
                            <div class="col-md-3">
                                <select name="alanID" class="form-select form-select-sm" onchange="this.form.submit()">
                                    <option value="0">Tüm Alanlar</option>
                                    <cfloop query="qAlan">
                                        <option value="#id#" #url.alanID EQ id ? 'selected':''#>#ad#</option>
                                    </cfloop>
                                </select>
                            </div>

                            <div class="col-md-3">
                                <select name="siralama" class="form-select form-select-sm">
                                    <option value="yeni" #url.siralama EQ 'yeni' ? 'selected':''#>En Popüler</option>
                                </select>
                            </div>

                            <div class="col-md-3">
                                <button type="submit" class="btn btn-dark btn-sm w-100">
                                    <i class="bi bi-funnel"></i>Filtrele
                                </button>
                            </div>
                        </form> 
                    </div>
                </div>

                <cfif qSorular.recordCount EQ 0>
                    <div class="alert alert-info">
                        <i class="bi bi-info-circle"></i>Henüz soru bulunmamaktadır.
                    </div>
                <cfelse>
                    <div class="row row-cols-1 row-cols-md-4 g-3">
                        <cfloop query="qSorular">
                            <cfset favoriMi=listFind(favoriListesi,id) GT 0>
                            <div class="col">
                                <div class="card h-100 shadow-sm">
                                    <a href="/YKSSite/views/soru/soruDetay.cfm?id=#id#">
                                        <img src="/YKSSite/assets/images/sorular/#soruResmi#"
                                            class="card-img-top" style="height:160px; object-fit:cover;" alt="Soru">
                                    </a>

                                    <div class="card-body p-2">
                                        <div class="mb-1">
                                            <span class="badge bg-dark">#dersAd#</span>
                                            <span class="badge bg-secondary">#alanAd#</span>
                                        </div>

                                        <div class="d-flex align-items-center gap-1 mb-1">
                                            <img src="#application.avatarURL##soranAd#"
                                                width="20" height="20" class="rounded-circle">
                                                <small class="text-muted">#soranAd#</small>
                                        </div>

                                        <div class="d-flex justify-content-between align-items-center">
                                            <small class="text-muted">
                                                <i class="bi bi-eye"></i>#goruntulenmeSayisi#
                                            </small>

                                            <a href="/YKSSite/views/soru/favoriToggle.cfm?soruID=#id#&geri=#urlEncodedFormat(cgi.SCRIPT_NAME & '?' & cgi.QUERY_STRING)#" class="btn btn-sm #favoriMi ? 'btn-danger':'btn-outline-danger'#">
                                                <i class="bi bi-heart#favoriMi ? '-fill':''#"></i>#favoriSayisi#
                                            </a>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </cfloop>
                    </div>

                    <cfif toplamSayfa GT 1>
                        <nav class="mt-4">
                            <ul class="pagination justify-content-center">
                                <li class="page-item #url.sayfa EQ 1 ? 'disabled':''#">
                                    <a class="page-link" href="?alanID=#url.alanID#&dersID=#url.dersID#&siralama=#url.siralama#&sayfa=#url.sayfa-1#">
                                        <i class="bi bi-chevron-left"></i>
                                    </a>
                                </li>

                                <cfloop from="1" to="#toplamSayfa#" index="i">
                                    <li class="page-item #url.sayfa EQ i ? 'active':''#">
                                        <a class="page-link" href="?alanID=#url.alanID#&dersID=#url.dersID#&siralama=#url.siralama#&sayfa=#i#">#i#</a>
                                    </li>
                                </cfloop>

                                <li class="page-item #url.sayfa EQ toplamSayfa ? 'disabled':''#">
                                    <a class="page-link" href="?alanID=#url.alanID#&dersID=#url.dersID#&siralama=#url.siralama#&sayfa=#url.sayfa+1#">
                                        <i class="bi bi-chevron-right"></i>
                                    </a>
                                </li>
                            </ul>
                        </nav>
                    </cfif>
                </cfif>
            </div>

            <div class="col-md-3">
                <div class="card mb-3">
                    <div class="card-header bg-dark text-white">
                        <i class="bi bi-star"></i>Günün Soruları
                    </div>

                    <div class="card-body p-2">
                        <cfif qGunlukSoru.recordCount GT 0>
                            <cfloop query="qGunlukSoru">
                                <div class="border-bottom pb-2 mb-2">
                                    <span class="badge bg-secondary mb-1">#dersAd#</span>

                                    <cfif sistemSoru EQ 1>
                                        <p class="small mb-1">#left(soruMetni,80)#...</p>
                                    <cfelse>
                                        <img src="/YKSSite/assets/images/sorular/#soruResmi#"
                                            class="aimg-fluid rounded mb-1">
                                    </cfif>

                                    <div class="d-grid">
                                        <a href="/YKSSite/views/soru/soruDetay.cfm?id=#soruID#" class="btn btn-dark btn-sm">
                                            <i class="bi bi-pencil"></i>Cevapla
                                        </a>
                                    </div>
                                </div>
                            </cfloop>
                        <cfelse>
                            <p class="text-muted small text-center mb-0">Bugün için soru eklenmemiş.</p> 
                        </cfif>
                    </div>
                </div>

                <div class="card">
                    <div class="card-header bg-dark text-white">
                        <i class="bi bi-chat-dots"></i>Güncel Tartışma
                    </div>

                    <div class="card-body p-2">
                        <cfif isDefined("qYorumlar") AND qYorumlar.recordCount GT 0>
                            <cfloop query="qYorumlar">
                                <div class="border-bottom pb-2 mb-2">
                                    <div class="d-flex align-items-center gap-1 mb-1">
                                        <img src="#application.avatarURL##yazar#"
                                            width="20" height="20" class="rounded-circle">
                                        <small class="fw-bold">#yazar#</small>
                                    </div>

                                    <small class="text-muted">#left(metin,80)##len(metin) GT 80 ? '...':''#</small>
                                </div>
                            </cfloop>
                        <cfelse>
                            <p class="text-muted small text-center mb-0">
                                Henüz yorum yok.
                            </p>
                        </cfif>
                    </div>
                </div>
            </div>
        </div>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">