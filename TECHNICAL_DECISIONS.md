# Teknik Kararlar — EZAN Uygulaması

Tarih: 23 Eylül 2026  
Kapsam: Faz 0 teknik kararları ile Faz 1–6 uygulama sonuçları.

## 1. Mevcut çalışma ortamı

| Bileşen | Gözlem |
|---|---|
| Çalışma alanı | `C:\EzanCodex`; Flutter package adı `ezan`, Android namespace/applicationId `com.ezan.app`. |
| Flutter | SDK kurulu. `bin/cache/flutter.version.json`: Flutter **3.47.1 stable**, revision `6655482ec06e547f90abf8ae7590466f4415978d`. |
| Dart | SDK kurulu, sürüm **3.13.1**. |
| Android SDK | `C:\Users\Erkan\AppData\Local\Android\Sdk`; Android API 34, 35, 36 ve 37 preview platformları; Build Tools 34.0.0, 35.0.0, 36.0.0. |
| Java | Kalıcı User/Machine `JAVA_HOME` ve PATH girdileri Microsoft OpenJDK **21.0.12.1 LTS**. Çalışan IDE terminali eski JDK 26 `JAVA_HOME` değerini miras almıştı; User/Machine değerleri 21 iken bu oturum için doctor doğrulamasından önce `JAVA_HOME`/PATH JDK 21'e normalize edildi. Flutter JDK ayarı da 21. Yeni terminal 21'i devralmalı; uzun süredir açık IDE/terminal yeniden başlatılmalı. |
| Android Gradle | Flutter şablonunun ürettiği **AGP 9.1.0 + Gradle 9.3.1 + Kotlin 2.4.0** kombinasyonu korundu. AGP/Gradle çalışma zamanı JDK'sı **21**; uygulama bytecode hedefi şablon varsayılanı **Java/Kotlin 17**. |
| CLI doğrulaması | `flutter doctor -v` Flutter 3.47.1/Dart 3.13.1 ve JDK 21'i doğruladı. Android SDK lisansları `unknown`; kullanıcı adına lisans kabul edilmedi. |

## 2. Karar özeti

| Alan | Öneri | Gerekçe / doğrulama notu |
|---|---|---|
| Namaz vakti motoru | `adhan_dart` **2.0.1** | Faz 2'de kaynak/test/lisans/Android kapısı ve yayımlanmış Diyanet fixture'ları incelendi. Türkiye preset'i kabul edildi; 0–2 dakika fixture toleransı var, birebir Diyanet eşitliği iddia edilmiyor. |
| Saat dilimi | `timezone` **0.11.1**, `flutter_timezone` **5.1.0** | Faz 2'de kaynak/test/lisans/Android kapısından geçti. `flutter_timezone` cihazın IANA bölgesini, `timezone` çevrimdışı dönüşüm ve DST kurallarını sağlar. Bundled IANA verisi 2025c olduğundan güncel 2026d'ye göre eski; aşağıdaki sınırlamaya bak. |
| Konum | `geolocator` **14.0.3** | Faz 2'de kaynak/test/lisans/Android kapısından geçti. Yalnızca kullanıcı eylemiyle foreground konum izni istenir; background konum yoktur, koordinat sunucuya gönderilmez. |
| Kıble matematiği | Büyük daire başlangıç azimutu; Kâbe sabit koordinatları `21.4225, 39.8262` | Dereceyi kuzeyden saat yönünde dönen gerçek bearing olarak üret. Dört şehir fixture testi var; uygulama arayüzü yalnızca Kâbe görseli, göreli yön oku ve bearing derecesini gösterir. |
| Cihaz yönü | Android `TYPE_ROTATION_VECTOR`; yoksa accelerometer + magnetometer matrisi | Android'in füzyonlanmış dönüş vektörü temel kaynak; kıble hesabı gerçek kuzeye göre olduğundan manyetik sapmayı konum ve tarihle düzelt. Sensör doğruluğu/güvenilirlik sinyali ve kararsız alan için eşik tabanlı uyarı; sensör ekran dışında kapalı. |
| Tam vakit alarmı | Android `AlarmManager` `RTC_WAKEUP` exact alarm; native Kotlin `BroadcastReceiver` | Tam zamanlı kullanıcı işlevi. `SCHEDULE_EXACT_ALARM` özel erişimi kontrol et ve kullanıcıya ihtiyaç anında açıklayıp Ayarlar'a yönlendir. Android 12+ erişim ister; Android 14'te yeni yüklemelerde önceden verilmez. `USE_EXACT_ALARM` Play'de kısıtlı olduğu için tercih edilmemeli. |
| Alarm yeniden kurma | Boot, saat, saat dilimi, uygulama güncellemesi, konum/yöntem/ezan ayarı değişince yeniden planla | AlarmManager alarmları yeniden başlatmada silinir. Broadcast receiver planı yerel veriden geri kursun; zaman/saat dilimi değişiminde Flutter hesap motoru yeni tarih ve yerel saatlere göre zamanları yenilesin. |
| Arka plan ezanı | Exact-alarm receiver → kısa ömürlü native Android foreground playback service; Jetpack Media3 yerel ses oynatımı | Android'in exact alarm olayı arka plan FGS başlatma istisnasıdır. Servis foreground bildirimini derhal başlatmalı; playback `USAGE_ALARM` ile yapılır. Android 17 belgeleri exact alarm izni + alarm ses kullanımı için arka plan ses kısıtlaması istisnası tanımlıyor. Cihaz üreticisi ve DND/ses ayarları yine gerçek cihazda sınanmalı. |
| Ses dosyaları | Beş lisansı belgeli kayıt `android/app/src/main/res/raw/` içinde; tek müezzin ve tek mastering standardı | Gerçek kayıtlar henüz yok. Geçici sözsüz test tonu yalnız `src/debug/res/raw` içinde; release'e girmez. Gerçek dosya kaynağı, eser/performans ve dağıtım hakları yazılı olarak doğrulanmadan production varlığı eklenmemeli. |
| Yerel ayarlar | `shared_preferences` **2.5.5** | Faz 2+ adayı; eklenmedi. Alarm snapshot'ı native tarafta da tutulacak; paket değerlendirmesi öncesi karar yok. |
| Durum yönetimi / routing | `flutter_riverpod` 3.4.3 + `go_router` 18.0.1 | Mega Implementation Prompt bu mimariyi açıkça istedi; önceki Phase 1 yerleşik navigasyon önerisini bu gerekçeyle değiştirdi. Paket kapısı Phase 1'de uygulandı. |
| Tema / localization | Merkezi `ThemeData` Light/Dark + Riverpod `ThemeModeNotifier`; Flutter `flutter_localizations` + `intl`, ARB | ThemeMode başlangıcı system; dil Türkçe/İngilizce. Faz 1'de ayar UI/persistansı yok. |

## 3. Hesaplama ve doğruluk kararları

### Namaz vakitleri

- Faz 2 kararı: `adhan_dart 2.0.1` kullanılır. MIT lisansı, bakım/changelog, saf Dart Android uyumluluğu, kaynak ve upstream testleri incelendi. Türkiye parametreleri (Fajr 18°, Isha 17°, sunrise −7, Dhuhr +5, Asr +4, Maghrib +7) kaynakta doğrulandı.
- 2026-09-23/24 yayımlanmış resmi Diyanet çizelgeleriyle yapılan fixture karşılaştırmasında `adhan_dart` İstanbul, Ankara ve Antalya'da 0–2 dakika fark verdi. İstanbul 2026-09-23: `0, 0, -1, -1, -1, -2`; İstanbul 2026-09-24: `0, 0, 0, -2, -1, -1`; Ankara: `0, 0, 0, -1, -2, -2`; Antalya: `0, 0, 0, -2, -1, -2` (sıra Fajr, sunrise, Dhuhr, Asr, Maghrib, Isha; hesaplanan eksi resmi dakika). Ankara/Antalya şehir merkezi koordinatları yaklaşık, İstanbul koordinatı upstream fixture ile aynı. İki dakikadan az/eşit tolerans kabul edilmiştir; bu sonuç her konum/tarih için birebir eşitlik garantisi değildir.
- `prayer_time_plus 0.3.0` MIT / saf Dart alternatifi de lisans, bakım/olgunluk, Android uyumluluğu, kaynak ve test kapısından geçirildi. Genç/düşük kullanımlı projede Türkiye golden fixture'ı yok; aynı karşılaştırma genel olarak daha iyi değildi (İstanbul Maghrib −3, Isha −2; Ankara Maghrib −4 dakika). Bu nedenle Faz 1'e hesaplama bağımlılığı eklenmedi; Faz 2 öncesi bağımsız doğru motor/offset kararı gerekir.
- Resmî Diyanet referansları: [İstanbul](https://namazvakitleri.diyanet.gov.tr/tr-TR/9541/istanbul-icin-namaz-vakti), [Ankara](https://namazvakitleri.diyanet.gov.tr/tr-TR/9206/ankara-icin-namaz-vakti), [Antalya](https://namazvakitleri.diyanet.gov.tr/Tr-tr/9225/icin-namaz-vakti). Resmî tabloların koordinat/yuvarlama yöntemi ayrıca doğrulanmalı.
- `CalculationMethodParameters.turkiye()` kütüphane dokümanında Diyanet yönteminin **yaklaşımı** olarak tanımlanıyor; resmi Diyanet tablosunun her tarih ve konum için birebir eşdeğeri kabul edilmeyecek. Türkiye fixture'ları güncel, yayımlanmış Diyanet verisiyle karşılaştırılmalı; uluslararası testlerde seçili yöntem açıkça belirtilmeli.
- Asr için `Madhab.shafi` ve `Madhab.hanafi` desteklenecek. Hesap yöntemi ile Asr mezhep tercihi ayrı alanlar olacak.
- `HighLatitudeRule.recommended(coordinates)` dokümanda 48° üzeri için `seventhOfTheNight`, altı için `middleOfTheNight` seçiyor. Bu varsayılan açıkça kayda geçirilecek; polar güneş doğuşu/batışı olmayan tarihlerde `polarCircleResolution` açık bir politika olmadan `unresolved` bırakılmayacak.
- Hesaplama sonucu cihazın IANA saat dilimine çevrilir. Londra DST geçişi, Tromsø polar gün çözümü ve Isha sonrası yarının Fajr geçişi test edildi.
- `timezone` 0.11.1'in `latest_all` verisi IANA 2025c içeriyor; IANA 2026d 2026-09-11'de yayımlandı. Türkiye'de 2026 için saat dilimi kuralı değişmediğinden mevcut Türkiye vakit fixture'ları etkilenmiyor; yakın tarihte saat dilimi mevzuatı değişen başka bölgelerde bundled kurallar eski kalabilir. Paket güncelleme/DB yenileme sonraki bakım kararıdır.

### Kıble ve sensör

- Bearing formülü, başlangıç büyük daire azimutudur: `atan2(sin(Δλ)·cos(φ₂), cos(φ₁)·sin(φ₂) − sin(φ₁)·cos(φ₂)·cos(Δλ))`; sonuç 0–360° aralığına normalize edilir. Koordinatlar radyana çevrilir.
- Ok açısı = Kâbe bearing'i − cihaz azimutu; açısal fark `[-180°, 180°]` aralığına sarılır ve animasyon en kısa yönden döner.
- Android `TYPE_ROTATION_VECTOR` sanal/füzyonlanmış sensördür; manyetik kuzey referansını kıble motorunun gerçek kuzey bearing'iyle karıştırma. `GeomagneticField` ile yerel manyetik sapmayı uygula. Sensör kullanılamazsa ekranda dürüstçe yön ölçümünün hazır olmadığını göster.
- `GeomagneticField` X/Y/Z alan bileşenleri nanotesla (nT), `TYPE_MAGNETIC_FIELD` örnekleri microtesla (µT) verir; kararlılık filtresi oran hesabından önce nT→µT dönüşümü yapar. Android API'si WMM-2020 modelini kullandığını ve 2025'e kadar geçerli olmakla birlikte birkaç yıl daha kabul edilebilir sonuç üretmesinin beklendiğini belgeliyor. Gerçek yön hatası ve cihaz etkileri donanım testi gerektirir.
- Donanım kaynaklı parazite Android'de tek ve kesin bir boolean teşhis yoktur. Güvenilmez doğruluk durumu, anormal alan büyüklüğü ve süreklilik/kararlılık birlikte değerlendirilip sade uyarı gösterilmeli; bu eşikler cihaz testinde ayarlanmalı.

## 4. Android arka plan sınırları

- Exact alarm izni kullanıcı tarafından verilmemişse tam vakitte çalma garantisi verilemez. İzin kapalıyken arayüz durumu göstermeli ve planı tekrar kurmamalı; sessiz/inexact alternatif ürün kararı olarak ayrıca ele alınmalı.
- Sistem alarmları reboot'ta siler; `BOOT_COMPLETED` receiver yalnızca planı geri kursun. `TIME_SET`, `TIMEZONE_CHANGED`, `MY_PACKAGE_REPLACED`, exact alarm erişim izni kazanma ve uygulama içi konum/hesap ayarı değişikliği de planı yenilemeli.
- Kullanıcı Android Ayarları'ndan uygulamayı **zorla durdurursa** Android alarmları ve receiver'ları kullanıcı uygulamayı yeniden açana kadar çalışmaz. Bu, uygulama koduyla aşılamaz; kabul kriterinde “uygulama kapalı” ile “zorla durdurulmuş” ayrımı yapılmalı.
- Xiaomi/Samsung ve diğer üreticilerin pil tasarrufu süreçleri gecikmeye sebep olabilir. Android API testi yeterli değil; en az bir gerçek Samsung ve bir başka üretici üzerinde ekran kilitli/uygulama arka planda senaryosu gerekir.
- Android 13+ bildirim iznini ayrıca ele al; FGS bildirim davranışı ve kullanıcıya gösterilen alarm eylemi gerçek cihazda kontrol edilsin. DND, alarm/medya ses akışı ve Bluetooth çıktısı ses varlığına göre denenmeli.

## 5. Lisans ve çevrimdışı değerlendirmesi

| Paket / bileşen | Lisans | Karar |
|---|---|---|
| `adhan_dart` 2.0.1 | MIT | Kaynak/test/lisans ve Android uyumluluğu incelendi; Türkiye fixture'ları yayımlanmış Diyanet vakitleriyle en fazla 2 dakika fark gösterdi. Faz 2 hesaplama motoru olarak kabul edildi; Diyanet ile birebir eşit olduğu iddia edilmez. |
| `geolocator` 14.0.3 | MIT | Kaynak/test/lisans/Android uyumluluğu incelendi. Sadece foreground kullanıcı akışı ve son bilinen yerel konum kullanılır; background konum izni istenmez. |
| `timezone` 0.11.1 | BSD-2-Clause | Kaynak/test/lisans incelendi. Offline IANA dönüşümleri kullanılır; gömülü TZDB 2025c güncellik sınırlaması var. |
| `flutter_timezone` 5.1.0 | Apache-2.0 | Kaynak/test/lisans/Android uyumluluğu incelendi; cihaz IANA timezone adı alınır. Android derlemesi KGP uyumluluğu için Flutter gelecekteki uyarısı veriyor, mevcut build başarılı. |
| AndroidX Media3 ExoPlayer 1.11.1 | Apache-2.0 | Stabil AndroidX release; aktif changelog/depo bakımı ve ExoPlayer kaynak/test yapısı incelendi. Android minSdk 23 gereksinimi mevcut APK minSdk 24 ile uyumlu. Yerel WAV destekleniyor. Yalnız `media3-exoplayer` modülü eklendi; streaming/session/notification modülleri eklenmedi. |
| `flutter_lints` 6.0.0 + `lints` 6.1.0 | BSD-3-Clause | Faz 1 analiz yapılandırması; Flutter/Dart resmî depoları, konfigürasyon/YAML dışında runtime kodu yok, Android runtime uyumluluğu uygulanmaz. Lisans ve kaynak incelendi. |
| `intl` 0.20.3 | BSD-3-Clause | Faz 1 ARB localization üretim/runtime desteği; Dart ekibi tarafından bakılıyor, saf Dart, Android platform entegrasyonu yok. Kaynakta test/benchmark klasörleri var; lisans ve pubspec incelendi. |
| `clock`, `meta`, `path` | BSD-3-Clause | `intl`'in transitif bağımlılıkları; Dart ekibi paketleri, saf Dart. Yalnız kullanılan localization zinciri için pub çözümlemesinde eklendi. |
| `flutter_riverpod` 3.4.3 + `riverpod` 3.4.3 | MIT | Riverpod deposunda aktif bakım/changelog ve Flutter widget/provider testleri incelendi; pub metadata Android desteğini doğruluyor. Flutter/Dart tabanlıdır, Android plugin/permission eklemez. |
| `go_router` 18.0.1 | BSD-3-Clause | `flutter.dev` yayımcısı; Android desteği var. Flutter ekibi feature-complete olarak hata düzeltme/stabilite bakımı veriyor; named route, ShellRoute kaynağı ve navigation testleri incelendi. |
| `listen` 1.0.1, `state_notifier` 1.0.0 | BSD-3-Clause, MIT | Riverpod transitifleri; saf Dart ve Android'e özgü kod/izin yok, kaynak ve test klasörleri mevcut. `state_notifier` son kararlı sürümü eski ve düşük değişim sıklığında; küçük, olgun immutable-state yardımcı paketi olarak yalnız Riverpod transitifi, uygulama doğrudan kullanmıyor. |
| `uuid` 4.6.0, `crypto` 3.0.7, `fixnum` 1.1.1, `typed_data` 1.4.0 | MIT, BSD-3-Clause | Riverpod transitif zinciri; `uuid` güncel ve Android destekli saf Dart, diğerleri Dart core deposunda. Kaynak/test ve lisans dosyaları incelendi; platform plugin/izin yok. |
| `cupertino_ui` 1.1.1, `material_ui` 1.4.0, `logging` 1.3.0 | BSD-3-Clause | Router/Riverpod çözümlemesinden gelen transitifler. UI paketleri Flutter ekibinin resmi deposunda, Flutter 3.47+/Dart 3.13 uyumlu; logging Dart core paketidir. Kaynak/test/changelog ve lisanslar incelendi. |
| `flutter_localizations`, `flutter_test` | Flutter SDK | SDK bağımlılıkları; ek üçüncü taraf pub paketi değil. `flutter_test` transitifleri geliştirme/test kapsamındadır. |
| Diğer runtime paketleri | — | Faz 1'e eklenmedi. Sonraki her üçüncü taraf paket için lisans → bakım durumu → Android uyumluluğu → kaynak/test incelemesi → kullanım kararı kapısı zorunludur. |
| Android AlarmManager / SensorManager / Media3 | AndroidX/Android API lisansları | Native altyapı; Media3 bağımlılıkları ve sürümleri proje oluşturulunca sabitlenip lisans bildirimi envanterine eklenecek. |
| Ezan kayıtları | Henüz belirlenmedi | Uygulamaya dahil etme hakkı yazılı ve dağıtım kapsamını açıkça içeren kayıtlar bulunmadan ses varlığı ekleme. AI klonlama yok. |

Şehir adına dönüşüm için bir çevrimiçi reverse-geocoder kullanmak, koordinatları cihazdan çıkarabilir. İlk sürümde konum koordinatını üçüncü taraf geocoder'a gönderme. Şehir etiketi için lisansı ve çevrimdışı kapsamı doğrulanmış yerel bir katalog veya kullanıcı seçimi tasarlanmalı; paket/şehir verisi seçimi Faz 2 öncesinde netleştirilecek.

## 9. Faz 1 uygulama ve doğrulama kaydı

- Flutter package adı `ezan`; Android namespace/applicationId `com.ezan.app`; manifest uygulama etiketi `Ezan`; Kotlin `MainActivity` paketi `com.ezan.app` olarak ayarlandı.
- Flutter Android şablonundaki AGP **9.1.0**, Gradle wrapper **9.3.1**, Kotlin Gradle Plugin **2.4.0** korunup JDK **21.0.12.1** ile debug derlemede doğrulandı. Android bytecode hedefi şablonun Java/Kotlin 17 ayarı olarak kaldı.
- `JAVA_HOME`, kullanıcı `PATH` başı ve Flutter JDK ayarı `C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot` / `bin` ile eşleşiyor. `java -version` çıktısı OpenJDK 21.0.12.1 LTS.
- Riverpod `ProviderScope`, route provider, `ThemeModeNotifier`, merkezi `MaterialApp.router` ve `/home`, `/qibla`, `/settings` ShellRoute'ları kuruldu. ARB localization, Light/Dark theme altyapısı ve domain kontratları korundu; `data`, `infrastructure`, `application/services` sınırları belgelendi. Prayer/Qibla engine, konum, sensor, adhan playback, alarm veya ayar persistansı eklenmedi.
- `flutter_riverpod 3.4.3` MIT ve `go_router 18.0.1` BSD-3-Clause direct bağımlılık kapısından geçti. Lisans, bakım, Android platform desteği, kaynak ve upstream testleri incelendi. Transitif Android dışı/runtime yardımcıları ve Flutter test/lint tooling bağımlılıkları `pubspec.lock` üzerinden ayrıca sınıflandırıldı; tam liste lisans karar tablosundadır.
- `pubspec.lock` içindeki hosted paketlerin tamamı için yerel cache envanterinde lisans dosyası, kaynak kodu ve test dizini kontrol edildi; test/lint amaçlı SDK transitifleri runtime bağımlılıklarından ayrı değerlendirildi.
- User/Machine Java değişkenleri okundu; ikisi de Microsoft JDK 21'e ayarlı. `java -version` ve `flutter doctor -v`, doğrulama oturumu JDK 21'e normalize edildikten sonra aynı Microsoft OpenJDK 21.0.12.1'i doğruladı. Flutter 3.47.1/Dart 3.13.1 ve Android SDK 36.0.0 görüldü; **Android SDK license status unknown** uyarısı kaldı. Lisanslar kullanıcı adına kabul edilmedi. Debug build yine de başarıyla tamamlandı.
- `flutter analyze`: başarılı, sorun yok.
- `flutter test`: tüm 6 test başarılı; Diyanet şehir fixture'ları (≤2 dakika), Hanafi/Standard Asr, Londra DST, Tromsø polar gün ve yarının Fajr geçişi ile named-route/widget testi.
- `flutter build apk --debug`: başarılı; çıktı `build\app\outputs\flutter-apk\app-debug.apk`.
- `aapt2 dump badging` ile APK applicationId `com.ezan.app`, app label `Ezan` ve compileSdk 36 doğrulandı.
- Android API 31–37 exact alarm ve Media3 gerçek davranış testleri bu fazda yapılmadı; native scheduling/playback yoktur. Bu doğrulama Phase 5 çıkış kapısıdır. `SCHEDULE_EXACT_ALARM` açıklaması ve doğru Ayarlar ekranına yönlendirme uygulamanın kullanıcı akışına bağlanacak. Force-stop kısıtı kabul ölçütünde tutulur.
- Geçici paket karşılaştırma scratch dosyaları sonuçlar bu belgeye aktarıldıktan sonra silindi.

## 6. Önerilen mimari

```text
Flutter UI (Home / Qibla / Settings)
  └─ Presentation state (Riverpod): Prayer, Location, Qibla, Settings, Adhan
      └─ Application services / use cases
          ├─ PrayerCalculationService → adhan_dart + IANA timezone database
          ├─ LocationService → geolocator + local last-known location
          ├─ QiblaCalculator → bearing math; QiblaSensorService → Android channel
          ├─ SettingsRepository → local preferences
          ├─ AdhanPlaybackService → MethodChannel → Media3 ExoPlayer
          └─ PrayerAlarmScheduler → MethodChannel → Kotlin AlarmManager
               ├─ Boot/time/permission BroadcastReceivers → restore/recalculate alarms
               └─ AdhanAlarmReceiver → Media3 foreground playback service → bundled local audio
```

Faz 1'de `app`, `application`, `core`, `domain`, `data`, `infrastructure`, `presentation` katmanları belgelendi/kuruldu; Riverpod, go_router named routes ve ARB localization eklendi. Faz 2'de konum/timezone adaptörleri, namaz motoru ve home ekranı veri akışı; Faz 3'te bearing motoru ve ekrana bağlı Android yön sensörü; Faz 4'te Media3 foreground preview; Faz 5'te exact alarm ve arka plan Media3 iskeleti eklendi. Geliştirme tonu yalnız debug kaynak setindedir. Lisanslı gerçek ezan kayıtları bekleniyor. Kıble ekranında pusula kadranı, N/E/S/W işaretleri veya pusula çemberi yoktur.

## 7. Faz planı ve çıkış ölçütleri

| Faz | İş | Faz tamamlanma koşulu |
|---|---|---|
| 0 — Teknik araştırma | Bu belge, ortam/paket/lisans/Android kararları | CLI ve Java ortamı normalize edildi; prayer engine seçimi açık ve Diyanet doğruluğu bekliyor; alarm izni UX'i tasarım gereksinimi. |
| 1 — Proje iskeleti | Flutter package `ezan`, Android `com.ezan.app`, Riverpod, go_router (`/home`, `/qibla`, `/settings`), merkezi Light/Dark theme, ARB, katman yapısı | `flutter doctor -v`, `flutter analyze`, `flutter test`, Android debug build raporlanır; prayer/Qibla/adhan/alarm implementasyonu yok. |
| 2 — Konum + namaz | Foreground konum izni, yerel son konum, doğrulanmış engine bağdaştırıcısı, yöntem/Asr/yüksek enlem ayarları | Diyanet dahil şehir/tarih fixture kabul toleransı önceden yazılır; bağımsız yayımlanmış fixture testleri; saat dilimi/DST ve offline akış. |
| 3 — Kıble motoru | Büyük daire bearing'i, testler, Android sensör kanalı, declination, durum/kararlılık | Dört şehir bearing testleri; gerçek cihazda yön ve yön değişimi testi; klasik pusula görünümü yok. |
| 4 — Ezan motoru | Media3 yerel oynatım; gerçek hak belgeli beş kayıt gelene kadar geçici yerel placeholder ses | Placeholder yalnız geliştirme/test için; beş gerçek kayıt daha sonra lisans belgeleriyle değiştirilir; AI voice cloning yok. |
| 5 — Android zamanlama | Native exact AlarmManager, `SCHEDULE_EXACT_ALARM` açıklama/ayar akışı, receiver/service, reboot/time/timezone/ayar yeniden planlama | Proje sonrası SDK ile Android 12–17 davranışı doğrulanır; force-stop sınırı açık kabul kriteridir; kilitli ekran ve üretici cihaz testleri. |
| 6 — Light UI | Home, Qibla, Settings; ölçülü premium tipografi ve boşluk | Hedef küçük/büyük ekranlarda taşma yok; görsel referansa göre inceleme. |
| 7 — Dark UI | Aynı token sistemiyle near-black/charcoal tema | Her iki temada kontrast kontrolü; üçüncü tema seçeneği yok. |
| 8 — Polish / kabul | Loading/izin/sensör durumları, hafif animasyon, haptic | UI hata durumları; gerçek cihaz kabul listesi; sürüm build'i ancak ayrı istekle. |

### Faz 4 uygulama sonucu (2026-09-23)

- Media3 ExoPlayer **1.11.1** sabit Gradle sürümü seçildi. Lisans (Apache-2.0), bakım/changelog, Android uyumu, resmi kaynak ve testler incelendi. Media3 minSdk 23; projenin APK minSdk'si 24.
- Yerel playback MethodChannel servisi, ExoPlayer foreground player, alarm kullanımına uygun AudioAttributes, play/stop ve beş namaz slotunun tek tek audio-id eşlemesi kuruldu. Faz 5 background service yerine geçmez.
- Gerçek müezzin kayıtları olmadığı için sözsüz iki kısa tonlu WAV, yalnız Android debug kaynak setinde bulunur. Settings'te preview kontrolleri yalnız debug build'de görünür. Bu dosya adhan değildir ve release APK'sine girmez; beş slot geçici olarak aynı debug tona işaret eder.
- İlk emülatör oynatımında Media3, `USAGE_ALARM` ile otomatik audio-focus isteğini reddetti; alarm kullanımı için otomatik focus yönetimi kapatıldı. Native çağrı artık Media3 `STATE_READY`/hata sonucunu Flutter'a geri iletiyor.
- `flutter analyze`: başarılı, sorun yok. `flutter test`: 12/12 başarılı. `flutter build apk --debug`: başarılı.
- Pixel_8 AVD'de debug placeholder tetiklendi; Android AudioTrack kaydı `USAGE_ALARM`, 16 kHz mono kaynağı gösterdi ve oynatma tamamlanıp durdu. İlgili ExoPlayer hata logu kalmadı. Emülatör playback doğrulaması; fiziksel cihaz üretici/ses davranışı doğrulaması değildir.
- Hiçbir gerçek ezan kaydı veya AI sesi eklenmedi. Production için beş lisanslı kayıt beklenir.

### Faz 3 uygulama sonucu (2026-09-23)

- `QiblaBearingCalculator` büyük daire başlangıç bearing'ini kuzeyden saat yönüne hesaplıyor; Kâbe `21.4225, 39.8262`. İstanbul, Ankara, New York ve Tokyo fixture'ları eklendi.
- Android `TYPE_ROTATION_VECTOR` birincil kaynak; sensör yoksa accelerometer + magnetometer matrisi fallback. Ekran rotasyonu hesaba katılıyor. Native `GeomagneticField` cihazın manyetik azimutunu gerçek kuzeye düzeltiyor.
- Sensor stream yalnızca Kıble rotası dinlendiğinde açılıp stream iptalinde kapanır. Android sensör doğruluğu, beklenen/ölçülen manyetik alan oranı ve sekiz örnekli dairesel heading istikrarı kontrol edilir. Kararlı olmayan veya sensörü olmayan durumda ok güvenilir ölçüm rengiyle gösterilmez; kısa durum bilgisi verilir.
- UI yalnızca Kâbe çizimi, göreli yön oku ve kuzeyden bearing derecesi kullanır; pusula kadranı/yön işaretleri eklenmedi. Ok kısa açısal farkla animasyon yapar.
- Üçüncü taraf dependency eklenmedi. SensorManager ve GeomagneticField Android SDK API'leridir.
- `flutter analyze`: başarılı. `flutter test`: 10 test başarılı. `flutter build apk --debug`: başarılı (`build\\app\\outputs\\flutter-apk\\app-debug.apk`).
- `adb devices -l` boş liste döndürdü; fiziksel Android cihaz veya emülatör bağlı değil. Bu nedenle yön değişimi, sensör fallback'i, gerçek manyetik kalibrasyon/kararlılık ve ekran döndürme donanımda doğrulanamadı. Faz 3 gerçek cihaz kabulü açık kalır; Faz 4'e geçiş için cihaz testi gerekir.
- Android referansı: `GeomagneticField` alan değerleri nT, `SensorEvent` manyetik alan değerleri µT; uygulamadaki eşik karşılaştırması birimleri normalize eder.

### Faz 5 uygulama sonucu (2026-09-23)

- Android native `PrayerAlarmScheduler`, `RTC_WAKEUP` + `setExactAndAllowWhileIdle` kullanır. Manifestte `SCHEDULE_EXACT_ALARM` vardır; `USE_EXACT_ALARM` eklenmemiştir. Android 12+ kullanıcı izni, Ayarlar'daki “Otomatik ezan” anahtarıyla Android'in kesin alarm erişim sayfasına bağlanır. İzin dönüşü uygulama durumu yeniler ve kuyruğu kurar. Anahtarı kapatmak kayıtlı `PendingIntent` alarmlarını iptal eder.
- Flutter, cihazda çevrimdışı hesaplanan beş ezan vakitini (güneş doğuşu hariç) sonraki 30 gün için native kanala verir. Native zaman damgasına özgü immutable `PendingIntent` oluşturur ve kuyruğu `SharedPreferences` içine yazar. Konum ve Asr yöntemi değişimlerinde, takvim günü/saat dilimi yenilemesinde ve uygulama yeniden açıldığında kuyruk yenilenir. Alarm olayı işlendiğinde tüketilir; geçmiş olaylar yeniden çaldırılmaz.
- Boot, saat, saat dilimi, uygulama güncellemesi ve kesin alarm izni değişiminde `AlarmRestoreReceiver` kalan gelecekteki yerel kuyruğu yeniden kurar. Saat/saat dilimi broadcast'inde native taraf mevcut mutlak zaman damgalarını koruyup yeniden kurar; yeni cihaz saat dilimine göre prayer engine tekrar hesabı uygulama foreground olduğunda yapar.
- `AdhanAlarmReceiver`, geçerli local slot için kısa ömürlü native `Service` başlatır. Servis `onCreate` sırasında localized, sessiz/düşük önem bildirimini hemen foreground'a alır; ardından Media3 ExoPlayer ile playback yapar. Manifest `FOREGROUND_SERVICE` ve `FOREGROUND_SERVICE_MEDIA_PLAYBACK` izinlerini ve `mediaPlayback` türünü tanımlar. Oynatım `USAGE_ALARM` ile yapılır. İlk cihaz E2E testinin ortaya çıkardığı controller'sız `MediaSessionService` foreground zaman aşımı giderildikten sonra kullanılmayan `media3-session` kaldırıldı; ExoPlayer korunuyor.
- Gerçek kayıtlar mevcut olmadığından aynı debug-only sözsüz placeholder tüm slotlarda geçici kaynak olarak kalır. Bu resource release paketinde yoktur; production alarm sesi lisanslı beş kayıt eklenene kadar hazır değildir.
- Android 35 Pixel AVD'de debug APK kuruldu ve uygulama açıldı. Önceden izinli app-op senaryosunda anahtar native kanalda etkinleşti; ardından izin varsayılana döndürülüp anahtarın Android “Alarms & reminders” özel erişim sayfasını açtığı ve izin dönüşünde `enabled=true` değerinin SharedPreferences'a yazıldığı doğrulandı. Emülatörde konum fix'i alınamadığından dolu alarm kuyruğu ve gerçek tetikleme çalıştırılamadı.
- `flutter analyze`: temiz. `flutter test`: 12/12 başarılı. `flutter build apk --debug`: başarılı. Ekran rotası testindeki `pumpAndSettle` sürekli bekleyebildiğinden içerik doğrulamasını koruyan sınırlı frame pump kullanıldı.
- Android 12–17'nin tamamı ve en az iki fiziksel OEM cihazı henüz doğrulanmadı; mevcut makinede yalnız API 35 system image kurulu, bağlı fiziksel cihaz yok. Bu Faz 5 kabul kontrolü açık kalır. SDK lisansları da kabul edilmedi (`flutter doctor -v`: Android license status unknown).
- Force-stop sonrası Android alarm/receiver teslimatı garanti edilmez. Kullanıcı uygulamayı sistemden force-stop ederse alarmlar ancak uygulama kullanıcı tarafından yeniden açıldıktan sonra kurulabilir; bu sınır kabul kriteridir.
- Açık tasarım sınırı: çevrimdışı native kuyruk 30 günle sınırlıdır. Uygulama 30 günden uzun süre hiç açılmazsa kuyruk kendiliğinden prayer engine ile doldurulamaz; bu nedenle uzun süreli kullanılmama davranışı garanti edilmez ve release öncesi arka plan yenileme yaklaşımıyla ayrıca ele alınmalıdır.

### Faz 6 uygulama sonucu (2026-09-23)

- Light tema sıcak ivory yüzey, ölçülü altın vurgu, koyu okunaklı metin, sade kartlar ve tek tip Material 3 kontrolleriyle kuruldu. Dark tema tokenları Faz 7 kapsamında değişmedi.
- Home ekranı konum/tarih, sıradaki vakit ve geri sayım ile günlük vakitleri merkezlenmiş, kaydırılabilir tek hiyerarşide sunar. Kıble ekranı Kâbe görseli, yön oku ve dereceyi korur; küçük ekranlarda dikey kaydırma sağlar, pusula kadranı/yön işareti eklenmedi.
- Settings ekranına konum yenileme, mevcut hesaplama ve Asr seçimi, exact alarm anahtarı, ses düzeyi, tema, dil ve hakkında alanları yerleştirildi. Ezan ses düzeyi native SharedPreferences'ta saklanır; kayıtlar gelene kadar debug-only sözsüz placeholder kullanılır. Lisanslı gerçek kayıtlar hâlâ mevcut değildir.
- ARB Türkçe/İngilizce etiketleri üretildi; üçüncü taraf dependency eklenmedi. Tema ve dil seçimi mevcut uygulama oturumu boyunca Riverpod durumunda tutulur.
- `flutter analyze`: başarılı, sorun yok. `flutter test`: 12/12 başarılı. `flutter build apk --debug`: başarılı (`build\\app\\outputs\\flutter-apk\\app-debug.apk`). Derleme `flutter_timezone` KGP gelecek uyumluluk uyarısını verdi.
- `java -version` ve `flutter doctor -v`, Flutter yapılandırmasındaki JDK 21'i doğruladı; Android SDK lisans durumu unknown ve bağlı Android cihaz/emülatör yok.
- Gerçek küçük/büyük ekran görsel incelemesi ve fiziksel cihaz kabulü yapılmadı. Faz 5 Android 12–17 ve OEM cihaz kontrolleri, alarmın gerçek tetiklenmesi ve force-stop sınırının cihaz doğrulaması açık kalır. Bu faz UI kaynakları ve debug build ile doğrulandı; cihaz davranışı PASS olarak sunulmaz.

### Faz 7 uygulama sonucu (2026-09-23)

- Dark tema charcoal/near-black arka plan ve surface kademeleri, kırık beyaz ana metin, açık nötr ikincil metin ve sınırlı sıcak altın vurgu kullanır. Yeşil marka tonu koyu temadaki vurgu olarak kaldırıldı; Light palet aynen korundu.
- Koyu temanın metin/yüzey, ikincil metin/kart, altın/yüzey ve buton yazısı/altın kontrast eşleşmeleri için tema testleri eklendi; her eşleşme WCAG normal metin için 7:1 eşiğini geçti.
- `flutter analyze`: başarılı, sorun yok. `flutter test`: 15/15 başarılı. `flutter build apk --debug`: başarılı (`build\\app\\outputs\\flutter-apk\\app-debug.apk`). Derlemede `flutter_timezone` KGP gelecek uyumluluk uyarısı devam etti.
- Bağlı Android cihaz/emülatör bulunmadığından gerçek ekran görüntüsü/cihaz görsel incelemesi yapılmadı. Faz 5 gerçek Android sürüm/OEM testleri ve alarm tetikleme kabulü açık kalır.

### Faz 8 final kabul sonucu (2026-09-23)

- `flutter analyze`: temiz. `flutter test`: 17/17 başarılı; Diyanet yayımlanmış şehir/tarih fixture'ları (tanımlı en çok 2 dakika tolerans), Standard/Hanafi Asr, DST/high-latitude/sonraki namaz, dört şehir kıble bearing'i, yön kararlılığı, beş ayrı ezan slotu, tema kontrastı ve dar ekran rota testi dahil.
- Güncel `flutter build apk --debug --target-platform android-arm64`, `flutter build apk --release` ve `flutter build appbundle --release` başarılı. Release çıktıları: APK 52.9 MB, AAB 51.6 MB; kimlik `com.ezan.app`, sürüm `1.0.0+1`, minSdk 24 / targetSdk 36. Release paketinde `placeholder_chime` yok.
- Release APK `apksigner verify` ile doğrulanmıyor; `jarsigner` AAB için `jar is unsigned` bildiriyor. `android/key.properties`, keystore ve gerçek imza bu çalışmada bulunmuyor; Gradle artık debug anahtarı fallback'i yapmıyor. **Production signing release blocker'ıdır.**
- Release manifestte coarse/fine location, `SCHEDULE_EXACT_ALARM`, boot ve media playback foreground service izinleri var; `INTERNET`, `ACCESS_BACKGROUND_LOCATION` ve `USE_EXACT_ALARM` yok. Media3 ExoPlayer manifest merge'i `ACCESS_NETWORK_STATE` ve `WAKE_LOCK` ekliyor. Kaynakta backend/HTTP çağrısı veya koordinat upload akışı bulunmadı.
- Kullanılmayan `media3-session` bağımlılığı, alarm servisi MediaSession controller/notification akışını kullanmadığı ve kısa çalmada foreground geçişinin gerçekleşmediği cihaz testiyle anlaşıldıktan sonra kaldırıldı. ExoPlayer kalıyor. `flutter_timezone` için basılan KGP uyumluluk uyarısı önceki kaynak/Gradle incelemesindeki koşullu built-in Kotlin false-positive'i olarak sürüyor.
- `flutter doctor -v`: Flutter 3.47.1 / Dart 3.13.1, Android SDK 36, Microsoft JDK 21.0.12.1 ve bağlı A065 Android 16 / API 36 doğrulandı. Android SDK lisans durumu `unknown`; kabul ettirilmedi. Tek cihaz/OEM dışında Android 12–15/17, ikinci OEM, boot/time/timezone restore, force-stop sonrası otomatik teslimat ve gerçek lisanslı ezan kayıtları doğrulanmadı.
- Faz 8 teknik QA tamamlandı. Production release **BLOCKED**: production keystore/signing ve lisans belgeli 5 gerçek kayıt henüz yok; ikinci OEM/Android sürüm kapsamı da açık.

### Fiziksel cihaz devam testleri (2026-09-23)

- `flutter doctor -v`: Flutter 3.47.1 / Dart 3.13.1, Android SDK 36 ve Flutter yapılandırmasındaki Microsoft JDK 21.0.12 doğrulandı. Android SDK lisans durumu hâlâ `unknown`. `flutter analyze` temiz, `flutter test` 15/15 başarılı.
- Güncel ARM64 debug APK üretildi, `com.ezan.app` olarak Nothing A065 (`Pong`), Android 16 / API 36 cihaza kuruldu ve açıldı. Ekran 1080×2412, yoğunluk 420 dpi; Home, Kıble ve Ayarlar ekranları açıldı, taşma/çökme görülmedi. Home'da cihaz konumu ve günlük altı vakit yüklendi.
- Foreground konum izni uygulamanın kullanıcı akışı üzerinden istendi ve “Uygulamayı kullanırken” seçeneğiyle verildi. Release/debug manifestte arka plan konum izni yok.
- Kıble ekranı Kâbe görseli, göreli ok ve 151° bearing gösterdi; pusula kadranı/yön işaretleri yok. Donanımda `TYPE_ROTATION_VECTOR`, accelerometer ve magnetometer bulundu. Qibla route açılınca rotation-vector/magnetometer akışı 20 ms periyotla başladı; Home'a dönünce kapandı ve Kıble'ye dönünce yeniden başladı. Kullanıcının cihazı yaklaşık 90° sağa çevirmesinden sonra rotation-vector örneği `z=-0.68, w=0.74` değerlerinden `z=-0.25, w=0.97` değerlerine değişti; ekran oku da karşı yönde değişti, Kaaba bearing'i 151° sabit kaldı. Bu fiziksel cihazda sensör akışı ve yön tepkisi doğrulandı; mutlak derece doğruluğu bağımsız referansla ölçülmedi.
- Android 16 exact-alarm ayarı uygulama anahtarından açıldı; `SCHEDULE_EXACT_ALARM` app-op `allow` oldu. Tercih kapanınca Android Alarm Manager `alarm_cancelled` kaydı üretti; yeniden açılınca sonraki 30 gün için 148 `RTC_WAKEUP` exact alarmı kuruldu. `am force-stop` sonrasında etkin alarmlar temizlendi; kullanıcı uygulamayı yeniden açınca kuyruk geri kuruldu.
- İlk sistem teslimatı testinde Android 16'da MediaSession tabanlı playback servisi placeholder bitince foreground'a geçemedi; `ForegroundServiceDidNotStartInTimeException` logu bunu kanıtladı. Çözüm: servis kısa ömürlü `Service` olarak düzenlendi, `onCreate` içinde sessiz playback bildirimiyle hemen `startForeground` yapıyor; sonra ExoPlayer başlatıyor. Kullanılmayan `media3-session` Gradle bağımlılığı çıkarıldı.
- Düzeltme sonrası özgün 147 gelecek alarm olayı yedeklenerek 35 saniye sonrasına tek geçici exact alarm eklendi. `AlarmManager` synthetic timestamp'i gösterdi; teslimatta sistem `code:ALARM_MANAGER_WHILE_IDLE` ile playback FGS başlangıcına izin verdi; ExoPlayer 1.11.1 playback `PLAYING` durumuna geçti, kısa debug tonu tamamlandı, sentetik olay tercih listesinden tüketildi ve foreground-timeout/crash oluşmadı. Özgün XML geri kondu, receiver ile eski kuyruk yeniden planlandı ve uygulama açıldı. Bu **gerçek prayer saati değil, gerçek AlarmManager exact teslimatını kullanan sentetik E2E olayıdır**.
- Settings'teki debug-only “Test sesini çal” placeholder'ı Media3 1.11.1 üzerinde ayrıca doğrulandı. Ton sözsüzdür; gerçek ezan kaydı değildir. Gerçek 5 kayıt ve lisansları bekleniyor.
- Cihaz doğrulaması yalnız Nothing A065 / Android 16 ile sınırlı. Android 12–15/17, ikinci OEM, boot/time/timezone restore, gerçek namaz vakti, offline lisanslı ses ve küçük ekranların fiziksel doğrulaması açık kalır. Force-stop sonrası teslimat garanti edilmez; kullanıcı uygulamayı yeniden açtıktan sonra planlama başlar.

### Built-in Kotlin geçişi (2026-09-23)

- `flutter_timezone 5.1.0` kaynak incelemesinde Android Gradle script'inin AGP 9 ve `android.builtInKotlin=true` koşulunda `kotlin-android` uygulamadığı doğrulandı. Projedeki AGP 9.1 ve Flutter 3.47.1 built-in Kotlin desteğiyle uyumlu; `android/gradle.properties` bu modu açacak şekilde güncellendi.
- Gradle değerlendirme modeliyle yapılan doğrudan probe `:flutter_timezone`, `:geolocator_android` ve `:package_info_plus` için `plugins.hasPlugin('kotlin-android') == false`, `android.builtInKotlin == true` döndürdü. Değişiklik sonrası debug APK, release APK ve release AAB build'leri başarılı.
- Flutter 3.47.1 uyarısı yine basılıyor; `FlutterPluginUtils.kt` build dosyalarını regex ile okuyor ve `pluginsWithKGPAppliedList` değerini gerçek Gradle plugin durumunu sormadan bu statik eşleşmeden kuruyor. `flutter_timezone` içindeki koşullu/etkin olmayan `apply plugin: 'kotlin-android'` satırı bu yüzden uyarı listesine giriyor. Flutter issue [#189770](https://github.com/flutter/flutter/issues/189770) aynı hatalı davranışı doğrulanmış ve açık issue olarak izliyor. Bu sürümde uyarı mesajı sürse de etkin build yolu built-in Kotlin'dir; Flutter ve `flutter_timezone` yükseltmelerinde tekrar doğrulanmalı.
- Resmî dayanak: Flutter'ın built-in Kotlin kılavuzu, Flutter 3.47+ ve AGP 9+ ile `android.builtInKotlin=true` akışını tanımlar; `flutter_timezone 5.1.0` changelog'u AGP 9 desteğini listeler.

### Faz 2 uygulama sonucu (2026-09-23)

- Konum izni kullanıcı konum yenileme eylemiyle foreground olarak istenir; mevcut izin varsa son bilinen konum kullanılabilir. Uygulama konumu sunucuya göndermez ve background izni tanımlamaz.
- Türkiye preset'li `adhan_dart` bağdaştırıcısı, Standard/Hanafi Asr, önerilen yüksek enlem kuralı ve polar gün için `aqrabYaum` çözümü eklendi. Home'da altı günlük vakit, sıradaki namaz ve geri sayım gösterilir.
- `flutter analyze`: başarılı, sorun yok. `flutter test`: 6/6 başarılı. `flutter build apk --debug`: başarılı (`build\\app\\outputs\\flutter-apk\\app-debug.apk`).
- Derlemede `flutter_timezone` KGP gelecek uyumluluk uyarısı görüldü; hata değil. `flutter doctor -v` JDK 21'i doğruladı; Android SDK lisans durumu bilinmiyor uyarısı devam ediyor. Kullanıcı ve makine ortam değişkenleri 21'e ayarlı olsa da açık kalmış terminal süreci eski JDK 26 değerini miras almıştı; bu terminal/IDE yeniden başlatılmalı.
- Faz 2 tamamlandı. Sonraki faz yalnızca kullanıcının açık “DEVAM ET” talebiyle başlayacak.

## 8. Kaynaklar

- Adhan Dart `adhan_dart` API/preset/yüksek enlem/Qibla: https://pub.dev/packages/adhan_dart
- Adhan Dart kaynak deposu ve testleri: https://github.com/prayer-timetable/adhan_dart
- Prayer Time Plus alternatif paketi, kaynak ve testleri: https://pub.dev/packages/prayer_time_plus
- Flutter lint paketi/lisansı: https://pub.dev/packages/flutter_lints
- Dart intl paketi/lisansı: https://pub.dev/packages/intl
- Android Gradle Plugin 9.1 sürüm/uyumluluk tablosu: https://developer.android.com/build/releases/agp-9-1-0-release-notes
- Android build JDK rehberi: https://developer.android.com/build/jdks
- Flutter Android Gradle yapılandırma rehberi: https://docs.flutter.dev/deployment/android
- Adhan Dart lisansı ve sürümü: https://pub.dev/packages/adhan_dart/license
- Eski `adhan` paketi karşılaştırması: https://pub.dev/packages/adhan
- `geolocator` sürüm, izin ve MIT lisansı: https://pub.dev/packages/geolocator
- IANA timezone verisi, offline veritabanı ve BSD-2 lisansı: https://pub.dev/packages/timezone
- IANA timezone veritabanı sürüm geçmişi: https://www.iana.org/time-zones/releases
- Cihaz timezone eklentisi: https://pub.dev/packages/flutter_timezone
- Android exact alarm rehberi ve izin ayrımı: https://developer.android.com/develop/background-work/services/alarms
- Android 14 exact alarm izni davranışı: https://developer.android.com/about/versions/14/behavior-changes-all
- Google Play `USE_EXACT_ALARM` kabul sınırı: https://support.google.com/googleplay/android-developer/answer/9888170
- Exact alarmın background foreground-service istisnası: https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start
- Android konum/yön sensörleri ve füzyon: https://developer.android.com/develop/sensors-and-location/sensors/sensors_position
- Android rotation vector referans eksenleri: https://developer.android.com/develop/sensors-and-location/sensors/sensors_motion
- Android Media3 background playback: https://developer.android.com/media/media3/session/background-playback
- Android 17 background audio kısıtları ve alarm ses istisnası: https://developer.android.com/about/versions/17/changes/bg-audio
- `android_alarm_manager_plus` alternatifinin reboot ve force-stop sınırları: https://pub.dev/packages/android_alarm_manager_plus
- `shared_preferences` lisansı ve depolama seçenekleri: https://pub.dev/packages/shared_preferences
- `flutter_riverpod` lisansı: https://pub.dev/packages/flutter_riverpod
- `go_router` lisansı: https://pub.dev/packages/go_router
- Media3 stable sürümler/release notes: https://developer.android.com/jetpack/androidx/releases/media3
- Media3 ExoPlayer WAV desteği: https://developer.android.com/media/media3/exoplayer/supported-formats
- AndroidX Media kaynak, testler ve Apache-2.0 lisansı: https://github.com/androidx/media

## 10. Premium UI ve release blocker kapanış denetimi (2026-09-23)

### Technical status

- `JAVA_HOME` (User/Machine), PATH'teki ilk Java ve Flutter JDK yapılandırması Microsoft OpenJDK **21.0.12.1 LTS** ile eşleşiyor. `java -version` bunu doğruladı. `flutter doctor -v`: Flutter **3.47.1**, Dart **3.13.1**, Android SDK **36.0.0**; bağlı Nothing A065 Android **16 / API 36**. Android SDK lisans durumu `unknown`; lisans kabulü yapılmadı.
- Bu turda `flutter analyze` sorunsuz tamamlandı. `flutter test`: **23/23** başarılı; 320/360/411/600/800 dp görünüm, yatay yerleşim, Türkçe/İngilizce, System/Light/Dark ve 320 dp'de %160 metin ölçeği kapsamı var. UI tercihlerinin yerel kalıcılığı için yeniden açılış testi eklendi.
- UI tercihleri Android `SharedPreferences` üzerinden saklanıyor; yeni paket/izin yok. Tema (`system`, `light`, `dark`) ve dil (`tr`, `en`) yeniden açılıştan sonra korunuyor. Cihaz testinde seçimler doğrulandı; test sonunda cihaz teması System'e, dili Türkçe'ye döndürüldü.
- `flutter_timezone` için Flutter built-in Kotlin/KGP gelecek uyumluluk uyarısı debug/APK/AAB derlemelerinde hâlâ basılıyor. AGP 9.1 + `android.builtInKotlin=true` çalışma modu önceki Gradle plugin probe'unda doğrulanmıştı; uyarı Flutter'ın statik Gradle dosyası taramasından geliyor. Derlemeler başarılı, uyarı ayrı takip edilmelidir.

### Prayer status

- `adhan_dart 2.0.1` ve Diyanet karşılaştırma kararı yukarıdaki Faz 0/2 kayıtlarında korunuyor: şehir/tarih fixture'ları en fazla 2 dakika fark gösterdi; birebir eşitlik iddiası yok.
- Asr tercihi Android yerel depoda saklanıyor ve kuyruk yeniden hesaplanıyor. A065'te Hanafi seçimi uygulama force-stop/reopen sonrasında korundu; test sonunda Standard'a geri alındı.

### Alarm status

- Kaynak akışı tekrar incelendi: exact `RTC_WAKEUP` → `AdhanAlarmReceiver` → `startForegroundService` → servis `onCreate` içinde Media3/tercih okumadan önce `startForeground` → ExoPlayer. Servis daha sonra olay/ses doğrulaması yapıyor. İzin akışı `SCHEDULE_EXACT_ALARM` sistem ekranına gidiyor; manifestte `USE_EXACT_ALARM` yok.
- Önceki Android 16 sentetik AlarmManager/Media3 E2E ve bu turdaki cihaz durumu kayıtları korunuyor. A065'te exact alarm app-op `allow`; force-stop sonrasında uygulama yeniden açılınca **147** gelecek olay kuruldu. Hanafi değişikliğinde kuyruk tekrar hesaplandı. Flutter testleri gün 1/gün 30/gün 31, timezone, location, Asr ve reopen durumlarını kapsıyor.
- `TIME_SET` ve `TIMEZONE_CHANGED` receiver'ı saklanan eski olayları iptal edip `schedule_invalidated=true` yapıyor. Dart yeni lokasyon/timezone hesaplamasını ancak uygulama ön plana geldiğinde veya yeniden açıldığında yapabilir; uygulama kapalıyken bu iki olaydan sonra alarm kuyruğu boş kalabilir. Bu nedenle arka planda kendiliğinden yeniden hesaplama garanti edilmez.
- Boot, package replacement ve exact-alarm izin değişikliğinde saklanan gelecek epoch olayları yeniden kurulur; gerçek boot/time/timezone/permission broadcast matrisi bu turda A065 dışında fiziksel olarak sınanmadı. Force-stop Android'in alarmları kaldırdığı kabul edilen sınırdır; uygulama tekrar açılınca kuyruk kurulur, force-stop durumunda teslimat garantisi verilmez.
- Android 12–17 ve iki farklı OEM cihaz kabul matrisi eksik olduğu için alarm kabulü **PARTIAL**.

### Audio status

- Fajr/Dhuhr/Asr/Maghrib/Isha için ayrı local asset kimlikleri doğrulandı; Media3 **1.11.1** yerel oynatma kullanıyor. Lisanslı beş kayıt bulunmadığından yalnızca debug kaynak setindeki sözsüz placeholder test edilebilir. Release APK arşivinde `placeholder_chime` veya `res/raw` kaydı yok. Gerçek ticari lisanslar gelene kadar production audio **BLOCKED**; AI voice cloning yok.

### Device validation and UI status

- Fiziksel ekran incelemesi yalnızca Nothing A065 / Android 16 / API 36'da yapıldı. Home Light, Qibla Light, Settings Light; Home Dark, Qibla Dark ve Settings Dark ekranları incelendi. Kıble UI'ında pusula halkası, kadran veya yön harfleri yok; Kâbe görseli, yön oku ve derece dışında compass UI eklenmedi.
- Home'da sıradaki namaz ve serif zaman hiyerarşisi öne çıkarıldı; altı ayrı kart kaldırıldı ve aktif namaz ince bir vurgu ile ayrıldı. Ayarlar kart yığınından bölümlü düz listeye dönüştü. Renk/spacing/typography/motion token'ları merkezileştirildi. A065 görünümünde yoğunluk, hizalama, kontrast ve responsive davranış gözden geçirildi. Premium UI ölçütleri bu gerçek cihaz görüntü incelemesi ve widget matrisiyle **PASS**; bu karar release veya final device acceptance anlamına gelmez.
- Ekran okuyucu/sensör mutlak yön referansı ve fiziksel font ölçeği cihaz matrisi kapsamı tamamlanmadı. Kıble büyük daire matematiği ve sensör yaşam döngüsü yazılım testleri/önceki A065 turuyla doğrulandı; gerçek kuzey referansına göre mutlak doğruluk doğrulanmış değildir.

### Release blockers

- `android/app/build.gradle.kts` release signing yapılandırması varsa production anahtarıyla, yoksa `null` ile derleniyor; debug signing fallback yok. Mevcut proje Android dizininde gerçek `key.properties`/keystore bulunmadı; yalnızca secretsiz `key.properties.example` var. Çıkan release APK'da `apksigner verify --print-certs` başarısız oldu (`DOES NOT VERIFY`); AAB `jarsigner -verify` çıktısı `jar is unsigned`. Paket `com.ezan.app`, sürüm `1.0.0+1`, minSdk 24, targetSdk 36. APK/AAB **build PASS, production signing BLOCKED**.
- Release manifest coarse/fine location, `SCHEDULE_EXACT_ALARM`, boot ve media playback foreground service izinlerini içeriyor; `INTERNET`, background location ve `USE_EXACT_ALARM` içermiyor. Media3 manifest merge `ACCESS_NETWORK_STATE`/`WAKE_LOCK` ekliyor.
- Açık P0 release blocker'ları: **production signing**, **lisansı doğrulanmış beş gerçek ezan kaydı**, **final cihaz kabul matrisi**. Bunlar kapanana kadar `READY FOR RELEASE` veya `final acceptance` denemez.
- P1: zaman dilimi paketi içindeki IANA verisi belgelenen 2025c snapshot'ında; son IANA kurallarıyla yeniden doğrulama/güncelleme gerekiyor. Uygulama kapalıyken time/timezone sonrası yeniden hesaplama ve tam OS/OEM alarm yaşam döngüsü fiziksel doğrulanmadı.
- P2: Android SDK lisans durumu `unknown` kaldı; kullanıcı adına lisans kabulü yapılmadı. KGP uyarısı mevcut build'i durdurmuyor ancak sonraki Flutter/plugin yükseltmelerinde yeniden doğrulanmalı.
- Bu tur sonu artefaktları: debug ARM64 APK, unsigned release APK ve unsigned release AAB başarıyla üretildi. APK: `build/app/outputs/flutter-apk/app-release.apk` (**52.8 MB**); AAB: `build/app/outputs/bundle/release/app-release.aab` (**51.5 MB**). Başarılı derleme production release kabulü değildir.
