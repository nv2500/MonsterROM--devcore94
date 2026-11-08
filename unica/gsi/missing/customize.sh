source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

MOD_DIR="$SRC_DIR/unica/gsi/missing"

LOG "- adding ColorOS vendor blobs"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libexposuremonitor.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libAImode_wrapper.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/vendor.oplus.hardware.olc2-V2-ndk.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libAIphoto_core.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib64/libExposureMonitor.uniplugin@1.0.so" 0 0 644 "u:object_r:vendor_configs_file:s0"

ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib/libAImode_wrapper.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib/vendor.oplus.hardware.olc2-V2-ndk.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "$MOD_DIR" "vendor" "lib/libAIphoto_core.camera.samsung.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
