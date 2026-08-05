<cfif isDefined("SESSION.kullaniciID")>
    <cfquery datasource="DSN">
        UPDATE Oturum
        SET aktiflik=0
        WHERE kullaniciID=<cfqueryparam value="#SESSION.kullaniciID#" cfsqltype="cf_sql_integer">
        AND aktiflik=1
    </cfquery>

    <cfcookie name="beniHatirla" value="" expires="now">

    <cfset structClear(SESSION)>
</cfif>

<cflocation url="/YKSSite/views/kimlik/giris.cfm" addtoken="false">