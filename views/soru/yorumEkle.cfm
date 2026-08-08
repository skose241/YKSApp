<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif NOT structKeyExists(form,"cevapID") OR NOT structKeyExists(form,"metin")>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset cevapID=val(form.cevapID)>
<cfset soruID=val(form.soruID)>
<cfset metin=trim(form.metin)>
<cfset ustYorumID=structKeyExists(form,"ustYorumID") AND isNumeric(form.ustYorumID) ? val(form.ustYorumID):"">

<cfif metin NEQ "" AND cevapID GT 0>
    <cfquery datasource="DSN">
        INSERT INTO Yorum(cevapID,yazanID,metin,ustYorumID,aktiflik,eklenmeTarihi)
        VALUES(
            <cfqueryparam value="#cevapID#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#SESSION.kullaniciID#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#metin#" cfsqltype="cf_sql_varchar">,
            <cfif ustYorumID NEQ "">
                <cfqueryparam value="#ustYorumID#" cfsqltype="cf_sql_integer">,
            <cfelse>
                NULL,
            </cfif>
            1,
            GETDATE()
        )
    </cfquery>

    <cfquery datasource="DSN">
        INSERT INTO Puan(kullaniciID,islemTipi,puanDegeri,referansID,referansTip,eklenmeTarihi)
        VALUES(
            <cfqueryparam value="#SESSION.kullaniciID#" cfsqltype="cf_sql_integer">,
            'yorum_yapti',
            1,
            <cfqueryparam value="#cevapID#" cfsqltype="cf_sql_integer">,
            'cevap',
            GETDATE()
        )
    </cfquery>

    <cfquery datasource="DSN">
        UPDATE Kullanici 
        SET xp=xp+1
        WHERE id=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    </cfquery>
</cfif>

<cflocation url="/YKSSite/views/soru/soruDetay.cfm?id=#soruID#" addtoken="false">