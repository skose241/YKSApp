<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfparam name="url.alanID" default="0">
<cfparam name="url.dersID" default="0">
<cfparam name="url.siralama" default="yeni">
<cfparam name="url.sayfa" default="1">

<cfset alanID=val(url.alanID)>
<cfset dersID=val(url.dersID)>
<cfset siralama=listFind("yeni,populer,favori",trim(url.siralama)) ? trim(url.siralama):"yeni">
<cfset sayfa=val(url.sayfa) LT 1 ? 1:val(url.sayfa)>

<cfset sayfaBasi=20>

<cfquery name="qAlan" datasource="DSN">
    SELECT id,ad
    FROM Alan
    ORDER BY id
</cfquery>

<cfquery name="qDers" datasource="DSN">
    SELECT id,ad,alanID
    FROM Ders
    ORDER BY ad
</cfquery>

<cfquery name="qToplamSoru" datasource="DSN">
    SELECT COUNT(*) AS toplam
    FROM Soru s
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE s.aktiflik=1
    AND s.sistemSoru=0
    <cfif alanID GT 0>
        AND a.id=<cfqueryparam value="#alanID#" cfsqltype="cf_sql_integer">
    </cfif>
    <cfif dersID GT 0>
        AND d.id=<cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">
    </cfif>
</cfquery>

<cfset toplamSayfa=ceiling(qToplamSoru.toplam/sayfaBasi)>

<cfif toplamSayfa GT 0 AND sayfa GT toplamSayfa>
    <cfset sayfa=toplamSayfa>
</cfif>

<cfset offset=(sayfa-1)*sayfaBasi>

<cfquery name="qSorular" datasource="DSN">
    SELECT s.id,s.soruResmi,s.soruMetni,s.goruntulenmeSayisi,s.eklenmeTarihi,
        d.ad AS dersAd,a.ad AS alanAd,k.ad AS soranAd,
        (SELECT COUNT(*) FROM Favori f WHERE f.soruID=s.id) AS favoriSayisi,
        (SELECT COUNT(*) FROM Cevap c WHERE c.soruID=s.id AND c.aktiflik=1) AS cevapSayisi
    FROM Soru s
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    INNER JOIN Kullanici k ON k.id=s.soranID
    WHERE s.aktiflik=1
    AND s.sistemSoru=0
    <cfif alanID GT 0>
        AND a.id=<cfqueryparam value="#alanID#" cfsqltype="cf_sql_integer">
    </cfif>
    <cfif dersID GT 0>
        AND d.id=<cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">
    </cfif>
    <cfif siralama EQ "populer">
        ORDER BY s.goruntulenmeSayisi DESC,s.id DESC
    <cfelseif siralama EQ "favori">
        ORDER BY favoriSayisi DESC,s.id DESC
    <cfelse>
        ORDER BY s.eklenmeTarihi DESC,s.id DESC
    </cfif>
    OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer"> ROWS
    FETCH NEXT <cfqueryparam value="#sayfaBasi#" cfsqltype="cf_sql_integer"> ROWS ONLY
</cfquery>

<cfquery name="qGunlukSoru" datasource="DSN">
    SELECT TOP 5
        gs.id,s.id AS soruID,s.soruResmi,s.soruMetni,s.sistemSoru,
        d.ad AS dersAd,a.ad AS alanAd
    FROM GunlukSoru gs
    INNER JOIN Soru s ON s.id=gs.soruID
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE gs.tarih=CAST(GETDATE() AS DATE)
    AND s.aktiflik=1
    ORDER BY gs.id DESC
</cfquery>

<cfquery name="qYorumlar" datasource="DSN">
    SELECT TOP 5 y.metin,y.eklenmeTarihi,k.ad AS yazar,c.soruID
    FROM Yorum y
    INNER JOIN Cevap c ON c.id=y.cevapID
    INNER JOIN Soru s ON s.id=c.soruID
    INNER JOIN Kullanici k ON k.id=y.yazanID
    WHERE y.aktiflik=1
    AND c.aktiflik=1
    AND s.aktiflik=1
    ORDER BY y.eklenmeTarihi DESC
</cfquery>

<cfquery name="qFavoriler" datasource="DSN">
    SELECT soruID
    FROM Favori
    WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
</cfquery>

<cfset favoriListesi=valueList(qFavoriler.soruID)>
<cfset geriURL=urlEncodedFormat("/YKSSite/anaSayfa.cfm?alanID=" & alanID & "&dersID=" & dersID & "&siralama=" & siralama & "&sayfa=" & sayfa)>
<cfset filtreURL="?alanID=" & alanID & "&dersID=" & dersID & "&siralama=" & siralama>

<script>
    const dersListesi={
        <cfoutput query="qDers">"#qDers.id#":{ad:"#jsStringFormat(qDers.ad)#",alanID:"#qDers.alanID#"}<cfif qDers.currentRow NEQ qDers.recordCount>,</cfif></cfoutput>
    };

    function dersDoldur(alanID,seciliDers){
        const dersSec=document.getElementById('dersSec');
        dersSec.innerHTML='';

        const ilk=document.createElement('option');
        ilk.value='0';
        ilk.textContent='Tüm Dersler';
        dersSec.appendChild(ilk);

        Object.entries(dersListesi).forEach(([id,ders])=>{
            if(alanID=='0' || ders.alanID==alanID){
                const opt=document.createElement('option');
                opt.value=id;
                opt.textContent=ders.ad;

                if(id==seciliDers) opt.selected=true;

                dersSec.appendChild(opt);
            }
        });
    }

    document.addEventListener('DOMContentLoaded',function(){
        const alanSec=document.getElementById('alanSec');
        dersDoldur(alanSec.value,'<cfoutput>#dersID#</cfoutput>');

        alanSec.addEventListener('change',function(){
            dersDoldur(this.value,'0');
        });
    });
</script>

<cfoutput>
    <div class="container-fluid mt-3">
        <div class="row">
            <div class="col-md-9">
                <div class="card mb-3">
                    <div class="card-body py-2">
                        <form method="GET" class="row g-2 align-items-center">
                            <div class="col-md-3">
                                <select name="alanID" id="alanSec" class="form-select form-select-sm">
                                    <option value="0">Tüm Alanlar</option>
                                    <cfloop query="qAlan">
                                        <option value="#qAlan.id#" #alanID EQ qAlan.id ? 'selected':''#>#encodeForHTML(qAlan.ad)#</option>
                                    </cfloop>
                                </select>
                            </div>

                            <div class="col-md-3">
                                <select name="dersID" id="dersSec" class="form-select form-select-sm">
                                    <option value="0">Tüm Dersler</option>
                                </select>
                            </div>

                            <div class="col-md-3">
                                <select name="siralama" class="form-select form-select-sm">
                                    <option value="yeni" #siralama EQ 'yeni' ? 'selected':''#>En Yeni</option>
                                    <option value="populer" #siralama EQ 'populer' ? 'selected':''#>En Popüler</option>
                                    <option value="favori" #siralama EQ 'favori' ? 'selected':''#>En Çok Favoriye Alınan</option>
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
                            <cfset favoriMi=listFind(favoriListesi,qSorular.id) GT 0>

                            <div class="col">
                                <div class="card h-100 shadow-sm">
                                    <a href="/YKSSite/views/soru/soruDetay.cfm?id=#qSorular.id#">
                                        <cfif len(trim(qSorular.soruResmi))>
                                            <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qSorular.soruResmi)#"
                                                class="card-img-top" style="height:160px; object-fit:cover;" alt="Soru">
                                        <cfelse>
                                            <div class="card-img-top bg-light p-2 small text-dark" style="height:160px; overflow:hidden;">
                                                #encodeForHTML(left(qSorular.soruMetni,180))#
                                            </div>
                                        </cfif>
                                    </a>

                                    <div class="card-body p-2">
                                        <div class="mb-1">
                                            <span class="badge bg-dark">#encodeForHTML(qSorular.dersAd)#</span>
                                            <span class="badge bg-secondary">#encodeForHTML(qSorular.alanAd)#</span>
                                        </div>

                                        <div class="d-flex align-items-center gap-1 mb-1">
                                            <img src="#application.avatarURL##urlEncodedFormat(qSorular.soranAd)#"
                                                class="rounded-circle" width="20" height="20" alt="">
                                            <small class="text-muted">#encodeForHTML(qSorular.soranAd)#</small>
                                        </div>

                                        <div class="d-flex justify-content-between align-items-center">
                                            <small class="text-muted">
                                                <i class="bi bi-eye"></i>#qSorular.goruntulenmeSayisi#
                                                <i class="bi bi-chat ms-2"></i>#qSorular.cevapSayisi#
                                            </small>

                                            <a href="/YKSSite/views/soru/favoriToggle.cfm?soruID=#qSorular.id#&geri=#geriURL#" class="btn btn-sm #favoriMi ? 'btn-danger':'btn-outline-danger'#">
                                                <i class="bi bi-heart#favoriMi ? '-fill':''#"></i>#qSorular.favoriSayisi#
                                            </a>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </cfloop>
                    </div>

                    <cfif toplamSayfa GT 1>
                        <cfset ilkSayfa=max(1,sayfa-3)>
                        <cfset sonSayfa=min(toplamSayfa,sayfa+3)>

                        <nav class="mt-4">
                            <ul class="pagination justify-content-center flex-wrap">
                                <li class="page-item #sayfa EQ 1 ? 'disabled':''#">
                                    <a class="page-link" href="#filtreURL#&sayfa=#sayfa-1#">
                                        <i class="bi bi-chevron-left"></i>
                                    </a>
                                </li>

                                <cfif ilkSayfa GT 1>
                                    <li class="page-item">
                                        <a class="page-link" href="#filtreURL#&sayfa=1">1</a>
                                    </li>

                                    <cfif ilkSayfa GT 2>
                                        <li class="page-item disabled"><span class="page-link">...</span></li>
                                    </cfif>
                                </cfif>

                                <cfloop from="#ilkSayfa#" to="#sonSayfa#" index="i">
                                    <li class="page-item #sayfa EQ i ? 'active':''#">
                                        <a class="page-link" href="#filtreURL#&sayfa=#i#">#i#</a>
                                    </li>
                                </cfloop>

                                <cfif sonSayfa LT toplamSayfa>
                                    <cfif sonSayfa LT toplamSayfa-1>
                                        <li class="page-item disabled"><span class="page-link">...</span></li>
                                    </cfif>

                                    <li class="page-item">
                                        <a class="page-link" href="#filtreURL#&sayfa=#toplamSayfa#">#toplamSayfa#</a>
                                    </li>
                                </cfif>

                                <li class="page-item #sayfa EQ toplamSayfa ? 'disabled':''#">
                                    <a class="page-link" href="#filtreURL#&sayfa=#sayfa+1#">
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
                                    <span class="badge bg-secondary mb-1">#encodeForHTML(qGunlukSoru.dersAd)#</span>

                                    <cfif qGunlukSoru.sistemSoru EQ 1>
                                        <p class="small mb-1">#encodeForHTML(left(qGunlukSoru.soruMetni,80))#...</p>
                                    <cfelseif len(trim(qGunlukSoru.soruResmi))>
                                        <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qGunlukSoru.soruResmi)#"
                                            class="img-fluid rounded mb-1" alt="Soru">
                                    </cfif>

                                    <div class="d-grid">
                                        <a href="/YKSSite/views/soru/soruDetay.cfm?id=#qGunlukSoru.soruID#" class="btn btn-dark btn-sm">
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
                        <cfif qYorumlar.recordCount GT 0>
                            <cfloop query="qYorumlar">
                                <a href="/YKSSite/views/soru/soruDetay.cfm?id=#qYorumlar.soruID#" class="text-decoration-none text-dark">
                                    <div class="border-bottom pb-2 mb-2">
                                        <div class="d-flex align-items-center gap-1 mb-1">
                                            <img src="#application.avatarURL##urlEncodedFormat(qYorumlar.yazar)#"
                                                class="rounded-circle" width="20" height="20" alt="">
                                            <small class="fw-bold">#encodeForHTML(qYorumlar.yazar)#</small>
                                        </div>

                                        <small class="text-muted">#encodeForHTML(left(qYorumlar.metin,80))##len(qYorumlar.metin) GT 80 ? '...':''#</small>
                                    </div>
                                </a>
                            </cfloop>
                        <cfelse>
                            <p class="text-muted small text-center mb-0">Henüz yorum yok.</p>
                        </cfif>
                    </div>
                </div>
            </div>
        </div>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">