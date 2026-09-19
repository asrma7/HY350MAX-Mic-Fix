#!/system/bin/sh

TAG="hy350max-mic-fix"
REMOTE_NAME="Bluetooth remote Keyboard"

# Allow Android and Bluetooth to finish starting.
sleep 10

get_home_package() {
    HOME_COMPONENT="$(cmd package resolve-activity --brief \
        -a android.intent.action.MAIN \
        -c android.intent.category.HOME 2>/dev/null | tail -n 1)"

    case "$HOME_COMPONENT" in
        */*) echo "${HOME_COMPONENT%%/*}" ;;
        *)   echo "" ;;
    esac
}

while true; do
    EVENT=""

    # eventX numbers can change after reboot/reconnection, so resolve by name.
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
                HOME_PKG="$(get_home_package)"
                TOP="$(dumpsys activity activities 2>/dev/null | grep -m1 'topResumedActivity')"

                if [ -n "$HOME_PKG" ]; then
                    case "$TOP" in
                        *"$HOME_PKG/"*)
                            log -t "$TAG" "Mic pressed on HOME ($HOME_PKG) - launching Assistant"
                            am start --user 0 -a android.intent.action.ASSIST >/dev/null 2>&1
                            ;;
                        *)
                            log -t "$TAG" "Mic pressed outside HOME ($HOME_PKG) - ignored"
                            ;;
                    esac
                else
                    log -t "$TAG" "Could not resolve HOME launcher - ignored"
                fi
                ;;
        esac
    done

    # getevent exits if the Bluetooth input device disappears. Resolve it again.
    sleep 2
done
