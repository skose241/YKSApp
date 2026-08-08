<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif NOT structKeyExists(url,"soruID") OR NOT isNumeric(url.soruID)>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset soruID=val(url.soruID)>
<cfset geri=structKeyExists(url,"geri") ? url.geri:"/YKSSite/anaSayfa.cfm">

<cfquery name="qKontrol" datasource="DSN">
    SELECT id
    FROM Favori
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND kullaniciID=<cfqueryparam value="#SESSION.kullaniciID#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif qKontrol.recordCount GT 0>
    <cfquery datasource="DSN">
        DELETE FROM Favori
        WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
        AND kullaniciID=<cfqueryparam value="#SESSION.kullaniciID#" cfsqltype="cf_sql_integer">
    </cfquery>
<cfelse>
    <cfquery datasource="DSN">
        INSERT INTO Favori(kullaniciID,soruID,eklenmeTarihi)
        VALUES(
            <cfqueryparam value="#SESSION.kullaniciID#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
            GETDATE()
        )
    </cfquery>
</cfif>

<cflocation url="#geri#" addtoken="false">