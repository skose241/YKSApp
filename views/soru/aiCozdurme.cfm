<cfheader name="Content-Type" value="application/json; charset=UTF-8">

<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfset ai=createObject("component","YKSSite.views.includes.ai")>

<cfif NOT structKeyExists(url,"soruID") OR NOT isNumeric(url.soruID)>
    <cfoutput>{"basari":false,"hata":"Geçersiz istek."}</cfoutput>
    <cfabort>
</cfif>

<cfset soruID=val(url.soruID)>

<cfquery name="qSoru" datasource="DSN">
    SELECT s.soruResmi,s.soruMetni,s.sikA,s.sikB,s.sikC,s.sikD,s.sikE,d.ad AS dersAd
    FROM Soru s 
    INNER JOIN Ders d ON d.id=s.dersID
    WHERE s.id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND s.aktiflik=1
</cfquery>

<cfif qSoru.recordCount EQ 0>
    <cfoutput>{"basari":false,"hata":"Soru bulunamadı."}</cfoutput>
    <cfabort>
</cfif>

<cfset gunlukLimit=structKeyExists(application,"aiLimit") ? application.aiLimit:10>

<cfquery name="qLimit" datasource="DSN">
    SELECT COUNT(*) AS adet 
    FROM AI 
    WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    AND islemTipi='kullanici_cozum'
    AND CAST(eklenmeTarihi AS DATE)=CAST(GETDATE() AS DATE)
</cfquery>

<cfif qLimit.adet GTE gunlukLimit>
    <cfoutput>{"basari":false,"hata":"Günlük AI limitine(#gunlukLimit#) ulaştınız."}</cfoutput>
    <cfabort>
</cfif>
<cfquery name="qOnBellek" datasource="DSN">
    SELECT TOP 1 cikti
    FROM AI 
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND islemTipi='kullanici_cozum'
    ORDER BY eklenmeTarihi DESC
</cfquery>

<cfif qOnBellek.recordCount GT 0>
    <cfset ai.logKaydetme(
        kullaniciID=val(SESSION.kullaniciID),
        soruID=soruID,
        islemTipi="kullanici_cozum",
        girdi="onbellekten",
        cikti=qOnBellek.cikti
    )>

    <cfoutput>{"basari":true,"metin":#serializeJSON(qOnBellek.cikti)#,"onbellek":true}</cfoutput>
    <cfabort>
</cfif>

<cfset prompt="Sen bir YKS uzmanısın. Sana gelen #qSoru.dersAd# sorusunu,ortalama bir lise öğrencisinin anlayabileceği sadelikte anlatmanı istiyorum. Cevap yazarken şu istenilenlerin dışına lütfen,çıkma.

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
    
    Doğru Cevap:#qSoru.dogruCevap# şıkkıdır.
    Açıklama:Bu cevabın neden doğru olduğunu istenilen şekilde belirt. Ayrıca diğer şıkların neden olamayacağına da kısaca değin.
    
    Uyarı:'Doğru Cevap' ve 'Açıklama' satırlarını asla atlamadan çözüm işlemini tamamla.
    Sana güveniyorum ve tüm bu sadece tüm bu söylediklerime bağlı kalarak müthiş bir iş çıkarabileceğine inanıyorum.">

<cfif len(trim(qSoru.soruResmi))>
    <cfset resimYolu=expandPath("/YKSSite/assets/images/sorular/#qSoru.soruResmi#")>
    <cfset sonuc=ai.resimCozme(
        resimYolu=resimYolu,
        prompt=prompt
    )>
<cfelse>
    <cfset soruMetniOzet= "Ders:#qSoru.dersAd##chr(10)#"
                    & "Soru:#qSoru.soruMetni##chr(10)#"
                    & "A)#qSoru.sikA##chr(10)#"
                    & "B)#qSoru.sikB##chr(10)#"
                    & "C)#qSoru.sikC##chr(10)#"
                    & "D)#qSoru.sikD##chr(10)#"
                    & "E)#qSoru.sikE##chr(10)#"
                    & prompt>
    
    <cfset sonuc=ai.metinUretme(
        prompt=soruMetniOzet,
        amac="cozum"
    )>
</cfif>

<cfif sonuc.basari>
    <cfset ai.logKaydetme(
        kullaniciID=val(SESSION.kullaniciID),
        soruID=soruID,
        islemTipi="kullanici_cozum",
        girdi=prompt,
        cikti=sonuc.metin
    )>

    <cfoutput>{"basari":true,"metin":#serializeJSON(sonuc.metin)#,"onbellek":false}</cfoutput>
<cfelse>
    <cfset ai.hataYazma(
        sayfa="/YKSSite/views/soru/aiCozdurme.cfm",
        islem="kullanici_cozum",
        mesaj="soruID:#soruID# | #sonuc.hata#",
        detay=sonuc.ham
    )>

    <cfoutput>{"basari":false,"hata":"Şu an çözüm üretilemiyor,lütfen tekrar deneyiniz."}</cfoutput>
</cfif>