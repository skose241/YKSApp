<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfif NOT structKeyExists(url,"id") OR NOT isNumeric(url.id) OR val(url.id) LTE 0>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset soruID=val(url.id)>
<cfset kullaniciID=val(SESSION.kullaniciID)>

<cfparam name="hata" default="">
<cfparam name="basari" default="">
<cfparam name="dogruMu" default="0">
<cfparam name="cevapHata" default="">
<cfparam name="cevapBasari" default="">

<cfif structKeyExists(form,"cevapDuzelt") AND val(SESSION.rol) GTE 2>
    <cfparam name="form.yeniDogruCevap" default="">

    <cfset yeniCevap=uCase(trim(form.yeniDogruCevap))>

    <cfquery name="qEski" datasource="DSN">
        SELECT dogruCevap,sistemSoru
        FROM Soru
        WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
        AND aktiflik=1
    </cfquery>

    <cfif NOT listFind("A,B,C,D,E",yeniCevap)>
        <cfset cevapHata="Geçersiz şık.">
    <cfelseif qEski.recordCount EQ 0>
        <cfset cevapHata="Soru bulunamadı.">
    <cfelseif compareNoCase(yeniCevap,qEski.dogruCevap) EQ 0>
        <cfset cevapHata="Doğru cevap zaten #yeniCevap# olarak kayıtlı.">
    <cfelse>
        <cftry>
            <cftransaction>
                <cfquery name="qEtkilenen" datasource="DSN">
                    SELECT cozenID,kullaniciCevabi,onay
                    FROM Cevap
                    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                    AND kullaniciCevabi IS NOT NULL
                </cfquery>

                <cfquery datasource="DSN">
                    UPDATE k SET k.xp=k.xp+5
                    FROM Kullanici k
                    INNER JOIN Cevap c ON c.cozenID=k.id
                    WHERE c.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                    AND c.onay<>1
                    AND c.kullaniciCevabi=<cfqueryparam value="#yeniCevap#" cfsqltype="cf_sql_char">
                </cfquery>

                <cfquery datasource="DSN">
                    INSERT INTO Puan(kullaniciID,islemTipi,puanDegeri,referansID,referansTip,eklenmeTarihi)
                    SELECT c.cozenID,'dogru_cevap',5,c.soruID,'soru',GETDATE()
                    FROM Cevap c
                    WHERE c.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                    AND c.onay<>1
                    AND c.kullaniciCevabi=<cfqueryparam value="#yeniCevap#" cfsqltype="cf_sql_char">
                </cfquery>

                <cfquery datasource="DSN">
                    UPDATE k SET k.xp=CASE WHEN k.xp-5<0 THEN 0 ELSE k.xp-5 END
                    FROM Kullanici k
                    INNER JOIN Cevap c ON c.cozenID=k.id
                    WHERE c.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                    AND c.onay=1
                    AND c.kullaniciCevabi<><cfqueryparam value="#yeniCevap#" cfsqltype="cf_sql_char">
                </cfquery>

                <cfquery datasource="DSN">
                    DELETE p
                    FROM Puan p
                    INNER JOIN Cevap c ON c.cozenID=p.kullaniciID AND c.soruID=p.referansID
                    WHERE p.referansTip='soru'
                    AND p.islemTipi='dogru_cevap'
                    AND p.referansID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                    AND c.onay=1
                    AND c.kullaniciCevabi<><cfqueryparam value="#yeniCevap#" cfsqltype="cf_sql_char">
                </cfquery>

                <cfquery datasource="DSN">
                    UPDATE Cevap
                    SET onay=CASE WHEN kullaniciCevabi=<cfqueryparam value="#yeniCevap#" cfsqltype="cf_sql_char"> THEN 1 ELSE 0 END
                    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                    AND kullaniciCevabi IS NOT NULL
                </cfquery>

                <cfquery datasource="DSN">
                    UPDATE Soru
                    SET dogruCevap=<cfqueryparam value="#yeniCevap#" cfsqltype="cf_sql_char">
                    WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                </cfquery>

                <cfif qEski.sistemSoru EQ 1>
                    <cfquery datasource="DSN">
                        UPDATE Soru
                        SET aciklama=<cfqueryparam value="" cfsqltype="cf_sql_longvarchar">
                        WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                    </cfquery>
                </cfif>

                <cfquery datasource="DSN">
                    DELETE FROM AI
                    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                    AND islemTipi IN ('kullanici_cozum','kullanici_cozum_onbellek')
                </cfquery>

                <cfloop query="qEtkilenen">
                    <cfset yeniDurum=compareNoCase(trim(qEtkilenen.kullaniciCevabi),yeniCevap) EQ 0 ? 1:0>

                    <cfif val(qEtkilenen.onay) NEQ yeniDurum>
                        <cfquery datasource="DSN">
                            INSERT INTO Bildirim(kullaniciID,islemTipi,mesaj,goruldu,hedefURL,tarih)
                            VALUES(
                                <cfqueryparam value="#qEtkilenen.cozenID#" cfsqltype="cf_sql_integer">,
                                <cfqueryparam value="sistem" cfsqltype="cf_sql_varchar">,
                                <cfqueryparam value="#yeniDurum EQ 1 ? 'Çözdüğünüz bir sorunun cevap anahtarı düzeltildi, cevabınız doğru sayıldı.':'Çözdüğünüz bir sorunun cevap anahtarı düzeltildi, cevabınız yanlış olarak güncellendi.'#" cfsqltype="cf_sql_varchar">,
                                0,
                                <cfqueryparam value="/YKSSite/views/soru/soruDetay.cfm?id=#soruID#" cfsqltype="cf_sql_varchar">,
                                GETDATE()
                            )
                        </cfquery>
                    </cfif>
                </cfloop>

                <cfquery datasource="DSN">
                    UPDATE Sikayet SET durum=2
                    WHERE hedefTip='soru'
                    AND hedefID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                    AND durum=0
                </cfquery>
            </cftransaction>

            <cfset cevapBasari="Doğru cevap #qEski.dogruCevap# → #yeniCevap# olarak güncellendi. Kullanıcı cevapları ve puanları yeniden hesaplandı.">

            <cfquery name="qXP" datasource="DSN">
                SELECT xp FROM Kullanici
                WHERE id=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset SESSION.xp=val(qXP.xp)>

            <cfcatch type="any">
                <cfset cevapHata="Güncelleme sırasında hata oluştu.">
                <cfset aiHata=createObject("component","YKSSite.views.includes.ai")>
                <cfset aiHata.hataYazma(
                    sayfa="/YKSSite/views/soru/soruDetay.cfm",
                    islem="cevapDuzelt",
                    mesaj="soruID:#soruID# | #cfcatch.message#",
                    detay=cfcatch.detail
                )>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfquery name="qKontrol" datasource="DSN">
    SELECT id,kullaniciCevabi,onay
    FROM Cevap
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND cozenID=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
</cfquery>

<cfset cevapKontrol=qKontrol.recordCount GT 0>

<cfquery name="qSoru" datasource="DSN">
    SELECT s.id,s.soranID,s.soruResmi,s.soruMetni,
        s.sikA,s.sikB,s.sikC,s.sikD,s.sikE,s.aciklama,
        s.sistemSoru,s.dogruCevap,s.goruntulenmeSayisi,s.eklenmeTarihi,
        d.ad AS dersAd,a.ad AS alanAd,k.ad AS soranAd
    FROM Soru s
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    INNER JOIN Kullanici k ON k.id=s.soranID
    WHERE s.id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND s.aktiflik=1
</cfquery>

<cfif qSoru.recordCount EQ 0>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>

<cfif cgi.request_method NEQ "POST" AND qSoru.soranID NEQ kullaniciID>
    <cfquery datasource="DSN">
        UPDATE Soru
        SET goruntulenmeSayisi=goruntulenmeSayisi+1
        WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    </cfquery>
</cfif>

<cfquery name="qFavori" datasource="DSN">
    SELECT id
    FROM Favori
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND kullaniciID=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
</cfquery>

<cfset favoriKontrol=qFavori.recordCount GT 0>

<cfif structKeyExists(form,"cevapGonder") AND NOT cevapKontrol>
    <cfparam name="form.kullaniciCevabi" default="">
    <cfparam name="form.cozumMetni" default="">

    <cfset gelenCevap=uCase(trim(form.kullaniciCevabi))>
    <cfset gelenCozum=left(trim(form.cozumMetni),2000)>

    <cfif qSoru.soranID EQ kullaniciID>
        <cfset hata="Kendi sorunuzu çözemezsiniz.">
    <cfelseif NOT listFind("A,B,C,D,E",gelenCevap)>
        <cfset hata="Lütfen bir şık seçiniz.">
    <cfelse>
        <cfset dogruMu=compareNoCase(gelenCevap,qSoru.dogruCevap) EQ 0 ? 1:0>

        <cftry>
            <cftransaction>
                <cfquery datasource="DSN">
                    INSERT INTO Cevap(soruID,cozenID,kullaniciCevabi,cozumMetni,onay,aktiflik,eklenmeTarihi)
                    VALUES(
                        <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#gelenCevap#" cfsqltype="cf_sql_char">,
                        <cfqueryparam value="#gelenCozum#" cfsqltype="cf_sql_longvarchar">,
                        <cfqueryparam value="#dogruMu#" cfsqltype="cf_sql_integer">,
                        1,
                        GETDATE()
                    )
                </cfquery>

                <cfif dogruMu EQ 1>
                    <cfquery datasource="DSN">
                        INSERT INTO Puan(kullaniciID,islemTipi,puanDegeri,referansID,referansTip,eklenmeTarihi)
                        VALUES(
                            <cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="dogru_cevap" cfsqltype="cf_sql_varchar">,
                            5,
                            <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="soru" cfsqltype="cf_sql_varchar">,
                            GETDATE()
                        )
                    </cfquery>

                    <cfquery datasource="DSN">
                        UPDATE Kullanici SET xp=xp+5
                        WHERE id=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
                    </cfquery>
                </cfif>
            </cftransaction>

            <cfif dogruMu EQ 1>
                <cfset SESSION.xp=val(SESSION.xp)+5>
            </cfif>

            <cfset cevapKontrol=true>
            <cfset basari=dogruMu ? "Tebrikler,doğru çözdünüz! (+5 XP)":"Maalesef,çözümünüzü kontrol ediniz! Doğru Cevap=#qSoru.dogruCevap#">

            <cfquery name="qKontrol" datasource="DSN">
                SELECT id,kullaniciCevabi,onay
                FROM Cevap
                WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                AND cozenID=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfcatch type="any">
                <cfset hata="Cevabınız kaydedilirken bir hata oluştu.">
                <cfset aiHata=createObject("component","YKSSite.views.includes.ai")>
                <cfset aiHata.hataYazma(
                    sayfa="/YKSSite/views/soru/soruDetay.cfm",
                    islem="cevapGonder",
                    mesaj="soruID:#soruID# | #cfcatch.message#",
                    detay=cfcatch.detail
                )>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfquery name="qCevaplar" datasource="DSN">
    SELECT c.id,c.cozenID,c.cozumMetni,c.cozumResmi,c.onay,c.eklenmeTarihi,
        k.ad AS cozenAd,
        (SELECT COUNT(*) FROM Begeni b WHERE b.hedefID=c.id AND b.hedefTip='cevap') AS begeniSayisi,
        (SELECT COUNT(*) FROM Yorum y WHERE y.cevapID=c.id AND y.aktiflik=1) AS yorumSayisi
    FROM Cevap c
    INNER JOIN Kullanici k ON k.id=c.cozenID
    WHERE c.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND c.aktiflik=1
    ORDER BY c.eklenmeTarihi ASC
</cfquery>

<cfquery name="qYorumTum" datasource="DSN">
    SELECT y.id,y.cevapID,y.ustYorumID,y.metin,y.eklenmeTarihi,k.ad AS yazar
    FROM Yorum y
    INNER JOIN Kullanici k ON k.id=y.yazanID
    INNER JOIN Cevap c ON c.id=y.cevapID
    WHERE c.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND y.aktiflik=1
    AND c.aktiflik=1
    ORDER BY y.eklenmeTarihi ASC
</cfquery>

<cfset ustYorumlar={}>
<cfset yanitlar={}>

<cfloop query="qYorumTum">
    <cfset kayit={
        id=qYorumTum.id,
        metin=qYorumTum.metin,
        yazar=qYorumTum.yazar,
        tarih=qYorumTum.eklenmeTarihi
    }>

    <cfif val(qYorumTum.ustYorumID) EQ 0>
        <cfset cevapAnahtar=val(qYorumTum.cevapID)>

        <cfif NOT structKeyExists(ustYorumlar,cevapAnahtar)>
            <cfset ustYorumlar[cevapAnahtar]=[]>
        </cfif>

        <cfset arrayAppend(ustYorumlar[cevapAnahtar],kayit)>
    <cfelse>
        <cfset ustAnahtar=val(qYorumTum.ustYorumID)>

        <cfif NOT structKeyExists(yanitlar,ustAnahtar)>
            <cfset yanitlar[ustAnahtar]=[]>
        </cfif>

        <cfset arrayAppend(yanitlar[ustAnahtar],kayit)>
    </cfif>
</cfloop>

<cfset aiCozumGoster=cevapKontrol AND (qSoru.sistemSoru EQ 0 OR NOT len(trim(qSoru.aciklama)))>
<cfset geriURL=urlEncodedFormat("/YKSSite/views/soru/soruDetay.cfm?id=" & soruID)>

<script>
    function yorumlariGoster(cevapID){
        document.getElementById('yorumlar_'+cevapID).classList.toggle('d-none');
    }

    function yanitAc(yorumID){
        document.getElementById('yanit_'+yorumID).classList.toggle('d-none');
    }
</script>

<cfif aiCozumGoster>
    <div class="modal fade" id="aiCozModal" tabindex="-1">
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header bg-dark text-white">
                    <h5 class="modal-title"><i class="bi bi-robot"></i>AI Çözümü</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>

                <div class="modal-body" id="aiCozumIcerik">
                    <div class="text-center py-4">
                        <div class="spinner-border text-dark" role="status"></div>
                        <p class="mt-2 text-muted">AI çözümü hazırlanıyor,lütfen bekleyiniz.</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</cfif>

<cfoutput>
    <div class="container mt-4">
        <div class="row">
            <div class="col-md-8">
                <div class="card shadow mb-4">
                    <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center">
                        <div>
                            <span class="badge bg-secondary">#encodeForHTML(qSoru.alanAd)#</span>
                            <span class="badge bg-light text-dark">#encodeForHTML(qSoru.dersAd)#</span>
                        </div>

                        <small><i class="bi bi-eye"></i>#qSoru.goruntulenmeSayisi#</small>
                    </div>

                    <div class="card-body">
                        <cfif qSoru.sistemSoru EQ 1>
                            <div class="p-3 bg-light rounded mb-3">
                                <p class="fs-5 mb-4">#encodeForHTML(qSoru.soruMetni)#</p>

                                <div class="d-flex flex-column gap-2">
                                    <div class="p-2 border rounded">A) #encodeForHTML(qSoru.sikA)#</div>
                                    <div class="p-2 border rounded">B) #encodeForHTML(qSoru.sikB)#</div>
                                    <div class="p-2 border rounded">C) #encodeForHTML(qSoru.sikC)#</div>
                                    <div class="p-2 border rounded">D) #encodeForHTML(qSoru.sikD)#</div>
                                    <div class="p-2 border rounded">E) #encodeForHTML(qSoru.sikE)#</div>
                                </div>
                            </div>
                        <cfelseif len(trim(qSoru.soruResmi))>
                            <div class="text-center">
                                <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qSoru.soruResmi)#"
                                    class="img-fluid rounded" style="max-height:500px;" alt="Soru Görseli">
                            </div>
                        <cfelse>
                            <p class="fs-5">#encodeForHTML(qSoru.soruMetni)#</p>
                        </cfif>
                    </div>

                    <div class="card-footer d-flex justify-content-between align-items-center">
                        <div class="d-flex align-items-center gap-2">
                            <img src="#application.avatarURL##urlEncodedFormat(qSoru.soranAd)#"
                                class="rounded-circle" width="28" height="28" alt="">
                            <small class="text-muted">#encodeForHTML(qSoru.soranAd)# . #dateFormat(qSoru.eklenmeTarihi,'dd.mm.yyyy')#</small>
                        </div>

                        <a href="/YKSSite/views/soru/favoriToggle.cfm?soruID=#soruID#&geri=#geriURL#" class="btn btn-sm #favoriKontrol ? 'btn-danger':'btn-outline-danger'#">
                            <i class="bi bi-heart#favoriKontrol ? '-fill':''#"></i>
                            #favoriKontrol ? 'Favoriden Çıkar':'Favoriye Ekle'#
                        </a>
                    </div>
                </div>

                <cfif len(hata)>
                    <div class="alert alert-danger">
                        <i class="bi bi-exclamation-circle"></i>#encodeForHTML(hata)#
                    </div>
                </cfif>

                <cfif len(basari)>
                    <div class="alert #dogruMu ? 'alert-success':'alert-warning'#">
                        <i class="bi bi-#dogruMu ? 'check':'x'#-circle"></i>#encodeForHTML(basari)#
                    </div>
                </cfif>

                <cfif NOT cevapKontrol>
                    <cfif qSoru.soranID EQ kullaniciID>
                        <div class="alert alert-info">
                            <i class="bi bi-info-circle"></i>Bu soru size ait. Kendi sorunuzu çözemezsiniz.
                        </div>
                    <cfelse>
                        <div class="card mb-4">
                            <div class="card-header bg-dark text-white">
                                <i class="bi bi-pencil"></i>Cevabınızı seçiniz.
                            </div>

                            <div class="card-body">
                                <form method="POST" action="?id=#soruID#">
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
                                        <textarea name="cozumMetni" class="form-control" rows="4" maxlength="2000"
                                            placeholder="Çözümünüzü açıklamak isterseniz buraya yazabilirsiniz."></textarea>
                                    </div>

                                    <div class="d-grid">
                                        <button type="submit" name="cevapGonder" value="1" class="btn btn-dark">
                                            <i class="bi bi-send"></i>Cevabı Paylaş
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </cfif>
                <cfelse>
                    <div class="alert #qKontrol.onay EQ 1 ? 'alert-success':'alert-danger'#">
                        <i class="bi bi-#qKontrol.onay EQ 1 ? 'check':'x'#-circle"></i>
                        Sizin Cevabınız:<strong>#encodeForHTML(qKontrol.kullaniciCevabi)#</strong> -
                        Doğru Cevap:<strong>#encodeForHTML(qSoru.dogruCevap)#</strong>
                    </div>

                    <cfif qSoru.sistemSoru EQ 1 AND len(trim(qSoru.aciklama))>
                        <div class="alert alert-info mt-3 shadow-sm" style="border-left:5px solid ##0dcaf0;">
                            <h5 class="alert-heading text-info">
                                <i class="bi bi-robot"></i>Yapay Zeka Çözüm Açıklaması
                            </h5>

                            <hr class="border-info">

                            <p class="mb-0 text-dark">
                                #replace(encodeForHTML(qSoru.aciklama),chr(10),"<br>","all")#
                            </p>
                        </div>
                    </cfif>
                </cfif>

                <cfif qCevaplar.recordCount GT 0>
                    <h5 class="mb-3"><i class="bi bi-chat-left-text"></i>Çözümler(#qCevaplar.recordCount#)</h5>

                    <cfloop query="qCevaplar">
                        <div class="card mb-3">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <div class="d-flex align-items-center gap-2">
                                    <img src="#application.avatarURL##urlEncodedFormat(qCevaplar.cozenAd)#"
                                        class="rounded-circle" width="28" height="28" alt="">

                                    <strong>#encodeForHTML(qCevaplar.cozenAd)#</strong>

                                    <span class="badge #qCevaplar.onay EQ 1 ? 'bg-success':qCevaplar.onay EQ 0 ? 'bg-danger':'bg-secondary'#">
                                        #qCevaplar.onay EQ 1 ? 'Doğru':qCevaplar.onay EQ 0 ? 'Yanlış':'Belirsiz'#
                                    </span>
                                </div>

                                <small class="text-muted">#dateFormat(qCevaplar.eklenmeTarihi,'dd.mm.yyyy')#</small>
                            </div>

                            <div class="card-body">
                                <cfif len(trim(qCevaplar.cozumMetni))>
                                    <p>#replace(encodeForHTML(qCevaplar.cozumMetni),chr(10),"<br>","all")#</p>
                                </cfif>

                                <cfif len(trim(qCevaplar.cozumResmi))>
                                    <img src="/YKSSite/assets/images/cevaplar/#encodeForHTMLAttribute(qCevaplar.cozumResmi)#"
                                        class="img-fluid rounded mb-2" alt="Çözüm Görseli">
                                </cfif>

                                <div class="d-flex justify-content-between align-items-center mt-2">
                                    <div class="d-flex gap-2">
                                        <cfif qCevaplar.cozenID NEQ kullaniciID>
                                            <a href="/YKSSite/views/soru/begeniToggle.cfm?hedefID=#qCevaplar.id#&hedefTip=cevap&geri=#geriURL#" class="btn btn-sm btn-outline-primary">
                                                <i class="bi bi-hand-thumbs-up"></i>#qCevaplar.begeniSayisi#
                                            </a>

                                            <a href="/YKSSite/views/sikayet/sikayet.cfm?hedefTip=cevap&hedefID=#qCevaplar.id#" class="btn btn-sm btn-outline-danger">
                                                <i class="bi bi-flag"></i>Çözümü Şikayet Et
                                            </a>
                                        <cfelse>
                                            <span class="btn btn-sm btn-outline-secondary disabled">
                                                <i class="bi bi-hand-thumbs-up"></i>#qCevaplar.begeniSayisi#
                                            </span>
                                        </cfif>
                                    </div>

                                    <button type="button" class="btn btn-sm btn-outline-primary" onclick="yorumlariGoster(#qCevaplar.id#)">
                                        <i class="bi bi-chat"></i>Yorumlar(#qCevaplar.yorumSayisi#)
                                    </button>
                                </div>

                                <div id="yorumlar_#qCevaplar.id#" class="mt-3 d-none">
                                    <cfif structKeyExists(ustYorumlar,val(qCevaplar.id))>
                                        <cfloop array="#ustYorumlar[val(qCevaplar.id)]#" index="y">
                                            <div class="d-flex gap-2 mb-2">
                                                <img src="#application.avatarURL##urlEncodedFormat(y.yazar)#"
                                                    class="rounded-circle flex-shrink-0" width="24" height="24" alt="">

                                                <div class="bg-light rounded p-2 flex-grow-1">
                                                    <div class="d-flex justify-content-between">
                                                        <small class="fw-bold">#encodeForHTML(y.yazar)#</small>
                                                        <small class="text-muted">#dateFormat(y.tarih,'dd.mm.yyyy')#</small>
                                                    </div>

                                                    <p class="mb-1 small">#encodeForHTML(y.metin)#</p>

                                                    <div class="d-flex gap-3">
                                                        <button type="button" class="btn btn-link btn-sm p-0 text-decoration-none" onclick="yanitAc(#y.id#)">
                                                            <small><i class="bi bi-reply"></i>Yanıtla</small>
                                                        </button>

                                                        <a href="/YKSSite/views/sikayet/sikayet.cfm?hedefTip=yorum&hedefID=#y.id#" class="text-danger text-decoration-none">
                                                            <small><i class="bi bi-flag"></i>Şikayet Et</small>
                                                        </a>
                                                    </div>

                                                    <cfif structKeyExists(yanitlar,y.id)>
                                                        <cfloop array="#yanitlar[y.id]#" index="yanit">
                                                            <div class="d-flex gap-2 mt-2 ms-3 border-start ps-2">
                                                                <img src="#application.avatarURL##urlEncodedFormat(yanit.yazar)#"
                                                                    class="rounded-circle flex-shrink-0" width="20" height="20" alt="">

                                                                <div class="flex-grow-1">
                                                                    <div class="d-flex justify-content-between">
                                                                        <small class="fw-bold">#encodeForHTML(yanit.yazar)#</small>
                                                                        <small class="text-muted">#dateFormat(yanit.tarih,'dd.mm.yyyy')#</small>
                                                                    </div>

                                                                    <p class="mb-1 small">#encodeForHTML(yanit.metin)#</p>

                                                                    <a href="/YKSSite/views/sikayet/sikayet.cfm?hedefTip=yorum&hedefID=#yanit.id#" class="text-danger text-decoration-none">
                                                                        <small><i class="bi bi-flag"></i>Şikayet Et</small>
                                                                    </a>
                                                                </div>
                                                            </div>
                                                        </cfloop>
                                                    </cfif>

                                                    <form method="POST" action="/YKSSite/views/soru/yorumEkle.cfm" id="yanit_#y.id#" class="d-none mt-2">
                                                        <input type="hidden" name="cevapID" value="#qCevaplar.id#">
                                                        <input type="hidden" name="soruID" value="#soruID#">
                                                        <input type="hidden" name="ustYorumID" value="#y.id#">

                                                        <div class="input-group input-group-sm">
                                                            <input type="text" name="metin" class="form-control"
                                                                placeholder="#encodeForHTMLAttribute(y.yazar)# kullanıcısına yanıt veriniz."
                                                                required maxlength="500">

                                                            <button type="submit" class="btn btn-dark">
                                                                <i class="bi bi-send"></i>
                                                            </button>
                                                        </div>
                                                    </form>
                                                </div>
                                            </div>
                                        </cfloop>
                                    </cfif>

                                    <form method="POST" action="/YKSSite/views/soru/yorumEkle.cfm">
                                        <input type="hidden" name="cevapID" value="#qCevaplar.id#">
                                        <input type="hidden" name="soruID" value="#soruID#">
                                        <input type="hidden" name="ustYorumID" value="0">

                                        <div class="input-group mt-2">
                                            <input type="text" name="metin" class="form-control form-control-sm"
                                                placeholder="Yorum yazınız." required maxlength="500">

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
                        <p class="mb-1"><strong>Alan:</strong>#encodeForHTML(qSoru.alanAd)#</p>
                        <p class="mb-1"><strong>Ders:</strong>#encodeForHTML(qSoru.dersAd)#</p>
                        <p class="mb-1"><strong>Soran:</strong>#encodeForHTML(qSoru.soranAd)#</p>
                        <p class="mb-1"><strong>Tarih:</strong>#dateFormat(qSoru.eklenmeTarihi,'dd.mm.yyyy')#</p>
                        <p class="mb-0"><strong>Görüntülenme:</strong>#qSoru.goruntulenmeSayisi#</p>
                    </div>
                </div>

                <cfif qSoru.soranID NEQ kullaniciID>
                    <div class="d-grid">
                        <a href="/YKSSite/views/sikayet/sikayet.cfm?hedefTip=soru&hedefID=#soruID#" class="btn btn-outline-danger btn-sm">
                            <i class="bi bi-flag"></i>Şikayet Et
                        </a>
                    </div>
                </cfif>

                <cfif aiCozumGoster>
                    <div class="d-grid mt-2">
                        <button type="button" class="btn btn-outline-primary btn-sm" data-bs-toggle="modal" data-bs-target="##aiCozModal" data-soruid="#qSoru.id#">
                            <i class="bi bi-robot"></i>AI ile Çöz
                        </button>
                    </div>
                </cfif>

                <cfif val(SESSION.rol) GTE 2>
                    <div class="card mt-3 border-warning">
                        <div class="card-header bg-warning text-dark">
                            <i class="bi bi-tools"></i>Moderatör İşlemi
                        </div>

                        <div class="card-body">
                            <cfif len(cevapHata)>
                                <div class="alert alert-danger py-2 small mb-2">#encodeForHTML(cevapHata)#</div>
                            </cfif>

                            <cfif len(cevapBasari)>
                                <div class="alert alert-success py-2 small mb-2">#encodeForHTML(cevapBasari)#</div>
                            </cfif>

                            <form method="POST" action="?id=#soruID#">
                                <label class="form-label small mb-1">Cevap anahtarını düzelt:</label>

                                <div class="input-group input-group-sm">
                                    <select name="yeniDogruCevap" class="form-select" required>
                                        <cfloop list="A,B,C,D,E" index="s">
                                            <option value="#s#" #compareNoCase(s,qSoru.dogruCevap) EQ 0 ? 'selected':''#>#s#</option>
                                        </cfloop>
                                    </select>

                                    <button type="submit" name="cevapDuzelt" value="1" class="btn btn-warning"
                                        onclick="return confirm('Cevap anahtarı değişecek, tüm kullanıcı cevapları ve puanları yeniden hesaplanacak. Emin misiniz?')">
                                        Kaydet
                                    </button>
                                </div>

                                <small class="text-muted">Mevcut:<strong>#encodeForHTML(qSoru.dogruCevap)#</strong></small>
                            </form>
                        </div>
                    </div>
                </cfif>
            </div>
        </div>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">