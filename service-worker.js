var surum=new URL(self.location).searchParams.get("v") || "0";
var onbellek="np-" + surum;

var kabuk=[
	"/YKSSite/assets/css/style.css",
	"/YKSSite/assets/js/custom.js",
	"/YKSSite/assets/vendor/katex/katex.min.css",
	"/YKSSite/assets/vendor/katex/katex.min.js",
	"/YKSSite/assets/vendor/katex/auto-render.min.js",
	"/YKSSite/assets/images/favicon.ico",
	"/YKSSite/assets/images/icon-512.png"
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
	if(event.request.method==="navigate") return;

	var url=event.request.url;
	if(url.indexOf("/YKSSite/")===-1) return;

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