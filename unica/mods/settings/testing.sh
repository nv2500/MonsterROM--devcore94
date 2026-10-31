source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
SECSETTINGS_APK="$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk"

# Keep the ANGLE developer option available on vendor API levels that hide it.
ANGLE_CONTROLLER="$(find "$SECSETTINGS_APK" -type f \
    -path '*/GraphicsDriverEnableAngleAsSystemDriverController.smali' -print -quit)"
[ "$ANGLE_CONTROLLER" ] || ABORT "ANGLE developer-option controller not found"
ANGLE_CONTROLLER="${ANGLE_CONTROLLER//$SECSETTINGS_APK\//}"
if ! grep -q -F '.method public final isAvailable()Z' "$SECSETTINGS_APK/$ANGLE_CONTROLLER"; then
    ABORT "ANGLE developer-option availability method not found"
fi
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$ANGLE_CONTROLLER" "return" \
    'isAvailable()Z' \
    'true'