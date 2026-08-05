<cfif NOT isDefined("SESSION.kullaniciID")>
    <cflocation url="/views/kimlik/giris.cfm">
</cfif>

<cfquery name="qAktiflik" datasource="DSN">
    SELECT aktiflik
    FROM Kullanici 
    WHERE id=<cfqueryparam value="SESSION.kullaniciID" cfsqltype="cf_sql_integer">
</cfquery>

<cfif qAktiflik.recordCount EQ 0 OR qAktiflik.aktiflik EQ 0>
    <cfset structClear(SESSION)>
    
    <cfcookie name="beniHatirla" value="" expires="now">

    <cflocation url="/views/kimlik/giris.cfm" addtoken="false">
</cfif>