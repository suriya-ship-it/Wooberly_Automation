# Spec-Driven Development Rule

This project follows a **Spec-Driven Development** methodology. 

## 1. Design Specs
All UI, theme, and component configurations are centrally documented in the `design_specs/` directory:
- `design_specs/theme.md` - Contains color codes, typography, and global theme constants.
- `design_specs/components.md` - Contains standard definitions for button structures, layouts, heights, widths, and cosmetics.

## 2. Agent Responsibilities
- **Read Specs First:** Whenever you are tasked with building a new UI feature or modifying an existing one, you MUST first read the relevant `.md` files in `design_specs/` to ensure your Flutter code adheres to the defined structures, colors, and cosmetics. Do NOT invent new colors or button structures if a matching one exists in the specs.
- **Automatic Theme Syncing:** If the user requests a change to the design or edits the color codes in `design_specs/theme.md`, you MUST automatically update the corresponding values in `Wooberly_Rider_V3.5/lib/resources/values/app_colors.dart` by running `npm run sync-theme` (or making the code changes directly to keep the codebase perfectly synchronized).

## 3. Modifying Specs
When introducing a new global color, font, or standard component:
1. First, document it as a separate, distinct entry in the `design_specs/` markdown files so the user can easily manage it.
2. Then, implement it in the Flutter codebase (`lib/resources/values/`).
