# Flutter KGP Migration & Temporary Dependency Overrides

## Overview

This project has been migrated to Flutter's Built-in Kotlin Gradle Plugin (KGP) configuration.

```properties
android.builtInKotlin=true
android.newDsl=false
```

Reference:
https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin

## What Was Changed

### 1. Removed Plugin-Level Kotlin Gradle Plugin Configuration

Removed legacy Kotlin plugin declarations from locally patched plugins.

**Groovy (build.gradle)**

```gradle
apply plugin: 'kotlin-android'
```

**Kotlin DSL (build.gradle.kts)**

```kotlin
id("org.jetbrains.kotlin.android")
```

These declarations conflict with Flutter's built-in Kotlin configuration and may generate KGP migration warnings.

---

### 2. Added Temporary Dependency Overrides

The following plugins use locally patched versions from the `third_party` directory:

```yaml

pay_android:
   path: third_party/pay_android-3.2.0
   
age_range_signals:
   path: third_party/age_range_signals-0.8.0
```

These overrides allow the project to work with:

```properties
android.builtInKotlin=true
android.newDsl=false
```

---


## Current Dependency Overrides

```yaml
dependency_overrides:
   pay_android:
      path: third_party/pay_android-3.2.0

age_range_signals:
   path: third_party/age_range_signals-0.8.0
```

---

## When Can These Overrides Be Removed?


### KGP Migration Overrides

Remove when:

1. Plugin maintainers officially support Flutter Built-in Kotlin migration.
2. No plugin contains:
    - `apply plugin: 'kotlin-android'`
    - `id("org.jetbrains.kotlin.android")`
3. Latest pub.dev version builds successfully.
4. No KGP migration warnings remain.

---

## Upgrade Checklist

1. Remove one override.
2. Run:

```bash
flutter clean
flutter pub get
```

3. Build:

```bash
flutter build apk
```

or

```bash
flutter build appbundle
```

4. Verify:
    - No KGP warnings.
    - No record_web warnings.
    - Android build succeeds.
    - iOS build succeeds.

---

## Migration Status

| Item                               | Status |
|------------------------------------|--------|
| Flutter Built-in Kotlin Enabled    | ✅ |
| android.builtInKotlin=true         | ✅ |
| Local Plugin Patches Applied       | ✅ |
| record_web Override Applied        | ✅ |
| Flutter 3.47 Compatible            | ✅ |
| Temporary Overrides Still Required | ⚠️ |
| Can Be Removed Today               | ❌ |

## Notes

The overrides inside `dependency_overrides` are intentional and should not be removed without testing.

Before removing any override:

1. Verify upstream plugin support.
2. Test Android builds.
3. Test iOS builds.
4. Verify no KGP warnings remain.
5. Verify no record_web warnings remain.
