<cfcomponent output="false" displayname="AI Asistan Sınıfı">
    <cfset variables.model="gemini-3.5-flash">

    <cffunction name="metinCekme" access="private" returntype="string" output="false">
        <cfargument name="json" type="any" required="true">

        <cfset var cikti="">

        <cfif NOT isStruct(arguments.json) OR NOT structKeyExists(arguments.json,"steps")>
            <cfreturn "">
        </cfif>

        <cfloop array="#arguments.json.steps#" index="local.adim">
            <cfif isStruct(local.adim) AND structKeyExists(local.adim,"content") AND NOT structKeyExists(local.adim,"signature")>
                <cfloop array="#local.adim.content#" index="local.blok">
                    <cfif isStruct(local.blok) AND structKeyExists(local.blok,"text")>
                        <cfset cikti=cikti&local.blok.text>
                    </cfif>
                </cfloop>
            </cfif>
        </cfloop>

        <cfreturn cikti>
    </cffunction>

    <cffunction name="gemini" access="private" returntype="struct" output="false">
        <cfargument name="input" type="any" required="true">
        <cfargument name="amac" type="string" required="false" default="soru">
        <cfargument name="zamanAsimi" type="numeric" required="false" default="150">

        <cfset var local={}>
        <cfset local.sonuc={basari=false,metin="",hata="",ham=""}>

        <cftry>
            <cfif arguments.amac EQ "cozum">
                <cfset local.anahtar=structKeyExists(application,"geminiCozumKey") ? application.geminiCozumKey:"">
                <cfset local.anahtarAd="GEMINI_API_KEY_Cozum">
            <cfelse>
                <cfset local.anahtar=structKeyExists(application,"geminiSoruKey") ? application.geminiSoruKey:"">
                <cfset local.anahtarAd="GEMINI_API_KEY_Soru">
            </cfif>

            <cfif NOT len(trim(local.anahtar))>
                <cfset local.sonuc.hata="#local.anahtarAd# okunamadı. Lucee servisini yeniden başlatın.">
                <cfreturn local.sonuc>
            </cfif>

            <cfset local.istek={
                "model":variables.model,
                "input":arguments.input
            }>

            <cfhttp method="POST"
                    url="#application.geminiURL#"
                    result="local.cevap"
                    charset="UTF-8"
                    timeout="#arguments.zamanAsimi#">
                <cfhttpparam type="header" name="Content-Type" value="application/json; charset=UTF-8">
                <cfhttpparam type="header" name="x-goog-api-key" value="#local.anahtar#">
                <cfhttpparam type="body" value="#serializeJSON(local.istek)#">
            </cfhttp>

            <cfset local.sonuc.ham=local.cevap.fileContent>

            <cfif val(local.cevap.statusCode) NEQ 200>
                <cfset local.sonuc.hata="API Hatası:#local.cevap.statusCode# - #left(local.cevap.fileContent,500)#">
                <cfreturn local.sonuc>
            </cfif>

            <cfset local.json=deserializeJSON(local.cevap.fileContent)>
            <cfset local.sonuc.metin=metinCekme(local.json)>
            <cfset local.sonuc.basari=len(trim(local.sonuc.metin)) GT 0>

            <cfif NOT local.sonuc.basari>
                <cfset local.sonuc.hata="Text bloğu bulunamadı.">
            </cfif>

            <cfcatch type="any">
                <cfset local.sonuc.hata="İstisna:#cfcatch.message# | #cfcatch.detail#">
            </cfcatch>
        </cftry>

        <cfreturn local.sonuc>
    </cffunction>

    <cffunction name="metinUretme" returntype="struct" output="false">
        <cfargument name="prompt" type="string" required="true">
        <cfargument name="amac" type="string" required="false" default="soru">

        <cfreturn gemini(input=arguments.prompt,amac=arguments.amac)>
    </cffunction>

    <cffunction name="resimCozme" returntype="struct" output="false">
        <cfargument name="resimYolu" type="string" required="true">
        <cfargument name="amac" type="string" required="false" default="cozum">
        <cfargument name="prompt" type="string" required="true">

        <cfset var local={}>
        <cfset local.sonuc={basari=false,metin="",hata="",ham=""}>

        <cftry>
            <cfif NOT fileExists(arguments.resimYolu)>
                <cfset local.sonuc.hata="Resim bulunamadı:#arguments.resimYolu#">

                <cfreturn local.sonuc>
            </cfif>


            <cffile action="readbinary"
                    file="#arguments.resimYolu#"
                    variable="local.resimData">

            <cfset local.base64=toBase64(local.resimData)>
            <cfset local.uzanti=lCase(listLast(arguments.resimYolu,"."))>

            <cfswitch expression="#local.uzanti#">
                <cfcase value="jpg,jpeg"><cfset local.mime="image/jpeg"></cfcase>
                <cfcase value="png"><cfset local.mime="image/png"></cfcase>
                <cfcase value="webp"><cfset local.mime="image/webp"></cfcase>
                <cfdefaultcase><cfset local.mime="image/jpeg"></cfdefaultcase>
            </cfswitch>

            <cfreturn gemini(
                input=[
                    {"type":"text","text":arguments.prompt},
                    {"type":"image","data":local.base64,"mime_type":local.mime}
                ],
                amac=arguments.amac,
                zamanAsimi=60
            )>

            <cfcatch type="any">
                <cfset local.sonuc.hata="Resim Hatası:#cfcatch.message#">
            </cfcatch>
        </cftry>
            
        <cfreturn local.sonuc>
    </cffunction>

    <cffunction name="hataYazma" returntype="void" output="false">
        <cfargument name="sayfa" type="string" required="true">
        <cfargument name="islem" type="string" required="true">
        <cfargument name="mesaj" type="string" required="true">
        <cfargument name="detay" type="string" required="false" default="">

        <cftry>
            <cfquery datasource="DSN">
                INSERT INTO HataLog(sayfa,islem,mesaj,detay,eklenmeTarihi)
                VALUES(
                    <cfqueryparam value="#arguments.sayfa#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.islem#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#left(arguments.mesaj,3000)#" cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#left(arguments.detay,8000)#" cfsqltype="cf_sql_longvarchar">,
                    GETDATE()
                )
            </cfquery>

            <cfcatch type="any">

            </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="logKaydetme" returntype="void" output="false">
        <cfargument name="kullaniciID" type="numeric" required="true">
        <cfargument name="soruID" type="numeric" required="false" default="0">
        <cfargument name="islemTipi" type="string" required="true">
        <cfargument name="girdi" type="string" required="true">
        <cfargument name="cikti" type="string" required="true">

        <cftry>
            <cfquery datasource="DSN">
                INSERT INTO AI(kullaniciID,soruID,islemTipi,girdi,cikti,model,eklenmeTarihi)
                VALUES(
                    <cfqueryparam value="#arguments.kullaniciID#" cfsqltype="cf_sql_integer" null="#(arguments.kullaniciID EQ 0)#">,
                    <cfqueryparam value="#arguments.soruID#" cfsqltype="cf_sql_integer" null="#(arguments.soruID EQ 0)#">,
                    <cfqueryparam value="#arguments.islemTipi#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.girdi#" cfsqltype="cf_sql_longvarchar">,
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