source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"


LOG_STEP_IN "- Enabling BSOH in SecSettings"

FTP="
system/priv-app/SecSettings/SecSettings.apk/smali_classes5/com/samsung/android/settings/deviceinfo/batteryinfo/BatteryRegulatoryPreferenceController.smali
system/priv-app/SecSettings/SecSettings.apk/smali_classes5/com/samsung/android/settings/deviceinfo/batteryinfo/SecBatteryInfoFragment.smali
"
for f in $FTP; do
    sed -i "s/SM-A236B/SM-S731B/g" "$APKTOOL_DIR/$f"
done
LOG_STEP_OUT


# Always show One UI minor version
# SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
#     "smali_classes5/com/samsung/android/settings/deviceinfo/softwareinfo/OneUIVersionPreferenceController.smali" "replace" \
#     'isDeviceWithMicroVersion()Z' \
#     'move-result p0' \
#     'const/4 p0, 0x1'

# Show real device model number
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes5/com/samsung/android/settings/deviceinfo/aboutphone/ModelNameGetter.smali" "replace" \
    'getModelName()Ljava/lang/String;' \
    'ro.product.model' \
    'ro.boot.em.model'