#!/system/bin/sh
for f in perfconfigstore.xml perfboostsconfig.xml; do umount /vendor/etc/perf/$f 2>/dev/null; done
rm -f /data/adb/perf_tweaks_khaje.conf /data/adb/perf_tweaks_khaje_games.txt /data/local/tmp/perf_tweaks_khaje.log*
