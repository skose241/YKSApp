<cfcomponent output="false" displayname="Güvenlik Sınıfı">
    <cffunction name="istemciIP" access="public" returntype="string" output="false">
        <cfset var basliklar=getHttpRequestData().headers>
        <cfif structKeyExists(basliklar,"CF-Connecting-IP") AND len(trim(basliklar["CF-Connecting-IP"]))>
            <cfreturn left(trim(basliklar["CF-Connecting-IP"]),50)>
        </cfif>
    
        <cfreturn left(cgi.remote_addr,50)>
    </cffunction>

    <cffunction name="denemeSiniriAsildi" access="public" returntype="boolean" output="false">
        <cfargument name="tur" type="string" required="true">
        <cfargument name="anahtar" type="string" required="true">
        <cfargument name="hesapSiniri" type="numeric" required="false" default="5">
        <cfargument name="ipSiniri" type="numeric" required="false" default="20">
        <cfargument name="dakika" type="numeric" required="false" default="15">
        <cfset var qDeneme="">
        
        <cfquery name="qDeneme" datasource="#application.DSN#">
            SELECT
            (SELECT COUNT(*) FROM GirisDeneme
            WHERE tur=<cfqueryparam value="#left(arguments.tur,20)#" cfsqltype="cf_sql_varchar">
            AND anahtar=<cfqueryparam value="#left(arguments.anahtar,100)#" cfsqltype="cf_sql_varchar">
            AND tarih>=DATEADD(MINUTE,-<cfqueryparam value="#arguments.dakika#" cfsqltype="cf_sql_integer">,GETDATE())) AS hesapAdet,
            (SELECT COUNT(*) FROM GirisDeneme
            WHERE tur=<cfqueryparam value="#left(arguments.tur,20)#" cfsqltype="cf_sql_varchar">
            AND ip=<cfqueryparam value="#istemciIP()#" cfsqltype="cf_sql_varchar">
            AND tarih>=DATEADD(MINUTE,-<cfqueryparam value="#arguments.dakika#" cfsqltype="cf_sql_integer">,GETDATE())) AS ipAdet
        </cfquery>
        
        <cfreturn val(qDeneme.hesapAdet) GTE arguments.hesapSiniri OR val(qDeneme.ipAdet) GTE arguments.ipSiniri>
    </cffunction>
    
    <cffunction name="denemeKaydetme" access="public" returntype="void" output="false">
        <cfargument name="tur" type="string" required="true">
        <cfargument name="anahtar" type="string" required="true">
        <cfquery datasource="#application.DSN#">
            DELETE FROM GirisDeneme
            WHERE tarih<DATEADD(DAY,-1,GETDATE())
        </cfquery>
        
        <cfquery datasource="#application.DSN#">
            INSERT INTO GirisDeneme(tur,anahtar,ip,tarih)
            VALUES(
            <cfqueryparam value="#left(arguments.tur,20)#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#left(arguments.anahtar,100)#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#istemciIP()#" cfsqltype="cf_sql_varchar">,
            GETDATE()
            )
        </cfquery>
    </cffunction>

    <cffunction name="denemeTemizleme" access="public" returntype="void" output="false">
        <cfargument name="tur" type="string" required="true">
        <cfargument name="anahtar" type="string" required="true">
        
        <cfquery datasource="#application.DSN#">
            DELETE FROM GirisDeneme
            WHERE tur=<cfqueryparam value="#left(arguments.tur,20)#" cfsqltype="cf_sql_varchar">
            AND anahtar=<cfqueryparam value="#left(arguments.anahtar,100)#" cfsqltype="cf_sql_varchar">
        </cfquery>
    </cffunction>
</cfcomponent>