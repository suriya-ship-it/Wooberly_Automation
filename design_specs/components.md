# Component Structure Specification

This document defines the common structures, widths, heights, and cosmetic details for standard UI elements in the application.

## 1. Buttons

### Primary Button
- **Height**: 50.0 (using `AppDimen.buttonHeight`)
- **Background Color**: `AppColors.lightPrimaryColor` (or inverse in dark mode).
- **Border Radius**: 8.0 (rounded rectangle).
- **Text Style**: Bold, 16sp, `WHITE_TEXT_COLOR`.
- **Usage**: Main actions like "Book Now", "Login", "Confirm".

### Secondary/Outlined Button
- **Height**: 50.0
- **Background Color**: Transparent or `AppColors.PRIMARY_LIGHT_COLOR`.
- **Border**: 1px solid `AppColors.PRIMARY_BORDER_COLOR`.
- **Text Style**: Medium, 16sp, `BLACK_TEXT_COLOR`.
- **Usage**: Secondary actions, "Cancel", "Back".

## 2. Text Input Fields
- **Height**: 55.0
- **Background**: `AppColors.COMMON_BG_COLOR`
- **Border**: None (flat) or very subtle 1px border.
- **Border Radius**: 8.0
- **Text Style**: 14sp, `BLACK_TEXT_COLOR`.
- **Placeholder Style**: 14sp, `AppColors.PLACEHOLDER_TEXT_COLOR`.
- **Padding**: Horizontal 16.0, Vertical 12.0.

## 3. Cards & Containers (e.g. Category Selection)
- **Background Color**: `AppColors.WHITE` (which flips to dark card color in dark mode).
- **Border Radius**: 12.0
- **Shadow/Elevation**: 2.0 (subtle shadow for depth).
- **Padding**: 16.0 on all sides.

## 4. Fonts and Typography
- **Primary Font Family**: Standard system font (as defined in `app_fonts.dart`).
- **Heading 1**: 24sp, Bold, `BLACK_TEXT_COLOR`.
- **Heading 2**: 18sp, Semi-Bold, `BLACK_TEXT_COLOR`.
- **Body Text**: 14sp, Regular, `BLACK_TEXT_COLOR`.
- **Caption Text**: 12sp, Regular, `AppColors.SEARCH_TEXT_COLOR`.

---
*Note: Any time a new UI element is created, the agent must check this spec to apply the consistent height, width, and cosmetics. If a new structural element is introduced, it must be documented here.*

## 5. Accessibility & Localization Constraints
- **Dark Mode Support**: All components MUST be designed with dynamic coloring using `globals.isDarkTheme`. Hardcoded white or black backgrounds without dark-mode equivalents are strictly prohibited.
- **RTL (Right-To-Left) Support**: The UI must flawlessly support Arabic formats. All padding, margins, and alignments should use directional APIs (e.g., `padding: EdgeInsetsDirectional`) rather than hardcoded left/right absolute coordinates whenever possible.
