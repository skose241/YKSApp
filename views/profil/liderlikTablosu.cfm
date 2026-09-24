<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">
<cfinclude template="/YKSSite/views/includes/baslik.cfm">
 
<cfquery name="qLiderlik" datasource="DSN">
	SELECT TOP 50
	id,ad,xp,rol,kayitTarihi,
	RANK() OVER (ORDER BY xp DESC) AS siralama
	FROM Kullanici
	WHERE aktiflik=1
	AND sistemHesap=0
	ORDER BY xp DESC,kayitTarihi ASC
</cfquery>
 
<cfquery name="qSira" datasource="DSN">
	SELECT siralama
	FROM (
		SELECT id,
		RANK() OVER (ORDER BY xp DESC) AS siralama
		FROM Kullanici
		WHERE aktiflik=1
		AND sistemHesap=0
	) AS t
	WHERE t.id=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
</cfquery>
 
<cfoutput>
    <section class="kart">
        <div class="kart__baslik">
            <span>Liderlik Tablosu</span>
            <span class="rozet rozet--xp">Sıranız:<span class="veri">#qSira.recordCount ? qSira.siralama:"-"#</span></span>
        </div>
    
        <div class="kart__govde">
            <ol class="siralama">
                <cfloop query="qLiderlik">
                    <cfset benMi=qLiderlik.id EQ val(SESSION.kullaniciID) ? ' aria-current="true"':''>
                    <li#benMi#>
                        <span class="sira-no">#numberFormat(qLiderlik.siralama,'00')#</span>
                        <span class="avatar">#uCase(left(qLiderlik.ad,2))#</span>
                        
                        <a class="siralama__ad" href="/YKSSite/views/profil/profilim.cfm?id=#qLiderlik.id#">#encodeForHTML(qLiderlik.ad)#</a>
                        <cfif qLiderlik.rol GTE 2>
                            <span class="rozet">#qLiderlik.rol EQ 3 ? "Admin":"Moderatör"#</span>
                        </cfif>
                        <span class="siralama__xp">#numberFormat(qLiderlik.xp,',')#</span>
                    </li>
                </cfloop>
            </ol>
        </div>
    
        <div class="kart__ayrac">
            <p class="sessiz">İlk 50 kullanıcı gösterilmektedir.</p>
        </div>
    </section>
</cfoutput>
 
<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">