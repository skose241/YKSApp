<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif NOT structKeyExists(url,"hedefID") OR NOT isNumeric(url.hedefID)>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset hedefID=val(url.hedefID)>
<cfset hedefTip=structKeyExists(url,"hedefTip") ? url.hedefTip:"cevap">
<cfset geri=structKeyExists(url,"geri") ? url.geri:"/YKSSite/anaSayfa.cfm">

<cfquery name="qKontrol" datasource="DSN">
    SELECT id 
    FROM Begeni
    WHERE hedefID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
    AND hedefTip=<cfqueryparam value="#hedefTip#" cfsqltype="cf_sql_varchar">
    AND kullaniciID=<cfqueryparam value="#SESSION.kullaniciID#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif qKontrol.recordCount GT 0>
    <cfquery datasource="DSN">
        DELETE FROM Begeni
        WHERE hedefID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
        AND hedefTip=<cfqueryparam value="#hedefTip#" cfsqltype="cf_sql_varchar">
        AND kullaniciID=<cfqueryparam value="#SESSION.kullaniciID#" cfsqltype="cf_sql_integer">
    </cfquery>
<cfelse>
    <cfquery  datasource="DSN">
        INSERT INTO Begeni(kullaniciID,hedefTip,hedefID,tarih)
        VALUES(
            <cfqueryparam value="#SESSION.kullaniciID#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#hedefTip#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">,
            GETDATE()
        )
    </cfquery>

    <cfif hedefTip EQ "cevap">
        <cfquery name="qKisi" datasource="DSN">
            SELECT cozenID
            FROM Cevap 
            WHERE id=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfif qKisi.recordCount GT 0 AND qKisi.cozenID NEQ val(SESSION.kullaniciID)>
            <cfquery datasource="DSN">
                INSERT INTO Puan(kullaniciID,islemTipi,puanDegeri,referansID,referansTip,eklenmeTarihi)
                VALUES(
                    <cfqueryparam value="#qKisi.cozenID#" cfsqltype="cf_sql_integer">,
                    'cevap_begenildi',
                    2,
                    <cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">,
                    'cevap',
                    GETDATE()
                )
            </cfquery>

            <cfquery datasource="DSN">
                UPDATE Kullanici 
                SET xp=xp+2
                WHERE id=<cfqueryparam value="#qKisi.cozenID#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>
    </cfif>
</cfif>

<cflocation url="#geri#" addtoken="false">