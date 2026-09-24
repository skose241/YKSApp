<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">
<cfinclude template="/YKSSite/views/includes/baslik.cfm">

<cfif NOT structKeyExists(url,"hedefTip") OR NOT structKeyExists(url,"hedefID") OR NOT isNumeric(url.hedefID) OR val(url.hedefID) LTE 0>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset hedefTip=lCase(trim(url.hedefTip))>
<cfset hedefID=val(url.hedefID)>

<cfif NOT listFind("soru,cevap,yorum,kullanici",hedefTip)>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfswitch expression="#hedefTip#">
    <cfcase value="soru">
        <cfquery name="qHedef" datasource="DSN">
            SELECT id,soranID AS sahipID
            FROM Soru
            WHERE id=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
            AND aktiflik=1
        </cfquery>
    </cfcase>

    <cfcase value="cevap">
        <cfquery name="qHedef" datasource="DSN">
            SELECT id,cozenID AS sahipID
            FROM Cevap
            WHERE id=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
            AND aktiflik=1
        </cfquery>
    </cfcase>

    <cfcase value="yorum">
        <cfquery name="qHedef" datasource="DSN">
            SELECT id,yazanID AS sahipID
            FROM Yorum
            WHERE id=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
            AND aktiflik=1
        </cfquery>
    </cfcase>

    <cfdefaultcase>
        <cfquery name="qHedef" datasource="DSN">
            SELECT id,id AS sahipID
            FROM Kullanici
            WHERE id=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
            AND aktiflik=1
        </cfquery>
    </cfdefaultcase>
</cfswitch>

<cfif qHedef.recordCount EQ 0>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfif val(qHedef.sahipID) EQ val(SESSION.kullaniciID)>
    <cfset kendiIcerik=true>
<cfelse>
    <cfset kendiIcerik=false>
</cfif>

<cfquery name="qKontrol" datasource="DSN">
    SELECT id
    FROM Sikayet
    WHERE sikayetciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    AND hedefID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
    AND hedefTip=<cfqueryparam value="#hedefTip#" cfsqltype="cf_sql_varchar">
</cfquery>

<cfset sikayet=qKontrol.recordCount GT 0>
<cfset sebep="">

<cfif hedefTip EQ "soru">
    <cfset sebep="Yanlış Cevap,Okunmaz Görsel,Yanlış Kategori,Mükerrer Soru,Telif İhlali,Spam/Reklam,Diğer">
<cfelseif hedefTip EQ "cevap">
    <cfset sebep="Yanlış Çözüm,Eksik/Yetersiz Çözüm,Okunmaz Görsel,Konu Dışı,Argo/Hakaret,Spam/Reklam,Diğer">
<cfelseif hedefTip EQ "yorum">
    <cfset sebep="Argo/Hakaret,Spam/Reklam,Konu Dışı,Tehdit/Taciz,Diğer">
<cfelseif hedefTip EQ "kullanici">
    <cfset sebep="Uygunsuz İsim,Spam/Reklam,Hakaret/Tehdit,Bot Hesap,Diğer">
</cfif>

<cfset hedefAd=hedefTip EQ 'soru' ? 'Soru':hedefTip EQ 'cevap' ? 'Çözüm':hedefTip EQ 'yorum' ? 'Yorum':'Kullanıcı'>

<cfparam name="hata" default="">
<cfparam name="basari" default="">

<cfif NOT sikayet AND NOT kendiIcerik AND structKeyExists(form,"sikayetGonder")>
    <cfparam name="form.neden" default="">
    <cfparam name="form.aciklama" default="">

    <cfset neden=trim(form.neden)>
    <cfset aciklama=left(trim(form.aciklama),200)>

    <cfquery name="qGunluk" datasource="DSN">
        SELECT COUNT(*) AS adet
        FROM Sikayet
        WHERE sikayetciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        AND CAST(tarih AS DATE)=CAST(GETDATE() AS DATE)
    </cfquery>

    <cfif sebep EQ "">
        <cfset hata="Lütfen şikayet sebebinizi seçiniz.">
    <cfelseif NOT listFind(sebep,neden)>
        <cfset hata="Geçersiz sebep seçimi.">
    <cfelseif qGunluk.adet GTE 20>
        <cfset hata="Günlük şikayet sınırına(20) ulaştınız.">
    <cfelse>
        <cftry>
            <cfset tamSebep=left(neden & (len(aciklama) ? "-" & aciklama:""),255)>

            <cfquery datasource="DSN">
                INSERT INTO Sikayet(sikayetciID,hedefTip,hedefID,sebep,durum,tarih)
                VALUES(
                    <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#hedefTip#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#tamSebep#" cfsqltype="cf_sql_varchar">,
                    0,
                    GETDATE()
                )
            </cfquery>

            <cfset basari="Şikayetiniz başarıyla alındı,moderatörler tarafından incelenecektir.">
            <cfset sikayet=true>

            <cfcatch type="any">
                <cfset hata="Şikayetiniz gönderilirken bir hata oluştu.">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfoutput>
    <div class="dar dar--genis">
        <section class="kart">
            <div class="kart__baslik">Şikayet Et</div>

            <div class="kart__govde">
                <p class="hedef-kutu">
                    <strong>Şikayet Edilen:</strong> #encodeForHTML(hedefAd)# <span class="veri">###hedefID#</span>
                </p>

                <cfif len(hata)>
                    <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hata)#</div>
                </cfif>

                <cfif len(basari)>
                    <div class="bildirim bildirim--basarili" role="status">#encodeForHTML(basari)#</div>
                </cfif>

                <cfif kendiIcerik>
                    <div class="bildirim" role="status">Kendi içeriğinizi şikayet edemezsiniz.</div>
                <cfelseif sikayet AND NOT len(basari)>
                    <div class="bildirim" role="status">Bu içeriği daha önce zaten daha önce şikayet ettiniz. Şikayetiniz moderatörler tarafından incelenmektedir.</div>
                </cfif>

                <cfif NOT sikayet AND NOT kendiIcerik>
                    <form method="POST" action="?hedefTip=#encodeForURL(hedefTip)#&hedefID=#hedefID#">
                        <div class="alan ust-bosluk">
                            <label for="neden">Şikayet Sebebiniz:</label>
                            
                            <select class="secim" name="neden" id="neden" required>
                                <option value="">Sebep Seçiniz:</option>
                                <cfloop list="#sebep#" index="s">
                                    <option value="#encodeForHTMLAttribute(s)#">#encodeForHTML(s)#</option>
                                </cfloop>
                            </select>
                        </div>

                        <div class="alan">
                            <label for="aciklama">Açıklama<span class="sessiz">(isteğe bağlı):</span></label>
                            <textarea class="girdi" name="aciklama" id="aciklama" rows="3" maxlength="200" placeholder="Eklemek istediğiniz bir şey varsa yazabilirsiniz."></textarea>
                            <span class="alan__ipucu">En fazla 200 karakter.</span>
                        </div>

                        <button class="dugme dugme--tehlike dugme--tam" type="submit" name="sikayetGonder" value="1">Şikayeti Gönder</button>
                    </form>
                </cfif>

                <p class="ayrac-metin">veya</p>

                <p class="sessiz" style="text-align:center"><a class="bag" href="javascript:history.back()">Geri Dön</a></p>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">