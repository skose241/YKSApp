<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif cgi.request_method NEQ "POST" AND NOT structKeyExists(url,"hedefID")>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfif NOT structKeyExists(url,"hedefID") OR NOT isNumeric(url.hedefID) OR val(url.hedefID) LTE 0>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset hedefID=val(url.hedefID)>
<cfset hedefTip=structKeyExists(url,"hedefTip") ? lCase(trim(url.hedefTip)):"cevap">
<cfset kullaniciID=val(SESSION.kullaniciID)>

<cfif NOT listFind("cevap,yorum",hedefTip)>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset geri="/YKSSite/anaSayfa.cfm">

<cfif structKeyExists(url,"geri") AND left(url.geri,9) EQ "/YKSSite/" AND NOT find("//",replace(url.geri,"/YKSSite/","",​"one"))>
    <cfset geri=url.geri>
</cfif>

<cfquery name="qHedef" datasource="DSN">
    <cfif hedefTip EQ "cevap">
        SELECT id,cozenID AS sahipID
        FROM Cevap
        WHERE id=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
        AND aktiflik=1
    <cfelse>
        SELECT id,yazanID AS sahipID
        FROM Yorum
        WHERE id=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
        AND aktiflik=1
    </cfif>
</cfquery>

<cfif qHedef.recordCount EQ 0>
    <cflocation url="#geri#" addtoken="false">
</cfif>

<cfif val(qHedef.sahipID) EQ kullaniciID>
    <cflocation url="#geri#" addtoken="false">
</cfif>

<cftry>
    <cfquery name="qKontrol" datasource="DSN">
        SELECT id
        FROM Begeni
        WHERE hedefID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
        AND hedefTip=<cfqueryparam value="#hedefTip#" cfsqltype="cf_sql_varchar">
        AND kullaniciID=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cftransaction>
        <cfif qKontrol.recordCount GT 0>
            <cfquery datasource="DSN">
                DELETE FROM Begeni
                WHERE hedefID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
                AND hedefTip=<cfqueryparam value="#hedefTip#" cfsqltype="cf_sql_varchar">
                AND kullaniciID=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfif hedefTip EQ "cevap">
                <cfquery name="qPuan" datasource="DSN">
                    SELECT TOP 1 id
                    FROM Puan
                    WHERE kullaniciID=<cfqueryparam value="#qHedef.sahipID#" cfsqltype="cf_sql_integer">
                    AND islemTipi='cevap_begenildi'
                    AND referansTip='cevap'
                    AND referansID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
                    ORDER BY id DESC
                </cfquery>

                <cfif qPuan.recordCount GT 0>
                    <cfquery datasource="DSN">
                        DELETE FROM Puan
                        WHERE id=<cfqueryparam value="#qPuan.id#" cfsqltype="cf_sql_integer">
                    </cfquery>

                    <cfquery datasource="DSN">
                        UPDATE Kullanici
                        SET xp=CASE WHEN xp-2 < 0 THEN 0 ELSE xp-2 END
                        WHERE id=<cfqueryparam value="#qHedef.sahipID#" cfsqltype="cf_sql_integer">
                    </cfquery>
                </cfif>
            </cfif>
        <cfelse>
            <cfquery datasource="DSN">
                INSERT INTO Begeni(kullaniciID,hedefTip,hedefID,tarih)
                VALUES(
                    <cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#hedefTip#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">,
                    GETDATE()
                )
            </cfquery>

            <cfif hedefTip EQ "cevap">
                <cfquery datasource="DSN">
                    INSERT INTO Puan(kullaniciID,islemTipi,puanDegeri,referansID,referansTip,eklenmeTarihi)
                    VALUES(
                        <cfqueryparam value="#qHedef.sahipID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="cevap_begenildi" cfsqltype="cf_sql_varchar">,
                        2,
                        <cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="cevap" cfsqltype="cf_sql_varchar">,
                        GETDATE()
                    )
                </cfquery>

                <cfquery datasource="DSN">
                    UPDATE Kullanici
                    SET xp=xp+2
                    WHERE id=<cfqueryparam value="#qHedef.sahipID#" cfsqltype="cf_sql_integer">
                </cfquery>
            </cfif>
        </cfif>
    </cftransaction>

    <cfcatch type="any">
        <cfset ai=createObject("component","YKSSite.views.includes.ai")>
        <cfset ai.hataYazma(
            sayfa="/YKSSite/views/soru/begeniToggle.cfm",
            islem="begeniToggle",
            mesaj=cfcatch.message,
            detay=cfcatch.detail
        )>
    </cfcatch>
</cftry>

<cflocation url="#geri#" addtoken="false">