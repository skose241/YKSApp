<cfheader name="Content-Type" value="application/json">

<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfset ai=createObject("component","YKSSite.views.includes.ai")>

<cfif NOT structKeyExists(url,"soruID") OR NOT isNumeric(url.soruID)>
    <cfoutput>{"basari":false,"hata":"Geçersiz istek."}</cfoutput>
    <cfabort>
</cfif>

<cfset soruID=val(url.soruID)>

<cfquery name="qSoru" datasource="DSN">
    SELECT s.soruResmi,d.ad AS dersAd
    FROM Soru s 
    INNER JOIN Ders d ON d.id=s.dersID
    WHERE s.id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND s.aktiflik=1
    AND s.sistemSoru=0
</cfquery>

<cfif qSoru.recordCount EQ 0>
    <cfoutput>{"basari":false,"hata":"Soru bulunamadı."}</cfoutput>
    <cfabort>
</cfif>

<cfquery name="qLog" datasource="DSN">
    SELECT cikti
    FROM AI 
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    AND islemTipi='kullanici_cozum'
    ORDER BY eklenmeTarihi DESC
</cfquery>

<cfif qLog.recordCount GT 0>
    <cfoutput>{"basari":true,"metin":#serializeJSON(qLog.cikti)#}</cfoutput>
    <cfabort>
</cfif>

<cfset resimYolu=expandPath("/YKSSite/assets/images/sorular/#qSoru.soruResmi#")>

<cfset prompt="Bu #qSoru.dersAd# sorusunu adım adım çöz. Türkçe olarak ve ortalama bir lise öğrencisinin anlayabileceği sadelikte açıkla. Sonunda mutlaka doğru cevabı belirt.">

<cfset sonuc=ai.resimCozme(resimYolu,prompt)>

<cfif sonuc.basari>
    <cfset ai.logKaydetme(
        kullaniciID=val(SESSION.kullaniciID),
        soruID=soruID,
        islemTipi="kullanici_cozum",
        girdi=prompt,
        cikti=sonuc.metin
    )>
    
    <cfoutput>{"basari":true,"metin":#serializeJSON(sonuc.metin)#}</cfoutput>
<cfelse>
    <cfoutput>{"basari":false,"hata":#serializeJSON(sonuc.hata)#}</cfoutput>
</cfif>