document.querySelector('input[name="soruResmi"]')?.addEventListener("change",function(){
    var dosya=this.files[0];
    var onizleme=document.getElementById("onizleme");
    var kutu=document.getElementById("onizlemeKutu");
    var ad=document.getElementById("onizlemeAd");
    if(!onizleme || !kutu) return;
    if(!dosya){
        kutu.hidden=true;
        return;
    }
    if(dosya.size>5 * 1024 * 1024){
        alert("Dosya boyutu 5 MB üzerinde olamaz.");
        this.value="";
        kutu.hidden=true;
        return;
    }
	var okuyucu=new FileReader();
    okuyucu.onload=function(olay){
        onizleme.src=olay.target.result;
        if(ad) ad.textContent=dosya.name;
        kutu.hidden=false;
    };
    okuyucu.readAsDataURL(dosya);
});

(function(){
    var kok=document.documentElement;
    var temaDugme=document.getElementById("temaDugme");
    if(temaDugme){
        temaDugme.addEventListener("click",function(){
            var gece=kok.dataset.tema==="gece";
            kok.dataset.tema=gece ? "gunduz":"gece";
            try{
                localStorage.setItem("npTema",kok.dataset.tema);
            }catch(e){}
            this.setAttribute("aria-label", gece ? "Gece moduna geç":"Gündüz moduna geç");
        });
    }
})();

document.querySelectorAll(".siklar").forEach(function(grup){
    grup.addEventListener("click",function(event){
        var sik=event.target.closest(".sik");
        if(!sik || sik.disabled) return;
        grup.querySelectorAll(".sik").forEach(function(d){
            d.setAttribute("aria-pressed","false");
        });
        sik.setAttribute("aria-pressed","true");
        var gizli=grup.parentNode.querySelector("input[name='secilenSik']");
        if(gizli) gizli.value=sik.dataset.sik;
    });
});

document.querySelectorAll("[data-cozum-ac]").forEach(function(dugme){
    dugme.addEventListener("click",function(){
        var kutu=document.getElementById(this.getAttribute("aria-controls"));
        if(!kutu) return;
        var acik=!kutu.hidden;
        kutu.hidden=acik;
        this.setAttribute("aria-expanded",String(!acik));
        this.textContent=acik ? "Çözümü Göster":"Çözümü Gizle";
    });
});

document.querySelectorAll(".cetvel").forEach(function(cetvel){
    var net=parseFloat(cetvel.dataset.net || "0");
    var toplam=parseFloat(cetvel.dataset.toplam || "40");
    var oran=Math.max(0, Math.min(100, (net / toplam) * 100));
    var dolgu=cetvel.querySelector(".cetvel__dolgu");
    var imlec=cetvel.querySelector(".cetvel__imlec");
    if(dolgu) dolgu.style.width=oran + "%";
    if(imlec) imlec.style.left=oran + "%";
});

document.addEventListener("click",function(event){
    document.querySelectorAll("details.hesap[open]").forEach(function(d){
        if(!d.contains(event.target)) d.removeAttribute("open");
    });
});

document.addEventListener("keydown",function(event){
    if(event.key!=="Escape") return;
    document.querySelectorAll("details.hesap[open]").forEach(function(d){
        d.removeAttribute("open");
    });
});

document.querySelectorAll(".sekmeler").forEach(function(grup){
    grup.addEventListener("click",function(event){
        var dugme=event.target.closest(".sekme");
        if(!dugme) return;
        grup.querySelectorAll(".sekme").forEach(function(d){
            d.setAttribute("aria-selected", "false");
            var p=document.getElementById(d.getAttribute("aria-controls"));
            if(p) p.hidden=true;
        });
        dugme.setAttribute("aria-selected", "true");
        var panel=document.getElementById(dugme.getAttribute("aria-controls"));
        if(panel) panel.hidden=false;
    });
});

document.querySelectorAll("[data-pencere-ac]").forEach(function(dugme){
    dugme.addEventListener("click",function(){
        var p=document.getElementById(this.dataset.pencereAc);
        if(p && typeof p.showModal==="function") p.showModal();
    });
});

document.querySelectorAll("[data-pencere-kapat]").forEach(function(dugme){
    dugme.addEventListener("click",function(){
        var p=this.closest("dialog");
        if(p) p.close();
    });
});

document.addEventListener("click",function(event){
    var dugme=event.target.closest("[data-ac]");
    if(!dugme) return;
    var hedef=document.getElementById(dugme.dataset.ac);
    if(!hedef) return;
    hedef.hidden=!hedef.hidden;
    dugme.setAttribute("aria-expanded", String(!hedef.hidden));
});

document.addEventListener("DOMContentLoaded",function(){
    if(typeof renderMathInElement !== "function") return;
    document.querySelectorAll(".soru__metin, .cozum, .ai-kutu, .soru-kutu__onizleme, .sik__yazi").forEach(function(alan){
        renderMathInElement(alan,{
            delimiters: [
                { left: "$$", right: "$$", display: true },
                { left: "$", right: "$", display: false },
                { left: "\\(", right: "\\)", display: false },
                { left: "\\[", right: "\\]", display: true }
            ],
            throwOnError: false
        });
    });
});

(function(){
    var pencere=document.getElementById("aiPencere");
    var acDugme=document.getElementById("aiAcDugme");
    var icerik=document.getElementById("aiCozumIcerik");
    if(!pencere || !acDugme || !icerik) return;

    var ilkIcerik=icerik.innerHTML;
    acDugme.addEventListener("click",function(){
        if(icerik.dataset.yuklendi==="1" || icerik.dataset.yukleniyor==="1") return;
        var soruID=this.dataset.soruid;
        var csrf=this.dataset.csrf || "";
        if(!soruID){
            icerik.textContent="Soru bilgisi okunamadı.";
            return;
        }
        icerik.dataset.yukleniyor="1";
        icerik.innerHTML=ilkIcerik;
        fetch("/YKSSite/views/soru/aiCozdurme.cfm",{
            method:"POST",
            headers:{"Content-Type":"application/x-www-form-urlencoded; charset=UTF-8"},
            body:"soruID="+encodeURIComponent(soruID)+"&csrf="+encodeURIComponent(csrf)
        })
        .then(function(r){
            if(!r.ok) throw new Error("sunucu");
            return r.json();
        })
        .then(function(data){
            if(!data.basari){
                icerik.textContent=data.hata || "Bir hata oluştu.";
                return;
            }
            icerik.textContent=data.metin;
            icerik.innerHTML=icerik.innerHTML.replace(/\n/g,"<br>");
            if(typeof renderMathInElement==="function"){
                renderMathInElement(icerik,{
                    delimiters:[
                        {left:"$$",right:"$$",display:true},
                        {left:"$",right:"$",display:false}
                    ],
                    throwOnError:false
                });
            }
            icerik.dataset.yuklendi="1";
        })
        .catch(function(){
            icerik.textContent="Çözüm alınamadı, lütfen tekrar deneyiniz.";
        })
        .finally(function(){
            icerik.dataset.yukleniyor="0";
        });
    });
})();