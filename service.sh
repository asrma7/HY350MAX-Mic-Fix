#!/system/bin/sh

TAG="hy350max-mic-fix"
REMOTE_NAME="Bluetooth remote Keyboard"

# Allow Android and Bluetooth to finish starting.
sleep 10

get_foreground_package() {
    TOP="$(dumpsys activity activities 2>/dev/null |
        grep -m1 'topResumedActivity')"

    # Extract package from:
    # ... u0 com.example.app/.MainActivity ...
    echo "$TOP" |
        sed -n 's/.* u[0-9][0-9]* \([^/ ]*\)\/.*/\1/p'
}

is_home_package() {
    PKG="$1"

    [ -n "$PKG" ] || return 1

    RESULT="$(cmd package query-activities --brief \
        -a android.intent.action.MAIN \
        -c android.intent.category.HOME \
        "$PKG" 2>/dev/null)"

    echo "$RESULT" | grep -q 'activities found:' || return 1
    echo "$RESULT" | grep -qv '^0 activities found:'
}

while true; do
    EVENT=""

    # eventX numbers can change after reboot/reconnection.
    # Find the remote by its input-device name instead.
    for e in /sys/class/input/event*; do
        if [ "$(cat "$e/device/name" 2>/dev/null)" = "$REMOTE_NAME" ]; then
            EVENT="/dev/input/$(basename "$e")"
            break
        fi
    done

    if [ -z "$EVENT" ]; then
        sleep 2
        continue
    fi

    log -t "$TAG" "Listening on $EVENT"

    getevent -l "$EVENT" 2>/dev/null |
    while IFS= read -r line; do
        case "$line" in
            *"KEY_VOICECOMMAND"*"DOWN"*)
                FOREGROUND_PKG="$(get_foreground_package)"

                if is_home_package "$FOREGROUND_PKG"; then
                    log -t "$TAG" \
                        "Mic pressed on HOME ($FOREGROUND_PKG) - launching Assistant"

                    am start --user 0 \
                        -a android.intent.action.ASSIST \
                        >/dev/null 2>&1
                else
                    log -t "$TAG" \
                        "Mic pressed outside HOME ($FOREGROUND_PKG) - ignored"
                fi
                ;;
        esac
    done

    # Bluetooth reconnection may create a different eventX.
    sleep 2
done