<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">
<cfinclude template="/YKSSite/views/includes/baslik.cfm">

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
                                <cfqueryparam value="#yeniDurum EQ 1 ? 'Çözdüğünüz bir sorunun cevap anahtarı düzeltildi,cevabınız doğru sayıldı.':'Çözdüğünüz bir sorunun cevap anahtarı düzeltildi,cevabınız yanlış olarak güncellendi.'#" cfsqltype="cf_sql_varchar">,
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

            <cfset cevapBasari="Doğru cevap #qEski.dogruCevap# → #yeniCevap# olarak güncellendi.Kullanıcı cevapları ve puanları yeniden hesaplandı.">

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
            <cfset basari=dogruMu ? "Tebrikler,doğru çözdünüz!(+5 XP)":"Maalesef,çözümünüzü kontrol ediniz!Doğru Cevap=#qSoru.dogruCevap#">

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

<cfoutput>
    <div class="sutunlar">
        <div class="yigin">
            <article class="kart">
                <div class="kart__baslik">
                    <span class="soru__ust" style="margin:0">
                        <span class="rozet rozet--sinav">#encodeForHTML(qSoru.alanAd)#</span>
                        <span class="rozet rozet--ders">#encodeForHTML(qSoru.dersAd)#</span>

                        <cfif qSoru.sistemSoru EQ 1>
                            <span class="rozet rozet--yz">Yapay Zeka Sorusu:</span>
                        </cfif>
                    </span>

                    <span class="veri sessiz">Görüntülenme Sayısı:#qSoru.goruntulenmeSayisi#</span>
                </div>

                <div class="kart__govde">
                    <cfif qSoru.sistemSoru EQ 1>
                        <p class="soru__metin">#encodeForHTML(qSoru.soruMetni)#</p>
                    <cfelseif len(trim(qSoru.soruResmi))>
                        <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qSoru.soruResmi)#"
                            class="soru-gorsel" alt="Soru Resmi">
                    <cfelse>
                        <p class="soru__metin">#encodeForHTML(qSoru.soruMetni)#</p>
                    </cfif>
                </div>

                <div class="kart__ayrac">
                    <div class="eylem-seridi">
                        <span class="mini-avatar">#uCase(left(qSoru.soranAd,2))#</span>
                        
                        <span class="sessiz">#encodeForHTML(qSoru.soranAd)# · #dateFormat(qSoru.eklenmeTarihi,'dd.mm.yyyy')#</span>
                        <span class="eylem-seridi__bosluk"></span>

                        <form method="POST" action="/YKSSite/views/soru/favoriToggle.cfm" class="favori-form">
                            <input type="hidden" name="csrf" value="#SESSION.csrf#">
                            <input type="hidden" name="soruID" value="#soruID#">
                            <input type="hidden" name="geri" value="#geriURL#">

                            <button class="favori#favoriKontrol ? ' favori--dolu':''#" type="submit">
                                <svg class="simge"><use href="###favoriKontrol ? 's-kalp-dolu':'s-kalp'#"></use></svg>
                            </button>
                        </form>
                    </div>
                </div>
            </article>

            <cfif len(hata)>
                <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hata)#</div>
            </cfif>

            <cfif NOT cevapKontrol>
                <cfif qSoru.soranID EQ kullaniciID>
                    <div class="bildirim" role="status">Kendi sorunuzu çözemezsiniz.</div>
                <cfelse>
                    <section class="kart">
                        <div class="kart__baslik">Cevabınız:</div>

                        <div class="kart__govde">
                            <form method="POST" action="?id=#soruID#">
                                <div class="siklar<cfif qSoru.sistemSoru NEQ 1> siklar--satir</cfif>" role="radiogroup" aria-label="Şıklar">
                                    <cfloop list="A,B,C,D,E" index="sik">
                                        <cfset sikMetni=qSoru.sistemSoru EQ 1 ? trim(qSoru["sik" & sik]) : "">
                                        
                                        <label class="sik<cfif NOT len(sikMetni)> sik--sade</cfif>">                                            
                                            <input type="radio" name="kullaniciCevabi" value="#sik#" required>
                                            <span class="optik" aria-hidden="true">#sik#</span>

                                            <cfif len(sikMetni)>
                                                <span class="sik__yazi">#encodeForHTML(sikMetni)#</span>
                                            <cfelse>
                                                <span class="gizli-metin">#sik# Şıkkı</span>
                                            </cfif>
                                        </label>
                                    </cfloop>
                                </div>
                                
                                <div class="alan">
                                    <label for="cozumMetni">Çözümünüz<span class="sessiz">(isteğe bağlı):</span></label>
                                    <textarea class="girdi" name="cozumMetni" id="cozumMetni" rows="4" maxlength="2000" placeholder="Çözümünüzü anlatmak ister misiniz?"></textarea>
                                </div>
        
                                <button class="dugme dugme--ana dugme--tam" type="submit" name="cevapGonder" value="1">Çözüm Gönder</button>
                            </form>
                        </div>
                    </section>
                </cfif>
            <cfelse>
                <cfset sonucSinif=qKontrol.onay EQ 1 ? "sonuc--dogru":"sonuc--yanlis">
                <div class="sonuc #sonucSinif#">
                    <cfif qSoru.sistemSoru EQ 1>
                        <section class="kart">
                            <div class="kart__baslik">Şıklar:</div>

                            <div class="kart__govde">
                                <div class="siklar">
                                    <cfloop list="A,B,C,D,E" index="sik">
                                        <cfset sikMetni=trim=(qSoru["sik" & sik])>
                                        <cfset sikSinif="">

                                        <cfif compareNoCase(sik,qSoru.dogruCevap) EQ 0>
                                            <cfset sikSinif=" sik--dogru">
                                        <cfelseif compareNoCase(sik,qKontrol.kullaniciCevabi EQ 0)>
                                            <cfset sikSinif=" sik--yanlis">
                                        </cfif>

                                        <div class="sik#sikSinif#">
                                            <span class="optik" aria-hidden="true">#sik#</span>
                                            <span class="sik__yazi">#encodeForHTML(sikMetni)#</span>
                                        </div>
                                    </cfloop>
                                </div>
                            </div>
                        </section>
                    </cfif>
                </div>

                <cfif qSoru.sistemSoru EQ 1 AND len(trim(qSoru.aciklama))>
                    <div class="ai-kutu">
                        <p class="ai-kutu__baslik">Yapay Zeka Çözümü:</p>
                        <p>#replace(encodeForHTML(qSoru.aciklama),chr(10),"<br>","all")#</p>
                    </div>
                </cfif>
            </cfif>

            <cfif qCevaplar.recordCount GT 0>
                <h2 class="goz">Çözümler · #qCevaplar.recordCount#</h2>
                
                <cfloop query="qCevaplar">
                    <article class="kart">
                        <div class="kart__govde">
                            <div class="cozum-kart__ust">
                                <span class="mini-avatar">#uCase(left(qCevaplar.cozenAd,2))#</span>

                                <span class="cozum-kart__ad">#encodeForHTML(qCevaplar.cozenAd)#</span>

                                <cfif qCevaplar.onay EQ 1>
                                    <span class="rozet rozet--dogru">Doğru</span>
                                <cfelseif qCevaplar.onay EQ 0>
                                    <span class="rozet rozet--yanlis">Yanlış</span>
                                <cfelse>
                                    <span class="rozet">Belirsiz</span>
                                </cfif>
                                    
                                <span class="cozum-kart__tarih">#dateFormat(qCevaplar.eklenmeTarihi,'dd.mm.yyyy')#</span>
                            </div>
                            
                            <cfif len(trim(qCevaplar.cozumMetni))>
                                <p class="ust-bosluk">#replace(encodeForHTML(qCevaplar.cozumMetni),chr(10),"<br>","all")#</p>
                            </cfif>
                            
                            <cfif len(trim(qCevaplar.cozumResmi))>
                                <img src="/YKSSite/assets/images/cevaplar/#encodeForHTMLAttribute(qCevaplar.cozumResmi)#"
                                    class="cozum-gorsel" alt="Çözüm görseli">
                            </cfif>
                        </div>
                
                        <div class="kart__ayrac">
                            <div class="eylem-seridi">
                                <cfif qCevaplar.cozenID NEQ kullaniciID>
                                    <form method="POST" action="/YKSSite/views/soru/begeniToggle.cfm" class="eylem-form">
                                        <input type="hidden" name="csrf" value="SESSION.csrf">
                                        <input type="hidden" name="hedefID" value="#qCevaplar.id#">
                                        <input type="hidden" name="hedefTip" value="cevap">
                                        <input type="hidden" name="geri" value="#geriURL#">

                                        <button class="eylem" type="submit">
                                            <svg class="simge"><use href="##s-begeni"></use></svg><span class="veri">#qCevaplar.begeniSayisi#</span>
                                        </button>
                                    </form> 
                                <cfelse>
                                    <svg class="simge"><use href="##s-begeni"></use></svg> <span class="veri">#qCevaplar.begeniSayisi#</span>
                                </cfif>
                        
                                <button class="eylem" type="button" data-ac="yorumlar_#qCevaplar.id#" aria-expanded="false" aria-controls="yorumlar_#qCevaplar.id#">
                                    <svg class="simge"><use href="##s-sohbet"></use></svg>Yorumlar<span class="veri">#qCevaplar.yorumSayisi#</span>
                                </button>

                                <span class="eylem-seridi__bosluk"></span>

                                <cfif qCevaplar.cozenID NEQ kullaniciID>
                                    <a class="eylem" href="/YKSSite/views/sikayet/sikayet.cfm?hedefTip=cevap&hedefID=#qCevaplar.id#" aria-label="Çözümü Şikayet Ediniz.">
                                        <svg class="simge"><use href="##s-bayrak"></use></svg>
                                    </a>
                                </cfif>
                            </div>

                            <div class="yorum-alani" id="yorumlar_#qCevaplar.id#" hidden>
                                <cfif structKeyExists(ustYorumlar,val(qCevaplar.id))>
                                    <cfloop array="#ustYorumlar[val(qCevaplar.id)]#" index="y">
                                        <div class="yorum">
                                            <span class="avatar">#uCase(left(y.yazar,2))#</span>

                                            <div style="flex:1;min-width:0">
                                                <div class="yorum__ust">
                                                    <span class="yorum__ad">#encodeForHTML(y.yazar)#</span>
                                                    <span class="yorum__zaman">#dateFormat(y.tarih,'dd.mm.yyyy')#</span>
                                                </div>

                                                <p>#encodeForHTML(y.metin)#</p>

                                                <div class="yorum__eylem">
                                                    <button class="metin-dugme" type="button" data-ac="yanit_#y.id#" aria-expanded="false" aria-controls="yanit_#y.id#">Yanıtla</button>
                                                            
                                                    <a class="metin-dugme metin-dugme--tehlike" href="/YKSSite/views/sikayet/sikayet.cfm?hedefTip=yorum&hedefID=#y.id#">Şikayet Et</a>
                                                </div>
                                    
                                                <cfif structKeyExists(yanitlar,y.id)>
                                                    <cfloop array="#yanitlar[y.id]#" index="yanit">
                                                        <div class="yorum yorum--yanit">
                                                            <span class="mini-avatar">#uCase(left(yanit.yazar,1))#</span>
                                                                
                                                            <div style="flex:1;min-width:0">
                                                                <div class="yorum__ust">
                                                                    <span class="yorum__ad">#encodeForHTML(yanit.yazar)#</span>
                                                                    <span class="yorum__zaman">#dateFormat(yanit.tarih,'dd.mm.yyyy')#</span>
                                                                </div>
                                                                            
                                                                <p>#encodeForHTML(yanit.metin)#</p>
                                                                            
                                                                <div class="yorum__eylem">
                                                                    <a class="metin-dugme metin-dugme--tehlike" href="/YKSSite/views/sikayet/sikayet.cfm?hedefTip=yorum&hedefID=#yanit.id#">Şikayet Et</a>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </cfloop>
                                                </cfif>

                                                <form class="mini-form" method="POST" action="/YKSSite/views/soru/yorumEkle.cfm" id="yanit_#y.id#" hidden>
                                                    <input type="hidden" name="cevapID" value="#qCevaplar.id#">
                                                    <input type="hidden" name="soruID" value="#soruID#">
                                                    <input type="hidden" name="ustYorumID" value="#y.id#">
                                                    <input class="girdi" type="text" name="metin" maxlength="500" required placeholder="#encodeForHTMLAttribute(y.yazar)# kullanıcısına cevap veriniz..">
                                                            
                                                    <button class="dugme dugme--ana" type="submit">Gönder</button>
                                                </form>
                                            </div>
                                        </div>
                                    </cfloop>
                                </cfif>

                                <form class="mini-form" method="POST" action="/YKSSite/views/soru/yorumEkle.cfm">
                                    <input type="hidden" name="cevapID" value="#qCevaplar.id#">
                                    <input type="hidden" name="soruID" value="#soruID#">
                                    <input type="hidden" name="ustYorumID" value="0">
                                    <input class="girdi" type="text" name="metin" maxlength="500" required placeholder="Yorum yapınız.">
                                        
                                    <button class="dugme dugme--ana" type="submit">Gönder</button>
                                </form>
                            </div>
                        </div>
                    </article>
                </cfloop>
            </cfif>
        </div>

        <div class="yigin">
            <section class="kart">
                <div class="kart__baslik">Soru Bilgisi</div>

                <div class="kart__govde">
                    <dl class="bilgi-liste">
                        <div><dt>Alan:</dt><dd>#encodeForHTML(qSoru.alanAd)#</dd></div>
                        <div><dt>Ders:</dt><dd>#encodeForHTML(qSoru.dersAd)#</dd></div>
                        <div><dt>Soran:</dt><dd>#encodeForHTML(qSoru.soranAd)#</dd></div>
                        <div><dt>Tarih:</dt><dd class="veri">#dateFormat(qSoru.eklenmeTarihi,'dd.mm.yyyy')#</dd></div>
                        <div><dt>Görüntülenme:</dt><dd class="veri">#qSoru.goruntulenmeSayisi#</dd></div>
                    </dl>
                </div>
            </section>

            <cfif aiCozumGoster>
                <button class="dugme dugme--ikincil dugme--tam" type="button" id="aiAcDugme" data-pencere-ac="aiPencere" data-soruid="#qSoru.id#">Yapay zeka ile çöz</button>
            </cfif>

            <cfif qSoru.soranID NEQ kullaniciID>
                <a class="dugme dugme--tehlike dugme--tam" href="/YKSSite/views/sikayet/sikayet.cfm?hedefTip=soru&hedefID=#soruID#">Soruyu şikayet ediniz</a>
            </cfif>

            <cfif val(SESSION.rol) GTE 2>
                <section class="kart mod-kutu">
                    <div class="kart__baslik">Moderatör işlemi</div>

                    <div class="kart__govde">
                        <cfif len(cevapHata)>
                            <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(cevapHata)#</div>
                        </cfif>

                        <cfif len(cevapBasari)>
                            <div class="bildirim bildirim--basarili" role="status">#encodeForHTML(cevapBasari)#</div>
                        </cfif>

                        <form method="POST" action="?id=#soruID#">
                            <div class="alan ust-bosluk">
                                <label for="yeniDogruCevap">Cevap Anahtarı:</label>
                                <select class="secim" name="yeniDogruCevap" id="yeniDogruCevap" required>
                                    <cfloop list="A,B,C,D,E" index="s">
                                        <option value="#s#" #compareNoCase(s,qSoru.dogruCevap) EQ 0 ? "selected":""#>#s#</option>
                                    </cfloop>
                                </select>
        
                                <span class="alan__ipucu">Mevcut cevap anahtarı:#encodeForHTML(qSoru.dogruCevap)#.Değiştirirseniz tüm cevaplar ve puanlar yeniden hesaplanır.</span>
                            </div>
                        
                            <button class="dugme dugme--ana dugme--tam" type="submit" name="cevapDuzelt" value="1" onclick="return confirm('Cevap anahtarı değişecek,tüm kullanıcı cevapları ve puanları yeniden hesaplanacak. Emin misin?')">Kaydet</button>
                        </form>
                    </div>
                </section>
            </cfif>
        </div>
    </div>
</cfoutput>

<cfif aiCozumGoster>
    <dialog class="pencere pencere--genis" id="aiPencere">
        <div class="kart__baslik">
            <span>Yapay Zeka Çözümü</span>

            <button class="simge-dugme" type="button" data-pencere-kapat aria-label="Kapat">✕</button>
        </div>

        <div class="pencere__govde pencere__kaydir" id="aiCozumIcerik">
            <div class="yukleniyor">
                <span class="donen" aria-hidden="true"></span>

                <p>Çözüm hazırlanıyor,lütfen bekleyiniz.</p>
            </div>
        </div> 
    </dialog>
</cfif>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">