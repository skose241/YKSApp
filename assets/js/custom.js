document.querySelectorAll('.avatar-sec').forEach(img=>{
    img.addEventListener('click',function(){
        document.querySelectorAll('.avatar-sec').forEach(i=>{
            i.classList.remove('border-dark');
            i.classList.add('border-light');
        });

        this.classList.remove('border-light');
        this.classList.add('border-dark');

        this.previousElementSibling.checked=true;
    });
});



document.querySelector('input[name="soruResmi"]')?.addEventListener('change',function(){
    const file=this.files[0];
    if(file){
        const reader=new FileReader();
        reader.onload=e=>{
            document.getElementById('onizleme').src=e.target.result;
            document.getElementById('onizlemeDiv').classList.remove('d-none');
        };
        reader.readAsDataURL(file);
    }
});