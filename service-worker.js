var surum=new URL(self.location).searchParams.get("v") || "0";
var onbellek="np-" + surum;
var cevrimdisiSayfa="/YKSSite/offline.html";
var kabuk=[
    "/YKSSite/assets/css/style.css?v=" + surum,
    "/YKSSite/assets/js/custom.js?v=" + surum,
    "/YKSSite/assets/vendor/katex/katex.min.css?v=" + surum,
    "/YKSSite/assets/vendor/katex/katex.min.js?v=" + surum,
    "/YKSSite/assets/vendor/katex/auto-render.min.js?v=" + surum,
    "/YKSSite/assets/images/favicon.ico",
    "/YKSSite/assets/images/icon-512.png",
    cevrimdisiSayfa
];

self.addEventListener("install",function(event){
    event.waitUntil(
        caches.open(onbellek).then(function(c){
            return Promise.all(kabuk.map(function(yol){
                return c.add(yol).catch(function(){ return null; });
            }));
        })
    );
    self.skipWaiting();
});

self.addEventListener("activate",function(event){
    event.waitUntil(
        caches.keys().then(function(adlar){
            return Promise.all(adlar.filter(function(a){
                return a!==onbellek;
            }).map(function(a){
                return caches.delete(a);
            }));
        })
    );
    self.clients.claim();
});

function statikMi(url){
    return url.indexOf("/YKSSite/assets/")!==-1;
}

self.addEventListener("fetch",function(event){
    if(event.request.method!=="GET") return;
    var url=event.request.url;
    if(url.indexOf("/YKSSite/")===-1) return;
    if(event.request.mode==="navigate"){
        event.respondWith(
            fetch(event.request).catch(function(){
                return caches.match(cevrimdisiSayfa).then(function(bulunan){
                    return bulunan || new Response("Çevrimdışısınız.",{ status:503, headers:{ "Content-Type":"text/plain; charset=utf-8" } });
                });
            })
        );
        return;
    }
	
    if(statikMi(url)){
        event.respondWith(
            caches.match(event.request, { ignoreSearch: false }).then(function(bulunan){
                if(bulunan) return bulunan;
                return fetch(event.request).then(function(cevap){
                    if(cevap && cevap.status===200){
                        var kopya = cevap.clone();
                        caches.open(onbellek).then(function(c){
                            c.put(event.request, kopya);
                        });
                    }
                    return cevap;
                });
            })
        );
        return;
    }
});