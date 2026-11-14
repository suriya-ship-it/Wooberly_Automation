# App Theme Specification

This document is the **single source of truth** for colors, fonts, and global themes.
When a color code is changed here, the AI will automatically sync the changes to `Wooberly_Rider_V3.5/lib/resources/values/app_colors.dart`.

## Global Color Palette

| Color Name | Hex Code (Light) | Hex Code (Dark) | Description |
| :--- | :--- | :--- | :--- |
| **Primary** (`lightPrimaryColor`) | `0xFF131314` | `0xFFFFFFFF` | Main branding color (Black in light mode, White in dark mode). |
| **Secondary** (`lightsecondaryColor`) | `0xFF1654E4` | `0xFF1654E4` | Accent branding color (Blue). |
| **Background** (`COMMON_BG_COLOR`) | `0xFFF6F6F6` | `0xFF0E142F` | Main application background color. |
| **Divider** (`DIVIDER_COLOR`) | `0xFFEAEAEA` | `0xFF383B4B` | Used for list separators and borders. |
| **Primary Text** (`BLACK_TEXT_COLOR`) | `0xFF151515` | `0xFFC7D8EB` | Default text color. |
| **Inverse Text** (`WHITE_TEXT_COLOR`) | `0xFFFFFFFF` | `0xFF151515` | Inverse text color (e.g., text on primary buttons). |
| **Disabled** (`DISABLE_COLOR`) | `0xFFEFEFEF` | `0xFF171D37` | Color for disabled buttons or fields. |
| **Placeholder** (`PLACEHOLDER_TEXT_COLOR`) | `0xFF848484` | `0xFFA1BBD7` | Input field hint text. |

## Status Colors
Used for ride states and notifications:
- **Verify / Success:** `0xFF43A047`
- **Error / Exception:** `0xFFE14C38`
- **Trip Created:** `0xFF3676D1`
- **Trip Started:** `0xFFFF8439`
- **Trip Reached:** `0xFFE0A90F`
- **Completed:** `0xFF03C03C`

---
*Note: If you need to add a new color, add it to this file first in a separate category so it can be managed easily.*
