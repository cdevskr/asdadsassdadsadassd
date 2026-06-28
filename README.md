# lr_properties

Sıfırdan yazılmış, sıfır UI bağımlılığı olan FiveM **ev + işletme** sistemi.
Kendi NUI'si, kendi gizmo'su (taşıma/döndürme), kendi bildirimleri.

## Ne içeriyor
- **Ev & İşletme** sahipliği: satın alma (tek sefer) + kiralama (dönemlik).
- **İşletme:** giriş ücreti (girene yansır), çalışan al/çıkar + yetki, kapı kilidi,
  dekorasyon modu, **para kasası** (yatır/çek) + **otomatik maaş bordrosu**.
- **Anahtar sistemi:** sahip + anahtar verilenler + **zil/kapı çalma**.
- **Custom gizmo:** grid snap, yüzey (duvar/zemin) snap, undo/redo, kopyala-yapıştır.
- **Resimli, kategorili, aranabilir** obje kataloğu (Mobilya / Dekor / Yapısal / Aydınlatma).
- **Aydınlatma objeleri** açılıp kapanabilir.
- **Interior tipleri:** hazır IPL daireler, taşınabilir shell'ler (sonsuz kopya),
  ve **custom** (bomboş void — alıcı her şeyi gizmo ile kendi yapar).
- **Depo / kasa / kıyafet dolabı** → `ox_inventory` (kıyafet eventini sen yazıyorsun, biz tetikliyoruz).
- **Vergi/bakım** ödenmezse mülk haczedilir. Kira ödenmezse tahliye.
- **Emlakçı** job ile değil, **komutla** verilir.
- Para sadece **nakit**.
- Arayüz dili **config + locale dosyası** (tr/en).

## Gerekli kaynaklar
- `oxmysql`  (veritabanı)
- `ox_inventory`  (depo / kasa / kıyafet stash)
- (opsiyonel) `es_extended` / `qb-core` / `ox_core` — para köprüsü otomatik algılar.
  Hiçbiri yoksa standalone çalışır (para kontrolü devre dışı — `server/bridge.lua`'dan özelleştir).
- (opsiyonel) `ox_target` / `qb-target` — sadece `Config.Interaction.mode = 'target'` seçersen.

## Kurulum
1. Klasörü `resources/[local]/lr_properties` içine koy.
2. `sql/install.sql` dosyasını veritabanında çalıştır.
3. `server.cfg`:
   ```
   ensure oxmysql
   ensure ox_inventory
   ensure lr_properties
   ```
4. Admin yetkisi için `server.cfg`'ye ekle (komutlar için):
   ```
   add_ace group.admin lr.admin allow
   ```
5. `config/config.lua` → `Config.Locale`, `Config.Interaction.mode` vb. ayarla.

## Komutlar
- `/grantrealtor [id]`  → oyuncuyu emlakçı yap (admin).
- `/revokerealtor [id]` → emlakçılığı al (admin).
- `/realtor`            → emlakçı yerleştirme menüsü (emlakçılar).
- `/property`           → sadece `Config.Interaction.mode = 'command'` ise en yakın kapıyı açar.
- `/propmenu` (varsayılan **F6**) → mülk menüsü.

## Menüler nasıl açılır
- **Kapıda (dışarıda):** seçtiğin moda göre (marker = [E], target = kapıya bak+tıkla,
  command = `/property`). Burada sadece **kapı işlemleri** var: Satın al / Kirala / Gir / Kilitle.
- **Yönetim menüsü içeride:** mülke girdikten sonra **F6** (veya `/propmenu`).
  Depo, kıyafet dolabı, dekorasyon, çıkış noktası, anahtarlar, çalışanlar, giriş ücreti,
  para kasası, kilit ve satma hep buradadır. Yönetim bilinçli olarak kapıya konmadı —
  mülkün içinden yönetilir. Tuşu oyuncular GTA Ayarlar > Tuş Atamaları'ndan değiştirebilir
  (`Config.Interaction.menuKey`).

## Resimler
Kendi resimlerini şuraya koy:
- Objeler: `html/img/catalog/`  (dosya adı = `config/catalog.lua` → `thumb`)
- Interior'lar: `html/img/interiors/`  (dosya adı = `config/interiors.lua` → `thumb`)
Resim yoksa NUI blueprint placeholder gösterir.

## Kıyafet dolabı (senin tarafın)
Dolap kullanılınca şu event tetiklenir (config'ten değiştirilebilir):
```lua
RegisterNetEvent('lr_properties:client:openWardrobe', function(data)
    -- data = { propertyId = <id>, owner = <bool>, type = 'house'|'business' }
    -- kendi outfit menünü burada aç
end)
```

## Gizmo tuşları (config'ten değiştirilebilir)
- Oklar: taşı • PgUp/PgDn: Z ekseni • SHIFT: hızlı
- LALT: taşıma/döndürme modu • G: grid snap • B: yüzey snap
- Z: geri al • SHIFT+Z: ileri al • SPACE: kopyala
- ENTER: onayla • BACKSPACE: iptal

## Notlar / sınırlar
- Ev başına obje limiti `Config.MaxObjects` (varsayılan 300).
- IPL koordinatları ve shell prop modelleri örnektir — kendi sunucuna göre `config/interiors.lua`'da güncelle.
- Katalog model adları örnektir; geçersiz model placeholder olarak görünmez, spawn olmaz — kendi prop'larınla değiştir.
- Resmi `lr_properties` adıyla çalışır. Klasör adını değiştirirsen:
  `fxmanifest.lua` → `name`, ve `html/script.js` → `RESOURCE` sabitini güncelle.

## Instancing, relog ve native shell'ler
- **Routing bucket (instancing):** her mülk kendi routing bucket'ında çalışır
  (`Config.Bucket`). Farklı evlerdeki oyuncular aynı shell koordinatında olsalar
  bile birbirini görmez. Girişte oyuncu mülkün bucket'ına alınır, çıkışta 0'a döner.
- **Relog'da evde doğma:** evdeyken çıkış yaparsan (`lr_inside` tablosu) tekrar
  girdiğinde aynı mülkün içinde doğarsın. Normal çıkışta kayıt silinir.
- **Shell'ler tamamen native (qb-interior GEREKMEZ):** shell oluşturma mantığı
  (`CreateObject` + freeze) doğrudan scripte gömülü. `config/interiors.lua` içindeki
  shell'ler `kind = 'shell'` ve `model` alanıyla çalışır; hepsi `Config.ShellBase`
  ortak koordinatında bucket-izole oluşturulur.
  - Hazır 24 shell slotu var (Michael, Apartman, Trevor karavanı, Boş Shell'ler...).
    Varsayılan olarak base-game bir shell modeline (`Config.ShellFallbackModel`)
    düşerler, yani **hiçbir ek dosya olmadan çalışırlar**.
  - Kendi shell'lerini istiyorsan: shell prop dosyalarını bu resource'un `stream/`
    klasörüne at ve ilgili girdideki `model` alanına o modelin adını yaz. (qb-interior
    şu an açık değil — sadece onun ücretsiz shell **asset** dosyalarını kullanmak
    istersen `stream` klasörünü kopyalaman yeterli; resource'u kurmana gerek yok.)
  - Model stream edilmemişse otomatik olarak fallback modele düşer, interior asla
    bozulmaz.

## Prop görselleri (foto / CDN, yoksa SVG)
`Config.Thumbnails` ile dekorasyon kataloğunda gerçek prop fotoğrafı gösterebilirsin.
Sıra: **yerel resim paketi → opsiyonel CDN → SVG ikon** (otomatik fallback).
- **Yerel paket:** `html/img/catalog/<model>.png` (veya jpg/webp) koy; o prop için
  fotoğraf çıkar. Interior'lar için `html/img/interiors/<id>.png`.
- **CDN:** `Config.Thumbnails.cdn = 'https://senin.cdn/props/{model}.png'`. Kalıplar:
  `{model}` ve `{hash}` (unsigned joaat — NUI tarafında hesaplanır).
- Not: Forge/qb-interior görselleri model adına göre değil **dahili ID'ye** göre
  anahtarlı olduğu için otomatik kurulamaz; bu yüzden model-adına dayalı bir paket
  ya da CDN gerekir. Hiçbiri yoksa SVG ikonlar gösterilir (her zaman çalışır).

## Arayüz: koyu lacivert "gaming" tema (vanilla değil)
Tüm NUI sıfırdan koyu lacivert + mavi vurgulu, kartlı, glow'lu bir temayla yazıldı.
- **Yönetim paneli (F6 içeride):** geniş bir dashboard — büyük başlık + kilit rozeti,
  bölümlere ayrılmış aksiyon kartları (Hızlı Erişim, Mülk Yönetimi, Kişiler, Güvenlik)
  ve sağda gerçek **Işıklar** paneli (yerleştirdiğin ışıkları aç/kapa anahtarıyla).
- **Dekorasyon barı:** ekranın altında tam genişlikte furniture barı — kategori
  çipleri, arama, yatay kaydırılan prop kartları (SVG ikonlu), depo/dolap/kasa
  düğmeleri ve üstte tuş ipuçları şeridi (TAB / SOL TIK / TEKER / DEL / WASD).
- **Bildirimler / menüler / formlar / interior seçici** hepsi aynı koyu temada.
- Proplarda foto yok; içeriğe göre otomatik SVG ikon (sandalye, lamba, tv, kasa...).

## Eklenen hazır interior'lar (IPL)
Kullanıcı listesinden mülk olarak mantıklı olanlar eklendi:
- **Daireler (ev):** Eclipse 1/2/3, Tinsel Towers, Vinewood Villa.
- **Ofisler (işletme):** Maze Bank, Lombank, Arcadius, Lifeinvader.
- **Kulüp / Yasadışı / Eğlence / Depo / Atölye:** MC kulübü, kokain/meth/esrar/sahte
  para/evrak, bunker, doomsday tesisi, gece kulübü, arcade, Vanilla Unicorn, comedy
  club, araç deposu, Arena workshop, LS Tuners.
- **Eklenmeyenler (sebebiyle):** karakol/FIB/adliye/hastane (satılık mülk mantıklı
  değil), uçak gemisi/Simeon/Lester (hikâye lokasyonu), Kosatka & Benny's (IPL
  şüpheli), Casino floor/penthouse (MLO entity-set ister, düz IPL ile boş gelir).
- Not: DLC/`_milo_` interior'larda mobilyanın tam görünmesi için interior entity-set
  gerekebilir; koordinatlar düzenlenebilir, çıkış noktasını mülk-başına ayarlayabilirsin.
