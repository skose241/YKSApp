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