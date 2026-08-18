<cfcomponent output="false" displayname="AI Asistan Sınıfı">
    <cfset variables.model="gemini-3.5-flash">

    <cffunction name="metinCekme" access="private" returntype="string" output="false">
        <cfargument name="json" type="any" required="true">

        <cfset var cikti="">

        <cfif NOT isStruct(arguments.json)>
            <cfreturn "">
        </cfif>

        <cfif structKeyExists(arguments.json,"steps") AND isArray(arguments.json.steps)>
            <cfloop array="#arguments.json.steps#" index="local.adim">
                <cfif isStruct(local.adim) AND structKeyExists(local.adim,"content") AND isArray(local.adim.content) AND NOT structKeyExists(local.adim,"signature")>
                    <cfloop array="#local.adim.content#" index="local.blok">
                        <cfif isStruct(local.blok) AND structKeyExists(local.blok,"text")>
                            <cfset cikti=cikti & local.blok.text>
                        </cfif>
                    </cfloop>
                </cfif>
            </cfloop>
        </cfif>

        <cfif NOT len(trim(cikti)) AND structKeyExists(arguments.json,"candidates") AND isArray(arguments.json.candidates)>
            <cfloop array="#arguments.json.candidates#" index="local.aday">
                <cfif isStruct(local.aday) AND structKeyExists(local.aday,"content") AND structKeyExists(local.aday.content,"parts") AND isArray(local.aday.content.parts)>
                    <cfloop array="#local.aday.content.parts#" index="local.blok">
                        <cfif isStruct(local.blok) AND structKeyExists(local.blok,"text")>
                            <cfset cikti=cikti & local.blok.text>
                        </cfif>
                    </cfloop>
                </cfif>
            </cfloop>
        </cfif>

        <cfreturn cikti>
    </cffunction>

    <cffunction name="govdeOkuma" access="private" returntype="string" output="false">
        <cfargument name="icerik" type="any" required="true">

        <cfset var ham=arguments.icerik>

        <cfif isBinary(ham)>
            <cfset ham=toString(ham,"UTF-8")>
        <cfelseif NOT isSimpleValue(ham)>
            <cfset ham=toString(ham)>
        </cfif>

        <cfreturn trim(ham)>
    </cffunction>

    <cffunction name="gemini" access="private" returntype="struct" output="false">
        <cfargument name="input" type="any" required="true">
        <cfargument name="amac" type="string" required="false" default="soru">
        <cfargument name="zamanAsimi" type="numeric" required="false" default="150">
        <cfargument name="yenidenDene" type="boolean" required="false" default="true">

        <cfset var sonuc={basari=false,metin="",hata="",ham=""}>

        <cftry>
            <cfif arguments.amac EQ "cozum">
                <cfset local.anahtar=structKeyExists(application,"geminiCozumKey") ? application.geminiCozumKey:"">
                <cfset local.anahtarAd="GEMINI_API_KEY_Cozum">
            <cfelse>
                <cfset local.anahtar=structKeyExists(application,"geminiSoruKey") ? application.geminiSoruKey:"">
                <cfset local.anahtarAd="GEMINI_API_KEY_Soru">
            </cfif>

            <cfif NOT len(trim(local.anahtar))>
                <cfset sonuc.hata="#local.anahtarAd# okunamadı. Lucee servisini yeniden başlatıp ?resetApp=TOKEN ile çalıştırınız.">
                <cfreturn sonuc>
            </cfif>

            <cfset local.istek={
                "model":variables.model,
                "input":arguments.input,
                "store":false
            }>

            <cfset local.govde=serializeJSON(local.istek)>

            <cfhttp method="POST"
                    url="#application.geminiURL#"
                    result="local.cevap"
                    charset="UTF-8"
                    throwonerror="false"
                    timeout="#arguments.zamanAsimi#">
                <cfhttpparam type="header" name="Api-Revision" value="2026-05-20">
                <cfhttpparam type="header" name="Content-Type" value="application/json; charset=UTF-8">
                <cfhttpparam type="header" name="x-goog-api-key" value="#local.anahtar#">
                <cfhttpparam type="header" name="Accept-Encoding" value="identity">
                <cfhttpparam type="header" name="Accept" value="application/json">
                <cfhttpparam type="body" value="#local.govde#">
            </cfhttp>

            <cfset sonuc.ham=govdeOkuma(local.cevap.fileContent)>

            <cfif val(local.cevap.statusCode) EQ 429 AND arguments.yenidenDene>
                <cfset local.bekle=35>

                <cfif reFind("retry in ([0-9]+)",sonuc.ham)>
                    <cfset local.bekle=val(reReplace(sonuc.ham,".*retry in ([0-9]+).*","\1"))+3>
                </cfif>

                <cfif local.bekle LTE 0 OR local.bekle GT 40>
                    <cfset local.bekle=35>
                </cfif>

                <cfset sleep(local.bekle*1000)>

                <cfhttp method="POST"
                        url="#application.geminiURL#"
                        result="local.cevap"
                        charset="UTF-8"
                        throwonerror="false"
                        timeout="#arguments.zamanAsimi#">
                    <cfhttpparam type="header" name="Api-Revision" value="2026-05-20">
                    <cfhttpparam type="header" name="Content-Type" value="application/json; charset=UTF-8">
                    <cfhttpparam type="header" name="x-goog-api-key" value="#local.anahtar#">
                    <cfhttpparam type="header" name="Accept-Encoding" value="identity">
                    <cfhttpparam type="header" name="Accept" value="application/json">
                    <cfhttpparam type="body" value="#local.govde#">
                </cfhttp>

                <cfset sonuc.ham=govdeOkuma(local.cevap.fileContent)>
            </cfif>

            <cfif val(local.cevap.statusCode) NEQ 200>
                <cfset sonuc.hata="API Hatası:#local.cevap.statusCode#"
                    & " | errorDetail:#structKeyExists(local.cevap,'errorDetail') ? local.cevap.errorDetail:''#"
                    & " | istek:#len(local.govde)# bayt"
                    & " | yanıt:#left(sonuc.ham,500)#">
                <cfreturn sonuc>
            </cfif>

            <cfif NOT isJSON(sonuc.ham)>
                <cfset sonuc.hata="Geçersiz JSON."
                    & " tip:#isBinary(local.cevap.fileContent) ? 'binary':'string'#"
                    & " | uzunluk:#len(sonuc.ham)#"
                    & " | mimetype:#structKeyExists(local.cevap,'mimetype') ? local.cevap.mimetype:''#"
                    & " | ilk200:#left(sonuc.ham,200)#">
                <cfreturn sonuc>
            </cfif>

            <cfset local.json=deserializeJSON(sonuc.ham)>
            <cfset sonuc.metin=trim(metinCekme(local.json))>
            <cfset sonuc.basari=len(sonuc.metin) GT 0>

            <cfif NOT sonuc.basari>
                <cfset sonuc.hata="Text bloğu bulunamadı.">
            </cfif>

            <cfcatch type="any">
                <cfset sonuc.basari=false>
                <cfset sonuc.hata="İstisna:#cfcatch.message# | #cfcatch.detail#">
            </cfcatch>
        </cftry>

        <cfreturn sonuc>
    </cffunction>

    <cffunction name="metinUretme" returntype="struct" output="false">
        <cfargument name="prompt" type="string" required="true">
        <cfargument name="amac" type="string" required="false" default="soru">
        <cfargument name="zamanAsimi" type="numeric" required="false" default="150">
        <cfargument name="yenidenDene" type="boolean" required="false" default="true">

        <cfreturn gemini(
            input=arguments.prompt,
            amac=arguments.amac,
            zamanAsimi=arguments.zamanAsimi,
            yenidenDene=arguments.yenidenDene
        )>
    </cffunction>

    <cffunction name="resimCozme" returntype="struct" output="false">
        <cfargument name="resimYolu" type="string" required="true">
        <cfargument name="prompt" type="string" required="true">
        <cfargument name="amac" type="string" required="false" default="cozum">
        <cfargument name="zamanAsimi" type="numeric" required="false" default="90">
        <cfargument name="yenidenDene" type="boolean" required="false" default="true">

        <cfset var sonuc={basari=false,metin="",hata="",ham=""}>

        <cftry>
            <cfif NOT fileExists(arguments.resimYolu)>
                <cfset sonuc.hata="Resim bulunamadı:#arguments.resimYolu#">
                <cfreturn sonuc>
            </cfif>

            <cfset local.gecici=getTempDirectory() & createUUID() & ".jpg">

            <cfimage action="read" source="#arguments.resimYolu#" name="local.img">

            <cfif imageGetWidth(local.img) GT 1024>
                <cfset imageResize(local.img,"1024","")>
            </cfif>

            <cfimage action="write" source="#local.img#" destination="#local.gecici#" quality="0.7" overwrite="true">

            <cffile action="readbinary" file="#local.gecici#" variable="local.resimData">
            <cfset local.base64=toBase64(local.resimData)>

            <cfset sonuc=gemini(
                input=[{
                    "type":"user_input",
                    "content":[
                        {"type":"image","mime_type":"image/jpeg","data":local.base64},
                        {"type":"text","text":arguments.prompt}
                    ]
                }],
                amac=arguments.amac,
                zamanAsimi=arguments.zamanAsimi,
                yenidenDene=arguments.yenidenDene
            )>

            <cfcatch type="any">
                <cfset sonuc.basari=false>
                <cfset sonuc.hata="Resim Hatası:#cfcatch.message# | #cfcatch.detail#">
            </cfcatch>
        </cftry>

        <cftry>
            <cfif structKeyExists(local,"gecici") AND fileExists(local.gecici)>
                <cffile action="delete" file="#local.gecici#">
            </cfif>

            <cfcatch type="any"></cfcatch>
        </cftry>

        <cfreturn sonuc>
    </cffunction>

    <cffunction name="hataYazma" returntype="void" output="false">
        <cfargument name="sayfa" type="string" required="true">
        <cfargument name="islem" type="string" required="true">
        <cfargument name="mesaj" type="string" required="true">
        <cfargument name="detay" type="string" required="false" default="">

        <cftry>
            <cfquery datasource="#application.DSN#">
                INSERT INTO HataLog(sayfa,islem,mesaj,detay,eklenmeTarihi)
                VALUES(
                    <cfqueryparam value="#left(arguments.sayfa,100)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#left(arguments.islem,100)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#left(arguments.mesaj,3000)#" cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#left(arguments.detay,8000)#" cfsqltype="cf_sql_longvarchar">,
                    GETDATE()
                )
            </cfquery>

            <cfcatch type="any">
                <cflog file="yksHata" type="error" text="hataYazma başarısız:#cfcatch.message#">
            </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="logKaydetme" returntype="void" output="false">
        <cfargument name="kullaniciID" type="numeric" required="true">
        <cfargument name="soruID" type="numeric" required="false" default="0">
        <cfargument name="islemTipi" type="string" required="true">
        <cfargument name="girdi" type="string" required="false" default="">
        <cfargument name="cikti" type="string" required="false" default="">

        <cftry>
            <cfquery datasource="#application.DSN#">
                INSERT INTO AI(kullaniciID,soruID,islemTipi,girdi,cikti,model,eklenmeTarihi)
                VALUES(
                    <cfqueryparam value="#arguments.kullaniciID#" cfsqltype="cf_sql_integer" null="#(arguments.kullaniciID EQ 0)#">,
                    <cfqueryparam value="#arguments.soruID#" cfsqltype="cf_sql_integer" null="#(arguments.soruID EQ 0)#">,
                    <cfqueryparam value="#left(arguments.islemTipi,50)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#left(arguments.girdi,2000)#" cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#arguments.cikti#" cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#variables.model#" cfsqltype="cf_sql_varchar">,
                    GETDATE()
                )
            </cfquery>

            <cfcatch type="any">
                <cfset hataYazma(
                    sayfa="/YKSSite/views/includes/ai.cfc",
                    islem="logKaydetme",
                    mesaj=cfcatch.message,
                    detay=cfcatch.detail
                )>
            </cfcatch>
        </cftry>
    </cffunction>
</cfcomponent>