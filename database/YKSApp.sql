CREATE TABLE GirisSoru(
	id INT IDENTITY(1,1) PRIMARY KEY,
	soruMetni NVARCHAR(255) NOT NULL
	);

GO

CREATE TABLE SinavTuru(
	id INT IDENTITY(1,1) PRIMARY KEY,
	ad NVARCHAR(3) NOT NULL
	);

GO

CREATE TABLE Alan(
	id INT IDENTITY(1,1) PRIMARY KEY,
	ad NVARCHAR(20) NOT NULL,
	sinavTuruID INT NOT NULL,
	FOREIGN KEY (sinavTuruID) REFERENCES SinavTuru(id)
	);

GO

CREATE TABLE Ders(
	id INT IDENTITY(1,1) PRIMARY KEY,
	ad NVARCHAR(100) NOT NULL,
	alanID INT NOT NULL,
	FOREIGN KEY (alanID) REFERENCES Alan(id)
	);

GO

CREATE TABLE Kullanici(
	id INT IDENTITY(1,1) PRIMARY KEY,
	rol INT DEFAULT 1,
	ad NVARCHAR(15) UNIQUE NOT NULL,
	sifre NVARCHAR(255) NOT NULL,
	gizliSoruID INT NOT NULL,
	gizliCevap NVARCHAR(255) NOT NULL,
	xp INT DEFAULT 0,
	kayitTarihi DATETIME DEFAULT GETDATE(),
	sonGirisTarihi DATETIME,
	aktiflik BIT DEFAULT 1,
	FOREIGN KEY (gizliSoruID) REFERENCES GirisSoru(id)
	);

GO

CREATE TABLE Oturum(
	id INT IDENTITY(1,1) PRIMARY KEY,
	kullaniciID INT NOT NULL,
	sessionToken NVARCHAR(255) NOT NULL,
	girisTarihi DATETIME DEFAULT GETDATE(),
	sonGoruldu DATETIME,
	aktiflik BIT DEFAULT 1,
	FOREIGN KEY (kullaniciID) REFERENCES Kullanici(id)
	);

GO

CREATE TABLE Soru(
	id INT IDENTITY(1,1) PRIMARY KEY,
	dersID INT NOT NULL,
	soranID INT NOT NULL,
	dogruCevap CHAR(1) NOT NULL,
	soruResmi NVARCHAR(255) NOT NULL,
	soruMetni NVARCHAR(MAX),
	sikA NVARCHAR(500),
    sikB NVARCHAR(500),
    sikC NVARCHAR(500),
    sikD NVARCHAR(500),
    sikE NVARCHAR(500),
    aciklama NVARCHAR(MAX),
	sistemSoru BIT DEFAULT 0,
	aktiflik BIT DEFAULT 1,
	goruntulenmeSayisi INT DEFAULT 0,
	eklenmeTarihi DATETIME DEFAULT GETDATE(),
	FOREIGN KEY (dersID) REFERENCES Ders(id),
	FOREIGN KEY(soranID) REFERENCES Kullanici(id)
	);

GO

CREATE TABLE Cevap(
	id INT IDENTITY(1,1) PRIMARY KEY,
	soruID INT NOT NULL,
	cozenID INT NOT NULL,
	kullaniciCevabi CHAR(1),
	cozumMetni NVARCHAR(MAX),
	cozumResmi NVARCHAR(255),
	onay INT DEFAULT 2,
	eklenmeTarihi DATETIME DEFAULT GETDATE(),
	FOREIGN KEY (soruID) REFERENCES Soru(id),
	FOREIGN KEY (cozenID) REFERENCES Kullanici(id)
	);

GO

CREATE TABLE Yorum(
	id INT IDENTITY(1,1) PRIMARY KEY,
	cevapID INT NOT NULL,
	yazanID INT NOT NULL,
	metin NVARCHAR(MAX) NOT NULL,
	ustYorumID INT DEFAULT NULL,
	aktiflik BIT DEFAULT 1,
	eklenmeTarihi DATETIME DEFAULT GETDATE(),
	FOREIGN KEY (cevapID) REFERENCES Cevap(id),
	FOREIGN KEY (yazanID) REFERENCES Kullanici(id),
	FOREIGN KEY (ustYorumID) REFERENCES Yorum(id)
	);

GO

CREATE TABLE Begeni(
	id INT IDENTITY(1,1) PRIMARY KEY,
	kullaniciID INT NOT NULL,
	hedefTip NVARCHAR(20) NOT NULL,
	hedefID INT NOT NULL,
	tarih DATETIME DEFAULT GETDATE(),
	FOREIGN KEY (kullaniciID) REFERENCES Kullanici(id)
	);

GO

CREATE TABLE Favori(
	id INT IDENTITY(1,1) PRIMARY KEY,
	kullaniciID INT NOT NULL,
	soruID INT NOT NULL,
	eklenmeTarihi DATETIME DEFAULT GETDATE(),
	FOREIGN KEY (kullaniciID) REFERENCES Kullanici(id),
	FOREIGN KEY (soruID) REFERENCES Soru(id)
	);

GO

CREATE TABLE Puan(
	id INT IDENTITY(1,1) PRIMARY KEY,
	kullaniciID INT NOT NULL,
	islemTipi NVARCHAR(50) NOT NULL,
	puanDegeri INT NOT NULL,
	referansID INT,
	referansTip NVARCHAR(20),
	eklenmeTarihi DATETIME DEFAULT GETDATE(),
	FOREIGN KEY (kullaniciID) REFERENCES Kullanici(id)
	);

GO

CREATE TABLE AI(
	id INT IDENTITY(1,1) PRIMARY KEY,
	kullaniciID INT,
	soruID INT,
	islemTipi NVARCHAR(50),
	girdi NVARCHAR(MAX),
	cikti NVARCHAR(MAX),
	model NVARCHAR(50),
	eklenmeTarihi DATETIME DEFAULT GETDATE(),
	FOREIGN KEY (kullaniciID) REFERENCES Kullanici(id),
	FOREIGN KEY (soruID) REFERENCES Soru(id)
	);

GO

CREATE TABLE GunlukSoru(
	id INT IDENTITY(1,1) PRIMARY KEY,
	soruID INT NOT NULL,
	tarih DATE NOT NULL,
	alanID INT NOT NULL,
	olusturmaTipi NVARCHAR(20),
	goruntulenme INT DEFAULT 0,
	FOREIGN KEY (soruID) REFERENCES Soru(id),
	FOREIGN KEY (alanID) REFERENCES Alan(id)
	);

GO

CREATE TABLE Bildirim(
	id INT IDENTITY(1,1) PRIMARY KEY,
	kullaniciID INT NOT NULL,
	islemTipi NVARCHAR(20),
	mesaj NVARCHAR(500),
	goruldu BIT DEFAULT 0,
	hedefURL NVARCHAR(255),
	tarih DATETIME DEFAULT GETDATE(),
	FOREIGN KEY (kullaniciID) REFERENCES Kullanici(id)
	);

GO

CREATE TABLE Sikayet(
	id INT IDENTITY(1,1) PRIMARY KEY,
	sikayetciID INT NOT NULL,
	hedefTip NVARCHAR(20),
	hedefID INT NOT NULL,
	sebep NVARCHAR(255),
	durum INT DEFAULT 0,
	tarih DATETIME DEFAULT GETDATE(),
	FOREIGN KEY (sikayetciID) REFERENCES Kullanici(id)
	);

GO

CREATE TABLE HataLog(
	id INT IDENTITY(1,1) PRIMARY KEY,
	sayfa VARCHAR(100),
	islem VARCHAR(100),
	mesaj NVARCHAR(MAX),
	detay NVARCHAR(MAX),
	eklenmeTarihi DATETIME DEFAULT GETDATE()
	);

GO

INSERT INTO GirisSoru(soruMetni) VALUES
('En sevdiğiniz öğretmeninizin adı nedir?'),
('En sevdiğiniz hayvan hangisidir??'),
('En sevdiğiniz renk nedir?'),
('En güzel yapabildiğiniz yemek hangisidir?'),
('Gezmeyi en çok istediğiniz şehir hangisidir?');

GO

INSERT INTO SinavTuru(ad) VALUES('TYT'),('AYT');

GO

INSERT INTO Alan(ad,sinavTuruID) VALUES
('Sayısal',2),
('Sözel',2),
('Eşit Ağırlık',2),
('TYT',1);

GO

INSERT INTO Ders(ad,alanID) VALUES
('AYT Matematik',1),
('AYT Geometri',1),
('AYT Fizik',1),
('AYT Kimya',1),
('AYT Biyoloji',1),

('AYT Türk Dili ve Edebiyatı',2),
('AYT Tarih-1',2),
('AYT Coğrafya-1',2),
('AYT Tarih-2',2),
('AYT Coğrafya-2',2),
('AYT Felsefe Grubu',2),
('AYT Din Kültürü',2),

('AYT Matematik',3),
('AYT Geometri',3),
('AYT Edebiyat (EA)',3),
('AYT Tarih-1 (EA)',3),
('AYT Coğrafya-1 (EA)',3),

('TYT Türkçe',4),
('TYT Tarih',4),
('TYT Coğrafya',4),
('TYT Felsefe',4),
('TYT Din Kültürü',4),
('TYT Matematik',4),
('TYT Geometri',4),
('TYT Fizik',4),
('TYT Kimya',4),
('TYT Biyoloji',4);

UPDATE Kullanici SET rol=3 WHERE ad='admin'
UPDATE Kullanici SET rol=2 WHERE ad='moderatör'