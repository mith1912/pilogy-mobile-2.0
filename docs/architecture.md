# Architecture plan

Status: M01 Dart source and Android/iOS scaffolding are implemented at the mobile root. Native files were rendered from installed Flutter 3.13.9 templates because the CLI crashes; Dart compilation/dependency resolution and runtime tests remain unverified. The tree below describes the source organization.

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
  core/
    config/app_environment.dart
    network/api_failure.dart
    design_system/
      app_colors.dart
      app_typography.dart
      app_spacing.dart
      app_radius.dart
      app_theme.dart
      widgets/
  features/
    welcome/presentation/
    profiles/{data,domain,presentation}/
    discover/presentation/
    analysis/presentation/
    number_detail/presentation/
    settings/{data,presentation}/
    privacy_data/presentation/
  services/
    network/dio_provider.dart
    storage/local_database.dart
    storage/preferences_provider.dart
test/
docs/
```

Widgets render state and invoke view-model commands. Riverpod Notifier/AsyncNotifier view models own presentation state and orchestration. Feature repository interfaces separate storage/network from presentation only where real use cases require them; do not add empty generic repository hierarchies. Data implementations depend on shared Dio/database/preferences services. Route configuration lives in app/, reusable visuals in core/. M01 has eight placeholders without fabricated business data or full API repositories. A concrete local profile repository, injectable provider and ProfilesViewModel now implement offline CRUD and selection. Tests inject temporary SQLite factories or small UI/Firebase fakes.

## M02 local storage implementation

See [local database](local-database.md), [profile management](profile-management.md), [migration safety](local-data-migration.md), and [Firebase setup](firebase-setup.md) for the implemented schema and lifecycles. The new filename is pilogy_v1_local.db, schema version 1; M01/legacy files are not migrated or deleted.

The real LocalProfileRepository implements CRUD and selected profile transactions. ProfilesViewModel serializes writes and exposes consistent snapshots; selectedProfileProvider derives from them. Shared CacheStore persists opaque API response JSON and versioned shared articles without HTTP or local numerology. Random revision/context tokens prevent stale asynchronous responses from reviving invalidated cache. Fixed LocalDataException codes prevent SQL/input leakage.

Firebase startup runs before the UI with bounded initialization, identity validation and collection disabled by default. Profile CRUD has no Firebase dependency and works when initialization is unavailable. Eight routes remain placeholders; reusable create/edit/list/selection/deletion widgets await M04 composition. No full screen, API integration, authentication or synchronization was added.

## Validation authored; execution pending recovery

Tests cover startup under ProviderScope; light-theme tokens/component styles; route path/name resolution for all eight IDs and unknown-route handling; API URL defaults/overrides/invalid values; initial welcome placeholder rendering. Use injected services and disable font network fetching in widget tests. Add migration/API integration tests when those behaviors exist, rather than testing empty scaffolding.

## Actual feature structure

Eight feature widgets use `core/presentation/route_placeholder.dart`: welcome, profiles (form and list), discover, analysis, number_detail, settings, privacy_data. The only wired screen CTA is the explicitly supported Discover → Analysis relationship. `app/router.dart` contains eight named GoRoutes and an unknown-route empty state. No new screen IDs are introduced. No backend API call, DB open, repository query, or preferences load is required to show V01. Firebase initialization is attempted before UI startup; failure does not block local profile functionality.

Riverpod owns the router and Dio lifecycles; SQLite opens lazily and has explicit close/disposal. shared_preferences is a FutureProvider with namespaced preference keys. SDK/localization/testing/Firebase dependencies and exact declared direct package versions are recorded in README. Tests replace font rendering with system fonts and inject repositories without platform plugins.


## M03 integration layer

features/numerology/domain/api_models.dart contains strict typed response/request DTOs and date/display helpers; data/backend_repositories.dart contains ConfigRepository, NumerologyRepository and InterpretationRepository plus explicit DataSnapshot freshness/refresh/error metadata. Presentation providers use existing selectedProfileProvider and cacheStoreProvider; services/network/api_client.dart reuses centralized Dio. Widgets perform no HTTP or number calculations. The eight existing placeholders remain unchanged.

Selected calculation strips retained AsyncValue data on identity changes and cancels disposed requests. SQLite revision/context checks reject stale writes. See backend-integration.md, cache-strategy.md and flutter-api-verification.md for consumer semantics and actual blocked checks. No M04 screen or cloud profile service is introduced.


## M04 application composition

app/startup.dart reads preferences and an SQLite snapshot before choosing V01/V03/V08. app/router.dart keeps the same eight routes with safe type/edit context and restoration scopes; app/app.dart holds the profile view-model lifecycle. Existing screens now compose shared native widgets, local profile commands and M03 typed providers. HTTP and serialization stay out of screen widgets.

The selected-calculation stream stays alive across tabs, still cancels on input/date changes, and supports explicit cache-clear suspension to avoid hidden refill. PrivacyViewModel owns local maintenance commands; LocalDataActions serializes profile export via an injected native driver. Native Android/iOS save/share bridges are only used after explicit user confirmation. SettingsViewModel persists the scoped reminder preference without notification scheduling. Schema version remains 1; no legacy or cloud migration occurs. Runtime verification remains blocked (m04-verification.md).
