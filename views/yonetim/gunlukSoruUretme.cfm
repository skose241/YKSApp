<cfsetting requesttimeout="400">
<cfsetting showdebugoutput="false">

<cfif NOT structKeyExists(url,"token") OR url.token NEQ "messiah">
    <cfabort>
</cfif>

<cfset ai=createObject("component","YKSSite.views.includes.ai")>

<cfset sikLimit=400>

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
    <cfcase value="2"><cfset tytDersID=18></cfcase>
    <cfcase value="3"><cfset tytDersID=19></cfcase>
    <cfcase value="4"><cfset tytDersID=23></cfcase>
    <cfcase value="5"><cfset tytDersID=24></cfcase>
    <cfcase value="6"><cfset tytDersID=25></cfcase>
    <cfcase value="7"><cfset tytDersID=26></cfcase>
    <cfdefaultcase><cfset tytDersID=27></cfdefaultcase>
</cfswitch>

<cfswitch expression="#gunNo#">
    <cfcase value="2"><cfset aytMatID=1></cfcase>
    <cfcase value="3"><cfset aytMatID=1></cfcase>
    <cfcase value="4"><cfset aytMatID=2></cfcase>
    <cfcase value="5"><cfset aytMatID=1></cfcase>
    <cfcase value="6"><cfset aytMatID=1></cfcase>
    <cfcase value="7"><cfset aytMatID=2></cfcase>
    <cfdefaultcase><cfset aytMatID=1></cfdefaultcase>
</cfswitch>

<cfswitch expression="#gunNo#">
    <cfcase value="2"><cfset aytFenID=3></cfcase>
    <cfcase value="3"><cfset aytFenID=4></cfcase>
    <cfcase value="4"><cfset aytFenID=5></cfcase>
    <cfcase value="5"><cfset aytFenID=3></cfcase>
    <cfcase value="6"><cfset aytFenID=4></cfcase>
    <cfcase value="7"><cfset aytFenID=5></cfcase>
    <cfdefaultcase><cfset aytFenID=3></cfdefaultcase>
</cfswitch>

<cfswitch expression="#gunNo#">
    <cfcase value="2"><cfset aytEAID=6></cfcase>
    <cfcase value="3"><cfset aytEAID=6></cfcase>
    <cfcase value="4"><cfset aytEAID=7></cfcase>
    <cfcase value="5"><cfset aytEAID=6></cfcase>
    <cfcase value="6"><cfset aytEAID=6></cfcase>
    <cfcase value="7"><cfset aytEAID=8></cfcase>
    <cfdefaultcase><cfset aytEAID=6></cfdefaultcase>
</cfswitch>

<cfswitch expression="#gunNo#">
    <cfcase value="2"><cfset aytSozelID=9></cfcase>
    <cfcase value="3"><cfset aytSozelID=10></cfcase>
    <cfcase value="4"><cfset aytSozelID=11></cfcase>
    <cfcase value="5"><cfset aytSozelID=12></cfcase>
    <cfcase value="6"><cfset aytSozelID=9></cfcase>
    <cfcase value="7"><cfset aytSozelID=10></cfcase>
    <cfdefaultcase><cfset aytSozelID=11></cfdefaultcase>
</cfswitch>

<cfquery name="qDersler" datasource="DSN">
    SELECT id AS dersID,ad AS dersAd
    FROM Ders 
    WHERE id IN(
        <cfqueryparam value="#tytDersID#" cfsqltype="cf_sql_integer">,
        <cfqueryparam value="#aytMatID#" cfsqltype="cf_sql_integer">,
        <cfqueryparam value="#aytFenID#" cfsqltype="cf_sql_integer">,
        <cfqueryparam value="#aytEAID#" cfsqltype="cf_sql_integer">,
        <cfqueryparam value="#aytSozelID#" cfsqltype="cf_sql_integer">
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
    <cfif structKeyExists(dersAdi,secim.id)>
        <cfset arrayAppend(dersler,{
            dersID=secim.id,
            dersAd=dersAdi[secim.id],
            alanID=secim.alanID
        })>
    </cfif>
</cfloop>

<cfset uretilen=0>

<cfloop array="#dersler#" index="ders">
    <cfif uretilen GTE 5><cfbreak></cfif>

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
    'Cevap' ve 'Açıklama' satırlarını asla atlamadan soru işlemini tamamla.
    Sana güveniyorum ve tüm bu sadece tüm bu söylediklerime bağlı kalarak müthiş bir iş çıkarabileceğine inanıyorum.">

    <cfset aiSonuc=ai.metinUretme(prompt)>

    <cfif aiSonuc.basari>
        <cfset cevapMetni=aiSonuc.metin>

        <cftry>
            <cfset temizMetin=reReplace(cevapMetni,"```[a-zA-Z]*", "", "all")>
            <cfset temizMetin = replace(temizMetin,"**", "", "all")>
            <cfset temizMetin = replace(temizMetin, chr(13), "", "all")>

            <cfset satirlar=listToArray(temizMetin,chr(10))>

            <cfset veri={soru="",A="",B="",C="",D="",E="",cevap="",aciklama=""}>
            <cfset bolum="">

            <cfloop array="#satirlar#" index="hamSatir">
                <cfset satir=trim(hamSatir)>
                <cfif NOT len(satir)><cfcontinue></cfif>

                <cfif reFindNoCase("^soru\s*:",satir)>
                    <cfset bolum="soru">
                    <cfset veri.soru=trim(reReplaceNoCase(Satir,"^soru\s*:\s*", "", "one"))>
                <cfelseif reFindNoCase("^[A-Ea-e]\s*[\)\.\-]\s*",satir)>
                    <cfset bolum=uCase(left(satir,1))>
                    <cfset veri[bolum]=trim(reReplaceNoCase(satir,"^[A-Ea-e]\s*[\)\.\-]\s*", "", "one"))>
                <cfelseif reFindNoCase("^cevap\s*:", satir)>
                    <cfset bolum="cevap">
                    <cfset veri.cevap=trim(reReplaceNoCase(satir,"^cevap\s*:\s*", "", "one"))>
                <cfelseif reFindNoCase("^a[cç][iı]klama\s*:",satir)>
                    <cfset bolum="aciklama">
                    <cfset veri.aciklama=trim(reReplaceNoCase(satir,"^a[cç][iı]klama\s*:\s*", "", "one"))>
                <cfelseif len(bolum)>
                    <cfset veri[bolum]=veri[bolum] & " " & satir>
                </cfif>
            </cfloop>

            <cfset dogruCevap=uCase(left(reReplace(veri.cevap,"[^A-Ea-e]", "", "all"),1))>
            <cfset soruMetni=trim(veri.soru)>
            <cfset sikA=trim(veri.A)>
            <cfset sikB=trim(veri.B)>
            <cfset sikC=trim(veri.C)>
            <cfset sikD=trim(veri.D)>
            <cfset sikE=trim(veri.E)>
            <cfset aciklama=trim(veri.aciklama)>

            <cfset eksikler="">

            <cfif NOT listFind("A,B,C,D,E",dogruCevap)>
                <cfset eksikler=listAppend(eksikler,"Doğru Cevap:'#dogruCevap#'")>
            </cfif>

            <cfif len(soruMetni) LTE 10>
                <cfset eksikler=listAppend(eksikler,"Soru Metni kısa:(#len(soruMetni)#)")>
            </cfif>

            <cfloop list="A,B,C,D,E" index="h">
                <cfif NOT len(trim(veri[h]))>
                    <cfset eksikler=listAppend(eksikler,"Şık#h# boş.")>
                <cfelseif len(trim(veri[h])) GT sikLimit>
                    <cfset eksikler=listAppend(eksikler,"Şık#h# uzun:(#len(trim(veri[h]))#)")>
                </cfif>
            </cfloop>

            <cfif NOT len(eksikler)>
                <cfquery datasource="DSN" result="qYeniSoru">
                    INSERT INTO Soru(
                        dersID,soranID,dogruCevap,soruResmi,soruMetni,
                        sikA,sikB,sikC,sikD,sikE,aciklama,
                        sistemSoru,aktiflik,goruntulenmeSayisi,eklenmeTarihi
                    )
                    VALUES(
                        <cfqueryparam value="#ders.dersID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#application.aiKullaniciID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#dogruCevap#" cfsqltype="cf_sql_char">,
                        <cfqueryparam value="" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#soruMetni#" cfsqltype="varchar">,
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

                <cfset ai.logKaydetme(
                    kullaniciID=application.aiKullaniciID,
                    soruID=qYeniSoru.generatedKey,
                    islemTipi="gunluk_uretim",
                    girdi=prompt,
                    cikti=cevapMetni
                )>

                <cfset uretilen=uretilen+1>
            <cfelse>
                <cfquery datasource="DSN">
                    INSERT INTO HataLog(sayfa,islem,mesaj,detay,eklenmeTarihi)
                    VALUES(
                        '/YKSSite/views/yonetim/gunlukSoruUretme.cfm',
                        'Format Uyuşmazlığı(AI)',
                        <cfqueryparam value="#ders.dersAd# | Eksik:#eksikler#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#cevapMetni#" cfsqltype="cf_sql_varchar">,
                        GETDATE()
                    )
                </cfquery>
            </cfif>

            <cfcatch type="any">
                <cfquery datasource="DSN">
                    INSERT INTO HataLog(sayfa,islem,mesaj,detay,eklenmeTarihi)
                    VALUES(
                        '/YKSSite/views/yonetim/gunlukSoruUretme.cfm',
                        'Soru Parse Hatası:',
                        <cfqueryparam value="#cfcatch.message#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#cfcatch.detail#" cfsqltype="cf_sql_varchar">,
                        GETDATE()
                    )
                </cfquery>
            </cfcatch>
        </cftry>
    <cfelse>
        <cfquery datasource="DSN">
            INSERT INTO HataLog(sayfa,islem,mesaj,detay,eklenmeTarihi)
            VALUES(
                '/YKSSite/views/yonetim/gunlukSoruUretme.cfm',
                'Gemini API Hatası:',
                <cfqueryparam value="#ders.dersAd# | #aiSonuc.hata#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#left(aiSonuc.ham,8000)#" cfsqltype="cf_sql_varchar">,
                GETDATE()
            )
        </cfquery>
    </cfif>

    <cfset sleep(40000)>
</cfloop>

<cfoutput>#uretilen# soru üretildi.</cfoutput>