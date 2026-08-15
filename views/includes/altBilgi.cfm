<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
<script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
 <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"></script>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

<script src="/YKSSite/assets/js/custom.js"></script>

<script>
    document.addEventListener("DOMContentLoaded",function(){
        renderMathInElement(document.body,{
            delimiters:[
                {left:"$$",right:"$$",display:true},
                {left:"$",right:"$",display:false},
                {left:"\\(",right:"\\)",display:false},
                {left:"\\[",right:"\\]",display:true}
            ],
            throwOnError=false
        });
    });
</script>

<script>
    document.getElementById('aiCozModal')?.addEventListener('show.bs.modal',function(){
        const icerik=document.getElementById('aiCozumIcerik');
        
        if(icerik.dataset.yuklendi==='1') return;

        fetch('/YKSSite/views/soru/aiCozdurme.cfm?soruID=<cfoutput>soruID</cfoutput>')
            .then(r=>r.json())
            .then(data=>{
                if(data.basari){
                    icerik.innerHTML='<div class="p-3">'+data.metin.replace(/\n/g,'<br>')+'</div>';
                }else{
                    icerik.innerHTML='<div class="alert alert-danger">'+data.hata+'</div>';
                }

                icerik.dataset.yuklendi='1';
            })
            .catch(()=>{
                icerik.innerHTML='<div class="alert alert-danger">Bağlantı hatası.</div>';
            });
    });
</script>

<script>
    fetch('/YKSSite/views/soru/aiCozdurme.cfm?soruID='+soruID)
        .then(r=>r.json())
        .then(data=>{
            if(data.basari){
                document.getElementById('aiCozum').innerHTML=data.metin;

                renderMathInElement(document.getElementById('aiCozum'),{
                    delimiters:[
                        {left:"$$",right:"$$",display:true},
                        {left:"$",right:"$",display:false}
                    ],
                    throwOnError:false
                });
            }else{
                document.getElementById('aiCozum').innerHTML=data.hata;
            }
        })
        .catch(()=>{
            document.getElementById('aiCozum').innerHTML='Bağlantı hatası,tekrar deneyiniz.';
        });
</script>