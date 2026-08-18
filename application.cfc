<cfcomponent output="false">
    <cfset this.name="YKSSite.APP">

    <cfset this.datasource="DSN">
    <cfset this.sessionManagement=true>
    <cfset this.sessionTimeOut=createTimespan(0,2,0,0)>
    <cfset this.clientManagement=false>
    <cfset this.setClientCookies=true>
    <cfset this.sessionCookie.httpOnly=true>
    <cfset this.sessionCookie.secure=false>
    <cfset this.scriptProtect="all">

    <cffunction name="envDegeri" access="private" returntype="string" output="false">
        <cfargument name="ad" type="string" required="true">

        <cfset var env=server.system.environment>
        <cfset var k="">

        <cfloop collection="#env#" item="k">
            <cfif compareNoCase(trim(k),trim(arguments.ad)) EQ 0>
                <cfreturn trim(env[k])>
            </cfif>
        </cfloop>

        <cflog file="yksHata" type="warning" text="Ortam değişkeni bulunamadı:#arguments.ad#">

        <cfreturn "">
    </cffunction>

    <cffunction name="onApplicationStart" returntype="boolean" output="false">
        <cfset application.DSN="DSN">
        <cfset application.avatarURL="https://ui-avatars.com/api/?background=random&color=fff&size=64&bold=true&name=">

        <cfset application.geminiSoruKey=envDegeri("GEMINI_API_KEY_Soru")>
        <cfset application.geminiCozumKey=envDegeri("GEMINI_API_KEY_Cozum")>
        <cfset application.uretimToken=envDegeri("YKS_URETIM_TOKEN")>

        <cfset application.geminiURL="https://generativelanguage.googleapis.com/v1beta/interactions">

        <cfset application.aiLimit=5>
        <cfset application.aiKullaniciID=1>

        <cfreturn true>
    </cffunction>

    <cffunction name="onRequestStart" returntype="boolean" output="false">
        <cfargument name="targetPage" type="string" required="true">

        <cfif NOT structKeyExists(SESSION,"kullaniciID") AND structKeyExists(COOKIE,"beniHatirla") AND len(trim(COOKIE.beniHatirla))>
            <cfquery name="qOturum" datasource="#application.DSN#">
                SELECT k.id,k.ad,k.rol,k.xp
                FROM Oturum o
                INNER JOIN Kullanici k ON k.id=o.kullaniciID
                WHERE o.sessionToken=<cfqueryparam value="#COOKIE.beniHatirla#" cfsqltype="cf_sql_varchar">
                AND o.aktiflik=1
                AND k.aktiflik=1
                AND o.girisTarihi>DATEADD(DAY,-30,GETDATE())
            </cfquery>

            <cfif qOturum.recordCount>
                <cfset sessionRotate()>

                <cfset SESSION.kullaniciID=val(qOturum.id)>
                <cfset SESSION.kullaniciAd=qOturum.ad>
                <cfset SESSION.rol=val(qOturum.rol)>
                <cfset SESSION.xp=val(qOturum.xp)>

                <cfquery datasource="#application.DSN#">
                    UPDATE Oturum
                    SET sonGoruldu=<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
                    WHERE sessionToken=<cfqueryparam value="#COOKIE.beniHatirla#" cfsqltype="cf_sql_varchar">
                    AND aktiflik=1
                </cfquery>
            <cfelse>
                <cfcookie name="beniHatirla" value="" expires="now">
            </cfif>
        </cfif>

        <cfreturn true>
    </cffunction>

    <cffunction name="onSessionEnd" returntype="void" output="false">
        <cfargument name="sessionScope" required="true">
        <cfargument name="appScope" required="false">
    </cffunction>

    <cffunction name="onError" returntype="void" output="true">
        <cfargument name="exception" required="true">
        <cfargument name="eventName" type="string" required="false" default="">

        <cflog file="yksHata" type="error"
            text="#arguments.eventName# | #cgi.script_name# | #arguments.exception.message# | #arguments.exception.detail#">

        <cftry>
            <cfquery datasource="#application.DSN#">
                INSERT INTO HataLog(sayfa,islem,mesaj,detay,eklenmeTarihi)
                VALUES(
                    <cfqueryparam value="#left(cgi.script_name,100)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#left('onError:' & arguments.eventName,100)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#left(arguments.exception.message,3000)#" cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#left(arguments.exception.detail,8000)#" cfsqltype="cf_sql_longvarchar">,
                    GETDATE()
                )
            </cfquery>

            <cfcatch type="any"></cfcatch>
        </cftry>

        <cfoutput>
            <!DOCTYPE HTML>
            <html lang="tr">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width,initial-scale=1.0">
                    <title>Hata</title>
                    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
                </head>

                <body>
                    <div class="container mt-5">
                        <div class="row justify-content-center">
                            <div class="col-md-6">
                                <div class="alert alert-danger text-center">
                                    <h4>Bir hata oluştu</h4>
                                    <p class="mb-3">Lütfen daha sonra tekrar deneyiniz.</p>
                                    <a href="/YKSSite/anaSayfa.cfm" class="btn btn-dark btn-sm">Ana Sayfaya Dön</a>
                                </div>
                            </div>
                        </div>
                    </div>
                </body>
            </html>
        </cfoutput>
    </cffunction>
</cfcomponent>