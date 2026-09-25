<cfcomponent output="false" displayname="Şifreleme Sınıfı">
    <cffunction name="sifreUretme" access="public" returntype="struct" output="false">
        <cfargument name="sifre" type="string" required="true">
        <cfargument name="tuz" type="string" required="false" default="">

        <cfset var kullanilanTuz=len(trim(arguments.tuz)) ? trim(arguments.tuz) : hash(createUUID() & getTickCount(),"SHA-256")>
        <cfset var sifreHash=hash(kullanilanTuz & arguments.sifre,"SHA-512")>

        <cfloop from="1" to="20000" index="i">
            <cfset sifreHash=hash(kullanilanTuz & sifreHash,"SHA-512")>
        </cfloop>

        <cfreturn {tuz=kullanilanTuz,hash=sifreHash,hashSurum=2}>
    </cffunction>

    <cffunction name="sifreDogrulama" access="public" returntype="boolean" output="false">
        <cfargument name="sifre" type="string" required="true">
        <cfargument name="sifreHash" type="string" required="true">
        <cfargument name="tuz" type="string" required="true">
        <cfargument name="hashSurum" type="numeric" required="true">

        <cfset var denenen="">
        <cfset var dogrulama=false>

        <cfif val(arguments.hashSurum) GTE 2>
            <cfset denenen=hash(arguments.tuz & arguments.sifre,"SHA-512")>

            <cfloop from="1" to="20000" index="i">
                <cfset denenen=hash(arguments.tuz & denenen,"SHA-512")>
            </cfloop>

            <cfset dogrulama=compare(denenen,arguments.sifreHash) EQ 0>
        <cfelse>
            <cfset dogrulama=compare(hash(arguments.sifre,"SHA-256"),arguments.sifreHash) EQ 0>
        </cfif>

        <cfreturn dogrulama>
    </cffunction>

    <cffunction name="cevapDogrulama" access="public" returntype="boolean" output="false">
        <cfargument name="cevap" type="string" required="true">
        <cfargument name="cevapHash" type="string" required="true">
        <cfargument name="tuz" type="string" required="true">

        <cfset var denenen={}>

        <cfif len(trim(arguments.tuz))>
            <cfset denenen=sifreUretme(sifre=arguments.cevap,tuz=arguments.tuz)>

            <cfif compare(denenen.hash,arguments.cevapHash) EQ 0>
                <cfreturn true>
            </cfif>
        </cfif>

        <cfreturn compare(hash(arguments.cevap,"SHA-256"),arguments.cevapHash) EQ 0>
    </cffunction>
</cfcomponent>