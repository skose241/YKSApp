<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif NOT structKeyExists(url,"hedefTip") OR NOT structKeyExists(url,"hedefID") OR NOT isNumeric(url.hedefID)>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset hedefTip=trim(url.hedefTip)>
<cfset hedefID=val(url.hedefID)>

<cfif NOT listFind("soru,cevap,yorum,kullanici",hedefTip)>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
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
<cfif listFind("soru,cevap",hedefTip)>
    <cfset sebep="Yanlış Cevap,Okunmaz Görsel,Yanlış Kategori,Mükerrer Soru,Telif İhlali,Spam/Reklam,Diğer">
<cfelseif hedefTip EQ "yorum">
    <cfset sebep="Argo/Hakaret,Spam/reklam,Konu Dışı,Tehdit/Taciz,Diğer">
<cfelseif hedefTip EQ "kullanici">
    <cfset sebep="Uygunsuz İsim,Spam/Reklam,Hakaret/Tehdit,Bot Hesap,Diğer">
</cfif>

<cfparam name="hata" default="">
<cfparam name="basari" default="">

<cfif NOT sikayet AND structKeyExists(form,"sikayetGonder")>
    <cfset neden=trim(form.neden)>
    <cfset aciklama=trim(form.aciklama)>

    <cfif sebep EQ "">
        <cfset hata="Lütfen bir sebep seçiniz.">
    <cfelseif NOT listFind(sebep,neden)>
        <cfset hata="Geçersiz sebep seçimi.">
    <cfelse>
        <cfquery datasource="DSN">
            INSERT INTO Sikayet(sikayetciID,hedefTip,hedefID,sebep,durum,tarih)
            VALUES(
                <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#hedefTip#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#neden##aciklama NEQ '' ? '-' & aciklama:''#" cfsqltype="cf_sql_varchar">,
                0,
                GETDATE()
            )
        </cfquery>

        <cfset basari="Şikayetiniz alındı,moderatörler tarafından incelenecektir.">
        <cfset sikayet=true>
    </cfif>
</cfif>

<cfoutput>
    <div class="container mt-4">
        <div class="row justify-content-center">
            <div class="col-md-6">
                <div class="card shadow">
                    <div class="card-header bg-dark text-white">
                        <h5 class="mb-0"><i class="bi bi-flag"></i>Şikayet Et</h5>
                    </div>

                    <div class="card-body">
                        <div class="alert alert-secondary mb-3">
                            <small>
                                <strong>Şikayet Edilen:</strong>
                                #hedefTip EQ 'soru' ? 'Soru':
                                hedefTip EQ 'cevap' ? 'Cevap':
                                hedefTip EQ 'yorum' ? 'Yorum':'Kullanıcı'#
                                #hedefID#
                            </small>
                        </div>

                        <cfif hata NEQ "">
                            <div class="alert alert-danger">
                                <i class="bi bi-exclamation-circle"></i>#hata#
                            </div>
                        </cfif>

                        <cfif basari NEQ "">
                            <div class="alert alert-success">
                                <i class="bi bi-check-circle"></i>#basari#
                            </div>
                        </cfif>

                        <cfif sikayet AND basari EQ "">
                            <div class="alert alert-warning">
                                <i class="bi bi-exclamation-triangle"></i>
                                Bu içeriği daha önceden şikayet ettiniz.
                            </div>
                        </cfif>

                        <cfif NOT sikayet>
                            <form method="POST">
                                <div class="mb-3">
                                    <label class="form-label">Şikayet Sebebi:</label>
                                    <select name="neden" class="form-select" required>
                                        <option value="">Sebep Seçiniz.</option>
                                        <cfloop list="#sebep#" index="s">
                                            <option value="#s#">#s#</option>
                                        </cfloop>
                                    </select>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label">
                                        Açıklama:
                                        <small class="text-muted">(isteğe bağlı)</small>
                                    </label>

                                    <textarea name="aciklama" class="form-control" rows="3" maxlength="200" placeholder="Eklemek istediğiniz bir şey varsa yazabilirsiniz."></textarea>
                                    <small class="text-muted">Maksimum 200 karakter</small>
                                </div>

                                <div class="d-grid">
                                    <button type="submit" name="sikayetGonder" value="1" class="btn btn-danger">
                                        <i class="bi bi-flag"></i>Şikayeti Gönder
                                    </button>
                                </div>
                            </form>
                        </cfif>

                        <div class="text-center mt-3">
                            <a href="javascript:history.back()" class="text-muted small">
                                <i class="bi bi-arrow-left"></i>Geri Dön
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">