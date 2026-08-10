<cfinclude template="/YKSSite/views/includes/ai.cfm">

<cfif NOT structKeyExists(url,"token") OR url.token NEQ "messiah">
    <cfabort>
</cfif>

<cfquery name="qKontrol" datasource="DSN">
    SELECT COUNT(*) AS adet 
    FROM GunlukSoru
    WHERE tarih=CAST(GETDATE() AS DATE)
</cfquery>

<cfif qKontrol.adet GTE 5>
    <cfoutput>Bugün zaten 5 adet soru üretildi.</cfoutput>
    <cfabort>
</cfif>

<cfset gunNo=dayOfWeek(now())>

<cfswitch expression="#gunNo#">
    <cfcase value="2"><cfset tytDersAd="TYT Türkçe"></cfcase>
    <cfcase value="3"><cfset tytDersAd="TYT Sosyal"></cfcase>
    <cfcase value="4"><cfset tytDersAd="TYT Matematik"></cfcase>
    <cfcase value="5"><cfset tytDersAd="TYT Geometri"></cfcase>
    <cfcase value="6"><cfset tytDersAd="TYT Fizik"></cfcase>
    <cfcase value="7"><cfset tytDersAd="TYT Kimya"></cfcase>
    <cfdefaultcase><cfset tytDersAd="TYT Biyoloji"></cfdefaultcase>
</cfswitch>

<cfquery name="qTYTDers" datasource="DSN">
    SELECT id 
    FROM Ders 
    WHERE ad=<cfqueryparam value="#tytDersAd#" cfsqltype="cf_sql_varchar">
</cfquery>

<cfquery name="qAYTSayisal" datasource="DSN">
    SELECT TOP 1 d.id AS dersID,d.ad AS dersAd
    FROM Soru s 
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE a.id=1
    AND s.aktiflik=1
    AND s.sistemSoru=0
    AND CAST(s.eklenmeTarihi AS DATE)=CAST(GETDATE() AS DATE)
    ORDER BY s.goruntulenmeSayisi DESC
</cfquery>

<cfif qAYTSayisal.recordCount EQ 0>
    <cfquery name="qAYTSayisal" datasource="DSN">
        SELECT TOP 1 d.id AS dersID,d.ad AS dersAd
        FROM Soru s 
        INNER JOIN Ders d ON d.id=s.dersID
        INNER JOIN Alan a ON a.id=d.alanID
        WHERE a.id=1
        AND s.aktiflik=1
        AND s.sistemSoru=0
        ORDER BY s.goruntulenmeSayisi DESC
    </cfquery>
</cfif>

<cfquery name="qAYTSozel" datasource="DSN">
    SELECT TOP 1 d.id AS dersID,d.ad AS dersAd
    FROM Soru s 
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE a.id=2
    AND s.aktiflik=1
    AND s.sistemSoru=0
    AND CAST(s.eklenmeTarihi AS DATE)=CAST(GETDATE() AS DATE)
    ORDER BY s.goruntulenmeSayisi DESC
</cfquery>

<cfif qAYTSozel.recordCount EQ 0>
    <cfquery name="qAYTSozel" datasource="DSN">
        SELECT TOP 1 d.id AS dersID,d.ad AS dersAd
        FROM Soru s 
        INNER JOIN Ders d ON d.id=s.dersID
        INNER JOIN Alan a ON a.id=d.alanID
        WHERE a.id=2
        AND s.aktiflik=1
        AND s.sistemSoru=0
        ORDER BY s.goruntulenmeSayisi DESC
    </cfquery>
</cfif>

<cfquery name="qAYTEA" datasource="DSN">
    SELECT TOP 1 d.id AS dersID,d.ad AS dersAd
    FROM Soru s 
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE a.id=3
    AND s.aktiflik=1
    AND s.sistemSoru=0
    AND CAST(s.eklenmeTarihi AS DATE)=CAST(GETDATE() AS DATE)
    ORDER BY s.goruntulenmeSayisi DESC
</cfquery>

<cfif qAYTEA.recordCount EQ 0>
    <cfquery name="qAYTEA" datasource="DSN">
        SELECT TOP 1 d.id AS dersID,d.ad AS dersAd
        FROM Soru s 
        INNER JOIN Ders d ON d.id=s.dersID
        INNER JOIN Alan a ON a.id=d.alanID
        WHERE a.id=3
        AND s.aktiflik=1
        AND s.sistemSoru=0
        ORDER BY s.goruntulenmeSayisi DESC
    </cfquery>
</cfif>

<cfquery name="qAYTMat" datasource="DSN">
    SELECT TOP 1 d.id AS dersID,d.ad AS dersAd
    FROM Soru s 
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    WHERE a.sinavTuruID=2
    AND d.ad LIKE 'AYT Matematik%'
    AND s.aktiflik=1
    AND s.sistemSoru=0
    ORDER BY s.goruntulenmeSayisi DESC
</cfquery>

<cfset dersler=[]>

<cfif qTYTDers.recordCount GT 0>
    <cfset arrayAppend(dersler,{
        dersID=qTYTDers.id,
        dersAd=tytDersAd,
        alanID=4
    })>
</cfif>

<cfif qAYTSayisal.recordCount GT 0>
    <cfset arrayAppend(dersler,{
        dersID=qAYTSayisal.dersID,
        dersAd=qAYTSayisal.dersAd,
        alanID=1
    })>
</cfif>

<cfif qAYTSozel.recordCount GT 0>
    <cfset arrayAppend(dersler,{
        dersID=qAYTSozel.dersID,
        dersAd=qAYTSozel.dersAd,
        alanID=2
    })>
</cfif>

<cfif qAYTEA.recordCount GT 0>
    <cfset arrayAppend(dersler,{
        dersID=qAYTEA.dersID,
        dersAd=qAYTEA.dersAd,
        alanID=3
    })>
</cfif>

<cfif qAYTMat.recordCount GT 0>
    <cfset arrayAppend(dersler,{
        dersID=qAYTMat.dersID,
        dersAd=qAYTMat.dersAd,
        alanID=1
    })>
</cfif>

<cfset uretilen=0>

<cfloop array="#dersler#" index="ders">
    <cfif uretilen GTE 5><cfbreak></cfif>

    <cfset prompt="Sen bir YKS soru hazırlayıcısısın.
    Ders:#ders.dersAd#
    Görev:Bu derse uygun,lise düzeyinde 5 şıklı(A,B,C,D,E) yeni bir soru üret. Yanıtını sadece şu formatta ver,başka hiçbir şey yazma:
    
    Soru:[soru metni buraya]
    A)[şık metni]
    B)[şık metni]
    C)[şık metni]
    D)[şık metni]
    E)[şık metni]
    
    Cevap:[doğru şık]
    Açıklama:[olabildiğince sade,çözüm açıklaması]">

    <cfset aiSonuc=metinUretme(prompt)>

    <cfif aiSonuc.basari>
        <cfset cevapMetni=aiSonuc.metin>

        <cftry>
            <cfset soruMetni=trim(reReplaceNoCase(cevapMetni,".*SORU:\s*","","one"))>
            <cfset soruMetni=trim(reReplaceNoCase(cevapMetni,".*\nA\)\s*","","all"))>

            <cfset sikA=trim(reReplaceNoCase(cevapMetni,".*\nA\)\s*","","one"))>
            <cfset sikA=trim(reReplaceNoCase(sikA,"\nB\).*","","all"))>

            <cfset sikB=trim(reReplaceNoCase(cevapMetni,".*\nB\)\s*","","one"))>
            <cfset sikB=trim(reReplaceNoCase(sikB,"\nC\).*","","all"))>

            <cfset sikC=trim(reReplaceNoCase(cevapMetni,".*\nC\)\s*","","one"))>
            <cfset sikC=trim(reReplaceNoCase(sikC,"\nD\).*","","all"))>

            <cfset sikD=trim(reReplaceNoCase(cevapMetni,".*\nD\)\s*","","one"))>
            <cfset sikD=trim(reReplaceNoCase(sikD,"\nE\).*","","all"))>

            <cfset sikE=trim(reReplaceNoCase(cevapMetni,".*\nE\)\s*","","one"))>
            <cfset sikE=trim(reReplaceNoCase(sikE,"\nCEVAP.*","","all"))>

            <cfset dogruCevap=trim(reReplaceNoCase(cevapMetni,".*cEVAP:\s*","","one"))>
            <cfset dogruCevap=trim(left(reReplaceNoCase(dogruCevap,"\n.*","","all"),1))>
            <cfset dogruCevap=uCase(dogruCevap)>

            <cfset aciklama=trim(reReplaceNoCase(cevapMetni,".*AÇIKLAMA:\s*","","one"))>

            <cfif listFind("A,B,C,D,E",dogruCevap) AND len(soruMetni) GT 10>
                <cfquery datasource="DSN" result="qYeniSoru">
                    INSERT INTO Soru(
                        dersID,soranID,dogruCevap,soruResmi,soruMetni,sikA,sikB,sikC,sikD,sikE,aciklama,sistemSoru,aktiflik,goruntulenmeSayisi,eklenmeTarihi
                    )
                    VALUES(
                        <cfqueryparam value="#ders.dersID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#application.aiKullaniciID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#dogruCevap#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#soruMetni#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#sikA#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#sikB#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#sikC#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#sikD#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#sikE#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#aciklama#" cfsqltype="cf_sql_varchar">,
                        1,
                        1,
                        0,
                        GETDATE()
                    )
                </cfquery>

                <cfquery datasource="DSN">
                    INSERT INTO GunlukSoru(soruID,tarih,alanID,olusturmaTipi,goruntulenme)
                    VALUES(
                        <cfqueryparam value="#qYeniSoru.generatedKey#" cfsqltype="cf_sql_integer">,
                        CAST(GETDATE() AS DATE),
                        <cfqueryparam value="#ders.alanID#" cfsqltype="cf_sql_integer">,
                        'ai',
                        0
                    )
                </cfquery>

                <cfset logKaydetme(
                    kullaniciID=application.aiKullaniciID,
                    soruID=qYeniSoru.generatedKey,
                    islemTipi="gunluk_uretim",
                    girdi=prompt,
                    cikti=cevapMetni
                )>

                <cfset uretilen=uretilen+1>
            </cfif>

            <cfcatch type="any">
                <cflog file="yksHata" text="Soru Parse Hatası:#cfcatch.message#">
            </cfcatch>
        </cftry>
    <cfelse>
        <cflog file="yksHata" text="Gemini Hatası:#aiSonuc.hata#">
    </cfif>

    <cfset sleep(2000)>
</cfloop>

<cfoutput>#uretilen# soru üretildi.</cfoutput>