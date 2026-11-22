source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

MODPATH="$SRC_DIR/unica/patches/vndk"

if [[ "$SOURCE_BOARD_API_LEVEL" == "$TARGET_BOARD_API_LEVEL" ]]; then
    LOG "\033[0;33m! Nothing to do\033[0m"
    return 0
fi

# [
ADD_TARGET_VNDK_APEX() {
    case "$TARGET_BOARD_API_LEVEL" in
        "30")
            # if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge "37" ] && \
            #         [ "$TARGET_CODENAME" = "t2s" || "$TARGET_CODENAME" = "r9s" ]; then
            #     # Keep the exact G996 VNDK snapshot paired with its vendor,
            #     # including the 32-bit libraries required by legacy HALs.
                LOG "Keep target VNDK v30 to match with its vendor"
                ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" \
                    "apex/com.android.vndk.v30.apex" 0 0 644 \
                    "u:object_r:system_file:s0"
            # else
            #     ADD_TO_WORK_DIR "a73xqxx" "system_ext" \
            #         "apex/com.android.vndk.v30.apex" 0 0 644 \
            #         "u:object_r:system_file:s0"
            # fi
            ;;
        "31")
            ADD_TO_WORK_DIR "b0qxxx" "system_ext" "apex/com.android.vndk.v31.apex" 0 0 644 "u:object_r:system_file:s0"
            ;;
        "32")
            ADD_TO_WORK_DIR "b4qxxx" "system_ext" "apex/com.android.vndk.v32.apex" 0 0 644 "u:object_r:system_file:s0"
            ;;
        "33")
            ADD_TO_WORK_DIR "dm1qxxx" "system_ext" "apex/com.android.vndk.v33.apex" 0 0 644 "u:object_r:system_file:s0"
            ;;
        "34")
            ADD_TO_WORK_DIR "gta9pxxx" "system_ext" "apex/com.android.vndk.v34.apex" 0 0 644 "u:object_r:system_file:s0"
            ;;
        *)
            ABORT "No APEX blob available for VNDK $TARGET_BOARD_API_LEVEL"
            ;;
    esac
}
# ]

HAS_VENDOR_NDK_VERSION() {
    awk -v version="$1" '
        /<vendor-ndk>/ { in_vendor_ndk = 1 }
        in_vendor_ndk && index($0, "<version>" version "</version>") { found = 1 }
        /<\/vendor-ndk>/ { in_vendor_ndk = 0 }
        END { exit !found }
    ' "$2"
}

if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
    SYS_EXT_DIR="$WORK_DIR/system_ext"
else
    SYS_EXT_DIR="$WORK_DIR/system/system/system_ext"
fi

if [ "$SOURCE_BOARD_API_LEVEL" -gt "34" ] && [ "$TARGET_BOARD_API_LEVEL" -gt "34" ]; then
    :
elif [ "$SOURCE_BOARD_API_LEVEL" -gt "34" ] && [ "$TARGET_BOARD_API_LEVEL" -le "34" ]; then
    ADD_TARGET_VNDK_APEX || return 1
    MANIFEST="$SYS_EXT_DIR/etc/vintf/manifest.xml"
    if [ ! -f "$MANIFEST" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" \
            "etc/vintf/manifest.xml" || return 1
    fi
    if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
        VINTF_METADATA_PARTITION="system_ext"
        VINTF_METADATA_ENTRY="etc/vintf"
    else
        VINTF_METADATA_PARTITION="system"
        VINTF_METADATA_ENTRY="system/system_ext/etc/vintf"
    fi
    if ! grep -Fq "$VINTF_METADATA_ENTRY " \
            "$WORK_DIR/configs/fs_config-$VINTF_METADATA_PARTITION" ||
            ! grep -Fq "/$VINTF_METADATA_ENTRY " \
            "$WORK_DIR/configs/file_context-$VINTF_METADATA_PARTITION"; then
        SET_METADATA "$VINTF_METADATA_PARTITION" "$VINTF_METADATA_ENTRY" \
            0 0 755 "u:object_r:system_file:s0" || return 1
    fi
    VINTF_MANIFEST_ENTRY="$VINTF_METADATA_ENTRY/manifest.xml"
    if ! grep -Fq "$VINTF_MANIFEST_ENTRY " \
            "$WORK_DIR/configs/fs_config-$VINTF_METADATA_PARTITION" ||
            ! grep -Fq "/$VINTF_MANIFEST_ENTRY " \
            "$WORK_DIR/configs/file_context-$VINTF_METADATA_PARTITION"; then
        SET_METADATA "$VINTF_METADATA_PARTITION" "$VINTF_MANIFEST_ENTRY" \
            0 0 644 "u:object_r:system_file:s0" || return 1
    fi
    LOG "- Patching ${SYS_EXT_DIR//$WORK_DIR/}/etc/vintf/manifest.xml"
    if ! HAS_VENDOR_NDK_VERSION "$TARGET_BOARD_API_LEVEL" "$MANIFEST"; then
        TEMP_MANIFEST="$MANIFEST.tmp"
        awk -v version="$TARGET_BOARD_API_LEVEL" '
            /<\/manifest>/ && !inserted {
                print "    <vendor-ndk>"
                print "        <version>" version "</version>"
                print "    </vendor-ndk>"
                inserted = 1
            }
            { print }
            END { if (!inserted) exit 1 }
        ' "$MANIFEST" > "$TEMP_MANIFEST" || {
            rm -f "$TEMP_MANIFEST"
            ABORT "Failed to add vendor-ndk version $TARGET_BOARD_API_LEVEL to ${MANIFEST//$WORK_DIR\//}"
            return 1
        }
        EVAL "mv -f \"$TEMP_MANIFEST\" \"$MANIFEST\"" || {
            rm -f "$TEMP_MANIFEST"
            return 1
        }
    fi
    unset MANIFEST TEMP_MANIFEST VINTF_METADATA_PARTITION VINTF_METADATA_ENTRY VINTF_MANIFEST_ENTRY
elif [ "$SOURCE_BOARD_API_LEVEL" -le "34" ] && [ "$TARGET_BOARD_API_LEVEL" -gt "34" ]; then
    DELETE_FROM_WORK_DIR "system_ext" "apex/com.android.vndk.v$SOURCE_BOARD_API_LEVEL.apex"
    LOG "- Patching ${SYS_EXT_DIR//$WORK_DIR/}/etc/vintf/manifest.xml"
    EVAL "sed -i -e \"/vendor-ndk/d\" -e \"/version>/d\" \"$SYS_EXT_DIR/etc/vintf/manifest.xml\""
elif [ ! -f "$SYS_EXT_DIR/apex/com.android.vndk.v$TARGET_BOARD_API_LEVEL.apex" ]; then
    DELETE_FROM_WORK_DIR "system_ext" "apex/com.android.vndk.v$SOURCE_BOARD_API_LEVEL.apex"
    ADD_TARGET_VNDK_APEX
    LOG "- Patching ${SYS_EXT_DIR//$WORK_DIR/}/etc/vintf/manifest.xml"
    EVAL "sed -i \"s/version>$SOURCE_BOARD_API_LEVEL/version>$TARGET_BOARD_API_LEVEL/g\" \"$SYS_EXT_DIR/etc/vintf/manifest.xml\""
fi

unset SYS_EXT_DIR
unset -f ADD_TARGET_VNDK_APEX
unset -f HAS_VENDOR_NDK_VERSION
