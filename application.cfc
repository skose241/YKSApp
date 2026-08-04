<cfcomponent output="false">
    <cfset this.name="YKSSite.APP">

    <cfset this.datasource="DSN">
    <cfset this.sessionManagement=true>
    <cfset this.sessionTimeOut=createTimespan(0,2,0,0)>
    <cfset this.clientManagement=false>

    <cffunction name="onApplicationStart" returntype="boolean" output="false">
        <cfset application.DSN="DSN">
        <cfset application.sitAdi="YKS Platform">

        <cfreturn true>
    </cffunction>

    <cffunction name="onRequesStart" returntype="boolean" output="false">
        <cfargument name="targetPage" type="string" required="true">
        
        <cfif NOT isDefined("SESSION.kullaniciID")>
            <cfif isDefined("cookie.beniHatirla") AND cookie.beniHatirla NEQ "">
                <cfquery name="qOturum" datasource="DSN">
                    SELECT k.id,k.ad,k.rol,k.avatarID,k.xp
                    FROM Oturum o
                    INNER JOIN Kullanici k ON k.id=o.kullaniciID
                    WHERE o.sessionToken =<cfqueryparam value="#cookie.beniHatirla#" cfsqltype="varchar">
                    AND o.aktiflik=1
                    AND k.aktiflik=1
                </cfquery>

                <cfif qOturum.recordCount>
                    <cfset SESSION.kullaniciID=qOturum.id>
                    <cfset SESSION.kullaniciAd=qOturum.ad>
                    <cfset SESSION.rol=qOturum.rol>
                    <cfset SESSION.avatarID=qOturum.avatarID>
                    <cfset SESSION.xp=qOturum.xp>

                    <cfquery datasource="DSN">
                        UPDATE Oturum
                        SET sonGoruldu
                    </cfquery>
                </cfif>
            </cfif>
        </cfif>
    </cffunction>
</cfcomponent>