OUTDOOR_SMALI_DIR="smali_classes4"
if [ "$SOURCE_PLATFORM_SDK_VERSION" = "37" ]; then
    OUTDOOR_SMALI_DIR="smali_classes3"
fi

SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "${OUTDOOR_SMALI_DIR}/com/samsung/android/settings/display/controller/SecOutDoorModePreferenceController.smali" "return" \
    'isAvailable()Z' \
    'true'

unset OUTDOOR_SMALI_DIR
