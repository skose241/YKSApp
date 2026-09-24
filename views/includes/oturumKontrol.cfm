<cfif NOT structKeyExists(SESSION,"kullaniciID") OR NOT val(SESSION.kullaniciID)>
    <cflocation url="/YKSSite/views/kimlik/giris.cfm" addtoken="false">
</cfif>

<cfif NOT structKeyExists(SESSION,"csrf")>
    <cfset SESSION.csrf=hash(createUUID() & getTickCount(),"SHA-256")>
</cfif>

<cfquery name="qOturumKullanici" datasource="DSN">
    SELECT id,ad,rol,xp,aktiflik
    FROM Kullanici
    WHERE id=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif qOturumKullanici.recordCount EQ 0 OR qOturumKullanici.aktiflik EQ 0>
    <cfquery datasource="DSN">
        UPDATE Oturum
        SET aktiflik=0
        WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        AND aktiflik=1
    </cfquery>

    <cfcookie name="beniHatirla" value="" expires="now">
    <cfset structClear(SESSION)>

    <cflocation url="/YKSSite/views/kimlik/giris.cfm?durum=engelli" addtoken="false">
</cfif>

<cfset SESSION.kullaniciAd=qOturumKullanici.ad>
<cfset SESSION.rol=val(qOturumKullanici.rol)>
<cfset SESSION.xp=val(qOturumKullanici.xp)>