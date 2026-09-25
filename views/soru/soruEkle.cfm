<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">
<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfset kullaniciID=val(SESSION.kullaniciID)>
<cfset qAlan=duplicate(application.qAlan)>
<cfset qDers=duplicate(application.qDers)>
<cfset izinliFormat="jpg,jpeg,png,webp">
<cfset resimYolu=expandPath("/YKSSite/assets/images/sorular/")>
<cfparam name="hata" default="">
<cfparam name="basari" default="">

<cfif structKeyExists(form,"soruEkle")>
    <cfparam name="form.dersID" default="0">
    <cfparam name="form.dogruCevap" default="">
    <cfparam name="form.csrf" default="">
    <cfset dersID=val(form.dersID)>
    <cfset dogruCevap=uCase(trim(form.dogruCevap))>
    <cfset yuklendiMi=false>
    <cfset tamYol="">

    <cfquery name="qGunluk" datasource="DSN">
        SELECT COUNT(*) AS adet
        FROM Soru
        WHERE soranID=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
        AND eklenmeTarihi>=CAST(GETDATE() AS DATE)
    </cfquery>

    <cfquery name="qDersKontrol" datasource="DSN">
        SELECT id
        FROM Ders
        WHERE id=<cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif compare(form.csrf,SESSION.csrf) NEQ 0>
        <cfset hata="Oturum doğrulaması başarısız.Sayfayı yenileyip tekrar deneyiniz.">
    <cfelseif dersID EQ 0 OR qDersKontrol.recordCount EQ 0>
        <cfset hata="Lütfen geçerli bir ders seçiniz.">
    <cfelseif NOT listFind("A,B,C,D,E",dogruCevap)>
        <cfset hata="Lütfen geçerli bir cevap seçiniz.">
    <cfelseif NOT structKeyExists(form,"soruResmi") OR NOT len(trim(form.soruResmi))>
        <cfset hata="Lütfen soru resmini yükleyiniz.">
    <cfelseif qGunluk.adet GTE 20>
        <cfset hata="Günlük soru ekleme sınırına ulaştınız.">
    <cfelse>
        <cftry>
            <cfset geciciYol=expandPath("/YKSSite/gecici/")>
            <cfif NOT directoryExists(geciciYol)>
                <cfdirectory action="create" directory="#geciciYol#">
            </cfif>

            <cffile action="upload"
                filefield="soruResmi"
                destination="#geciciYol#"
                nameconflict="makeunique"
                result="yuklenenDosya">
            <cfset yuklendiMi=true>
            <cfset tamYol=geciciYol & yuklenenDosya.serverFile>
            <cfset dosyaUzantisi=lCase(yuklenenDosya.serverFileExt)>

            <cfif NOT listFind(izinliFormat,dosyaUzantisi)>
                <cffile action="delete" file="#tamYol#">
                <cfset yuklendiMi=false>
                <cfset hata="Sadece JPG,JPEG,PNG veya WEBP formatı kabul edilmektedir.">
            <cfelseif yuklenenDosya.fileSize GT 5242880>
                <cffile action="delete" file="#tamYol#">
                <cfset yuklendiMi=false>
                <cfset hata="Dosya boyutu 5 MB üzerinde olamaz.">
            <cfelse>
                <cftry>
                    <cfimage action="read" source="#tamYol#" name="kontrolResim">
                    <cfset gecerliResim=imageGetWidth(kontrolResim) GT 0>
                    <cfcatch type="any">
                        <cfset gecerliResim=false>
                    </cfcatch>
                </cftry>

                <cfif NOT gecerliResim>
                    <cffile action="delete" file="#tamYol#">
                    <cfset yuklendiMi=false>
                    <cfset hata="Geçerli bir resim dosyası yükleyiniz.">
                <cfelse>
                    <cfset yeniAd=createUUID() & "." & dosyaUzantisi>
                    <cffile action="rename"
                        source="#tamYol#"
                        destination="#resimYolu##yeniAd#">
                    <cfset tamYol=resimYolu & yeniAd>
                    <cftransaction>
                        <cfquery name="qYeniSoru" datasource="DSN">
                            INSERT INTO Soru(dersID,soranID,dogruCevap,soruResmi,sistemSoru,aktiflik,goruntulenmeSayisi,eklenmeTarihi)
                            OUTPUT INSERTED.id AS yeniID
                            VALUES(
                            <cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#dogruCevap#" cfsqltype="cf_sql_char">,
                            <cfqueryparam value="#yeniAd#" cfsqltype="cf_sql_varchar">,
                            0,
                            0,
                            0,
                            GETDATE()
                            )
                        </cfquery>
                        <cfset yeniSoruID=val(qYeniSoru.yeniID)>
                        <cfif yeniSoruID LTE 0>
                            <cfthrow message="Soru ID alınamadı.">
                        </cfif>
                    </cftransaction>

                    <cfset yuklendiMi=false>
                    <cfset basari="Sorunuz,moderatör onayına gönderildi. Onaylandığında 3 XP kazanacaksınız">
                </cfif>
            </cfif>

            <cfcatch type="any">
                <cfset hata="Soru eklenirken bir hata oluştu.">
                <cfif yuklendiMi AND len(tamYol) AND fileExists(tamYol)>
                    <cftry>
                        <cffile action="delete" file="#tamYol#">
                        <cfcatch type="any"></cfcatch>
                    </cftry>
                </cfif>

                <cfset aiHata=createObject("component","YKSSite.views.includes.ai")>
                <cfset aiHata.hataYazma(
                    sayfa="/YKSSite/views/soru/soruEkle.cfm",
                    islem="soruEkle",
                    mesaj=cfcatch.message,
                    detay=cfcatch.detail
                    )>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<script>
    const dersler={
        <cfoutput query="qDers">"#qDers.id#":{ad:"#jsStringFormat(qDers.ad)#",alanID:"#qDers.alanID#"}<cfif qDers.currentRow NEQ qDers.recordCount>,</cfif></cfoutput>
    };
    function dersFiltrele(alanID){
        const dersSec=document.getElementById('dersSec');
        dersSec.innerHTML='';
        const ilk=document.createElement('option');
        ilk.value='0';
        ilk.textContent=alanID==='0' ? "Önce Alan Seçiniz.":"Ders Seçiniz";
        dersSec.appendChild(ilk);
        Object.entries(dersler).forEach(([id,ders])=>{
            if(ders.alanID==alanID){
                const opt=document.createElement('option');
                opt.value=id;
                opt.textContent=ders.ad;
                dersSec.appendChild(opt);
            }
        });
    }
</script>
<cfoutput>
    <div class="dar dar--genis">
        <section class="kart">
            <div class="kart__baslik">Soru Ekle</div>
            <div class="kart__govde">
                <cfif len(hata)>
                    <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hata)#</div>
                </cfif>
                <cfif len(basari)>
                    <div class="bildirim bildirim--basarili" role="status">
                        #encodeForHTML(basari)#
                        <a class="bag" href="/YKSSite/anaSayfa.cfm">Ana sayfaya dön</a>
                    </div>
                </cfif>
                <form method="POST" enctype="multipart/form-data">
                    <cfinclude template="/YKSSite/views/includes/csrfAlan.cfm">
                    <div class="alan ust-bosluk">
                        <label for="alanSec">Alan</label>
                        <select class="secim" id="alanSec" onchange="dersFiltrele(this.value)">
                            <option value="0">Alan seç</option>
                            <cfloop query="qAlan">
                                <option value="#qAlan.id#">#encodeForHTML(qAlan.ad)#</option>
                            </cfloop>
                        </select>
                    </div>
                    <div class="alan">
                        <label for="dersSec">Ders:</label>
                        <select class="secim" name="dersID" id="dersSec" required>
                            <option value="0">Önce alan seçiniz</option>
                        </select>
                    </div>
                    <div class="alan">
                        <label for="soruResmi">Soru Resmi:</label>
                        <div class="dosya-alan">
                            <input type="file" name="soruResmi" id="soruResmi" accept=".jpg,.jpeg,.png,.webp" required>
                            <span class="dosya-alan__simge" aria-hidden="true"><svg class="simge simge--buyuk"><use href="##s-yukle"></use></svg></span>
                            <span class="dosya-alan__baslik">Görsel seçiniz veya buraya sürükleyiniz</span>
                            <span class="dosya-alan__ipucu">JPG,PNG veya WEBP formatı olmalıdır·En fazla 5 MB boyut sınırı</span>
                        </div>
                        <div class="onizleme" id="onizlemeKutu" hidden>
                            <img src=""
                                class="onizleme__resim" id="onizleme" alt="Seçilen görselin önizlemesi">
                            <span class="onizleme__ad" id="onizlemeAd"></span>
                        </div>
                    </div>
                    <div class="alan">
                        <label>Doğru Cevap:</label>
                        <div class="siklar siklar--satir" role="radiogroup" aria-label="Doğru cevap">
                            <cfloop list="A,B,C,D,E" index="sik">
                                <label class="sik sik--sade">
                                    <input type="radio" name="dogruCevap" value="#sik#" required>
                                    <span class="optik" aria-hidden="true">#sik#</span>
                                    <span class="gizli-metin">#sik# şıkkı</span>
                                </label>
                            </cfloop>
                        </div>
                        <span class="alan__ipucu">Doğru cevabı düzgün giriniz. Olası bir yanlışlıkta,eklenen puanlar daha sonradan değiştirilecektir</span>
                    </div>
                    <button class="dugme dugme--ana dugme--tam" type="submit" name="soruEkle" value="1">Soruyu Yükle</button>
                </form>
            </div>
            <div class="kart__ayrac">
                <p class="sessiz">Eklediğiniz her bir soru moderatör onayından sonra yayına girer. Onaylanan her soru 3 XP kazandırır,günlük sınır 20 sorudur</p>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">