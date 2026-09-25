<cfif structKeyExists(SESSION,"kullaniciID") AND val(SESSION.kullaniciID)>
    <cftry>
        <cfif structKeyExists(COOKIE,"beniHatirla") AND len(trim(COOKIE.beniHatirla))>
            <cfquery datasource="DSN">
                UPDATE Oturum
                SET aktiflik=0
                WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
                AND sessionToken=<cfqueryparam value="#COOKIE.beniHatirla#" cfsqltype="cf_sql_varchar">
                AND aktiflik=1
            </cfquery>
        </cfif>

        <cfcatch type="any"></cfcatch>
    </cftry>

    <cfcookie name="beniHatirla" value="" expires="now" httponly="true" secure="true">
    <cfset structClear(SESSION)>
</cfif>

<cflocation url="/YKSSite/views/kimlik/giris.cfm" addtoken="false">