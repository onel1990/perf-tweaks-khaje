#!/system/bin/sh
MODDIR=${0%/*}
CONF=/data/adb/perf_tweaks_khaje.conf
GAMES=/data/adb/perf_tweaks_khaje_games.txt
LOG=/data/local/tmp/perf_tweaks_khaje.log
PERF=/vendor/etc/perf
FILES="perfconfigstore.xml perfboostsconfig.xml"

log() {
  echo "$(date '+%m-%d %H:%M:%S') $*" >> "$LOG"
  if [ "$(wc -c < "$LOG")" -gt 60000 ]; then
    tail -n 100 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
  fi
}

[ -f "$CONF" ] || cat > "$CONF" <<'EOC'
# MODE: auto | normal | game | battery
MODE=auto
# auto: also use Battery profile when battery % <= LOW_PCT and not charging (0 = off)
LOW_PCT=0
# auto: 1 = Game profile wins over Battery when a game is in the foreground
GAME_PRIORITY=0
# Check interval in seconds
INTERVAL=10
EOC

[ -f "$GAMES" ] || cat > "$GAMES" <<'EOG'
# One package name per line. Add your games here.
com.mobile.legends
com.activision.callofduty.shooter
com.tencent.ig
com.pubg.imobile
com.miHoYo.GenshinImpact
com.HoYoverse.hkrpgoversea
com.dts.freefireth
com.dts.freefiremax
com.riotgames.league.wildrift
com.roblox.client
com.mojang.minecraftpe
com.supercell.brawlstars
com.supercell.clashofclans
EOG

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
sleep 30

# give profile files the same SELinux context as the stock files
for f in $FILES; do
  ctx=$(stat -c %C "$PERF/$f" 2>/dev/null)
  [ -n "$ctx" ] || ctx=u:object_r:vendor_configs_file:s0
  for p in normal game battery; do chcon "$ctx" "$MODDIR/profiles/$p/$f" 2>/dev/null; done
done

STATE=normal   # module overlay = normal profile

fg_pkg() {
  dumpsys window 2>/dev/null | grep -m1 mCurrentFocus | sed -n 's/.* \([A-Za-z0-9_.]*\)\/.*/\1/p'
}

get_target() {
  MODE=auto; LOW_PCT=0; GAME_PRIORITY=0
  . "$CONF" 2>/dev/null
  case "$MODE" in normal|game|battery) echo "$MODE"; return;; esac
  bat=0
  if [ "$(settings get global low_power 2>/dev/null)" = "1" ]; then bat=1; fi
  if [ "$bat" = 0 ] && [ "${LOW_PCT:-0}" -gt 0 ] 2>/dev/null; then
    cap=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
    st=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
    case "$st" in
      Charging|Full) ;;
      *) if [ -n "$cap" ] && [ "$cap" -le "$LOW_PCT" ]; then bat=1; fi ;;
    esac
  fi
  if [ "$bat" = 1 ] && [ "$GAME_PRIORITY" != 1 ]; then echo battery; return; fi
  pkg=$(fg_pkg)
  if [ -n "$pkg" ] && grep -qxF "$pkg" "$GAMES" 2>/dev/null; then echo game; return; fi
  if [ "$bat" = 1 ]; then echo battery; return; fi
  echo normal
}

restart_hal() {
  pids=""
  for d in /proc/[0-9]*; do
    pid=${d#/proc/}
    cmd=$(tr '\0' ' ' < "$d/cmdline" 2>/dev/null)
    exe=${cmd%% *}
    exe=${exe##*/}
    case "$exe" in
      vendor.qti.hardware.perf*service|perfservice) pids="$pids $pid" ;;
    esac
  done
  if [ -n "$pids" ]; then
    kill -9 $pids
    log "perf HAL restarted (pid$pids)"
  else
    log "perf HAL process not found - reboot to apply"
  fi
}

apply() {
  want=$1
  [ "$want" = "$STATE" ] && return
  if [ "$STATE" != normal ]; then
    for f in $FILES; do umount "$PERF/$f" 2>/dev/null; done
  fi
  if [ "$want" != normal ]; then
    for f in $FILES; do
      mount -o bind "$MODDIR/profiles/$want/$f" "$PERF/$f" || log "bind failed: $f"
    done
  fi
  STATE=$want
  log "profile -> $want"
  restart_hal
}

log "service started"
CNT=0; CAND=""
while true; do
  t=$(get_target)
  if [ "$t" = "$STATE" ]; then
    CNT=0; CAND=""
  else
    if [ "$t" = "$CAND" ]; then CNT=$((CNT + 1)); else CAND=$t; CNT=1; fi
    need=2
    [ "$STATE" = game ] && need=3   # leave Game mode a bit slower
    if [ "$CNT" -ge "$need" ]; then apply "$t"; CNT=0; CAND=""; fi
  fi
  INTERVAL=10
  . "$CONF" 2>/dev/null
  sleep "${INTERVAL:-10}"
done
