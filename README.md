# EZAN

Flutter Android uygulama iskeleti (`ezan`, `com.ezan.app`). Faz 1 yalnızca
Riverpod ve named route altyapısını, merkezi Light/Dark theme'i, Türkçe/İngilizce
ARB metinlerini ve katman yapısını kurar. Prayer/Qibla hesaplama, cihaz konumu,
sensör, ses ve Android alarm uygulamaları sonraki fazlardadır.

## Geliştirme kontrolleri

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
```

Teknik kararlar ve doğruluk araştırması için [TECHNICAL_DECISIONS.md](TECHNICAL_DECISIONS.md)
dosyasına bakın.
