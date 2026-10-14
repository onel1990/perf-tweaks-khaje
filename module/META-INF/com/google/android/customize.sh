SKIPUNZIP=0
PERF=/vendor/etc/perf
FILES="perfconfigstore.xml perfboostsconfig.xml"

ui_print "- Perf HAL Tweaks khaje v4.0"
command -v awk >/dev/null 2>&1 || abort "! awk not found"
for f in $FILES; do
  [ -f "$PERF/$f" ] || abort "! $PERF/$f not found"
done
grep -q 'Target="khaje"' "$PERF/perfconfigstore.xml" || abort "! Not an SM6225/khaje perf config - aborting"

ui_print "- Generating profiles from your device's own files"
mkdir -p "$MODPATH/system/vendor/etc/perf"
for p in normal game battery; do
  mkdir -p "$MODPATH/profiles/$p"
  sh "$MODPATH/patch.sh" $p store "$PERF/perfconfigstore.xml" "$MODPATH/profiles/$p/perfconfigstore.xml" \
    || abort "! Could not patch perfconfigstore.xml ($p) - firmware differs?"
  sh "$MODPATH/patch.sh" $p boost "$PERF/perfboostsconfig.xml" "$MODPATH/profiles/$p/perfboostsconfig.xml" \
    || abort "! Could not patch perfboostsconfig.xml ($p) - firmware differs?"
  ui_print "  $p ok"
done
cp "$MODPATH/profiles/normal/"*.xml "$MODPATH/system/vendor/etc/perf/"

ui_print "- Modes: Normal / Game / Battery (auto or forced)"
ui_print "- Config: /data/adb/perf_tweaks_khaje.conf"
ui_print "- Game list: /data/adb/perf_tweaks_khaje_games.txt"
ui_print "- Log: /data/local/tmp/perf_tweaks_khaje.log"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/uninstall.sh 0 0 0755
set_perm $MODPATH/patch.sh 0 0 0755
