# ROM build customization for the Exynos Valhall GPU driver.
SKIPUNZIP=1

source "$SRC_DIR/scripts/utils/common_utils.sh" || return 1
source "$SRC_DIR/scripts/utils/module_utils.sh" || return 1

MODPATH="$SRC_DIR/unica/patches/gpu--r49p1--1.0.0-1"
DRIVER_VER="r49p1 (32-bit and 64-bit)"

case "$TARGET_PLATFORM" in
    exynos2100|exynos2100_r)
        SOC_NAME="Exynos 2100"
        SOC_NUM="2100"
        ;;
    *)
        LOG "- Skipping $DRIVER_VER GPU driver for unsupported platform: $TARGET_PLATFORM"
        return 0
        ;;
esac

LOG_STEP_IN "- Adding $DRIVER_VER Valhall GPU driver for $SOC_NAME"

DRIVER_PAYLOAD="$MODPATH/system/vendor"
if [ ! -d "$DRIVER_PAYLOAD" ]; then
    LOGE "GPU driver payload not found: ${DRIVER_PAYLOAD//$SRC_DIR\//}"
    return 1
fi

HAS_VENDOR_LIB=false
[ -d "$WORK_DIR/vendor/lib" ] && HAS_VENDOR_LIB=true

while IFS= read -r -d '' source_file; do
    relative_file="${source_file#"$DRIVER_PAYLOAD"/}"
    if [ "$HAS_VENDOR_LIB" = false ] && [[ "$relative_file" == lib/* ]]; then
        continue
    fi

    case "$(basename "$relative_file")" in
        android.hardware.common-V2-ndk.so|android.hardware.graphics.allocator-V2-ndk.so|\
        android.hardware.graphics.common@1.0.so|android.hardware.graphics.common@1.1.so|\
        android.hardware.graphics.common@1.2.so|android.hardware.graphics.common-V7-ndk.so|\
        android.hardware.graphics.mapper@4.0.so|libcxx.so|libgralloctypes.so)
            if [ -e "$WORK_DIR/vendor/$relative_file" ]; then
                LOG "- Keeping target HAL support library: vendor/$relative_file"
                continue
            fi
            ;;
    esac

    ADD_TO_WORK_DIR "$MODPATH/system" "vendor" "$relative_file" 0 0 644 \
        "u:object_r:vendor_file:s0" || return 1
done < <(find "$DRIVER_PAYLOAD" \( -type f -o -type l \) -print0 | sort -z)

COMPAT_OPENCL="$MODPATH/compat_opencl/libOCLc.$SOC_NUM.so"
SPHAL_PATCHED_TOTAL=0
if [ -f "$COMPAT_OPENCL" ]; then
    SPHAL_SNAP="libsnap_compute.so libsnap_compute_secure.so"

    _sphal_snap() {
        case " $SPHAL_SNAP " in
            *" $1 "*) return 0 ;;
        esac
        return 1
    }

    patch_sphal_binary() {
        local file="$1"
        local count=0
        local offsets offset
        local find_awk='BEGIN { byte_offset=0; sequence_length=0; start_offset=0; split("69 62 4f 70 65 6e 43 4c 2e 73 6f 00", pattern_bytes, " ") } { for (field_index=1; field_index<=NF; field_index++) { current_byte=$field_index; current_offset=byte_offset; byte_offset++; if (sequence_length == 0) { if (current_byte == "6c") { sequence_length=1; start_offset=current_offset } } else if (current_byte == pattern_bytes[sequence_length]) { sequence_length++; if (sequence_length > 12) { print start_offset; sequence_length=0 } } else if (current_byte == "6c") { sequence_length=1; start_offset=current_offset } else { sequence_length=0 } } }'
        local name

        name="$(basename "$file")"
        offsets="$(od -A n -t x1 -v "$file" 2>/dev/null | awk "$find_awk")"
        for offset in $offsets; do
            printf 'libOCLc.so\000\000\000' | dd of="$file" bs=1 seek="$offset" conv=notrunc 2>/dev/null
            count=$((count + 1))
        done

        if [ "$count" -eq 0 ] && _sphal_snap "$name"; then
            local snap_awk='BEGIN { byte_offset=0; sequence_length=0; start_offset=0; split("6c 69 62 47 4c 45 53 5f 6d 61 6c 69 2e 73 6f 00", pattern_bytes, " ") } { for (field_index=1; field_index<=NF; field_index++) { current_byte=$field_index; current_offset=byte_offset; byte_offset++; if (current_byte == pattern_bytes[sequence_length+1]) { if (sequence_length == 0) start_offset=current_offset; sequence_length++; if (sequence_length == 16) { print start_offset; sequence_length=0 } } else if (current_byte == "6c") { sequence_length=1; start_offset=current_offset } else { sequence_length=0 } } }'
            offsets="$(od -A n -t x1 -v "$file" 2>/dev/null | awk "$snap_awk")"
            for offset in $offsets; do
                printf 'libOCLc.so\000\000\000\000\000\000' | dd of="$file" bs=1 seek="$offset" conv=notrunc 2>/dev/null
                count=$((count + 1))
            done
        fi

        if [ "$count" -gt 0 ]; then
            LOG "- Redirected OpenCL references in ${file#"$WORK_DIR"/}"
            SPHAL_PATCHED_TOTAL=$((SPHAL_PATCHED_TOTAL + count))
        fi
    }

    scan_sphal_dir() {
        local directory="$1"
        local file name
        [ -d "$directory" ] || return 0

        for file in "$directory"/*.so; do
            [ -f "$file" ] || continue
            name="$(basename "$file")"
            case "$name" in
                libGLES_mali.so|libOpenCL.so|libOCLc.so|libMali.so|libtensorflowlite_gpu_jni.so) continue ;;
            esac
            if grep -a -q -F 'libOpenCL.so' "$file" 2>/dev/null || \
               { _sphal_snap "$name" && grep -a -q -F 'libGLES_mali.so' "$file" 2>/dev/null; }; then
                patch_sphal_binary "$file"
            fi
        done
    }

    LOG "- Scanning system and vendor OpenCL clients"
    scan_sphal_dir "$WORK_DIR/system/system/lib64"
    scan_sphal_dir "$WORK_DIR/vendor/lib64"

    if [ "$SPHAL_PATCHED_TOTAL" -gt 0 ]; then
        mkdir -p "$WORK_DIR/vendor/lib64"
        cp -a "$COMPAT_OPENCL" "$WORK_DIR/vendor/lib64/libOCLc.so" || return 1
        SET_METADATA "vendor" "lib64/libOCLc.so" 0 0 644 \
            "u:object_r:same_process_hal_file:s0" || return 1

        PUBLIC_LIBRARIES="$WORK_DIR/vendor/etc/public.libraries.txt"
        if [ -f "$PUBLIC_LIBRARIES" ] && ! grep -q -F 'libOCLc.so' "$PUBLIC_LIBRARIES"; then
            printf '\nlibOCLc.so\n' >> "$PUBLIC_LIBRARIES"
            SET_METADATA "vendor" "etc/public.libraries.txt" 0 0 644 \
                "u:object_r:vendor_configs_file:s0" || return 1
        fi
        LOG "- Staged private $SOC_NAME OpenCL compatibility runtime"
    else
        LOG "- No OpenCL clients found; compatibility runtime not staged"
    fi
else
    LOG "- No $SOC_NAME compatibility OpenCL runtime; camera redirection disabled"
fi

LOG "- $DRIVER_VER GPU driver staged for $SOC_NAME"
LOG_STEP_OUT

unset -f _sphal_snap patch_sphal_binary scan_sphal_dir
