#!/system/bin/sh

ui_print "*******************************"
ui_print " HY350MAX Smart Mic Fix v1.0.0"
ui_print "*******************************"
ui_print "Remote: Bluetooth remote (1d5a:c081)"
ui_print "Launcher: auto-detected Android HOME app"
ui_print ""
ui_print "- Assistant on the active launcher/home screen"
ui_print "- No Assistant takeover inside apps"
ui_print "- Preserves push-to-talk for in-app voice search"
ui_print ""

KL="/system/usr/keylayout/Vendor_1d5a_Product_c081.kl"
if [ ! -f "$KL" ]; then
    abort "! Compatible key layout not found: Vendor_1d5a_Product_c081.kl"
fi

if ! grep -q 'key[[:space:]]\+0x246[[:space:]]\+VOICE_ASSIST' "$KL"; then
    ui_print "! Warning: stock 0x246 VOICE_ASSIST mapping was not detected."
    ui_print "! This firmware may use a different key layout."
fi

set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/system/usr/keylayout/Vendor_1d5a_Product_c081.kl" 0 0 0644

ui_print "Reboot after installation."
