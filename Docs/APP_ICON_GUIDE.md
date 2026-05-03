# NightBreath / 밤숨 App Icon Guide

## Product

- Korean app name: 밤숨
- English brand name: NightBreath
- Subtitle: 수면 소리 리포트 / Sleep Sound Report

NightBreath is an iPhone on-device sleep sound report app. The icon should feel calm, private, quiet, and wellness-oriented without looking like a medical device.

## Current Asset State

`SleepSoundApp/App/Assets.xcassets/AppIcon.appiconset` is intentionally a placeholder structure.

This guide does not add final high-quality app icon artwork. Final app icon export should be handled as a separate design task and then placed into the existing `AppIcon.appiconset`.

## Concept Directions

1. Moon + Breath Wave

- A simple moon form paired with one soft breath waveform.
- Best fit for the core idea of night, breathing, and sleep sound.
- Keep the waveform original and minimal, not a copied audio-app mark.

2. Night Sky + Small Breath Wave

- A quiet night field with a small, identifiable wave.
- Use NightBreath sleep and breath colors, with enough contrast at small icon sizes.
- Avoid decorative clutter and overly detailed star fields.

3. Shield + Breath Wave

- A privacy shield combined with a soft breathing wave.
- Best fit when emphasizing on-device analysis and no server transfer.
- Keep the shield friendly and wellness-like, not security-enterprise heavy.

## Recommended Visual Rules

- Use a simple silhouette that works at small sizes.
- Prefer one core symbol and one supporting cue.
- Use NightBreath color tokens as the source of truth: `sleep`, `breath`, `privacy`, `accent`, and soft background values.
- Check the icon on both light and dark home screen backgrounds.
- Verify legibility at 20pt, 29pt, 40pt, 60pt, and App Store sizes.
- Keep the icon text-free. The app name belongs in UI and metadata, not in the icon.

## Avoid

- Medical cross shapes, hospital-like visual language, or clinical alert styling.
- A generic bed + moon composition that looks close to existing sleep apps.
- Toss/TDS or any third-party brand style, logo, color token, component, or icon.
- Third-party app icon references, screenshots, or copied illustration styles.
- Complex typography, tiny text, dense charts, or detailed audio waveforms.
- Claims that imply medical diagnosis.

## Export Checklist For Final Artwork

- Fill all required iOS app icon slots in `AppIcon.appiconset`.
- Do not include transparency in final iOS app icon PNGs.
- Keep source artwork in a design-owned location outside the app bundle unless the team explicitly chooses to version it.
- Confirm the icon still reads as NightBreath when reduced.
- Re-run the Xcode app build after replacing placeholder assets.

## Relationship To SwiftUI Placeholders

The project includes SwiftUI original illustration placeholders in `NBIllustration.swift`. These are for onboarding and empty states, not final app icon artwork. They may inform the icon direction, but the final icon should be deliberately designed and exported separately.
