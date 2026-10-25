source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

MODPATH="$SRC_DIR/unica/mods/paradigm"

# shellcheck disable=SC2034
SKIPUNZIP=1

if [ ! "$(GET_PROP "system" "ro.unica.codename")" ]; then
    LOG "- Patching /system/system/etc/selinux/plat_property_contexts"
    EVAL "echo \"ro.unica.codename u:object_r:build_prop:s0 exact string\" >> \"$WORK_DIR/system/system/etc/selinux/plat_property_contexts\""
    # Match latest Samsung's flagship device codename
    ROM_CODENAME="$(basename "$MODPATH")"
    SET_PROP "system" "ro.unica.codename" "${ROM_CODENAME^}"
    unset ROM_CODENAME
fi

# 2026 Audio Pack
LOG_STEP_IN "- Adding 2026 Audio Pack"
if $TARGET_AUDIO_SUPPORT_ACH_RINGTONE; then
    SET_PROP "vendor" "ro.config.ringtone" "ACH_Galaxy_Bells.ogg"
    SET_PROP "vendor" "ro.config.notification_sound" "ACH_Brightline.ogg"
    SET_PROP "vendor" "ro.config.alarm_alert" "ACH_Morning_Xylophone.ogg"
    SET_PROP "vendor" "ro.config.media_sound" "Media_preview_Over_the_horizon.ogg"
    SET_PROP "vendor" "ro.config.ringtone_2" "ACH_Atomic_Bell.ogg"
    SET_PROP "vendor" "ro.config.notification_sound_2" "ACH_Three_Star.ogg"
else
    DELETE_FROM_WORK_DIR "system" "system/media/audio/notifications"
    DELETE_FROM_WORK_DIR "system" "system/media/audio/ringtones"
    ADD_TO_WORK_DIR "a56xnaxx" "system" "system/etc/ringtones_count_list.txt" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "a56xnaxx" "system" "system/media/audio/notifications" 0 0 755 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "a56xnaxx" "system" "system/media/audio/ringtones" 0 0 755 "u:object_r:system_file:s0"
    SET_PROP "vendor" "ro.config.ringtone" "Galaxy_Bells.ogg"
    SET_PROP "vendor" "ro.config.notification_sound" "Brightline.ogg"
    SET_PROP "vendor" "ro.config.alarm_alert" "Morning_Xylophone.ogg"
    SET_PROP "vendor" "ro.config.media_sound" "Media_preview_Over_the_horizon.ogg"
    SET_PROP "vendor" "ro.config.ringtone_2" "Atomic_Bell.ogg"
    SET_PROP "vendor" "ro.config.notification_sound_2" "Three_Star.ogg"
fi
# APPLY_PATCH "system" "system/priv-app/SecSoundPicker/SecSoundPicker.apk" \
#     "$MODPATH/brandsound/SecSoundPicker.apk/0001-Enable-SUPPORT_SAMSUNG_BRAND_SOUND_ONEUI_7.patch"
# LOG_STEP_OUT
#
# # Adaptive colour tone
# LOG_STEP_IN "- Adding Adaptive colour tone feature"
# if [ "$SOURCE_PLATFORM_SDK_VERSION" = "37" ]; then
#     ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" \
#         "system/etc/permissions/privapp-permissions-com.samsung.android.sead.xml" 0 0 644 "u:object_r:system_file:s0"
#     ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" \
#         "system/priv-app/EnvironmentAdaptiveDisplay/EnvironmentAdaptiveDisplay.apk" 0 0 644 "u:object_r:system_file:s0"
# else
#     ADD_TO_WORK_DIR "pa2qxxx" "system" \
#         "system/etc/permissions/privapp-permissions-com.samsung.android.sead.xml" 0 0 644 "u:object_r:system_file:s0"
#     ADD_TO_WORK_DIR "pa2qxxx" "system" \
#         "system/priv-app/EnvironmentAdaptiveDisplay/EnvironmentAdaptiveDisplay.apk" 0 0 644 "u:object_r:system_file:s0"
#     if $TARGET_LCD_SUPPORT_MDNIE_HW; then
#         APPLY_PATCH "system" "system/framework/services.jar" \
#             "$MODPATH/ead/services.jar/0001-Add-Adaptive-color-tone-feature.patch"
#     else
#         APPLY_PATCH "system" "system/framework/services.jar" \
#             "$MODPATH/ead_mdnie/services.jar/0001-Add-Adaptive-color-tone-feature.patch"
#     fi
#     if $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
#         if [ "$TARGET_PLATFORM_SDK_VERSION" -ge "36" ]; then
#             APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
#                 "$MODPATH/ead_resolution/SecSettings.apk/0001-Add-Adaptive-color-tone-feature.patch"
#         else
#             APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
#                 "$MODPATH/ead_resolution_legacy/SecSettings.apk/0001-Add-Adaptive-color-tone-feature.patch"
#         fi
#     else
#         APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
#             "$MODPATH/ead/SecSettings.apk/0001-Add-Adaptive-color-tone-feature.patch"
#     fi
#     APPLY_PATCH "system" "system/priv-app/SettingsProvider/SettingsProvider.apk" \
#         "$MODPATH/ead/SettingsProvider.apk/0001-Add-Adaptive-color-tone-feature.patch"
#     APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
#         "$MODPATH/ead/SystemUI.apk/0001-Add-Adaptive-color-tone-toggle.patch"
#     APPLY_PATCH "system" "system/priv-app/EnvironmentAdaptiveDisplay/EnvironmentAdaptiveDisplay.apk" \
#         "$MODPATH/ead/EnvironmentAdaptiveDisplay.apk/0001-Fix-resource-IDs-mismatch.patch"
# fi
# LOG_STEP_OUT

if [ "$SOURCE_PLATFORM_SDK_VERSION" = "37" ]; then
    PARADIGM_SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
    PARADIGM_AI_VERSION="$(GET_FLOATING_FEATURE_CONFIG "$FW_DIR/$PARADIGM_SOURCE_FIRMWARE_PATH/system/system/etc/floating_feature.xml" "SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION")"
    [[ "$PARADIGM_AI_VERSION" =~ ^[0-9]+$ ]] || ABORT "Source AI version is missing or invalid"
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION" "$PARADIGM_AI_VERSION"
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/app/SketchBook/SketchBook.apk" 0 0 644 "u:object_r:system_file:s0"
    unset PARADIGM_AI_VERSION PARADIGM_SOURCE_FIRMWARE_PATH
else
    # Set AI Version to 20271 (latest)
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION" "20271"

fi

# Media Context Analyzer
LOG_STEP_IN "- Adding Media Context Analyzer feature"
if [ -f "$SRC_DIR/platform/$TARGET_PLATFORM/patches/runtime/component.sh" ]; then
    source "$SRC_DIR/platform/$TARGET_PLATFORM/patches/runtime/component.sh"
fi
if declare -F RUNTIME_HAS_COMPONENT > /dev/null && RUNTIME_HAS_COMPONENT "mca"; then
    # The runtime's checked donor JNI implements VideoScan's MCA 3.0 API.
    # Preserve those matched native providers and the donor .nnc model inputs.
    # A56's nativeStart/nativeRelease ABI does not implement nativeInit/deinit.
    # Registration is checked now; every provider and facade is verified by
    # the finalizer after the normal APK/JAR build, not installed prematurely.
    LOG "- Keeping runtime-owned MCA 3.0 providers and donor models"
else
    ADD_TO_WORK_DIR "a56xnaxx" "system" "system/etc/mediacontextanalyzer/Detection.tflite" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "a56xnaxx" "system" "system/etc/mediacontextanalyzer/human-pet-det_SR-V131.tflite" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "a56xnaxx" "system" "system/etc/mediacontextanalyzer/human-pet-pose_SR-V200.tflite" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "a56xnaxx" "system" "system/etc/mediacontextanalyzer/Keyword.tflite" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "a56xnaxx" "system" "system/etc/mediacontextanalyzer/keyword-classification_SR-V031.tflite" 0 0 644 "u:object_r:system_file:s0"
    EVAL "ln -s \"human-pet-pose_SR-V200.tflite\" \"$WORK_DIR/system/system/etc/mediacontextanalyzer/Pose.tflite\""
    SET_METADATA "system" "system/etc/mediacontextanalyzer/Pose.tflite" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "a56xnaxx" "system" "system/lib64/libcontextanalyzer_jni.media.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "a56xnaxx" "system" "system/lib64/libmediacontextanalyzer.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "a56xnaxx" "system" "system/lib64/libvideo-highlight-arm64-v8a.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_MMFW_CONFIG_MEDIA_CONTEXT_ANALYZER_CORE" "GPU"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_MMFW_SUPPORT_MEDIA_CONTEXT_ANALYZER" "TRUE"
LOG_STEP_OUT

# Audio eraser
# Requires SEC_PRODUCT_FEATURE_MMFW_SUPPORT_MEDIA_CONTEXT_ANALYZER
LOG_STEP_IN "- Adding Audio eraser feature"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_AUDIO_CONFIG_MULTISOURCE_SEPARATOR" "{FastScanning_6, SourceSeparator_4, Version_1.3.0}"
LOG_STEP_OUT

if [ "$SOURCE_PLATFORM_SDK_VERSION" = "37" ]; then
    # ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/etc/default-permissions/default-permissions-com.samsung.android.app.moments.xml" 0 0 644 "u:object_r:system_file:s0"
    # ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.moments.xml" 0 0 644 "u:object_r:system_file:s0"
    # ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/etc/sysconfig/moments.xml" 0 0 644 "u:object_r:system_file:s0"
    # ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/etc/sysconfig/preinstalled-packages-com.samsung.android.app.moments.xml" 0 0 644 "u:object_r:system_file:s0"
    # ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/priv-app/Moments/Moments.apk" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.smartsuggestions.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/etc/default-permissions/default-permissions-com.samsung.android.smartsuggestions.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/etc/sysconfig/preinstalled-packages-com.samsung.android.smartsuggestions.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/etc/sysconfig/samsungsmartsuggestions.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/priv-app/SamsungSmartSuggestions/SamsungSmartSuggestions.apk" 0 0 644 "u:object_r:system_file:s0"
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_PERSONALIZED_DATA_CORE" "TRUE"
else
    # Now brief
    # Requires SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION >= 20251
    # or SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_AI_BRIEF_FOR_UT
    LOG_STEP_IN "- Adding Now brief feature"
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_PERSONALIZED_DATA_CORE" "TRUE"
    LOG_STEP_OUT

fi

LOG "- Forcing Now Nudge availability in SecSettings.apk"
APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$MODPATH/now-nudge/SecSettings.apk/0001-Force-Now-Nudge-Galaxy-AI-availability.patch"

if [ "$SOURCE_PLATFORM_SDK_VERSION" = "37" ]; then
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/etc/default-permissions/default-permissions-com.samsung.mediasearch.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/etc/permissions/privapp-permissions-com.samsung.mediasearch.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/etc/sysconfig/preinstalled-packages-com.samsung.mediasearch.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/priv-app/MediaSearch/MediaSearch.apk" 0 0 644 "u:object_r:system_file:s0"
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_MSCH_SUPPORT_NLSEARCH" "TRUE"
else
    # Semantic search
    # Requires SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION >= 20251
    LOG_STEP_IN "- Adding Semantic search feature"
    DECODE_APK "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk"
    LOG "- Enabling Semantic search feature in /system/system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk"
    EVAL "cp -a \"$MODPATH/semanticsearch/SecSettingsIntelligence.apk/res/raw/\"* \"$APKTOOL_DIR/system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk/res/raw\""
    SMALI_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
        "smali_classes2/com/samsung/android/settings/intelligence/Rune.smali" "replaceall" \
        "const-string v1, \\\"\\\"" \
        "const-string v1, \\\"400\\\"" \
        > /dev/null
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_MSCH_SUPPORT_NLSEARCH" "TRUE"
    LOG_STEP_OUT

fi

if [ "$SOURCE_PLATFORM_SDK_VERSION" = "37" ]; then
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/priv-app/GameTools_Dream/GameTools_Dream.apk" 0 0 644 "u:object_r:system_file:s0"
else
    # Game Booster
    LOG "- Downloading latest Game Booster app"
    DOWNLOAD_FILE "$(GET_GALAXY_STORE_DOWNLOAD_URL "com.samsung.android.game.gametools")" \
        "$WORK_DIR/system/system/priv-app/GameTools_Dream/GameTools_Dream.apk"

fi

# # Pet Detector in Galaxy AI
# LOG_STEP_IN "- Adding Pet Detector support in Galaxy AI features"
# if [ -d "$WORK_DIR/vendor/etc/petdetector/studio_pd" ]; then
#     DELETE_FROM_WORK_DIR "vendor" "etc/petdetector/studio_pd"
# fi
# ADD_TO_WORK_DIR "pa2qxxx" "vendor" "etc/petdetector/studio_pd/config_thresholds.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
# ADD_TO_WORK_DIR "pa2qxxx" "vendor" "etc/petdetector/studio_pd/studio_pd_cnn.info" 0 0 644 "u:object_r:vendor_configs_file:s0"
# ADD_TO_WORK_DIR "pa2qxxx" "vendor" "etc/petdetector/studio_pd/studio_pd_cnn.tflite" 0 0 644 "u:object_r:vendor_configs_file:s0"
# LOG_STEP_OUT
