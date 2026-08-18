<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

<cfset kullaniciID=val(SESSION.kullaniciID)>

<cfquery name="qAlan" datasource="DSN">
    SELECT id,ad
    FROM Alan
    ORDER BY id
</cfquery>

<cfquery name="qDers" datasource="DSN">
    SELECT id,ad,alanID
    FROM Ders
    ORDER BY ad
</cfquery>

<cfparam name="hata" default="">
<cfparam name="basari" default="">

<cfif structKeyExists(form,"soruEkle")>
    <cfparam name="form.dersID" default="0">
    <cfparam name="form.dogruCevap" default="">

    <cfset dersID=val(form.dersID)>
    <cfset dogruCevap=uCase(trim(form.dogruCevap))>
    <cfset yuklendiMi=false>
    <cfset tamYol="">

    <cfquery name="qGunluk" datasource="DSN">
        SELECT COUNT(*) AS adet
        FROM Soru
        WHERE soranID=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
        AND CAST(eklenmeTarihi AS DATE)=CAST(GETDATE() AS DATE)
    </cfquery>

    <cfquery name="qDersKontrol" datasource="DSN">
        SELECT id
        FROM Ders
        WHERE id=<cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif dersID EQ 0 OR qDersKontrol.recordCount EQ 0>
        <cfset hata="Lütfen geçerli bir ders seçiniz.">
    <cfelseif NOT listFind("A,B,C,D,E",dogruCevap)>
        <cfset hata="Lütfen geçerli bir cevap seçiniz.">
    <cfelseif NOT structKeyExists(form,"soruResmi") OR NOT len(trim(form.soruResmi))>
        <cfset hata="Lütfen soru resmini yükleyiniz.">
    <cfelseif qGunluk.adet GTE 20>
        <cfset hata="Günlük soru ekleme sınırına ulaştınız.">
    <cfelse>
        <cftry>
            <cfset resimYolu=expandPath("/YKSSite/assets/images/sorular/")>
            <cfset izinliFormat="jpg,jpeg,png,webp">

            <cffile action="upload"
                    filefield="soruResmi"
                    destination="#resimYolu#"
                    nameconflict="makeunique"
                    result="yuklenenDosya">

            <cfset yuklendiMi=true>
            <cfset tamYol=resimYolu & yuklenenDosya.serverFile>
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

                        <cfquery datasource="DSN">
                            INSERT INTO Puan(kullaniciID,islemTipi,puanDegeri,referansID,referansTip,eklenmeTarihi)
                            VALUES(
                                <cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">,
                                <cfqueryparam value="soru_ekledi" cfsqltype="cf_sql_varchar">,
                                3,
                                <cfqueryparam value="#yeniSoruID#" cfsqltype="cf_sql_integer">,
                                <cfqueryparam value="soru" cfsqltype="cf_sql_varchar">,
                                GETDATE()
                            )
                        </cfquery>

                        <cfquery datasource="DSN">
                            UPDATE Kullanici
                            SET xp=xp+3
                            WHERE id=<cfqueryparam value="#kullaniciID#" cfsqltype="cf_sql_integer">
                        </cfquery>
                    </cftransaction>

                    <cfset yuklendiMi=false>
                    <cfset SESSION.xp=val(SESSION.xp)+3>
                    <cfset basari="Sorunuz,moderatör onayına gönderildi. (+3 XP)">
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
        ilk.textContent='Ders Seçiniz.';
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
    <div class="container mt-4">
        <div class="row justify-content-center">
            <div class="col-md-7">
                <div class="card shadow">
                    <div class="card-header bg-dark text-white text-center">
                        <h4 class="mb-0"><i class="bi bi-plus-circle"></i>Soru Ekle</h4>
                    </div>

                    <div class="card-body">
                        <cfif len(hata)>
                            <div class="alert alert-danger">
                                <i class="bi bi-exclamation-circle"></i>#encodeForHTML(hata)#
                            </div>
                        </cfif>

                        <cfif len(basari)>
                            <div class="alert alert-success">
                                <i class="bi bi-check-circle"></i>#encodeForHTML(basari)#
                            </div>
                        </cfif>

                        <form method="POST" enctype="multipart/form-data">
                            <div class="mb-3">
                                <label class="form-label">Alan:</label>

                                <select id="alanSec" class="form-select" onchange="dersFiltrele(this.value)">
                                    <option value="0">Alan Seçiniz.</option>
                                    <cfloop query="qAlan">
                                        <option value="#qAlan.id#">#encodeForHTML(qAlan.ad)#</option>
                                    </cfloop>
                                </select>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Ders:</label>

                                <select name="dersID" id="dersSec" class="form-select" required>
                                    <option value="0">Önce alan seçiniz.</option>
                                </select>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Soru Resmi:</label>
                                <input type="file" name="soruResmi" class="form-control" accept=".jpg,.jpeg,.png,.webp" required>
                                <small class="text-muted">JPG,JPEG,PNG veya WEBP formatında,en fazla 5 MB olmalıdır.</small>

                                <div id="onizlemeDiv" class="mt-3 text-center d-none">
                                    <p class="text-muted small mb-1">Seçilen Resim Önizlemesi</p>
                                    <img id="onizleme" src="" alt="Soru Önizleme"
                                        class="img-fluid rounded border shadow-sm" style="max-height:300px;">
                                </div>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Doğru Cevap:</label>

                                <div class="d-flex gap-2">
                                    <cfloop list="A,B,C,D,E" index="sik">
                                        <input type="radio" class="btn-check" name="dogruCevap" id="sik#sik#" value="#sik#" required>
                                        <label class="btn btn-outline-dark" for="sik#sik#">#sik#</label>
                                    </cfloop>
                                </div>

                                <small class="text-muted">Doğru cevabı dikkatle seçiniz. Hatalı seçim moderatör tarafından düzeltilir.</small>
                            </div>

                            <div class="d-grid">
                                <button type="submit" name="soruEkle" value="1" class="btn btn-dark">
                                    <i class="bi bi-cloud-upload"></i>Soruyu Yükle
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</cfoutput>

<cfinclude template="/YKSSite/views/includes/altBilgi.cfm">