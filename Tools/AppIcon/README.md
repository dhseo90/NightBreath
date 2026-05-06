# App Icon Tools

NightBreath keeps the app icon as an on-device, project-owned asset. These tools are local-only helpers for regenerating, validating, and visually reviewing the icon before TestFlight/App Store work.

## Generate

Regenerate every `AppIcon.appiconset` PNG from the Swift drawing source:

```sh
xcrun swift Tools/AppIcon/generate_app_icon.swift
```

The generator writes only to:

- `SleepSoundApp/App/Assets.xcassets/AppIcon.appiconset/`

## Validate

Check that the asset catalog has all iPhone/iPad/App Store slots, matching PNG dimensions, and opaque artwork:

```sh
xcrun swift Tools/AppIcon/validate_app_icon.swift
```

This is safe to run without a simulator or real device.

## Review Sheet

Render a local review sheet for small-size visual inspection:

```sh
xcrun swift Tools/AppIcon/render_app_icon_review_sheet.swift
```

Default output:

- `Docs/AppIcon/app_icon_review_sheet.png`

Use the review sheet to check App Store, Home Screen, Settings, Search, and the smallest rendered sizes on light/dark backgrounds. The final manual gate still includes checking the icon on a real iPhone home screen and TestFlight install surface.

## Safety

- Do not add third-party logos, third-party app icons, or screenshots.
- Do not use hospital, cross, or clinical-device visual language.
- Do not imply diagnosis, treatment, or medical measurement.
- Keep the 1024px App Store source opaque; iOS applies the icon mask.
