source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

MODPATH="$SRC_DIR/unica/patches/miscs"

MISCS_MODULE_ROOT="$MODPATH"
MISCS_PLATFORM_SDK="${SOURCE_PLATFORM_SDK_VERSION:-$(GET_PROP "system" "ro.build.version.sdk")}"

SET_PROP_IF_DIFF "vendor" "ro.oem_unlock_supported" "0"

# Better device/model detection in CoreRune
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali_classes6/com/samsung/android/rune/CoreRune.smali" "replace" \
    '<clinit>()V' \
    'ro.product.model' \
    'ro.product.vendor.model'
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali_classes6/com/samsung/android/rune/CoreRune.smali" "replace" \
    '<clinit>()V' \
    'ro.product.device' \
    'ro.product.vendor.device'

# shellcheck disable=SC2016
# Disable RescueParty
if [ "$MISCS_PLATFORM_SDK" -ge "37" ]; then
    # Samsung replaced AOSP RescueParty with SecRescueParty in API 37. Its
    # SystemServer entry point only registers the package-health observer, so
    # nullifying that exact void method prevents destructive recovery actions
    # without fabricating a class or patching unrelated boot reporting code.
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/SecRescueParty.smali" "null" \
        'secRescuePartyRegisterHealthObserver(Landroid/content/Context;)V'
else
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/RescueParty.smali" "return" \
        '-$$Nest$smisDisabled()Z' \
        'true'
fi

# Better model detection in FreecessController
SMALI_PATCH "system" "system/framework/services.jar" \
    "smali/com/android/server/am/FreecessController.smali" "replace" \
    '<clinit>()V' \
    'ro.product.model' \
    'ro.product.vendor.model'

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

# Disable FRP
SET_PROP "vendor" "ro.frp.pst" ""
SET_PROP "product" "ro.frp.pst" ""

# Set Edge Lighting model
MODEL=$(echo "$TARGET_FIRMWARE" | sed -E 's/^([^/]+)\/.*/\1/')
SET_PROP "system" "ro.factory.model" "$MODEL"

# Fix portrait mode
SET_PROP "system" "ro.build.flavor" "$(GET_PROP "$FW_DIR/${MODEL}_${REGION}/system/system/build.prop" "ro.build.flavor")"

if [[ -f "$FW_DIR/${MODEL}_${REGION}/vendor/lib64/liblivefocus_capture_engine.so" ]]; then
    if grep -q "ro.product.name" "$FW_DIR/${MODEL}_${REGION}/vendor/lib64/liblivefocus_capture_engine.so"; then
        # For devices with this lib in system instead of vendor (e.g. S22 and up)
        # we will need to sed this in system lib after replacing with stock blob
        # in a platform patch.
        if [[ -f "$FW_DIR/${MODEL}_${REGION}/vendor/lib64/libDualCamBokehCapture.camera.samsung.so" ]]; then
            sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib/libDualCamBokehCapture.camera.samsung.so"
            sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib64/libDualCamBokehCapture.camera.samsung.so"
        fi
        sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib/liblivefocus_capture_engine.so"
        sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib/liblivefocus_preview_engine.so"
        sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib64/liblivefocus_capture_engine.so"
        sed -i "s/ro.product.name/ro.unica.camera/g" "$WORK_DIR/vendor/lib64/liblivefocus_preview_engine.so"
        echo -e "\nro.unica.camera u:object_r:build_prop:s0 exact string" >> "$WORK_DIR/system/system/etc/selinux/plat_property_contexts"
        SET_PROP "system" "ro.unica.camera" "$(GET_PROP "$FW_DIR/${MODEL}_${REGION}/system/system/build.prop" "ro.product.system.name")"
    fi
fi

sed -i s/init.svc.vendor.wvkprov_server_hal//g "$WORK_DIR/vendor/etc/selinux/vendor_property_contexts"
