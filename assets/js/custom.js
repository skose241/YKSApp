document.querySelectorAll('.avatar-sec').forEach(img=>{
    img.addEventListener('click',function(){
        document.querySelectorAll('.avatar-sec').forEach(i=>{
            i.classList.remove('border-dark');
            i.classList.add('border-light');
        });

        this.classList.remove('border-light');
        this.classList.add('border-dark');

        const radio=this.previousElementSibling;

        if(radio && radio.type==='radio'){
            radio.checked=true;
        }
    });
});

document.querySelector('input[name="soruResmi"]')?.addEventListener('change',function(){
    const file=this.files[0];
    const onizleme=document.getElementById('onizleme');
    const onizlemeDiv=document.getElementById('onizlemeDiv');

    if(!file || !onizleme || !onizlemeDiv) return;

    if(file.size>5*1024*1024){
        alert('Dosya boyutu 5 MB üzerinde olamaz.');
        this.value='';
        onizlemeDiv.classList.add('d-none');
        return;
    }

    const reader=new FileReader();

    reader.onload=e=>{
        onizleme.src=e.target.result;
        onizlemeDiv.classList.remove('d-none');
    };

    reader.readAsDataURL(file);
});

if(typeof renderMathInElement==='function'){
    renderMathInElement(document.body,{
        delimiters:[
            {left:'$$',right:'$$',display:true},
            {left:'$',right:'$',display:false},
            {left:'\\(',right:'\\)',display:false},
            {left:'\\[',right:'\\]',display:true}
        ],
        throwOnError:false
    });
}

(function(){
    const modal=document.getElementById('aiCozModal');

    if(!modal) return;

    modal.addEventListener('show.bs.modal',function(e){
        const icerik=document.getElementById('aiCozumIcerik');

        if(!icerik || icerik.dataset.yuklendi==='1') return;

        const soruID=e.relatedTarget && e.relatedTarget.dataset.soruid;

        if(!soruID){
            icerik.textContent='Soru bilgisi okunamadı.';
            return;
        }

        fetch('/YKSSite/views/soru/aiCozdurme.cfm?soruID='+encodeURIComponent(soruID))
            .then(r=>{
                if(!r.ok) throw new Error('sunucu');
                return r.json();
            })
            .then(data=>{
                if(!data.basari){
                    icerik.textContent=data.hata || 'Bir hata oluştu.';
                    return;
                }

                icerik.textContent=data.metin;
                icerik.innerHTML=icerik.innerHTML.replace(/\n/g,'<br>');

                if(typeof renderMathInElement==='function'){
                    renderMathInElement(icerik,{
                        delimiters:[
                            {left:'$$',right:'$$',display:true},
                            {left:'$',right:'$',display:false}
                        ],
                        throwOnError:false
                    });
                }

                icerik.dataset.yuklendi='1';
            })
            .catch(()=>{
                icerik.textContent='Bağlantı hatası,tekrar deneyiniz.';
            });
    });
})();