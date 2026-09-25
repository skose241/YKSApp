<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">
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
<cfset request.okunmamisAdet=0>
<cfinclude template="/YKSSite/views/includes/baslik.cfm">
    <cfoutput>
        <div class="dar dar--genis">
            <section class="kart">
                <div class="kart__baslik">
                    <span>Bildirimler</span>
                    <span class="rozet"><span class="veri">#qBildirim.recordCount#</span></span>
                </div>
                <cfif qBildirim.recordCount EQ 0>
                    <div class="kart__govde">
                        <div class="bos-durum">
                            <span class="bos-durum__daire" aria-hidden="true"></span>
                            <h3>Bildiriminiz bulunmamaktadır</h3>
                            <p>Sorunuza gelen çözümleri veya aldığınız yanıtları,buradan görüntüleyebilirsiniz</p>
                        </div>
                    </div>
                <cfelse>
                    <div class="liste">
                        <cfloop query="qBildirim">
                            <cfset ikonSinif=qBildirim.islemTipi EQ "sistem" ? "sistem" : qBildirim.islemTipi EQ "yorum" ? "yorum" : "ai">
                            <cfset ikonAd=qBildirim.islemTipi EQ "sistem" ? "s-ayar" : qBildirim.islemTipi EQ "yorum" ? "s-yorum" : "s-robot">
                            <cfset hedef=len(trim(qBildirim.hedefURL)) ? qBildirim.hedefURL:"##">
                            <a class="liste-bag #qBildirim.goruldu EQ 0 ? 'liste-bag--yeni':''#" href="#encodeForHTMLAttribute(hedef)#">
                                <span class="liste-ikon liste-ikon--#ikonSinif#" aria-hidden="true"><svg class="simge simge--buyuk"><use href="###ikonAd#"></use></svg></span>
                                <span class="liste-bag__govde">
                                    <span class="liste-bag__metin">#encodeForHTML(qBildirim.mesaj)#</span>
                                    <span class="liste-bag__zaman">#dateFormat(qBildirim.tarih,'dd.mm.yyyy')# · #timeFormat(qBildirim.tarih,'HH:mm')#</span>
                                </span>
                                <cfif len(trim(qBildirim.hedefURL))>
                                    <span class="liste-bag__ok" aria-hidden="true"><svg class="simge"><use href="##s-ok-sag"></use></svg></span>
                                </cfif>
                            </a>
                        </cfloop>
                    </div>
                </cfif>
            </section>
        </div>
    </cfoutput>
<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">