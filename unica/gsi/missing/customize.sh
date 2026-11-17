source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

MOD_DIR="$SRC_DIR/unica/gsi/missing"

LOG_STEP_IN "- Adding ColorOS vendor blobs"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libexposuremonitor.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libAImode_wrapper.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/vendor.oplus.hardware.olc2-V2-ndk.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libAIphoto_core.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libExposureMonitor.uniplugin@1.0.so" 0 0 644 "u:object_r:vendor_configs_file:s0"

ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib/libAImode_wrapper.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib/vendor.oplus.hardware.olc2-V2-ndk.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib/libAIphoto_core.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding ColorOS system blobs"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/etc/brightbridge.sh" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/etc/init/zz_bpf.rc" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/etc/init/zz_zygote_next.rc" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/etc/init/zz_dumpprops.rc" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/etc/init/zz_sf_shaders.rc" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/etc/init/zz_sf_fix.rc" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/etc/init/zz_brightbridge.rc" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/etc/init/zz_bootlog.rc" 0 0 644 "u:object_r:system_file:s0"

ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/bin/display_refresh_rate.sh" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/etc/init/display_refresh_rate.rc" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT


# delete junk files
DELETE_FROM_WORK_DIR "system" "my_product/media/theme/uxicons/hdpi/com.tencent.mm/微信扫一扫.png"
DELETE_FROM_WORK_DIR "system" "my_product/media/theme/uxicons/hdpi/com.tencent.mm/我的二维码.png"
DELETE_FROM_WORK_DIR "system" "my_product/media/theme/uxicons/hdpi/com.tencent.mm/收付款.png"


SET_PROP "system" "media.settings.xml" "/vendor/etc/media_profiles_V1_0.xml"
SET_PROP "system" "ro.debuggable" "1"
SET_PROP "system" "persist.sys.renderengine.retry" "0"
# SET_PROP "vendor" "ro.egl.blobcache.multifile" "true"

# remove QPerformance files
FRAMEWORK_DIR="$WORK_DIR/system/system/framework"
REMOVED_COUNT=0
while IFS= read -r -d '' FILE; do
    DELETE_FROM_WORK_DIR "system" "${FILE#"$WORK_DIR/system/"}" || return 1
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
done < <(find "$FRAMEWORK_DIR" -type f \
    \( -name "QPerformance*" -o -name "QXPerformance*" -o -name "UxPerformance*" \) \
    -print0)
LOG "- Removed $REMOVED_COUNT incompatible Qualcomm framework files"

unset FILE FRAMEWORK_DIR REMOVED_COUNT


# missing app
# ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/app/WebViewGoogle64CN/WebViewGoogle64CN.apk" 0 0 644 "u:object_r:system_file:s0"
# DELETE_FROM_WORK_DIR "system" "system/app/WebViewGoogle64CN"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/app/OplusCamera/OplusCamera.apk" 0 0 644 "u:object_r:system_file:s0"
# ADD_TO_WORK_DIR "$MOD_DIR" "my_manifest/etc/config/app_v2.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/app/Browser/Browser.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/app/Calculator2/Calculator2.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/app/ChromePartnerProvider/ChromePartnerProvider.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/app/Clock/Clock.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/app/Music/Music.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/app/OppoCompass2/OppoCompass2.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/app/OppoWeather2/OppoWeather2.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/app/OppoWeatherService/OppoWeatherService.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/priv-app/Calendar/Calendar.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/priv-app/Contacts/Contacts.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/priv-app/GlobalSearch/GlobalSearch.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/priv-app/MyDevices/MyDevices.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/priv-app/OppoGallery2/OppoGallery2.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "system" "system/priv-app/VideoGallery/VideoGallery.apk" 0 0 644 "u:object_r:system_file:s0"


# # below is not checking yet
# if [[ "$TARGET_CODENAME" != "r9s" ]]; then
#     LOG "- Skipping r9s GSI compatibility libraries on $TARGET_CODENAME"
#     return 0
# fi

# SYSTEM_SDK="$(GET_PROP "system" "ro.build.version.sdk")"
# SYSTEM_BRAND="$(GET_PROP "system" "ro.product.system.brand")"
# if [[ "$SYSTEM_SDK" != "37" ]] || [[ "$SYSTEM_BRAND" != "oplus" ]]; then
#     LOG "- Skipping legacy memtrack libraries for non-ColorOS 17 system"
#     unset SYSTEM_SDK SYSTEM_BRAND
#     return 0
# fi
# unset SYSTEM_SDK SYSTEM_BRAND

# MOD_DIR="$SRC_DIR/unica/mods/gsi"
# for LIB in \
#         "lib/android.hardware.memtrack@1.0.so" \
#         "lib64/android.hardware.memtrack@1.0.so" \
#         "lib64/libwifi-system-iface.so" \
#         "lib64/android.hardware.dumpstate@1.0.so" \
#         "lib64/android.hardware.dumpstate@1.1.so"; do
#     if [ ! -f "$MOD_DIR/system/$LIB" ]; then
#         ABORT "Required GSI compatibility library not found: ${MOD_DIR//$SRC_DIR\//}/system/$LIB"
#         return 1
#     fi

#     LOG "- Restoring legacy memtrack library /system/$LIB"
#     ADD_TO_WORK_DIR "$MOD_DIR" "system" "$LIB" \
#         0 0 644 "u:object_r:system_file:s0" || return 1
# done

unset MOD_DIR LIB
