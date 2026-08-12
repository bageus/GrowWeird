# GrowWeird — Yandex Games Integration

This document owns Yandex Games integration behavior and release checks. General platform boundaries remain authoritative in [`ARCHITECTURE.md`](ARCHITECTURE.md); test commands remain in [`TESTING.md`](TESTING.md).

## Integration boundary

Yandex SDK calls belong only under `src/infrastructure/platform/`.

- `PlatformAdapter` defines capabilities used by the application.
- `LocalPlatformAdapter` is the native/editor fallback.
- `YandexPlatformAdapter` owns JavaScript/Yandex SDK calls.
- `PlatformRuntime` selects an adapter and exposes one process-wide facade.
- Domain services never import `JavaScriptBridge`, Yandex SDK APIs or browser globals.

Application code may ask the platform for time, cloud storage, lifecycle or ad capabilities; it must not reimplement vendor calls.

## Bootstrap

The Web adapter loads the Yandex SDK from the platform-relative `/sdk.js` path when `YaGames` is not already present, then initializes it once.

If initialization fails, `PlatformRuntime` falls back to the local adapter instead of blocking gameplay. Local/editor runs therefore do not require the Yandex SDK.

After local/cloud save reconciliation and offline catch-up complete, the adapter reports the game ready through Yandex Loading API. Do not report ready before the playable state is reconstructed.

## Trusted session time

Yandex sessions use the platform server clock through `PlatformAdapter.now_unix()`. Native/editor sessions use local system time through the local adapter.

No Domain service reads wall-clock time directly. Saved `last_saved_unix` is stamped by `PersistenceCoordinator`, which is also the sole owner of local/cloud reconciliation and resume catch-up.

## Local and cloud saves

`SaveRepository` owns JSON serialization and local filesystem persistence. The exact same JSON payload is used for cloud storage.

Startup order:
1. load the local candidate;
2. initialize the platform;
3. load cloud data when available;
4. choose the candidate with the newer `last_saved_unix`;
5. calculate bounded offline progression using platform time;
6. persist the reconciled result locally and, when available, to cloud;
7. expose the reconciled state to the running simulation.

Cloud writes are throttled independently from local autosaves and guarded against overlapping requests. The Yandex adapter also rejects a save payload before it reaches the platform storage-size ceiling.

The cloud field key is an infrastructure detail. Changing it requires an explicit migration/compatibility plan because existing players may have data under the previous key.

## Offline progression

`OfflineProgressionService` is the only catch-up owner. It reuses `PlantSimulationService`, `FruitLifecycleService` and `FertilizerOfferService`; it does not contain alternative growth or care formulas.

Offline behavior is configured through `GameRules` switches for environment, growth, health, permanent death, fruiting and fertilizer offers. Maximum elapsed time and maximum simulation chunks are balance/performance values in the rules resource, not duplicated here.

Long absences are bounded. Never simulate one foreground tick for every missed second.

## Browser lifecycle

The Yandex adapter forwards `game_api_pause` and `game_api_resume` into `PlatformRuntime`.

On pause, `GameApp` stops realtime simulation, resets its accumulator and requests persistence. On resume, it computes elapsed time from platform time and applies the same offline catch-up policy before continuing realtime simulation.

This path is also used when the platform pauses the game around browser/platform UI.

## Ads and Gameplay API

The platform abstraction already exposes fullscreen-ad and gameplay-state capabilities, but GrowWeird currently has **no automatic advertising placement policy**.

Do not call fullscreen ads from Domain or arbitrary UI callbacks. A future monetization use case must own when an ad is eligible, cooldown/frequency rules, reward semantics and failure behavior.

Gameplay API markup is intentionally not started automatically in this slice. When it is activated, every real gameplay/menu/ad transition must be marked consistently rather than enabling only the startup path.

## Release verification

Before a Yandex release:
1. run all headless test runners from [`TESTING.md`](TESTING.md);
2. export the Godot Web build;
3. run it in the Yandex test environment, not only from a generic local HTTP server;
4. verify initialization reaches the playable screen and Loading API is completed;
5. verify a fresh anonymous/local session works when player cloud data is unavailable;
6. verify an authenticated player can save, reload and recover the newer cloud state;
7. background/pause the game, return later and confirm one bounded catch-up is applied;
8. confirm an active fertilizer offer cannot be rerolled by reload;
9. inspect browser console output for SDK/cloud errors;
10. do not enable production ad placements until their gameplay/menu lifecycle is fully wired and tested.

## Failure policy

Platform failure must degrade features, not corrupt gameplay:

- SDK unavailable → local adapter fallback;
- player/cloud unavailable → continue with local save;
- cloud read invalid → keep valid local candidate;
- cloud write failure → keep local state and retry only on a later normal save opportunity;
- ad unavailable/error → continue gameplay without granting vendor-dependent rewards;
- server time unavailable outside Yandex → local adapter clock.

Never erase the valid local candidate only because a platform request failed.
