self.addEventListener('fetch',function(event){
    event.respondWidth(fetch(event.request));
});