const fs = require('fs');
const path = require('path');

const THEME_MD_PATH = path.join(__dirname, '../design_specs/theme.md');
const APP_COLORS_PATH = path.join(__dirname, '../Wooberly_Rider_V3.5/lib/resources/values/app_colors.dart');

function syncTheme() {
    if (!fs.existsSync(THEME_MD_PATH) || !fs.existsSync(APP_COLORS_PATH)) {
        console.error("Error: Could not find theme.md or app_colors.dart");
        process.exit(1);
    }

    const themeContent = fs.readFileSync(THEME_MD_PATH, 'utf-8');
    let dartContent = fs.readFileSync(APP_COLORS_PATH, 'utf-8');

    // Simple markdown table parser for the Global Color Palette
    // Matches lines like: | **Primary** (`lightPrimaryColor`) | `0xFF131314` | `0xFFFFFFFF` | ...
    const rowRegex = /\|\s*\*\*.*?\*\*\s*\(`(.*?)`\)\s*\|\s*`(0x[0-9A-Fa-f]{8})`\s*\|\s*`(0x[0-9A-Fa-f]{8})`\s*\|/g;
    
    let match;
    let updates = 0;
    while ((match = rowRegex.exec(themeContent)) !== null) {
        const variableName = match[1];
        const lightHex = match[2];
        const darkHex = match[3];

        // This is a naive regex replacement that handles static const Color or static Color initialization
        const lightRegex = new RegExp(`(static (?:const )?Color ${variableName} =) (Color\\(0x[0-9A-Fa-f]{8}\\)|.*?)(;)`, 'g');
        if (dartContent.match(lightRegex)) {
            dartContent = dartContent.replace(lightRegex, `$1 Color(${lightHex})$3`);
            updates++;
            console.log(`Updated ${variableName} to ${lightHex}`);
        }
        
        // Handling dynamic globals.isDarkTheme assignments 
        const dynamicRegex = new RegExp(`(static Color ${variableName} =\\s*globals\\.isDarkTheme \\? Color\\()(0x[0-9A-Fa-f]{8})(\\) : Color\\()(0x[0-9A-Fa-f]{8})(\\);)`, 'g');
        if (dartContent.match(dynamicRegex)) {
            dartContent = dartContent.replace(dynamicRegex, `$1${darkHex}$3${lightHex}$5`);
            updates++;
            console.log(`Updated dynamic ${variableName} to Light: ${lightHex}, Dark: ${darkHex}`);
        }
    }

    // Also parse Status Colors
    // Matches: - **Verify / Success:** `0xFF43A047`
    const statusRegex = /-\s*\*\*.*?\*\*\s*`(0x[0-9A-Fa-f]{8})`/g;
    // We would need the exact variable name to map it, which isn't cleanly in the markdown right now,
    // so we rely on the agent for complex changes, but this script handles the main table!

    if (updates > 0) {
        fs.writeFileSync(APP_COLORS_PATH, dartContent, 'utf-8');
        console.log(`✅ Sync complete. Successfully applied ${updates} color changes to app_colors.dart`);
    } else {
        console.log("⚠️ No matching color mappings found to update. Make sure the table format matches.");
    }
}

syncTheme();
