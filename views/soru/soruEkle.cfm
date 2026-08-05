<cfinclude template="/YKSSite/views/includes/baslik.cfm">
<cfinclude template="/YKSSite/views/includes/oturumKontrol.cfm">

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

<script>
    const dersler={
        <cfoutput query="qDers">
            "#id#":{ad:"#JSStringFormat(ad)#",alanID:"#alanID#"}<cfif currentRow NEQ recordCount>,</cfif>
        </cfoutput>
    };

    function dersFiltrele(alanID){
        const dersSec=document.getElementById('dersSec');
        dersSec.innerHTML='<option value="0">Ders Seçiniz.</option>';

        Object.entries(dersler).forEach(([id,ders])=>{
            if(ders.alanID==alanID){
                dersSec.innerHTML+=`<option value="${id}">${ders.ad}</option>`;
            }
        });
    }
</script>

<cfparam name="hata" default="">
<cfparam name="basari" default="">

<cfif structKeyExists(form,"soruEkle")>
    <cfset dersID=val(form.dersID)>
    <cfset dogruCevap=trim(form.dogruCevap)>

    <cfif dersID EQ 0>
        <cfset hata="Lütfen bir ders seçiniz.">
    <cfelseif dogruCevap EQ "">
        <cfset hata="Lütfen bir cevap seçiniz.">
    <cfelseif NOT listFind("A,B,C,D,E",dogruCevap)>
        <cfset hata="Geçersiz cevap seçeneği.">
    <cfelseif NOT structKeyExists(form,"soruResmi") OR form.soruResmi EQ "">
        <cfset hata="Lütfen soru resmini yükleyiniz.">
    <cfelse>
        <cfset resimYolu=expandPath("/YKSSite/assets/images/sorular/")>
        <cfset izinliFormat="jpg,jpeg,png,webp">

        <cffile action="upload"
                    filefield="soruResmi"
                    destination="#resimYolu#"
                    nameconflict="makeunique"
                    result="yuklenenDosya">
        
        <cfset dosyaUzantisi=lCase(yuklenenDosya.serverFileExt)>

        <cfif NOT listFind(izinliFormat,dosyaUzantisi)>
            <cffile action="delete" file="#yuklenenDosya.serverDirectory#/#yuklenenDosya.serverFile#">
            <cfset hata="Sadece JPG,JPEG,PNG veya WEBP formatı kabul edilmektedir.">
        <cfelse>
            <cfset dosyaAdi=createUUID() & "." & dosyaUzantisi>

            <cffile action="rename"
                    source="#yuklenenDosya.serverDirectory#/#yuklenenDosya.serverFile#"
                    destination="#yuklenenDosya.serverDirectory#/#dosyaAdi#">

            <cfset dosyaAdi=yuklenenDosya.serverFile>
            
            <cfquery datasource="DSN">
                INSERT INTO Soru(dersID,soranID,dogruCevap,soruResmi,aktiflik,goruntulenmeSayisi,eklenmeTarihi)
                VALUES(
                    <cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#dogruCevap#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#dosyaAdi#" cfsqltype="cf_sql_varchar">,
                    0,
                    0,
                    GETDATE()
                )
            </cfquery>

            <cfquery datasource="DSN">
                INSERT INTO Puan(kullaniciID,islemTipi,puanDegeri,eklenmeTarihi)
                VALUES(
                    <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                    'soru_ekledi',
                    5,
                    GETDATE()
                )
            </cfquery>

            <cfquery datasource="DSN">
                UPDATE Kullanici 
                SET xp=xp+5
                WHERE id=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset basari="Sorunuz,moderatör onayına gönderildi.">
        </cfif>
    </cfif>
</cfif>

<cfoutput>
    <div class="container mt-4">
        <div class="row justify-content-center">
            <div class="col-md-7">
                <div class="card shadow">
                    <div class="card-header bg-dark text-white text-center">
                        <h4><i class="bi bi-plus-circle"></i>Soru Ekle</h4>
                    </div>

                    <div class="card-body">
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

                        <form method="POST" enctype="multipart/form-data">
                            <div class="mb-3">
                                <label class="form-label">Alan:</label>
                                <select id="alanSec" class="form-select" onchange="dersFiltrele(this.value)">
                                    <option value="0">Alan Seçiniz.</option>
                                    <cfoutput query="qAlan">
                                        <option value="#id#">#ad#</option>
                                    </cfoutput>
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
                                <small class="text-muted">JPG,JPEG,PNG veya WEBP formatında yükleyiniz.</small>

                                <div id="onizlemeDiv" class="mt-3 text-center d-none">
                                    <p class="text-muted small mb-1">Seçilen Resim Önizlemesi</p>
                                    <img id="onizleme" src="" alt="Soru Önizleme" class="img-fluid rounded border shadow-sm" style="max-height:300px;"
                                </div>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Doğru Cevap:</label>
                                <div class="d-flex gap-2">
                                    <cfoutput>
                                        <cfloop list="A,B,C,D,E" index="sik">
                                            <input type="radio" class="btn-check" name="dogruCevap" id="sik#sik#" value="#sik#" required>
                                            <label class="btn btn-outline-dark" for="sik#sik#">#sik#</label>
                                        </cfloop>
                                    </cfoutput>
                                </div>
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