# Migrate to Built-in Kotlin for Flutter

This plan migrates the `sound_stream` plugin and its example app to use Flutter's built-in Kotlin support. This removes the manual application of the Kotlin Gradle Plugin (KGP) and avoids build failures in future Flutter versions.

## User Review Required

> [!NOTE]
> The current `settings.gradle` in the example app uses `id "org.jetbrains.kotlin.android" version "2.4.20"`. Kotlin 2.4 is not yet released (current is 2.1.x). I will assume this might be a typo for `2.0.20` or similar, but I will keep it as is if it doesn't cause issues, or update it to a stable version like `1.9.23` if you prefer. For now, I'll focus on the structural migration.

## Proposed Changes

### [Component] Sound Stream Plugin (Root)

#### [MODIFY] [build.gradle](file:///Users/jeffle/Projects/personal/flutter-sound-stream/android/build.gradle)
- Remove the `buildscript` block which manually adds KGP as a dependency.
- Update the `plugins` block to use the declarative `id "org.jetbrains.kotlin.android"` without a version.

---

### [Component] Example App

#### [MODIFY] [app/build.gradle](file:///Users/jeffle/Projects/personal/flutter-sound-stream/example/android/app/build.gradle)
- Replace `id "kotlin-android"` with `id "org.jetbrains.kotlin.android"` in the `plugins` block.

#### [MODIFY] [settings.gradle](file:///Users/jeffle/Projects/personal/flutter-sound-stream/example/android/settings.gradle)
- (Verification) Ensure the Kotlin plugin is defined here with `apply false`. It seems already present, but I will double check consistency.

## Verification Plan

### Automated Tests
- Run `./gradlew :app:assembleDebug` in the `example/android` directory to ensure the build still works.
- Run `flutter build apk` (if possible via shell, but gradle build is usually enough for Android migration verification).

### Manual Verification
- Check that the IDE no longer shows the KGP migration warning during build (if triggered).
