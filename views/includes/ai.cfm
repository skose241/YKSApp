<cffunction name="metinUretme" returntype="struct" output="false">
    <cfargument name="prompt" type="string" required="true">

    <cfset local.sonuc={basari=false,metin="",hata=""}>

    <cftry>
        <cfset local.istek={
            "contents":[{
                "parts":[{
                    "text":arguments.prompt
                }]
            }],
            "generationConfig":{
                "temperature":0.7,
                "maxOutputTokens":1000
            }
        }>

        <cfhttp method="POST" 
                url="#application.geminiURL#?key=#application.geminiKey#"
                result="local.cevap"
                timeout="60">
            <cfhttpparam type="header" name="Content-Type" value="application/json">
            <cfhttpparam type="body" value="#serializeJSON(local.istek)#">
        </cfhttp>

        <cfif local.cevap.statusCode EQ "200 OK">
            <cfset local.json=deserializeJSON(local.cevap.fileContent)>
            <cfset local.sonuc.metin=local.json.candidates[1].Content.parts[1].text>
            <cfset local.sonuc.basari=true>
        <cfelse>
            <cfset local.sonuc.hata="API Hatası:#local.cevap.statusCode#">
        </cfif>

        <cfcatch type="any">
            <cfset local.sonuc.hata="Bağlantı Hatası:#cfcatch.message#">
        </cfcatch>
    </cftry>

    <cfreturn local.sonuc>
</cffunction>

<cffunction name="resimCozme" returntype="struct" output="false">
    <cfargument name="resimYolu" type="string" required="true">
    <cfargument name="prompt" type="string" required="true">

    <cfset local.sonuc={basari=false,metin="",hata=""}>

    <cftry>
        <cffile action="readbinary"
                file="#arguments.resimYolu#"
                variable="local.resimData">

        <cfset local.base64=toBase64(local.resimData)>
        <cfset local.uzanti=lCase(listLast(arguments.resimYolu,"."))>
        <cfset local.mime=local.uzanti EQ "jpg" OR local.uzanti EQ "jpeg" ? "image/jpeg":"image/png">
        
        <cfset local.istek={
            "contents":[{
                "parts":[
                    {"text":arguments.prompt},
                    {
                        "inlineData":{
                            "mimeType":local.mime,
                            "data":local.base64
                        }
                    }
                ]
            }],
            "generationConfig":{
                "temperature":0.3,
                "maxOutputTokens":1500
            }
        }>

        <cfhttp method="POST"
                url="#application.geminiURL#?key=#application.geminiKey#"
                result="local.cevap"
                timeout="120">
            <cfhttpparam type="header" name="Content-Type" value="application/json">
            <cfhttpparam type="body" value="#serializeJSON(local.istek)#">
        </cfhttp>

        <cfif local.cevap.statusCode EQ "200 OK">
            <cfset local.json=deserializeJSON(local.cevap.fileContent)>
            <cfset local.sonuc.metin=local.json.candidates[1].Content.parts[1].text>
            <cfset local.sonuc.basari=true>
        <cfelse>
            <cfset local.sonuc.hata="API Hatası:#local.cevap.statusCode#">
        </cfif>

        <cfcatch type="any">
            <cfset local.sonuc.hata="Bağlantı Hatası:#cfcatch.message#">
        </cfcatch>
    </cftry>

    <cfreturn local.sonuc>
</cffunction>

<cffunction name="logKaydetme" returntype="void" output="false">
    <cfargument name="kullaniciID" type="numeric" required="true">
    <cfargument name="soruID" type="numeric" required="false" default="0">
    <cfargument name="islemTipi" type="string" required="true">
    <cfargument name="girdi" type="string" required="true">
    <cfargument name="cikti" type="string" required="true">

    <cfquery datasource="DSN">
        INSERT INTO AI(kullaniciID,soruID,islemTipi,girdi,cikti,model,eklenmeTarihi)
        VALUES(
            <cfqueryparam value="#arguments.kullaniciID#" cfsqltype="cf_sql_integer">,
            <cfif arguments.soruID GT 0>
                <cfqueryparam value="#arguments.soruID#" cfsqltype="cf_sql_integer">,
            <cfelse>
                NULL,
            </cfif>
            <cfqueryparam value="#arguments.islemTipi#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#left(arguments.girdi,4000)#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#left(arguments.cikti,4000)#" cfsqltype="cf_sql_varchar">,
            'gemini-3.5-flash',
            GETDATE()
        )
    </cfquery>
</cffunction>