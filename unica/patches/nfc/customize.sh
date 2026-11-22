source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

if [[ "$TARGET_NFC_CHIP_VENDOR" == "NXP" && "$SOURCE_NFC_CHIP_VENDOR" == "SLSI" ]]; then
    BLOBS_LIST="
    system/lib64/libnfc_sec_jni.so
    "
    for blob in $BLOBS_LIST
    do
        DELETE_FROM_WORK_DIR "system" "$blob"
    done

    BLOBS_LIST="
    system/lib64/libnfc_nci_jni.so
    system/lib64/libnfc_prop_extn.so
    system/lib64/libnfc_vendor_extn.so
    "
    for blob in $BLOBS_LIST
    do
        ADD_TO_WORK_DIR "r11sxxx" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
    done
else
    LOGW "- NFC chip is not NXP. Ignoring."
fi

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

FTP="
system/priv-app/SecSettings/SecSettings.apk/smali_classes3/com/samsung/android/settings/nfc/NfcAntennaGuideDialog.smali
system/priv-app/SecSettings/SecSettings.apk/smali_classes3/com/samsung/android/settings/nfc/NfcSettings.smali
"
for f in $FTP; do
    sed -i 's/const-string v1, "1"/const-string v1, "24"/' "$APKTOOL_DIR/$f"
done

SET_PROP "vendor" "ro.vendor.nfc.info.antpos" "24"