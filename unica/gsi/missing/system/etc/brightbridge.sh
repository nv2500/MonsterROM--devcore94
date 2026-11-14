#!/system/bin/sh
# Brightness bridge for the ColorOS 17 port on the S21 FE (Exynos).
# ColorOS's display pipeline never reaches the Samsung light HAL, so this copies
# the slider value (settings: screen_brightness, 222..8191) to the HAL as a gray
# level (LOW..HIGH, the HAL takes 0-255). Auto-brightness must stay off.

# MIN=222      # screen_brightness at the lowest slider position
# MAX=8191     # screen_brightness at the highest slider position
# LOW=4        # HAL level at the lowest slider position (raise it if the minimum is too dark)
# HIGH=255     # HAL level at the highest slider position

# last=""
# n=0
# while true; do
#     x=$(settings get system screen_brightness 2>/dev/null)
#     case "$x" in
#         ''|*[!0-9]*) sleep 2; continue ;;
#     esac
#     # Apply on change, and re-apply every ~5 s in case the panel falls back after screen off/on.
#     if [ "$x" != "$last" ] || [ "$n" -ge 5 ]; then
#         last=$x
#         n=0
#         [ "$x" -lt "$MIN" ] && x=$MIN
#         [ "$x" -gt "$MAX" ] && x=$MAX
#         # Quadratic curve: the slider feels more even than a straight line.
#         t=$(( (x - MIN) * 1000 / (MAX - MIN) ))
#         v=$(( LOW + (HIGH - LOW) * t * t / 1000000 ))
#         # Gray color 0xFFvvvvvv as a signed 32-bit value.
#         c=$(( ((v << 16) | (v << 8) | v) - 16777216 ))
#         service call android.hardware.light.ILights/default 1 i32 0 i32 1 i32 24 i32 $c i32 0 i32 0 i32 0 i32 0 >/dev/null 2>&1
#     fi
#     n=$((n + 1))
#     sleep 1
# done
