<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">
<cfparam name="form.cevapID" default="0">
<cfparam name="form.soruID" default="0">
<cfparam name="form.metin" default="">
<cfparam name="form.ustYorumID" default="0">
<cfparam name="form.csrf" default="">
<cfset cevapID=val(form.cevapID)>
<cfset soruID=val(form.soruID)>
<cfset metin=left(trim(form.metin),500)>
<cfset ustID=val(form.ustYorumID)>
<cfset kullaniciID=val(SESSION.kullaniciID)>

<cfif cgi.request_method NEQ "POST">
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfif soruID LTE 0 OR cevapID LTE 0 OR NOT len(metin) OR kullaniciID LTE 0>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfif compare(form.csrf,SESSION.csrf) NEQ 0>
    <cflocation url="/YKSSite/views/soru/soruDetay.cfm?id=#soruID#&uyari=csrf" addtoken="false">
</cfif>

<cfquery name="qCevap" datasource="DSN">
    SELECT c.id,c.cozenID
    FROM Cevap c
    INNER JOIN Soru s ON s.id=c.soruID
    WHERE c.id=<cfqueryparam value="#cevapID#" cfsqltype="cf_sql_integer">
    AND c.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND c.aktiflik=1
    AND s.aktiflik=1
</cfquery>

<cfif qCevap.recordCount EQ 0>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfquery name="qSonYorum" datasource="DSN">
    SELECT TOP 1 metin,eklenmeTarihi
    FROM Yorum
    WHERE yazanID=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
    ORDER BY eklenmeTarihi DESC
</cfquery>

<cfif qSonYorum.recordCount GT 0>
    <cfif dateDiff("s",qSonYorum.eklenmeTarihi,now()) LT 10>
        <cflocation url="/YKSSite/views/soru/soruDetay.cfm?id=#soruID#&uyari=hizli" addtoken="false">
    </cfif>

    <cfif compare(trim(qSonYorum.metin),metin) EQ 0 AND dateDiff("n",qSonYorum.eklenmeTarihi,now()) LT 5>
        <cflocation url="/YKSSite/views/soru/soruDetay.cfm?id=#soruID#&uyari=tekrar" addtoken="false">
    </cfif>
</cfif>

<cfset ustYazanID=0>
<cfif ustID GT 0>
    <cfquery name="qUst" datasource="DSN">
        SELECT id,yazanID
        FROM Yorum
        WHERE id=<cfqueryparam value="#ustID#" cfsqltype="cf_sql_integer">
        AND cevapID=<cfqueryparam value="#cevapID#" cfsqltype="cf_sql_integer">
        AND ustYorumID IS NULL
        AND aktiflik=1
    </cfquery>
    <cfif qUst.recordCount EQ 0>
        <cfset ustID=0>
    <cfelse>
        <cfset ustYazanID=val(qUst.yazanID)>
    </cfif>
</cfif>

<cftry>
    <cftransaction>
        <cfquery datasource="DSN">
            INSERT INTO Yorum(cevapID,yazanID,metin,ustYorumID,aktiflik,eklenmeTarihi)
            VALUES(
            <cfqueryparam value="#cevapID#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#metin#" cfsqltype="cf_sql_longvarchar">,
            <cfqueryparam value="#ustID#" cfsqltype="cf_sql_integer" null="#(ustID EQ 0)#">,
            1,
            GETDATE()
            )
        </cfquery>

        <cfif ustID GT 0 AND ustYazanID GT 0 AND ustYazanID NEQ kullaniciID>
            <cfquery datasource="DSN">
                INSERT INTO Bildirim(kullaniciID,islemTipi,mesaj,goruldu,hedefURL,tarih)
                VALUES(
                <cfqueryparam value="#ustYazanID#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="yorum" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="Yorumunuza bir yanıt geldi." cfsqltype="cf_sql_varchar">,
                0,
                <cfqueryparam value="/YKSSite/views/soru/soruDetay.cfm?id=#soruID#" cfsqltype="cf_sql_varchar">,
                GETDATE()
                )
            </cfquery>
        </cfif>

        <cfif ustID EQ 0 AND val(qCevap.cozenID) NEQ kullaniciID>
            <cfquery datasource="DSN">
                INSERT INTO Bildirim(kullaniciID,islemTipi,mesaj,goruldu,hedefURL,tarih)
                VALUES(
                <cfqueryparam value="#qCevap.cozenID#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="yorum" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="Çözümünüze bir yorum yapıldı." cfsqltype="cf_sql_varchar">,
                0,
                <cfqueryparam value="/YKSSite/views/soru/soruDetay.cfm?id=#soruID#" cfsqltype="cf_sql_varchar">,
                GETDATE()
                )
            </cfquery>
        </cfif>
    </cftransaction>
    
    <cfcatch type="any">
        <cfset ai=createObject("component","YKSSite.views.includes.ai")>
        <cfset ai.hataYazma(
            sayfa="/YKSSite/views/soru/yorumEkle.cfm",
            islem="yorumEkle",
            mesaj=cfcatch.message,
            detay=cfcatch.detail
            )>
    </cfcatch>
</cftry>

<cflocation url="/YKSSite/views/soru/soruDetay.cfm?id=#soruID#" addtoken="false">