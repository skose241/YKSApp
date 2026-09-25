<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">
<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfif val(SESSION.rol) LT 2>
    <cflocation url="/YKSSite/anaSayfa.cfm" addtoken="false">
</cfif>
<cfparam name="hata" default="">
<cfparam name="basari" default="">
<cfset yoneticiID=val(SESSION.kullaniciID)>
<cfset yoneticiRol=val(SESSION.rol)>
<cfif structKeyExists(form,"islem")>
    <cfparam name="form.islem" default="">
    <cfparam name="form.csrf" default="">
    <cfif len(form.islem)>
        <cfif NOT structKeyExists(SESSION,"csrf") OR compare(form.csrf,SESSION.csrf) NEQ 0>
            <cfset hata="Oturum doğrulaması başarısız.Sayfayı yenileyip tekrar deneyiniz.">
        <cfelse>
            <cfswitch expression="#form.islem#">
                <cfcase value="onayla">
                    <cfif structKeyExists(form,"soruID") AND isNumeric(form.soruID)>
                        <cfset soruID=val(form.soruID)>
                        <cfquery name="qKisi" datasource="DSN">
                            SELECT soranID
                            FROM Soru
                            WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                            AND aktiflik=0
                        </cfquery>

                        <cfif qKisi.recordCount EQ 0>
                            <cfset hata="Soru bulunamadı veya zaten işlem yapılmış">
                        <cfelse>
                            <cftransaction>
                                <cfquery datasource="DSN">
                                    UPDATE Soru
                                    SET aktiflik=1
                                    WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                                    AND aktiflik=0
                                </cfquery>

                                <cfquery name="qPuanVar" datasource="DSN">
                                    SELECT TOP 1 id
                                    FROM Puan
                                    WHERE islemTipi='soru_ekledi'
                                    AND referansTip='soru'
                                    AND referansID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                                </cfquery>

                                <cfif qPuanVar.recordCount EQ 0>
                                    <cfquery datasource="DSN">
                                        INSERT INTO Puan(kullaniciID,islemTipi,puanDegeri,referansID,referansTip,eklenmeTarihi)
                                        VALUES(
                                        <cfqueryparam value="#qKisi.soranID#" cfsqltype="cf_sql_integer">,
                                        <cfqueryparam value="soru_ekledi" cfsqltype="cf_sql_varchar">,
                                        3,
                                        <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
                                        <cfqueryparam value="soru" cfsqltype="cf_sql_varchar">,
                                        GETDATE()
                                        )
                                    </cfquery>

                                    <cfquery datasource="DSN">
                                        UPDATE Kullanici
                                        SET xp=xp+3
                                        WHERE id=<cfqueryparam value="#qKisi.soranID#" cfsqltype="cf_sql_integer">
                                    </cfquery>
                                </cfif>

                                <cfquery datasource="DSN">
                                    INSERT INTO Bildirim(kullaniciID,islemTipi,mesaj,goruldu,hedefURL,tarih)
                                    VALUES(
                                    <cfqueryparam value="#qKisi.soranID#" cfsqltype="cf_sql_integer">,
                                    <cfqueryparam value="sistem" cfsqltype="cf_sql_varchar">,
                                    <cfqueryparam value="Sorunuz moderatör tarafından onaylandı(+3 XP)" cfsqltype="cf_sql_varchar">,
                                    0,
                                    <cfqueryparam value="/YKSSite/views/soru/soruDetay.cfm?id=#soruID#" cfsqltype="cf_sql_varchar">,
                                    GETDATE()
                                    )
                                </cfquery>
                            </cftransaction>
                            <cfset basari="Soru onaylandı.">
                        </cfif>
                    </cfif>
                </cfcase>

                <cfcase value="reddet">
                    <cfif structKeyExists(form,"soruID") AND isNumeric(form.soruID)>
                        <cfset soruID=val(form.soruID)>
                        <cfquery name="qKisi" datasource="DSN">
                            SELECT soranID,soruResmi
                            FROM Soru
                            WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                            AND aktiflik=0
                        </cfquery>
                        <cfif qKisi.recordCount EQ 0>
                            <cfset hata="Soru bulunamadı veya zaten işlem yapılmış">
                        <cfelse>
                            <cfset silinecekResim=trim(qKisi.soruResmi)>
                            <cftransaction>
                                <cfquery datasource="DSN">
                                    INSERT INTO Bildirim(kullaniciID,islemTipi,mesaj,goruldu,hedefURL,tarih)
                                    VALUES(
                                    <cfqueryparam value="#qKisi.soranID#" cfsqltype="cf_sql_integer">,
                                    <cfqueryparam value="sistem" cfsqltype="cf_sql_varchar">,
                                    <cfqueryparam value="Sorunuz moderatör tarafından reddedildi" cfsqltype="cf_sql_varchar">,
                                    0,
                                    <cfqueryparam value="/YKSSite/anaSayfa.cfm" cfsqltype="cf_sql_varchar">,
                                    GETDATE()
                                    )
                                </cfquery>

                                <cfquery datasource="DSN">
                                    DELETE FROM Sikayet
                                    WHERE hedefTip='soru'
                                    AND hedefID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                                </cfquery>

                                <cfquery name="qPuanVar" datasource="DSN">
                                    SELECT TOP 1 id
                                    FROM Puan
                                    WHERE islemTipi='soru_ekledi'
                                    AND referansTip='soru'
                                    AND referansID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                                </cfquery>

                                <cfif qPuanVar.recordCount GT 0>
                                    <cfquery datasource="DSN">
                                        DELETE FROM Puan
                                        WHERE islemTipi='soru_ekledi'
                                        AND referansTip='soru'
                                        AND referansID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                                    </cfquery>
									
                                    <cfquery datasource="DSN">
                                        UPDATE Kullanici
                                        SET xp=CASE WHEN xp-3<0 THEN 0 ELSE xp-3 END
                                        WHERE id=<cfqueryparam value="#qKisi.soranID#" cfsqltype="cf_sql_integer">
                                    </cfquery>
                                </cfif>

                                <cfquery datasource="DSN">
                                    DELETE FROM Favori
                                    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                                </cfquery>

                                <cfquery datasource="DSN">
                                    DELETE FROM AI
                                    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                                </cfquery>

                                <cfquery datasource="DSN">
                                    DELETE FROM Soru
                                    WHERE id=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                                    AND aktiflik=0
                                </cfquery>
                            </cftransaction>

                            <cfif len(silinecekResim) AND reFind("^[A-Za-z0-9_\-]+\.[A-Za-z0-9]{2,5}$",silinecekResim)>
                                <cftry>
                                    <cfset resimTamYol=expandPath("/YKSSite/assets/images/sorular/#silinecekResim#")>
                                    <cfif fileExists(resimTamYol)>
                                        <cffile action="delete" file="#resimTamYol#">
                                    </cfif>
                                    <cfcatch type="any"></cfcatch>
                                </cftry>
                            </cfif>
                            <cfset basari="Soru reddedildi ve silindi.">
                        </cfif>
                    </cfif>
                </cfcase>

                <cfcase value="sikayetCoz">
                    <cfif structKeyExists(form,"sikayetID") AND isNumeric(form.sikayetID)>
                        <cfset sikayetID=val(form.sikayetID)>
                        <cfquery name="qHedef" datasource="DSN">
                            SELECT hedefTip,hedefID
                            FROM Sikayet
                            WHERE id=<cfqueryparam value="#sikayetID#" cfsqltype="cf_sql_integer">
                            AND durum=0
                        </cfquery>

                        <cfif qHedef.recordCount EQ 0>
                            <cfset hata="Şikayet bulunamadı veya zaten işlem yapılmış.">
                        <cfelseif qHedef.hedefTip EQ "kullanici" AND val(qHedef.hedefID) EQ yoneticiID>
                            <cfset hata="Kendinizi engelleyemezsiniz.">
                        <cfelse>
                            <cfset yetkiVar=true>
                            <cfif qHedef.hedefTip EQ "kullanici">
                                <cfquery name="qHedefRol" datasource="DSN">
                                    SELECT rol,sistemHesap
                                    FROM Kullanici
                                    WHERE id=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                </cfquery>

                                <cfif qHedefRol.recordCount EQ 0>
                                    <cfset yetkiVar=false>
                                    <cfset hata="Şikayet edilen kullanıcı bulunamadı.">
                                <cfelseif qHedefRol.sistemHesap EQ 1>
                                    <cfset yetkiVar=false>
                                    <cfset hata="Sistem hesabı engellenemez.">
                                <cfelseif val(qHedefRol.rol) GTE yoneticiRol>
                                    <cfset yetkiVar=false>
                                    <cfset hata="Kendinizle eşdeğer veya üst yetkili birini engelleyemezsiniz.">
                                </cfif>
                            </cfif>

                            <cfif yetkiVar>
                                <cftransaction>
                                    <cfswitch expression="#qHedef.hedefTip#">
                                        <cfcase value="soru">
                                            <cfquery datasource="DSN">
                                                UPDATE Soru
                                                SET aktiflik=0
                                                WHERE id=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                            </cfquery>
                                        </cfcase>

                                        <cfcase value="cevap">
                                            <cfquery datasource="DSN">
                                                UPDATE Cevap
                                                SET aktiflik=0
                                                WHERE id=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                            </cfquery>
                                        </cfcase>

                                        <cfcase value="yorum">
                                            <cfquery datasource="DSN">
                                                UPDATE Yorum
                                                SET aktiflik=0
                                                WHERE id=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                                OR ustYorumID=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                            </cfquery>
                                        </cfcase>

                                        <cfcase value="kullanici">
                                            <cfquery datasource="DSN">
                                                UPDATE Kullanici
                                                SET aktiflik=0
                                                WHERE id=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                            </cfquery>

                                            <cfquery datasource="DSN">
                                                UPDATE Oturum
                                                SET aktiflik=0
                                                WHERE kullaniciID=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                                AND aktiflik=1
                                            </cfquery>
                                        </cfcase>
                                    </cfswitch>

                                    <cfquery datasource="DSN">
                                        UPDATE Sikayet
                                        SET durum=2
                                        WHERE hedefTip=<cfqueryparam value="#qHedef.hedefTip#" cfsqltype="cf_sql_varchar">
                                        AND hedefID=<cfqueryparam value="#qHedef.hedefID#" cfsqltype="cf_sql_integer">
                                        AND durum=0
                                    </cfquery>
                                </cftransaction>

                                <cfset basari="Şikayet onaylandı, ilgili içerik yayından kaldırıldı.">
                            </cfif>
                        </cfif>
                    </cfif>
                </cfcase>

                <cfcase value="sikayetReddet">
                    <cfif structKeyExists(form,"sikayetID") AND isNumeric(form.sikayetID)>
                        <cfquery datasource="DSN">
                            UPDATE Sikayet
                            SET durum=3
                            WHERE id=<cfqueryparam value="#val(form.sikayetID)#" cfsqltype="cf_sql_integer">
                            AND durum=0
                        </cfquery>

                        <cfset basari="Şikayet reddedildi olarak işaretlendi.">
                    </cfif>
                </cfcase>

                <cfcase value="kullaniciBan">
                    <cfif structKeyExists(form,"kullaniciID") AND isNumeric(form.kullaniciID)>
                        <cfset hedefKullanici=val(form.kullaniciID)>
                        <cfquery name="qRol" datasource="DSN">
                            SELECT rol,sistemHesap
                            FROM Kullanici
                            WHERE id=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                        </cfquery>

                        <cfif hedefKullanici EQ yoneticiID>
                            <cfset hata="Kendinizi engelleyemezsiniz.">
                        <cfelseif qRol.recordCount EQ 0>
                            <cfset hata="Kullanıcı bulunamadı.">
                        <cfelseif qRol.sistemHesap EQ 1>
                            <cfset hata="Sistem hesabı engellenemez.">
                        <cfelseif val(qRol.rol) GTE yoneticiRol>
                            <cfset hata="Kendinizle eşdeğer veya üst yetkili birini engelleyemezsiniz.">
                        <cfelse>
                            <cftransaction>
                                <cfquery datasource="DSN">
                                    UPDATE Kullanici
                                    SET aktiflik=0
                                    WHERE id=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                                </cfquery>
                                <cfquery datasource="DSN">
                                    UPDATE Oturum
                                    SET aktiflik=0
                                    WHERE kullaniciID=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                                    AND aktiflik=1
                                </cfquery>
                            </cftransaction>

                            <cfset basari="Kullanıcı engellendi.">
                        </cfif>
                    </cfif>
                </cfcase>

                <cfcase value="kullaniciAktiflestir">
                    <cfif structKeyExists(form,"kullaniciID") AND isNumeric(form.kullaniciID)>
                        <cfset hedefKullanici=val(form.kullaniciID)>
                        <cfquery name="qRol" datasource="DSN">
                            SELECT rol
                            FROM Kullanici
                            WHERE id=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                        </cfquery>

                        <cfif qRol.recordCount EQ 0>
                            <cfset hata="Kullanıcı bulunamadı.">
                        <cfelseif val(qRol.rol) GTE yoneticiRol AND hedefKullanici NEQ yoneticiID>
                            <cfset hata="Bu kullanıcı üzerinde işlem yapma yetkiniz yok.">
                        <cfelse>
                            <cfquery datasource="DSN">
                                UPDATE Kullanici
                                SET aktiflik=1
                                WHERE id=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                            </cfquery>
                            <cfset basari="Kullanıcı yeniden aktifleştirildi.">
                        </cfif>
                    </cfif>
                </cfcase>

                <cfcase value="rolDegistir">
                    <cfif yoneticiRol NEQ 3>
                        <cfset hata="Bu işlem için yetkiniz yok.">
                    <cfelseif structKeyExists(form,"kullaniciID") AND isNumeric(form.kullaniciID) AND structKeyExists(form,"yeniRol") AND isNumeric(form.yeniRol)>
                        <cfset hedefKullanici=val(form.kullaniciID)>
                        <cfset yeniRol=val(form.yeniRol)>
                        <cfquery name="qRolHedef" datasource="DSN">
                            SELECT sistemHesap
                            FROM Kullanici
                            WHERE id=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                        </cfquery>

                        <cfif hedefKullanici EQ yoneticiID>
                            <cfset hata="Kendi rolünüzü değiştiremezsiniz.">
                        <cfelseif qRolHedef.recordCount EQ 0>
                            <cfset hata="Kullanıcı bulunamadı.">
                        <cfelseif qRolHedef.sistemHesap EQ 1>
                            <cfset hata="Sistem hesabının rolü değiştirilemez.">
                        <cfelseif NOT listFind("1,2,3",yeniRol)>
                            <cfset hata="Geçersiz rol.">
                        <cfelse>
                            <cfquery datasource="DSN">
                                UPDATE Kullanici
                                SET rol=<cfqueryparam value="#yeniRol#" cfsqltype="cf_sql_integer">
                                WHERE id=<cfqueryparam value="#hedefKullanici#" cfsqltype="cf_sql_integer">
                            </cfquery>
                            <cfset basari="Kullanıcı rolü güncellendi">
                        </cfif>
                    </cfif>
                </cfcase>
            </cfswitch>
        </cfif>
    </cfif>
</cfif>

<cfquery name="qKullanici" datasource="DSN">
    SELECT id,ad,rol,sistemHesap,xp,aktiflik,kayitTarihi
    FROM Kullanici
    ORDER BY aktiflik ASC,kayitTarihi DESC
</cfquery>

<cfquery name="qSoru" datasource="DSN">
    SELECT s.id,s.soruResmi,s.soruMetni,s.sistemSoru,s.eklenmeTarihi,
    d.ad AS dersAd,a.ad AS alanAd,k.ad AS soranAd
    FROM Soru s
    INNER JOIN Ders d ON d.id=s.dersID
    INNER JOIN Alan a ON a.id=d.alanID
    INNER JOIN Kullanici k ON k.id=s.soranID
    WHERE s.aktiflik=0
    ORDER BY s.eklenmeTarihi ASC
</cfquery>

<cfquery name="qSikayet" datasource="DSN">
    SELECT s.id,s.hedefID,s.hedefTip,s.sebep,s.durum,s.tarih,
    k.ad AS sikayetciAd,
    CASE
    WHEN s.hedefTip='soru' THEN s.hedefID
    WHEN s.hedefTip='cevap' THEN(
    SELECT c.soruID FROM Cevap c WHERE c.id=s.hedefID
    )
    WHEN s.hedefTip='yorum' THEN(
    SELECT c2.soruID FROM Yorum y INNER JOIN Cevap c2 ON c2.id=y.cevapID WHERE y.id=s.hedefID
    )
    ELSE NULL
    END AS ilgiliSoruID
    FROM Sikayet s
    INNER JOIN Kullanici k ON k.id=s.sikayetciID
    WHERE s.durum=0
    ORDER BY s.tarih DESC
</cfquery>

<cfoutput>
    <div class="yigin">
        <h1 class="goz">Yönetim paneli</h1>
        <cfif len(hata)>
            <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hata)#</div>
        </cfif>

        <cfif len(basari)>
            <div class="bildirim bildirim--basarili" role="status">#encodeForHTML(basari)#</div>
        </cfif>

        <div class="sekmeler" role="tablist">
            <button class="sekme" type="button" role="tab" aria-selected="true" aria-controls="panelBekleyen">Bekleyen Sorular:
                <span class="sekme__sayi">#qSoru.recordCount#</span>
            </button>
            <button class="sekme" type="button" role="tab" aria-selected="false" aria-controls="panelSikayet">Şikayetler:
                <span class="sekme__sayi">#qSikayet.recordCount#</span>
            </button>
            <button class="sekme" type="button" role="tab" aria-selected="false" aria-controls="panelKullanici">Kullanıcılar:
                <span class="sekme__sayi">#qKullanici.recordCount#</span>
            </button>
        </div>

        <div class="sekme-panel" id="panelBekleyen" role="tabpanel">
            <cfif qSoru.recordCount EQ 0>
                <div class="bos-durum">
                    <span class="bos-durum__daire" aria-hidden="true"></span>
                    <h3>Kuyruk boş</h3>
                    <p>Onay bekleyen soru yok.</p>
                </div>
            <cfelse>
                <div class="onay-kutu">
                    <cfloop query="qSoru">
                        <article class="soru-kutu">
                            <cfif len(trim(qSoru.soruResmi))>
                                <a class="soru-kutu__ust" href="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qSoru.soruResmi)#" target="_blank" rel="noopener">
                                    <img src="/YKSSite/assets/images/sorular/#encodeForHTMLAttribute(qSoru.soruResmi)#"
                                        class="soru-kutu__gorsel" alt="Onay bekleyen soru görseli">
                                </a>
                            <cfelse>
                                <div class="soru-kutu__onizleme">#encodeForHTML(left(qSoru.soruMetni,300))#</div>
                            </cfif>
                            <div class="soru-kutu__govde">
                                <div class="soru-kutu__etiket">
                                    <span class="rozet rozet--sinav">#encodeForHTML(qSoru.alanAd)#</span>
                                    <span class="rozet rozet--ders">#encodeForHTML(qSoru.dersAd)#</span>
                                    <cfif qSoru.sistemSoru EQ 1>
                                        <span class="rozet rozet--yz">Yapay zekâ</span>
                                    </cfif>
                                </div>
                                <div class="soru-kutu__sayac">
                                    <span>#encodeForHTML(qSoru.soranAd)#</span>
                                    <span>#dateFormat(qSoru.eklenmeTarihi,'dd.mm.yyyy')#</span>
                                </div>
                                <div class="tablo__eylem">
                                    <form method="POST" style="flex:1">
                                        <input type="hidden" name="csrf" value="#SESSION.csrf#">
                                        <input type="hidden" name="islem" value="onayla">
                                        <input type="hidden" name="soruID" value="#qSoru.id#">
                                        <button class="dugme dugme--onay dugme--kucuk dugme--tam" type="submit" onclick="return confirm('Soruyu onaylamak istediğine emin misiniz?')">Onayla</button>
                                    </form>
                                    <form method="POST" style="flex:1">
                                        <input type="hidden" name="csrf" value="#SESSION.csrf#">
                                        <input type="hidden" name="islem" value="reddet">
                                        <input type="hidden" name="soruID" value="#qSoru.id#">
                                        <button class="dugme dugme--red dugme--kucuk dugme--tam" type="submit" onclick="return confirm('Soru ve görseli kalıcı olarak silinecek.Emin misiniz?')">Reddet</button>
                                    </form>
                                </div>
                            </div>
                        </article>
                    </cfloop>
                </div>
            </cfif>
        </div>
		
        <div class="sekme-panel" id="panelSikayet" role="tabpanel" hidden>
            <cfif qSikayet.recordCount EQ 0>
                <div class="bos-durum">
                    <span class="bos-durum__daire" aria-hidden="true"></span>
                    <h3>Şikayet yok</h3>
                    <p>Bekleyen şikayet bulunmuyor.</p>
                </div>
            <cfelse>
                <div class="tablo-sarmal">
                    <table class="tablo">
                        <thead>
                            <tr>
                                <th scope="col">Şikayetçi</th>
                                <th scope="col">Tür</th>
                                <th scope="col">Sebep</th>
                                <th scope="col">Tarih</th>
                                <th scope="col">İşlem</th>
                            </tr>
                        </thead>
                        <tbody>
                            <cfloop query="qSikayet">
                                <tr>
                                    <td>#encodeForHTML(qSikayet.sikayetciAd)#</td>
                                    <td>
                                        <span class="rozet">
                                            #qSikayet.hedefTip EQ 'soru' ? 'Soru' : qSikayet.hedefTip EQ 'cevap' ? 'Çözüm' : qSikayet.hedefTip EQ 'yorum' ? 'Yorum' : 'Kullanıcı'#
                                            ###qSikayet.hedefID#
                                        </span>
                                    </td>
                                    <td>#encodeForHTML(qSikayet.sebep)#</td>
                                    <td class="veri">#dateFormat(qSikayet.tarih,'dd.mm.yyyy')#</td>
                                    <td>
                                        <div class="tablo__eylem">
                                            <cfif qSikayet.hedefTip EQ "kullanici">
                                                <a class="dugme dugme--ikincil dugme--kucuk" href="/YKSSite/views/profil/profilim.cfm?id=#qSikayet.hedefID#" target="_blank" rel="noopener">Profili incele</a>
                                            <cfelseif val(qSikayet.ilgiliSoruID) GT 0>
                                                <a class="dugme dugme--ikincil dugme--kucuk" href="/YKSSite/views/soru/soruDetay.cfm?id=#qSikayet.ilgiliSoruID#" target="_blank" rel="noopener">İçeriği incele</a>
                                            <cfelse>
                                                <span class="sessiz">İçerik yok</span>
                                            </cfif>
                                            <form method="POST">
                                                <input type="hidden" name="csrf" value="#SESSION.csrf#">
                                                <input type="hidden" name="islem" value="sikayetCoz">
                                                <input type="hidden" name="sikayetID" value="#qSikayet.id#">
                                                <button class="dugme dugme--onay dugme--kucuk" type="submit" onclick="return confirm('Şikayet onaylanacak ve içerik yayından kaldırılacak.Emin misiniz?')">Onayla</button>
                                            </form>
                                            <form method="POST">
                                                <input type="hidden" name="csrf" value="#SESSION.csrf#">
                                                <input type="hidden" name="islem" value="sikayetReddet">
                                                <input type="hidden" name="sikayetID" value="#qSikayet.id#">
                                                <button class="dugme dugme--red dugme--kucuk" type="submit" onclick="return confirm('Şikayeti reddetmek istediğine emin misiniz?')">Reddet</button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            </cfloop>
                        </tbody>
                    </table>
                </div>
            </cfif>
        </div>
        <div class="sekme-panel" id="panelKullanici" role="tabpanel" hidden>
            <div class="tablo-sarmal">
                <table class="tablo">
                    <thead>
                        <tr>
                            <th scope="col">Kullanıcı</th>
                            <th scope="col">Rol</th>
                            <th scope="col">XP</th>
                            <th scope="col">Kayıt</th>
                            <th scope="col">Durum</th>
                            <th scope="col">İşlem</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop query="qKullanici">
                            <tr class="#qKullanici.aktiflik EQ 0 ? 'pasif' : ''#">
                                <td>
                                    <a class="bag" href="/YKSSite/views/profil/profilim.cfm?id=#qKullanici.id#">#encodeForHTML(qKullanici.ad)#</a>
                                    <cfif qKullanici.sistemHesap EQ 1>
                                        <span class="rozet rozet--sistem">Sistem</span>
                                    </cfif>
                                </td>
                                <td>
                                    <cfif yoneticiRol EQ 3 AND qKullanici.id NEQ yoneticiID AND qKullanici.sistemHesap EQ 0>
                                        <form method="POST">
                                            <input type="hidden" name="csrf" value="#SESSION.csrf#">
                                            <input type="hidden" name="islem" value="rolDegistir">
                                            <input type="hidden" name="kullaniciID" value="#qKullanici.id#">
                                            <select class="secim secim--kucuk" name="yeniRol" data-eski="#qKullanici.rol-1#" onchange="rolDegistir(this)" aria-label="#encodeForHTMLAttribute(qKullanici.ad)# rolü">
                                                <option value="1" #qKullanici.rol EQ 1 ? 'selected':''#>Kullanıcı</option>
                                                <option value="2" #qKullanici.rol EQ 2 ? 'selected':''#>Moderatör</option>
                                                <option value="3" #qKullanici.rol EQ 3 ? 'selected':''#>Admin</option>
                                            </select>
                                        </form>
                                    <cfelse>
                                        <span class="rozet">#qKullanici.rol EQ 3 ? 'Admin' : qKullanici.rol EQ 2 ? 'Moderatör' : 'Kullanıcı'#</span>
                                    </cfif>
                                </td>
                                <td class="veri">#numberFormat(qKullanici.xp,',')#</td>
                                <td class="veri">#dateFormat(qKullanici.kayitTarihi,'dd.mm.yyyy')#</td>
                                <td>
                                    <span class="rozet #qKullanici.aktiflik EQ 1 ? 'rozet--aktif' : 'rozet--pasif'#">#qKullanici.aktiflik EQ 1 ? 'Aktif' : 'Engelli'#</span>
                                </td>
                                <td>
                                    <cfif qKullanici.id NEQ yoneticiID AND qKullanici.sistemHesap EQ 0 AND val(qKullanici.rol) LT yoneticiRol>
                                        <form method="POST">
                                            <input type="hidden" name="csrf" value="#SESSION.csrf#">
                                            <input type="hidden" name="islem" value="#qKullanici.aktiflik EQ 1 ? 'kullaniciBan':'kullaniciAktiflestir'#">
                                            <input type="hidden" name="kullaniciID" value="#qKullanici.id#">
                                            <button class="dugme #qKullanici.aktiflik EQ 1 ? 'dugme--red':'dugme--onay'# dugme--kucuk" type="submit" onclick="return confirm('#jsStringFormat(qKullanici.ad)# kullanıcısı için işlemi onaylıyor musunuz?')">#qKullanici.aktiflik EQ 1 ? 'Engelle':'Aktif Et'#</button>
                                        </form>
                                    <cfelse>
                                        <span class="sessiz">—</span>
                                    </cfif>
                                </td>
                            </tr>
                        </cfloop>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</cfoutput>

<script>
    function rolDegistir(secici){
        if(confirm('Kullanıcı rolünü değiştirmek istediğinize emin misiniz?')){
            secici.form.submit();
        }else{
            secici.selectedIndex=secici.dataset.eski || 0;
        }
    }
</script>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">