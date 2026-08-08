<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif NOT structKeyExists(url,"id") OR NOT isNumeric(url.id)>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset soruID=val(url.id)>

<cfquery name="qSoru" datasource="DSN">
    SELECT s.id,s.soruResmi,s.dogruCevap,s.goruntulenmeSayisi,s.eklenmeTarihi,
        d.ad AS dersAd,a.ad AS alanAd,k.ad AS soranAd
    FROM Soru s 
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    INNER JOIN Kullanici k ON k.id=s.soranID
    WHERE s.id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND s.aktiflik=1
</cfquery>

<cfif qSoru.recordCount EQ 0>
    <cflocation url="/YKSSite/anaSayfa.cfm">
</cfif>

<cfquery datasource="DSN">
    UPDATE Soru
    SET goruntulenmeSayisi=goruntulenmeSayisi+1
    WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
</cfquery>

<cfquery name="qKontrol" datasource="DSN">
    SELECT id,kullaniciCevabi,onay 
    FROM Cevap 
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND cozenID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
</cfquery>
<cfset cevapKontrol=qKontrol.recordCount GT 0>

<cfquery name="qFavori" datasource="DSN">
    SELECT id 
    FROM Favori 
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
</cfquery>
<cfset favoriKontrol=qFavori.recordCount GT 0>

<cfquery name="qCevaplar" datasource="DSN">
    SELECT c.id,c.cozumMetni,c.cozumResmi,c.onay,c.eklenmeTarihi,
        k.ad AS cozenAd,
        (SELECT COUNT(*) FROM Begeni b WHERE b.hedefID=c.id AND b.hedefTip='cevap') AS begeniSayisi
    FROM Cevap c 
    INNER JOIN Kullanici k ON k.id=c.cozenID
    WHERE c.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    ORDER BY C.eklenmeTarihi ASC
</cfquery>

<script>
    function yorumlariGoster(cevapID){
        const div=document.getElementById('yorumlar_'+cevapID);
        div.classList.toggle('d-none');
    }
</script>

<cfparam name="hata" default="">
<cfparam name="basari" default="">

<cfif structKeyExists(form,"cevapGonder") AND NOT cevapKontrol>
    <cfset kullaniciCevabi=trim(form.kullaniciCevabi)>
    <cfset cozumMetni=trim(form.cozumMetni)>

    <cfif NOT listFind("A,B,C,D,E",kullaniciCevabi)>
        <cfset hata="Lütfen bir şık seçiniz.">
    <cfelse>
        <cfset dogruMu=kullaniciCevabi EQ qSoru.dogruCevap ? 1:0>
        <cfquery datasource="DSN">
            INSERT INTO Cevap(soruID,cozenID,kullaniciCevabi,cozumMetni,onay,eklenmeTarihi)
            VALUES(
                <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#kullaniciCevabi#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#cozumMetni#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#dogruMu#" cfsqltype="cf_sql_integer">,
                GETDATE()
            )
        </cfquery>

        <cfset puan=dogruMu ? 10:2>
        <cfquery datasource="DSN">
            INSERT INTO Puan(kullaniciID,islemTipi,puanDegeri,referansID,referansTip,eklenmeTarihi)
            VALUES(
                <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#dogruMu ? 'dogru_cevap':'yanlis_cevap'#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#puan#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
                'soru',
                GETDATE()
            )
        </cfquery>

        <cfquery datasource="DSN">
            UPDATE Kullanici 
            SET xp=xp+#puan#
            WHERE id=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfset SESSION.xp=SESSION.xp+puan>

        <cfset cevapKontrol=true>
        <cfset basari=dogruMu ? "Tebrikler,doğru çözdünüz!":"Maalesef,çözümünüzü kontrol ediniz! Doğru Cevap=#qSoru.dogruCevap#">

        <cfquery name="qKontrol" datasource="DSN">
            SELECT id,kullaniciCevabi,onay 
            FROM Cevap 
            WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
            AND cozenID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfquery name="qCevaplar" datasource="DSN">
            SELECT c.id,c.cozumMetni,c.cozumResmi,c.onay,c.eklenmeTarihi,
                k.ad AS cozenAd,
                (SELECT COUNT(*) FROM Begeni b WHERE b.hedefID=c.id AND b.hedefTip='cevap') AS begeniSayisi
            FROM Cevap c 
            INNER JOIN Kullanici k ON k.id=c.cozenID
            WHERE c.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
            ORDER BY C.eklenmeTarihi ASC
        </cfquery>
    </cfif>
</cfif>

<cfoutput>
    <div class="container mt-4">
        <div class="row">
            <div class="col-md-8">
                <div class="card shadow mb-4">
                    <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center">
                        <div>
                            <span class="badge bg-secondary">#qSoru.alanAd#</span>
                            <span class="badge bg-light text-dark">#qSoru.dersAd#</span>
                        </div>

                        <small><i class="bi bi-eye"></i>#qSoru.goruntulenmeSayisi#</small>
                    </div>

                    <div class="card-body text-center">
                        <img src="/YKSSite/assets/images/sorular/#qSoru.soruResmi#" 
                            class="img-fluid rounded" style="max-height:500px;">
                    </div>

                    <div class="card-footer d-flex justify-content-between align-items-center">
                        <div class="d-flex align-items-center gap-2">
                            <img src="https://ui-avatars.com/api/?background=random&color=fff&size=32&bold=true&name=#qSoru.soranAd#"
                                class="rounded-circle" width="28" height="28">
                            <small class="text-muted">#qSoru.soranAd# . #dateFormat(qSoru.eklenmeTarihi,'dd.mm.yyyy')#</small>
                        </div>

                        <a href="/YKSSite/views/soru/favoriToggle.cfm?soruID=#soruID#&geri=#urlEncodedFormat(cgi.SCRIPT_NAME & '?' & cgi.QUERY_STRING)#"
                            class="btn btn-sm #favoriKontrol ? 'btn-danger':'btn-outline-danger'#">
                            <i class="bi bi-heart#favoriKontrol ? '-fill':''#"></i>
                            #favoriKontrol ? 'Favoriden Çıkar':'Favoriye Ekle'#
                        </a>
                    </div>
                </div>

                <cfif hata NEQ "">
                    <div class="alert alert-danger">
                        <i class="bi bi-exclamation-circle"></i>#hata#
                    </div>
                </cfif>

                <cfif basari NEQ "">
                    <div class="alert alert-success">
                        <i class="bi bi-#dogruMu ? 'check':'x'#-circle"></i>#basari#
                    </div>
                </cfif>

                <cfif NOT cevapKontrol>
                    <div class="card mb-4">
                        <div class="card-header bg-dark text-white">
                            <i class="bi bi-pencil"></i>Cevabınızı seçiniz.
                        </div>

                        <div class="card-body">
                            <form method="POST">
                                <div class="mb-3">
                                    <label class="form-label">Şıkkınız:</label>
                                    <div class="d-flex gap-2">
                                        <cfloop list="A,B,C,D,E" index="sik">
                                            <input type="radio" class="btn-check" name="kullaniciCevabi" id="cv#sik#" value="#sik#" required>
                                            <label class="btn btn-outline-dark" for="cv#sik#">#sik#</label>
                                        </cfloop>
                                    </div>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label">Çözüm Açıklaması:<small class="text-muted">(isteğe bağlı)</small></label>
                                    <textarea name="cozumMetni" class="form-control" rows="4" placeholder="Çözümünüzü açıklamak isterseniz buraya yazabilirsiniz."></textarea>
                                </div>

                                <div class="d-grid">
                                    <button type="submit" name="cevapGonder" value="1" class="btn btn-dark">
                                        <i class="bi bi-send"></i>Cevabı Paylaş
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                <cfelse>
                    <div class="alert #qKontrol.onay EQ 1 ? 'alert-success':'alert-danger'#">
                        <i class="bi bi-#qKontrol.onay EQ 1 ? 'check':'x'#-circle"></i>
                        Sizin Cevabınız:<strong>#qKontrol.kullaniciCevabi#</strong> - 
                        Doğru Cevap:<strong>#qSoru.dogruCevap#</strong>
                    </div>
                </cfif>

                <cfif qCevaplar.recordCount GT 0>
                    <h5 class="mb-3"><i class="bi bi-chat-left-text"></i>Çözümler(#qCevaplar.recordCount#)</h5>

                    <cfloop query="qCevaplar">
                        <div class="card mb-3">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <div class="align-items-center gap-2">
                                    <img src="https://ui-avatars.com/api/?background=random&color=fff&size=32&bold=true&name=#cozenAd#"
                                        class="rounded-circle" width="28" height="28">
                                    <strong>#cozenAd#</strong>
                                    <span class="badge #onay EQ 1 ? 'bg-success':onay EQ 0 ? 'bg-danger':'bg-secondary'#">
                                        #onay EQ 1 ? 'Doğru':onay EQ 0 ? 'Yanlış':'Belirsiz'#
                                    </span>
                                </div>

                                <small class="text-muted">#dateFormat(eklenmeTarihi,'dd.mm.yyyy')#</small>
                            </div>

                            <div class="card-body">
                                <cfif cozumMetni NEQ "">
                                    <p>#cozumMetni#</p>
                                </cfif>

                                <cfif cozumResmi NEQ "">
                                    <img src="/YKSSite/assets/images/cevaplar/#cozumResmi#"
                                        class="img-fluid rounded mb-2">
                                </cfif>

                                <div class="d-flex justify-content-between align-items-center mt-2">
                                    <a href="/YKSSite/views/soru/begeniToggle.cfm?hedefID=#id#&hedefTip=cevap&geri=#urlEncodedFormat(cgi.SCRIPT_NAME & '?' & cgi.QUERY_STRING)#"
                                        class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-hand-thumbs-up"></i>#begeniSayisi#
                                    </a>

                                    <button class="btn btn-sm btn-outline-primary" onclick="yorumlariGoster(#id#)">
                                        <i class="bi bi-chat"></i>Yorumlar
                                    </button>
                                </div>

                                <div id="yorumlar_#id#" class="mt-3 d-none">
                                    <cfquery name="qYorumlar" datasource="DSN">
                                        SELECT y.id,y.metin,y.eklenmeTarihi,k.ad AS yazar 
                                        FROM Yorum y
                                        INNER JOIN Kullanici k ON k.id=y.yazanID
                                        WHERE y.cevapID=<cfqueryparam value="#id#" cfsqltype="cf_sql_integer">
                                        AND y.aktiflik=1
                                        AND y.ustYorumID IS NULL
                                        ORDER BY y.eklenmeTarihi ASC
                                    </cfquery>

                                    <cfif qYorumlar.recordCount GT 0>
                                        <cfloop query="qYorumlar">
                                            <div class="d-flex gap-2 mb-2">
                                                <img src="https://ui-avatars.com/api/?background=random&color=fff&size=24&bold=true&name=#yazar#"
                                                    class="rounded-circle" width="24" height="24">
                                                <div class="bg-light rounded p-2 flex-grow-1">
                                                    <small class="fw-bold">#yazar#</small>
                                                    <p class="mb-0 small">#metin#</p>
                                                </div>
                                            </div>
                                        </cfloop>
                                    </cfif>

                                    <form method="POST" action="/YKSSite/views/soru/yorumEkle.cfm">
                                        <input type="hidden" name="cevapID" value="#id#">
                                        <input type="hidden" name="soruID" value="#soruID#">
                                        <div class="input-group mt-2">
                                            <input type="text" name="metin" class="form-control form-control-sm" placeholder="Yorum yazınız." required>
                                            <button type="submit" class="btn btn-dark btn-sm">
                                                <i class="bi bi-send"></i>Yorum Paylaş
                                            </button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </cfloop>
                </cfif>
            </div>

            <div class="col-md-4">
                <div class="card mb-3">
                    <div class="card-header bg-dark text-white">
                        <i class="bi bi-info-circle"></i>Soru Bilgisi
                    </div>

                    <div class="card-body">
                        <p class="mb-1"><strong>Alan:</strong>#qSoru.alanAd#</p>
                        <p class="mb-1"><strong>Ders:</strong>#qSoru.dersAd#</p>
                        <p class="mb-1"><strong>Soran:</strong>#qSoru.soranAd#</p>
                        <p class="mb-1"><strong>Tarih</strong>#dateFormat(qSoru.eklenmeTarihi,'dd.mm.yyyy')#</p>
                        <p class="mb-0"><strong>Görüntülenme:</strong>#qSoru.goruntulenmeSayisi#</p>
                    </div>
                </div>

                <div class="d-grid">
                    <a href="/YKSSite/views/sikayet/sikayetEkle.cfm?hedefTip=soru&hedefID=#soruID#" class="btn btn-outline-danger btn-sm">
                        <i class="bi bi-flag"></i>Şikayet Et
                    </a>
                </div>
            </div>
        </div>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">