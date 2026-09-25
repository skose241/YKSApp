<cfsetting requesttimeout="900">
<cfsetting showdebugoutput="false">
<cfset ai=createObject("component","YKSSite.views.includes.ai")>

<cfif NOT structKeyExists(application,"uretimToken")
    OR NOT len(trim(application.uretimToken))
    OR NOT structKeyExists(url,"token")
    OR compare(url.token,application.uretimToken) NEQ 0>
    <cfheader statuscode="403" statustext="Forbidden">
    <cfabort>
</cfif>

<cfset sikLimit=400>
<cfset hedef=5>
<cfset sure=structKeyExists(application,"uretimBekleme") ? val(application.uretimBekleme):35000>
<cfset buSayfa="/YKSSite/views/yonetim/gunlukSoruUretme.cfm">

<cfquery name="qBugun" datasource="DSN">
    SELECT s.dersID
    FROM GunlukSoru gs
    INNER JOIN Soru s ON s.id=gs.soruID
    WHERE gs.tarih=CAST(GETDATE() AS DATE)
</cfquery>

<cfset uretilenDers=valueList(qBugun.dersID)>
<cfif qBugun.recordCount GTE hedef>
    <cfoutput>Bugün zaten #qBugun.recordCount# adet soru üretildi.</cfoutput>
    <cfabort>
</cfif>

<cfset gunNo=dayOfWeek(now())>
<cfset tytHaritasi={2=18,3=19,4=23,5=24,6=25,7=26}>
<cfset matHaritasi={2=1,3=1,4=2,5=1,6=1,7=2}>
<cfset fenHaritasi={2=3,3=4,4=5,5=3,6=4,7=5}>
<cfset eaHaritasi={2=13,3=14,4=15,5=16,6=17,7=13}>
<cfset sozelHaritasi={2=6,3=7,4=8,5=9,6=10,7=11}>
<cfset tytDersID=structKeyExists(tytHaritasi,gunNo) ? tytHaritasi[gunNo]:27>
<cfset aytMatID=structKeyExists(matHaritasi,gunNo) ? matHaritasi[gunNo]:1>
<cfset aytFenID=structKeyExists(fenHaritasi,gunNo) ? fenHaritasi[gunNo]:3>
<cfset aytEAID=structKeyExists(eaHaritasi,gunNo) ? eaHaritasi[gunNo]:13>
<cfset aytSozelID=structKeyExists(sozelHaritasi,gunNo) ? sozelHaritasi[gunNo]:6>

<cfquery name="qDersler" datasource="DSN">
    SELECT id AS dersID,ad AS dersAd
    FROM Ders
    WHERE id IN(
    <cfqueryparam value="#tytDersID#,#aytMatID#,#aytFenID#,#aytEAID#,#aytSozelID#" cfsqltype="cf_sql_integer" list="true">
    )
</cfquery>

<cfset dersAdi={}>
<cfloop query="qDersler">
    <cfset dersAdi[qDersler.dersID]=qDersler.dersAd>
</cfloop>

<cfset dersler=[]>
<cfset secimler=[
    {id=tytDersID,alanID=4},
    {id=aytMatID,alanID=1},
    {id=aytFenID,alanID=1},
    {id=aytEAID,alanID=3},
    {id=aytSozelID,alanID=2}
    ]>
<cfloop array="#secimler#" index="secim">
    <cfif structKeyExists(dersAdi,secim.id) AND NOT listFind(uretilenDers,secim.id)>
        <cfset arrayAppend(dersler,{
            dersID=secim.id,
            dersAd=dersAdi[secim.id],
            alanID=secim.alanID
            })>
    </cfif>
</cfloop>

<cfset uretilen=0>
<cfset sira=0>
<cfset basHarfler="A,B,C,D,E">
<cfloop array="#dersler#" index="ders">
    <cfset sira=sira+1>
    <cfif (qBugun.recordCount+uretilen) GTE hedef><cfbreak></cfif>
    <cfset prompt="Sen bir YKS soru hazırlayıcısısın.
Ders:#ders.dersAd#
Görev:Bu derse uygun,lise düzeyinde 5 şıklı(A,B,C,D,E) yeni bir soru üret. Soruların,2020 yılından itibaren çıkmış YKS soru formatında olmalı mutlaka. Soru yazarken şu istenilenlerin dışına lütfen,çıkma.
-Para birimi için sembol kullanma. TL veya lira gibi yazı ile yaz mutlaka.
-Markdown,yıldız,kalın yazı,başlık kullanma.
-Matematiksel ifadeleri LaTeX ile yaz.
--Satır içi formüller için tek dolar: $x^2+3x$
--Ayrı satırda gösterilecek büyük formüller için çift dolar: $$\int_0^1 x dx$$
--Küçüktür/Büyüktür için < ve > yerine \lt ve \gt kullan.
--Düz metin kısımlarında LaTeX kullanma,LaTeX sadece formüllerde kullanılacak çünkü.
--Kod bloğu(uç backtick) kullanma. Kalın yazı için çift yıldız kullanma.
Her bölüm ayrı satırda olsun ve aşağıdaki etiketlerin mutlaka hepsini kullanmalısın.
Yanıtını sadece şu formatta ver,başka hiçbir şey yazma:
Soru:[Sadece soru metni,şıklar dahil değil]
A)[şık metni,olabildiğince kısa tut.]
B)[şık metni,olabildiğince kısa tut.]
C)[şık metni,olabildiğince kısa tut.]
D)[şık metni,olabildiğince kısa tut.]
E)[şık metni,olabildiğince kısa tut.]
Cevap:[sadece doğru şık,başka da hiçbir metin olmayacak]
Açıklama:[olabildiğince sade şekilde çözüm açıklaması]
Uyarı:Şıklar,LaTeX dahil #sikLimit# karakteri geçmesin. Ama mutlaka tüm şıklarda bir metin olsun.
'Cevap' ve 'Açıklama' satırlarını asla atlamadan soru işlemini tamamla.">
    <cfset aiSonuc=ai.metinUretme(prompt=prompt,amac="soru")>
    <cfif NOT aiSonuc.basari>
        <cfset ai.hataYazma(
            sayfa=buSayfa,
            islem="Gemini API Hatası",
            mesaj="#ders.dersAd# | #aiSonuc.hata#",
            detay=aiSonuc.ham
            )>
    <cfelse>
        <cfset cevapMetni=aiSonuc.metin>
        <cftry>
            <cfset temizMetin=reReplace(cevapMetni,"```[a-zA-Z]*","","all")>
            <cfset temizMetin=replace(temizMetin,"```","","all")>
            <cfset temizMetin=replace(temizMetin,"**","","all")>
            <cfset temizMetin=replace(temizMetin,chr(13),"","all")>
            <cfset satirlar=listToArray(temizMetin,chr(10))>
            <cfset veri={soru="",A="",B="",C="",D="",E="",cevap="",aciklama=""}>
            <cfset bolum="">
            <cfloop array="#satirlar#" index="hamSatir">
                <cfset satir=trim(hamSatir)>
                <cfif NOT len(satir)><cfcontinue></cfif>
                <cfif reFindNoCase("^cevap\s*:",satir) AND NOT len(veri.cevap)>
                    <cfset bolum="cevap">
                    <cfset veri.cevap=trim(reReplaceNoCase(satir,"^cevap\s*:\s*","","one"))>
                <cfelseif bolum EQ "aciklama">
                    <cfset veri.aciklama=trim(veri.aciklama & " " & satir)>
                <cfelseif reFindNoCase("^soru\s*:",satir)>
                    <cfset bolum="soru">
                    <cfset veri.soru=trim(reReplaceNoCase(satir,"^soru\s*:\s*","","one"))>
                <cfelseif reFindNoCase("^a[cç][iı]klama\s*:",satir)>
                    <cfset bolum="aciklama">
                    <cfset veri.aciklama=trim(reReplaceNoCase(satir,"^a[cç][iı]klama\s*:\s*","","one"))>
                <cfelseif reFindNoCase("^[A-Ea-e]\s*[\)\.\-]\s*",satir)>
                    <cfset bolum=uCase(left(satir,1))>
                    <cfset veri[bolum]=trim(reReplaceNoCase(satir,"^[A-Ea-e]\s*[\)\.\-]\s*","","one"))>
                <cfelseif len(bolum)>
                    <cfset veri[bolum]=trim(veri[bolum] & " " & satir)>
                </cfif>
            </cfloop>
            <cfset dogruCevap=uCase(left(reReplace(veri.cevap,"[^A-Ea-e]","","all"),1))>
            <cfset soruMetni=trim(veri.soru)>
            <cfset sikA=trim(veri.A)>
            <cfset sikB=trim(veri.B)>
            <cfset sikC=trim(veri.C)>
            <cfset sikD=trim(veri.D)>
            <cfset sikE=trim(veri.E)>
            <cfset aciklama=trim(veri.aciklama)>
            <cfset eksikler="">
            <cfif NOT listFind(basHarfler,dogruCevap)>
                <cfset eksikler=listAppend(eksikler,"Doğru Cevap:'#dogruCevap#' okunamadı.")>
            </cfif>
            <cfif len(soruMetni) LTE 10>
                <cfset eksikler=listAppend(eksikler,"Soru Metni kısa:(#len(soruMetni)#)")>
            </cfif>
            <cfif len(soruMetni) GT 4000>
                <cfset eksikler=listAppend(eksikler,"Soru Metni uzun:(#len(soruMetni)#)")>
            </cfif>
            <cfif NOT len(aciklama)>
                <cfset eksikler=listAppend(eksikler,"Açıklama boş.")>
            </cfif>
            <cfloop list="#basHarfler#" index="h">
                <cfif NOT len(trim(veri[h]))>
                    <cfset eksikler=listAppend(eksikler,"Şık#h# boş.")>
                <cfelseif len(trim(veri[h])) GT sikLimit>
                    <cfset eksikler=listAppend(eksikler,"Şık#h# uzun:(#len(trim(veri[h]))#)")>
                </cfif>
            </cfloop>
            <cfset benzerSik=false>
            <cfloop list="#basHarfler#" index="h1">
                <cfloop list="#basHarfler#" index="h2">
                    <cfif compare(h1,h2) LT 0 AND compareNoCase(trim(veri[h1]),trim(veri[h2])) EQ 0>
                        <cfset benzerSik=true>
                    </cfif>
                </cfloop>
            </cfloop>
            <cfif benzerSik>
                <cfset eksikler=listAppend(eksikler,"Aynı şıklar mevcut.")>
            </cfif>
            <cfif len(eksikler)>
                <cfset ai.hataYazma(
                    sayfa=buSayfa,
                    islem="Format Uyuşmazlığı(AI)",
                    mesaj="#ders.dersAd# | Eksik:#eksikler#",
                    detay=cevapMetni
                    )>
            <cfelse>
                <cftransaction>
                    <cfquery name="qYeniSoru" datasource="DSN">
                        INSERT INTO Soru(
                        dersID,soranID,dogruCevap,soruResmi,soruMetni,
                        sikA,sikB,sikC,sikD,sikE,aciklama,
                        sistemSoru,aktiflik,goruntulenmeSayisi,eklenmeTarihi
                        )
                        OUTPUT INSERTED.id AS yeniID
                        VALUES(
                        <cfqueryparam value="#ders.dersID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#application.aiKullaniciID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#dogruCevap#" cfsqltype="cf_sql_char">,
                        <cfqueryparam value="" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#soruMetni#" cfsqltype="cf_sql_longvarchar">,
                        <cfqueryparam value="#sikA#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#sikB#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#sikC#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#sikD#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#sikE#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#aciklama#" cfsqltype="cf_sql_longvarchar">,
                        1,
                        1,
                        0,
                        GETDATE()
                        )
                    </cfquery>

                    <cfset yeniSoruID=val(qYeniSoru.yeniID)>
                    <cfif yeniSoruID LTE 0>
                        <cfthrow message="INSERT OUTPUT içerisinden soruID alınamadı.">
                    </cfif>

                    <cfquery datasource="DSN">
                        INSERT INTO GunlukSoru(soruID,tarih,alanID,olusturmaTipi,goruntulenme)
                        VALUES(
                        <cfqueryparam value="#yeniSoruID#" cfsqltype="cf_sql_integer">,
                        CAST(GETDATE() AS DATE),
                        <cfqueryparam value="#ders.alanID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="ai" cfsqltype="cf_sql_varchar">,
                        0
                        )
                    </cfquery>
                </cftransaction>

                <cfset ai.logKaydetme(
                    kullaniciID=application.aiKullaniciID,
                    soruID=yeniSoruID,
                    islemTipi="gunluk_uretim",
                    girdi="ders:#ders.dersAd#",
                    cikti=cevapMetni
                    )>
                <cfset uretilen=uretilen+1>
            </cfif>

            <cfcatch type="any">
                <cfset ai.hataYazma(
                    sayfa=buSayfa,
                    islem="Soru Parse/Kayıt Hatası",
                    mesaj="#ders.dersAd# | #cfcatch.message#",
                    detay=cfcatch.detail
                    )>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif sira LT arrayLen(dersler)>
        <cfset sleep(sure)>
    </cfif>
</cfloop>

<cfoutput>#uretilen# soru üretildi</cfoutput>