<cfcomponent output="false">
    <cfset this.name="YKSSite.APP">

    <cfset this.datasource="DSN">
    <cfset this.sessionManagement=true>
    <cfset this.sessionTimeOut=createTimespan(0,2,0,0)>
    <cfset this.clientManagement=false>

    <cffunction name="onApplicationStart" returntype="boolean" output="false">
        <cfset application.DSN="DSN">
        <cfset application.avatarURL="https://ui-avatars.com/api/?background=random&color=fff&size=64&bold=true&name=">

        <cfreturn true>
    </cffunction>

    <cffunction name="onRequestStart" returntype="boolean" output="false">
        <cfargument name="targetPage" type="string" required="true">
        
        <cfif NOT isDefined("SESSION.kullaniciID")>
            <cfif isDefined("cookie.beniHatirla") AND cookie.beniHatirla NEQ "">
                <cfquery name="qOturum" datasource="DSN">
                    SELECT k.id,k.ad,k.rol,k.xp
                    FROM Oturum o
                    INNER JOIN Kullanici k ON k.id=o.kullaniciID
                    WHERE o.sessionToken =<cfqueryparam value="#cookie.beniHatirla#" cfsqltype="cf_sql_varchar">
                    AND o.aktiflik=1
                    AND k.aktiflik=1
                </cfquery>

                <cfif qOturum.recordCount>
                    <cfset SESSION.kullaniciID=qOturum.id>
                    <cfset SESSION.kullaniciAd=qOturum.ad>
                    <cfset SESSION.rol=qOturum.rol>
                    <cfset SESSION.xp=qOturum.xp>

                    <cfquery datasource="DSN">
                        UPDATE Oturum
                        SET sonGoruldu=<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
                        WHERE sessionToken=<cfqueryparam value="#cookie.beniHatirla#" cfsqltype="varchar">
                    </cfquery>
                </cfif>
            </cfif>
        </cfif>

        <cfreturn true>
    </cffunction>

    <cffunction name="onSessionEnd" returntype="void" output="false">
        <cfargument name="sessionScope" required="true">
        <cfargument name="appScope" required="false">
    </cffunction>

    <cffunction name="onError" returntype="void" output="false">
        <cfargument name="exception" required="true">
        <cfargument name="eventName" type="string" required="true">

        <cflog file="yksHata" text="#arguments.exception.message#">

        <cfdump var="#arguments.exception#">
        <cfabort>
    </cffunction>
</cfcomponent>