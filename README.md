# Net Peşinde — YKS Soru & Çözüm Platformu

YKS'ye hazırlanan öğrencileri düzenli soru çözmeye teşvik eden; soru paylaşma, çözüm tartışma ve puanlama üzerine kurulu bir web platformu.

---

## Proje Hakkında

Öğrenciler platforma kendi çözemedikleri veya paylaşmak istedikleri soruları yükler, diğer öğrencilerin sorularını çözer ve çözüm yollarını birbirleriyle tartışır. Doğru çözümler ve onaylanan sorular XP kazandırır; bu puanlar liderlik tablosunda sıralanır. Yapay zekâ desteğiyle her gün yeni sorular üretilir ve istenen sorular için adım adım çözüm sunulur.

## Özellikler

### Hesap ve profil
- Platformu kullanmak için kayıt zorunludur; her kullanıcı benzersiz bir kullanıcı adı ve kendi şifresiyle kayıt olur.
- Şifre, kayıtta seçilen gizli soru üzerinden sıfırlanabilir.
- Kullanıcı profilinde kişinin sorduğu ve çözdüğü sorular listelenir; profiller diğer kullanıcılara açıktır.

### Soru paylaşımı
- Sorular fotoğraf olarak yüklenir. Kullanıcı dersi seçer, soru otomatik olarak o dersin alanına bağlanır.
- Soruyu yükleyen kişi doğru cevabı işaretlemek zorundadır.
- Yüklenen her soru moderatör onayından sonra yayına girer.
- Ana sayfada sorular, alan ve ders bazında filtrelenebilir.
- Sorular, favorilere eklenerek daha sonra tekrar incelenebilir.

### Çözüm ve tartışma
- Kullanıcı bir şık işaretleyerek soruyu cevaplar; isteğe bağlı olarak çözüm yolunu yazılı olarak anlatabilir.
- Diğer kullanıcıların çözümleri yalnızca soruyu cevaplamış kişilere gösterilir; böylece kopya çekmenin önüne geçilmiş  olunur.
- Çözümlerin altında iki seviyeli yorum ve yanıt ağacı bulunur. Bir çözümdeki hata, tartışma içinde diğer kullanıcılar tarafından düzeltilebilir.
- Yorum ve yanıtlar ilgili kişiye bildirim olarak iletilir.

### Puanlama
- Doğru cevap 5 XP, moderatör tarafından onaylanan soru 3 XP kazandırır.
- Kazanılan puanlara göre liderlik tablosu oluşturulur.

### Yapay zekâ desteği
- Google Gemini ile her gün farklı derslerden otomatik "Günün Soruları" üretilir.
- Kullanıcılar bir soru için yapay zekâdan adım adım çözüm isteyebilir. Her soru için çözüm bir kez üretilir, sonraki isteklerde önbellekten sunulur; kullanıcı başına günlük istek sınırı vardır.

### Moderasyon
- Sorular, çözümler, yorumlar ve kullanıcılar şikayet edilebilir; her yeni şikayet moderatörlere bildirim olarak düşer.
- Cevap anahtarının yanlış olduğu bildirilen sorularda moderatör doğru cevabı değiştirebilir. Bu durumda tüm kullanıcı cevapları ve puanları yeniden hesaplanır, etkilenen kullanıcılar bilgilendirilir.
- Uygunsuz dil kullanan hesaplar engellenebilir.

### Arayüz
- Gündüz ve gece teması.
- Matematiksel ifadeler LaTeX olarak yazılır ve KaTeX ile tarayıcıda işlenir.
- Progressive Web App desteği: Site telefona uygulama olarak kurulabilir, bağlantı kesildiğinde çevrimdışı sayfası gösterilir.

## Kullanılan Teknolojiler
 Programlama Dili: CFML, CFScript 
 Uygulama Sunucusu : Lucee 7
 Web Sunucusu: IIS, URL Rewrite
 Veritabanı: Microsoft SQL Server Express
 API Key: Google Gemini API
 Ön Yüz: HTML, CSS, JavaScript
 Sembol Gösterimi: LaTeX, KaTeX 
 PWA ve Web App: Manifest, Service Worker
 Sanal Sunucu: Netinternet SSD VDS III, Windows Server 2022 
 Ağ ve Güvenlik: Cloudflare
 Geliştirme araçları: VS Code, SQL Server Management Studio 2022, Postman, Git 

## Teknik Öne Çıkanlar

- **Şifre güvenliği:** Şifreler rastgele tuz ve 20.000 tur SHA-512 ile saklanır. Eski yöntemle kayıtlı hesaplar, ilk başarılı girişte otomatik olarak yeni yönteme yükseltilir.
- **Uygulama güvenliği:** Durum değiştiren tüm formlarda CSRF koruması, hesap ve IP bazlı hatalı giriş sınırı, tamamen parametreli SQL sorguları ve çok adımlı işlemlerde transaction kullanımı.
- **Yapay zekâ maliyet kontrolü:** Çözüm önbelleği, kullanıcı başına günlük limit, çift istek koruması ve geçersiz yanıtların önbelleğe alınmaması.
- **Performans:** Sık okunan referans veriler uygulama önbelleğinde tutulur; yoğun sorgular için indeksler tanımlıdır.
- **Hata takibi:** Beklenmeyen hatalar sayfa, işlem ve konum bilgisiyle veritabanına kaydedilir.

## Yerel Kurulum

1. `veritabani_kurulum.sql` script'i ile veritabanını oluşturun.
2. Lucee yönetim panelinde `DSN` adında bir SQL Server veri kaynağı tanımlayın.
3. Soru üretimi ve çözüm için kullanılan iki Gemini API anahtarını, `Application.cfc` dosyasının okuduğu ortam değişkenlerine tanımlayın.
4. Proje dosyalarını web kökünde `/YKSSite/` klasörüne yerleştirin.
5. Günlük soru üretimi için `gunlukSoruUretme.cfm` sayfasını Lucee'de her gün çalışacak bir zamanlanmış görev olarak ekleyin.

## Geliştirme Süreci

Bu projeye, öğrenmekte olduğum ColdFusion teknolojisini gerçek bir problem üzerinde uygulamak amacıyla başladım. Platformda bulunması gereken işlevlerin listesini çıkardıktan sonra geliştirme sürecinin tamamında Claude'u (Anthropic) bir mentor olarak kullandım. Her adımda maliyeti, doğru ve yanlış yönleri gerekçeleriyle tartışarak kararlarımı verdim.

Bu süreçte kazandıklarım:

- Hata mesajlarını okuyarak sorunun kök nedenine ulaşma alışkanlığı.
- Veri modelini kurduktan sonra üçüncü taraf bir API entegrasyonunu uçtan uca tamamlama; bu aşamada yazılımda sabrın ve soğukkanlılığın önemini deneyimleme.
- Bir projenin şemasını baştan sona çıkarma, değişen ihtiyaçlara göre planı yeniden düzenleme.
- Sanal sunucu, alan adı, HTTPS ve Cloudflare yapılandırmasıyla bir uygulamayı canlıya alma.
- Kişisel verilerin korunması (şifre hash'leme) ve API kullanımında maliyet hesaplaması.

## Gelecek Planları

Bu projede edindiğim deneyimle, sektördeki büyük ölçekli sistemleri inceleyerek kendime bir uzmanlık alanı belirlemek ve o alanda sistem geliştirmeye devam etmek istiyorum.

## İletişim

[Ad Soyad] · [LinkedIn] · [E-posta]
