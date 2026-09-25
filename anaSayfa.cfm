<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">
<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfparam name="url.alanID" default="0">
<cfparam name="url.dersID" default="0">
<cfparam name="url.siralama" default="yeni">
<cfparam name="url.sayfa" default="1">
<cfparam name="url.kaynak" default="kullanici">
<cfset alanID=val(url.alanID)>
<cfset dersID=val(url.dersID)>
<cfset siralama=listFind("yeni,populer,favori",trim(url.siralama)) ? trim(url.siralama):"yeni">
<cfset sayfa=val(url.sayfa) LT 1 ? 1:val(url.sayfa)>
<cfset kaynak=listFind("kullanici,yapayzeka,tumu",trim(url.kaynak)) ? trim(url.kaynak):"kullanici">
<cfset sayfaBasi=20>
<cfset qAlan=duplicate(application.qAlan)>
<cfset qDers=duplicate(application.qDers)>

<cfquery name="qToplamSoru" datasource="DSN">
    SELECT COUNT(*) AS toplam
    FROM Soru s
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE s.aktiflik=1
    <cfif kaynak EQ "yapayzeka">
        AND s.sistemSoru=1
    <cfelseif kaynak EQ "kullanici">
        AND s.sistemSoru=0
    </cfif>
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
    d.ad AS dersAd,a.ad AS alanAd,k.ad AS soranAd,k.id AS soranID,
    (SELECT COUNT(*) FROM Favori f WHERE f.soruID=s.id) AS favoriSayisi,
    (SELECT COUNT(*) FROM Cevap c WHERE c.soruID=s.id AND c.aktiflik=1) AS cevapSayisi,
    CASE WHEN EXISTS(
    SELECT 1 FROM Favori fk
    WHERE fk.soruID=s.id
    AND fk.kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    ) THEN 1 ELSE 0 END AS favoriMi
    FROM Soru s
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    INNER JOIN Kullanici k ON k.id=s.soranID
    WHERE s.aktiflik=1
    <cfif kaynak EQ "yapayzeka">
        AND s.sistemSoru=1
    <cfelseif kaynak EQ "kullanici">
        AND s.sistemSoru=0
    </cfif>
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
    AND k.sistemHesap=0
    ORDER BY y.eklenmeTarihi DESC
</cfquery>

<cfset geriURL="/YKSSite/anaSayfa.cfm?alanID=" & alanID & "&dersID=" & dersID & "&kaynak=" & kaynak & "&siralama=" & siralama & "&sayfa=" & sayfa>
<cfset filtreURL="?alanID=" & alanID & "&dersID=" & dersID & "&kaynak=" & kaynak & "&siralama=" & siralama>
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
        <div class="sutunlar">
            <div class="yigin">
                <section class="kart filtre">
                    <div class="kart__govde">
                        <form class="filtre__form" method="GET">
                            <select class="secim" name="alanID" id="alanSec">
                                <option value="0">Tüm Alanlar</option>
                                <cfloop query="qAlan">
                                    <option value="#qAlan.id#" #alanID EQ qAlan.id ? "selected":""#>#encodeForHTML(qAlan.ad)#</option>
                                </cfloop>
                            </select>
                            <select class="secim" name="dersID" id="dersSec">
                                <option value="0">Tüm Dersler</option>
                            </select>
                            <select class="secim" name="siralama">
                                <option value="yeni" #siralama EQ "yeni" ? "selected":""#>En Yeni</option>
                                <option value="populer" #siralama EQ "populer" ? "selected":""#>En Popüler</option>
                                <option value="favori" #siralama EQ "favori" ? "selected":""#>En Çok Beğenilen</option>
                            </select>
                            <select class="secim" name="kaynak">
                                <option value="kullanici" #kaynak EQ "kullanici" ? "selected":""#>Kullanıcı Soruları</option>
                                <option value="yapayzeka" #kaynak EQ "yapayzeka" ? "selected":""#>Yapay Zeka Soruları</option>
                                <option value="tumu" #kaynak EQ "tumu" ? "selected":""#>Tümü</option>
                            </select>
                            <button class="dugme dugme--ana" type="submit">Filtrele</button>
                        </form>
                    </div>
                </section>
                
                <cfif qSorular.recordCount EQ 0>
                    <div class="bos-durum">
                        <span class="bos-durum__daire" aria-hidden="true"></span>
                        <h3>Soru Bulunamadı</h3>
                        <p>Seçtiğiniz filtrelere uygun soru bulunmamaktadır.Filtreyi değiştirin veya ilk soruyu siz sorun</p>
                        <a class="dugme dugme--ana" href="/YKSSite/views/soru/soruEkle.cfm">Soru Ekle</a>
                    </div>
                <cfelse>
                    <div class="soru-izgara">
                        <cfloop query="qSorular">
                            <cfset favoriMi=qSorular.favoriMi EQ 1>
                            <article class="soru-kutu">
                                <a class="soru-kutu__ust" href="/YKSSite/views/soru/soruDetay.cfm?id=#qSorular.id#">
                                    <cfif len(trim(qSorular.soruResmi))>
                                        <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qSorular.soruResmi)#"
                                            class="soru-kutu__gorsel" alt="Soru Görseli">
                                    <cfelse>
                                        <div class="soru-kutu__onizleme">#encodeForHTML(left(qSorular.soruMetni,180))#</div>
                                    </cfif>
                                </a>
                                <div class="soru-kutu__govde">
                                    <div class="soru-kutu__etiket">
                                        <span class="rozet rozet--sinav">#encodeForHTML(qSorular.alanAd)#</span>
                                        <span class="rozet rozet--ders">#encodeForHTML(qSorular.dersAd)#</span>
                                    </div>
                                    <div class="soru-kutu__kisi">
                                        <span class="mini-avatar">#encodeForHTML(ucase(left(qSorular.soranAd,1)))#</span>
                                    </div>
                                    <div class="soru-kutu__alt">
                                        <div class="soru-kutu__sayac">
                                            <span><svg class="simge"><use href="##s-goz"></use></svg> #qSorular.goruntulenmeSayisi#</span>
                                            <span><svg class="simge"><use href="##s-sohbet"></use></svg> #qSorular.cevapSayisi#</span>
                                        </div>
                                        <form method="POST" action="/YKSSite/views/soru/favoriToggle.cfm" class="favori-form">
                                            <cfinclude template="/YKSSite/views/includes/csrfAlan.cfm">
                                            <input type="hidden" name="soruID" value="#qSorular.id#">
                                            <input type="hidden" name="geri" value="#encodeForHTMLAttribute(geriURL)#">
                                            <button class="favori#favoriMi ? ' favori--dolu':''#" type="submit">
                                                <svg class="simge"><use href="###favoriMi ? 's-kalp-dolu':'s-kalp'#"></use></svg>#qSorular.favoriSayisi#
                                            </button>
                                        </form>
                                    </div>
                                </div>
                            </article>
                        </cfloop>
                    </div>

                    <cfif toplamSayfa GT 1>
                        <cfset ilkSayfa=max(1,sayfa-3)>
                        <cfset sonSayfa=min(toplamSayfa,sayfa+3)>
                        <nav class="sayfalama ust-bosluk" aria-label="Sayfalar">
                            <cfif sayfa GT 1>
                                <a href="#filtreURL#&sayfa=#sayfa-1#" aria-label="Önceki Sayfa">‹</a>
                            <cfelse>
                                <span aria-hidden="true">‹</span>
                            </cfif>
                            <cfif ilkSayfa GT 1>
                                <a href="#filtreURL#&sayfa=1">1</a>
                                <cfif ilkSayfa GT 2>
                                    <span aria-hidden="true">…</span>
                                </cfif>
                            </cfif>
                            <cfloop from="#ilkSayfa#" to="#sonSayfa#" index="i">
                                <cfset aktifMi=sayfa EQ i ? ' aria-current="page"':''>
                                <a href="#filtreURL#&sayfa=#i#"#aktifMi#>#i#</a>
                            </cfloop>
                            <cfif sonSayfa LT toplamSayfa>
                                <cfif sonSayfa LT toplamSayfa-1>
                                    <span aria-hidden="true">…</span>
                                </cfif>
                                <a href="#filtreURL#&sayfa=#toplamSayfa#">#toplamSayfa#</a>
                            </cfif>
                            <cfif sayfa LT toplamSayfa>
                                <a href="#filtreURL#&sayfa=#sayfa+1#" aria-label="Sonraki Sayfa">›</a>
                            <cfelse>
                                <span aria-hidden="true">›</span>
                            </cfif>
                        </nav>
                    </cfif>
                </cfif>
            </div>

            <div class="yigin">
                <section class="kart">
                    <div class="kart__baslik">Günün AI Soruları:</div>
                    <div class="kart__govde">
                        <cfif qGunlukSoru.recordCount GT 0>
                            <div class="yigin">
                                <cfloop query="qGunlukSoru">
                                    <div>
                                        <span class="rozet rozet--ders">#encodeForHTML(qGunlukSoru.dersAd)#</span>
                                        <cfif qGunlukSoru.sistemSoru EQ 1>
                                            <p class="sessiz ust-bosluk">#encodeForHTML(left(qGunlukSoru.soruMetni,90))#…</p>
                                        <cfelseif len(trim(qGunlukSoru.soruResmi))>
                                            <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qGunlukSoru.soruResmi)#"
                                                class="soru-gorsel ust-bosluk" alt="Soru Resmi">
                                        </cfif>
                                        <a class="dugme dugme--ana dugme--tam ust-bosluk" href="/YKSSite/views/soru/soruDetay.cfm?id=#qGunlukSoru.soruID#">Cevapla</a>
                                    </div>
                                </cfloop>
                            </div>
                        <cfelse>
                            <p class="sessiz">Bugün için soru eklenmemiştir</p>
                        </cfif>
                    </div>
                </section>

                <section class="kart">
                    <div class="kart__baslik">Güncel Tartışma:</div>
                    <div class="kart__govde">
                        <cfif qYorumlar.recordCount GT 0>
                            <cfloop query="qYorumlar">
                                <div class="yorum">
                                    <span class="avatar">#encodeForHTML(ucase(left(qYorumlar.yazar,2)))#</span>
                                    <div style="flex:1; min-width:0">
                                        <div class="yorum__ust">
                                            <span class="yorum__ad">#encodeForHTML(qYorumlar.yazar)#</span>
                                            <span class="yorum__zaman">#dateFormat(qYorumlar.eklenmeTarihi,'dd.mm')#</span>
                                        </div>
                                        <a class="sessiz" href="/YKSSite/views/soru/soruDetay.cfm?id=#qYorumlar.soruID#">#encodeForHTML(left(qYorumlar.metin,80))##len(qYorumlar.metin) GT 80 ? "…":""#</a>
                                    </div>
                                </div>
                            </cfloop>
                        <cfelse>
                            <p class="sessiz">Henüz Yorum Yok</p>
                        </cfif>
                    </div>
                </section>
            </div>
        </div>
    </cfoutput>
<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">