source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

MODPATH="$SRC_DIR/unica/mods/tweaks"

DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"

# Disable app compaction
# Guard the patch as the source firmware might have this already disabled
LOG "- Applying \"Disable app compaction\" to /system/system/framework/services.jar"
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/appcompactor/services.jar/0001-Disable-app-compaction.patch"


LOG "- Fixing Chromium to /system/system/framework/framework.jar"
APPLY_PATCH "system" "system/framework/framework.jar" \
    "$MODPATH/chromium/framework.jar/0002-Fix-Chromium-sandboxed-process-fallback.patch"
