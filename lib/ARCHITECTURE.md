# EZAN application layers

```text
Flutter UI
  → Presentation
  → Application / services (Riverpod composition and state)
  → Domain (models and ports)
  → Data / Infrastructure (repositories and platform adapters)
  → Native Android (Kotlin platform integrations)
```

Faz 1 establishes the app boundary, navigation, localization, and theme state.
Faz 2 adds foreground location and device-timezone adapters, an isolated prayer
calculation service, and the Home prayer dashboard. Faz 3 adds the great-circle
Qibla bearing, a route-scoped Android orientation stream, geomagnetic correction,
and sensor reliability filtering. Faz 4 adds local Media3 ExoPlayer playback and
a debug-only non-voice placeholder preview. Faz 5 adds an exact-alarm scheduler
with a locally persisted 30-day queue, Android restore receivers, and a short-lived
native foreground playback service. It starts a silent low-importance notification
immediately, then plays the local audio through Media3 ExoPlayer. The alarm
permission is initiated from the Settings toggle. Licensed production recordings
and multi-version/OEM alarm validation are still pending. Force-stop prevents a
promise of alarm delivery; the user must launch the app again. The 30-day queue is
replenished when the app opens or relevant settings/date/timezone state changes.
