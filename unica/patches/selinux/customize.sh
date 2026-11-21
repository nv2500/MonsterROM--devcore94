source "$SRC_DIR/scripts/utils/common_utils.sh"
source "$SRC_DIR/scripts/utils/module_utils.sh"
source "$SRC_DIR/scripts/utils/smali_utils.sh"

TARGET_FIRMWARE_DIR="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
echo "TARGET_FIRMWARE_DIR=$TARGET_FIRMWARE_DIR"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE_DIR" "system" "system/system_ext/etc/selinux/mapping/30.0.cil" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE_DIR" "system" "system/system_ext/etc/selinux/mapping/30.0.compat.cil" 0 0 644 "u:object_r:system_file:s0"
# out/target/r9s/work_dir/system/system/system_ext/etc/selinux/mapping/30.0.cil

# UN1CA SELinux entries removal list
# - Append new type entries to the ENTRIES list
# - Add the EXACT type entry, DO NOT just add a common pattern (eg. "fabriccrypto", "fabriccrypto_exec" and NOT just "fabriccrypto")
# - DO NOT add the API version at the end of the entry (eg. "fabriccrypto" and NOT "fabriccrypto_30_0")
# - DO NOT add any parenthesis or statements (eg. "fabriccrypto" and NOT "expanttypeattribute ... (fabriccrypto)")
# - DO NOT add unnecessary types or remove the existing ones unless they aren't necessary anymore for all devices

# One UI 9.0 additions
ENTRIES+="
mosey_app
"

# One UI 8.0 additions
ENTRIES+="
heatmap_default
heatmap_default_exec
"

DUPLICATES+="
init.svc.vendor.wvkprov_server_hal
"

# One UI 7.0 additions
ENTRIES+="
attiqi_app
attiqi_app_data_file
ker_app
kpp_app
kpp_data_file
"

# One UI 6.1.1 additions
ENTRIES+="
hal_dsms_default
hal_dsms_default_exec
proc_compaction_proactiveness
sbauth
sbauth_exec
"

# One UI 5.1.1 additions
ENTRIES+="
audiomirroring
audiomirroring_exec
audiomirroring_service
fabriccrypto
fabriccrypto_exec
fabriccrypto_data_file
hal_dsms_service
uwb_regulation_skip_prop
"

# [
GET_SYSTEM_EXT()
{
    if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
        echo "system_ext"
    else
        echo "system/system/system_ext"
    fi
}

# RESTORE_TARGET_MAPPING <partition> <file> <work file>
RESTORE_TARGET_MAPPING()
{
    local PARTITION="$1"
    local FILE="$2"
    local WORK_FILE="$3"

    if [ ! -f "$WORK_FILE" ]; then
        LOG "- Restoring /$PARTITION/$FILE from target firmware"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "$PARTITION" "$FILE" \
            0 0 644 "u:object_r:system_file:s0" || \
            ABORT "Failed to restore target SELinux mapping: /$PARTITION/$FILE"
        PATCHED=true
    fi

    if [ ! -s "$WORK_FILE" ]; then
        ABORT "Missing target SELinux mapping: ${WORK_FILE//$WORK_DIR/}"
    fi
}

CIL_NAME="$(head -n 1 "$WORK_DIR/vendor/etc/selinux/plat_sepolicy_vers.txt")"
PATCHED=false
SYSTEM_EXT_DIR="$(GET_SYSTEM_EXT)"

# Android 17 no longer provides API 30 compatibility mappings. Restore both
# halves of the target's policy mapping floor; retaining only system_ext is not
# sufficient for a vendor whose plat_sepolicy_vers is 30.0.
if [[ "$CIL_NAME" == "30.0" ]]; then
    RESTORE_TARGET_MAPPING "system" "system/etc/selinux/mapping/$CIL_NAME.cil" \
        "$WORK_DIR/system/system/etc/selinux/mapping/$CIL_NAME.cil"
    RESTORE_TARGET_MAPPING "system" "system/etc/selinux/mapping/$CIL_NAME.compat.cil" \
        "$WORK_DIR/system/system/etc/selinux/mapping/$CIL_NAME.compat.cil"
    RESTORE_TARGET_MAPPING "system_ext" "etc/selinux/mapping/$CIL_NAME.cil" \
        "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.cil"
    RESTORE_TARGET_MAPPING "system_ext" "etc/selinux/mapping/$CIL_NAME.compat.cil" \
        "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.compat.cil"
fi

VENDOR_API_LIST="$(find "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping" -type f -printf "%f\n" | \
                    sed '/.compat./d' | sed 's/.cil//' | sed 's/\./_/' | sort)"
# ]

for e in $ENTRIES; do
    if grep -q -F "($e)" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.cil" || \
         grep -q -F "${e}_${CIL_NAME//./_}" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.cil"; then
        # the problematic entry is currently present in system_ext, check if we need to remove it
        if ! grep -q -F "(type $e)" "$WORK_DIR/vendor/etc/selinux/plat_pub_versioned.cil"; then
            PATCHED=true
            # the problematic entry is not supported by the target device
            LOG "- \"$e\" SELinux entry not supported. Removing"
            sed -i "/($e)/d" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.cil"
            for a in $VENDOR_API_LIST; do
                sed -i "/${e}_${a}/d" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.cil"
            done
            if grep -q "genfscon.*$e" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/system_ext_sepolicy.cil"; then
                sed -i "/genfscon.*$e/d" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/system_ext_sepolicy.cil"
            fi
            if grep -q "genfscon.*$e" "$WORK_DIR/system/system/etc/selinux/plat_sepolicy.cil"; then
                sed -i "/genfscon.*$e/d" "$WORK_DIR/system/system/etc/selinux/plat_sepolicy.cil"
            fi
        fi
    fi
done

for e in $DUPLICATES; do
    if grep -q "^$e.*" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/system_ext_property_contexts"; then
        # the problematic entry is currently present in system_ext, check if we need to remove it
        if grep -q "^$e.*" "$WORK_DIR/vendor/etc/selinux/vendor_property_contexts"; then
            PATCHED=true
            # the problematic entry is found in target vendor
            LOG "- \"$e\" SELinux duplicate entry found. Removing"
            sed -i "s/^$e/#SEC_DUPLICATE: $e/g" "$WORK_DIR/vendor/etc/selinux/vendor_property_contexts"
        fi
    fi
done

if ! POLICY_FIXES="$(python3 - "$WORK_DIR" "$CIL_NAME" <<'EOF'
import glob
import io
import os
import re
import sys
import xml.etree.ElementTree as ET

work_dir, cil_name = sys.argv[1:]
if not cil_name:
    raise SystemExit("Missing vendor plat_sepolicy version")

definition_paths = [
    "system/system/etc/selinux/plat_sepolicy.cil",
    "system_ext/etc/selinux/system_ext_sepolicy.cil",
    "system/system/system_ext/etc/selinux/system_ext_sepolicy.cil",
    "product/etc/selinux/product_sepolicy.cil",
    "vendor/etc/selinux/plat_pub_versioned.cil",
    "vendor/etc/selinux/vendor_sepolicy.cil",
    "odm/etc/selinux/odm_sepolicy.cil",
]

defined = set()
definition_files = 0
for relative_path in definition_paths:
    path = os.path.join(work_dir, relative_path)
    if not os.path.isfile(path):
        continue
    definition_files += 1
    with open(path, encoding="utf-8") as policy_file:
        for line in policy_file:
            stripped = line.strip()
            if not stripped or stripped.startswith(";"):
                continue
            defined.update(
                re.findall(
                    r"\((?:type|typeattribute|typealias)\s+([a-zA-Z0-9_-]+)",
                    stripped,
                )
            )

if not definition_files or not defined:
    raise SystemExit("No SELinux type definitions found; refusing to edit mappings")

mapping_paths = [
    f"system/system/etc/selinux/mapping/{cil_name}.cil",
    f"system_ext/etc/selinux/mapping/{cil_name}.cil",
    f"system/system/system_ext/etc/selinux/mapping/{cil_name}.cil",
    f"product/etc/selinux/mapping/{cil_name}.cil",
]

mapping_files = 0
updates = {}
fixes = []
for relative_path in mapping_paths:
    path = os.path.join(work_dir, relative_path)
    if not os.path.isfile(path):
        continue
    mapping_files += 1
    with open(path, encoding="utf-8") as mapping_file:
        lines = mapping_file.readlines()

    removed = 0
    clean_lines = []
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith(";"):
            clean_lines.append(line)
            continue

        expand = re.match(
            r"^\(expandtypeattribute\s+\(([a-zA-Z0-9_-]+)\)", stripped
        )
        if expand and expand.group(1) not in defined:
            removed += 1
            continue

        attribute_set = re.match(
            r"^\(typeattributeset\s+([a-zA-Z0-9_-]+)\s+\((.+)\)\)", stripped
        )
        if attribute_set:
            target = attribute_set.group(1)
            sources = attribute_set.group(2).split()
            has_unsupported_type = any(
                source.strip("()") not in defined
                and source.strip("()") not in {"and", "or", "not"}
                for source in sources
            )
            if target not in defined or has_unsupported_type:
                removed += 1
                continue

        clean_lines.append(line)

    if removed:
        updates[path] = "".join(clean_lines)
        fixes.append(
            f"- Removed {removed} unsupported mapping statements from {relative_path}"
        )

if not mapping_files:
    raise SystemExit(f"No mapping CIL files found for version {cil_name}")

for relative_path, duplicate_lines in (
    (
        "system/system/etc/selinux/plat_sepolicy.cil",
        {"(typeattribute system_and_vendor_property_type)"},
    ),
    (
        "product/etc/selinux/product_sepolicy.cil",
        {
            "(typeattribute system_and_vendor_property_type)",
            "(typeattribute cil_gen_require)",
        },
    ),
):
    path = os.path.join(work_dir, relative_path)
    if not os.path.isfile(path):
        continue
    if path in updates:
        lines = updates[path].splitlines(keepends=True)
    else:
        with open(path, encoding="utf-8") as policy_file:
            lines = policy_file.readlines()

    seen = set()
    clean_lines = []
    removed = 0
    for line in lines:
        stripped = line.strip()
        if stripped in duplicate_lines:
            if stripped in seen:
                removed += 1
                continue
            seen.add(stripped)
        clean_lines.append(line)

    if removed:
        updates[path] = "".join(clean_lines)
        fixes.append(f"- Removed {removed} duplicate declarations from {relative_path}")

for path in glob.glob(
    os.path.join(work_dir, "**/etc/selinux/*mac_permissions.xml"),
    recursive=True,
):
    tree = ET.parse(path)
    root = tree.getroot()
    changed = False
    for signer in root.findall("signer"):
        if signer.findall("seinfo"):
            continue
        packages = signer.findall("package")
        if not packages:
            continue

        package_values = []
        missing_package_values = False
        for package in packages:
            seinfo = package.find("seinfo")
            value = seinfo.get("value") if seinfo is not None else None
            if value:
                package_values.append(value)
            else:
                missing_package_values = True

        distinct_values = set(package_values)
        if len(distinct_values) > 1 or (
            distinct_values and missing_package_values
        ):
            raise SystemExit(
                f"Cannot safely normalize package seinfo values in {path}"
            )

        seinfo = ET.SubElement(signer, "seinfo")
        seinfo.set("value", next(iter(distinct_values), "default"))
        for package in packages:
            signer.remove(package)
        changed = True

    if changed:
        xml_output = io.BytesIO()
        tree.write(xml_output, encoding="utf-8", xml_declaration=True)
        updates[path] = xml_output.getvalue()
        fixes.append(
            f"- Normalized signer entries in {os.path.relpath(path, work_dir)}"
        )

for path, content in updates.items():
    if isinstance(content, bytes):
        with open(path, "wb") as output_file:
            output_file.write(content)
    else:
        with open(path, "w", encoding="utf-8") as output_file:
            output_file.write(content)

print("\n".join(fixes))
EOF
)"; then
    ABORT "Failed to sanitize SELinux policy"
    exit 1
fi

if [ -n "$POLICY_FIXES" ]; then
    printf '%s\n' "$POLICY_FIXES"
    PATCHED=true
fi

if ! $PATCHED; then
    LOG "\033[0;33m! Nothing to do\033[0m"
fi

unset ENTRIES DUPLICATES CIL_NAME PATCHED SYSTEM_EXT_DIR VENDOR_API_LIST POLICY_FIXES
unset -f GET_SYSTEM_EXT RESTORE_TARGET_MAPPING
