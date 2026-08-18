<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif NOT structKeyExists(url,"soruID") OR NOT isNumeric(url.soruID) OR val(url.soruID) LTE 0>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset soruID=val(url.soruID)>
<cfset kullaniciID=val(SESSION.kullaniciID)>

<cfset geri="/YKSSite/anaSayfa.cfm">

<cfif structKeyExists(url,"geri") AND left(url.geri,9) EQ "/YKSSite/">
    <cfset geri=url.geri>
</cfif>

<cfquery name="qSoru" datasource="DSN">
    SELECT id
    FROM Soru
    WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND aktiflik=1
</cfquery>

<cfif qSoru.recordCount EQ 0>
    <cflocation url="#geri#" addtoken="false">
</cfif>

<cftry>
    <cfquery name="qKontrol" datasource="DSN">
        SELECT id
        FROM Favori
        WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
        AND kullaniciID=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif qKontrol.recordCount GT 0>
        <cfquery datasource="DSN">
            DELETE FROM Favori
            WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
            AND kullaniciID=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <cfquery datasource="DSN">
            INSERT INTO Favori(kullaniciID,soruID,eklenmeTarihi)
            VALUES(
                <cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
                GETDATE()
            )
        </cfquery>
    </cfif>

    <cfcatch type="any">
        <cfset ai=createObject("component","YKSSite.views.includes.ai")>
        <cfset ai.hataYazma(
            sayfa="/YKSSite/views/soru/favoriToggle.cfm",
            islem="favoriToggle",
            mesaj=cfcatch.message,
            detay=cfcatch.detail
        )>
    </cfcatch>
</cftry>

<cflocation url="#geri#" addtoken="false">