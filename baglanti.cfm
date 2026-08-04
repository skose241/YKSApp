<!--- 
Datasource, application.cfc üzerinden tanımlandı. 

<cfset application.dsn="DSN">

<cfif NOT isDefined("application.dbBaglanti")>
    <cftry>
        <cfset application.dbBaglanti={
        datasource=application.dsn,
        username="sa",
        password="190327"
    }>
    <cfcatch type="any">
        <cflog file="hata" text="Veritabanı bağlantı hatası: #cfcatch.message#">
    </cfcatch>
    </cftry>
</cfif>