# Perf HAL Tweaks (SM6225 / khaje)

A Magisk / KernelSU module that tunes the Qualcomm perf HAL configs of **SM6225 (Snapdragon 680,685, "khaje""bengal")** devices and switches between three profiles automatically:

| Profile | When it is used | What it does |
|---|---|---|
| **Normal** | default | Balanced. Keeps more background apps (limit 32), shorter 8 s long-launch boosts. |
| **Game** | a game from your list is in the foreground | Longer launch / game-launch / resume boosts. Stock memory settings, so RAM is not hogged. |
| **Battery** | Android Battery Saver is ON (or battery <= `LOW_PCT`) | Short boosts, lower min frequencies, fewer background apps, fling boost off. |

> The effects are modest and **not benchmarked**. Expect small differences in battery and app retention, not a big FPS jump.

## How it works

- The module does **not ship any Qualcomm files**. At install time it reads your device's own
  `/vendor/etc/perf/perfconfigstore.xml` and `perfboostsconfig.xml` and generates the three profiles
  from them (`patch.sh`, `store.awk`, `boost.awk`). If the files do not look like a khaje config, the install aborts.
- The Normal profile is overlaid systemlessly on `/vendor/etc/perf/`.
- `service.sh` checks every `INTERVAL` seconds (default 10): Battery Saver (`settings get global low_power`),
  optional battery %, and the foreground app (`dumpsys window`). On a change it bind-mounts the right profile
  over the two files and restarts the perf HAL processes (`vendor.qti.hardware.perf*service`, `perfservice`)
  so the new values are read. A change must be seen twice in a row (three times to leave Game) to avoid flapping.

## Requirements

- SM6225 / khaje device with root (Magisk 20.4+ or KernelSU) and a working systemless overlay for `/vendor`
- `awk` in the root shell environment (Magisk and KernelSU busybox include it)

Tested on one SM6225 device with KernelSU. Other devices/ROMs: use at your own risk.

## Install

1. Download `perf_tweaks_khaje_<version>.zip` from Releases (or build it, see below).
2. Magisk / KernelSU manager -> Modules -> Install from storage.
3. Reboot.

## Configuration

Created on first boot:

- `/data/adb/perf_tweaks_khaje.conf`
  ```
  MODE=auto          # auto | normal | game | battery
  LOW_PCT=0          # auto: use Battery profile when battery <= this % and not charging (0 = off)
  GAME_PRIORITY=0    # auto: 1 = Game wins over Battery when a game is in the foreground
  INTERVAL=10        # seconds between checks
  ```
- `/data/adb/perf_tweaks_khaje_games.txt` – one package name per line. Add your games here.

Changes are picked up within one interval, no reboot needed.

## Verify

```sh
su
cat /data/local/tmp/perf_tweaks_khaje.log
grep bg_apps_limit /vendor/etc/perf/perfconfigstore.xml | head -1
```

`bg_apps_limit` = `32` Normal, `24` Game, `20` Battery. The log shows `profile -> ...` and `perf HAL restarted` on every switch.

## Troubleshooting

- **`perf HAL process not found`** in the log: send the output of `ps -A | grep -i perf` in an issue.
- **A game does not trigger Game mode**: check its package name against `dumpsys window | grep mCurrentFocus` while the game is open.
- **Install aborts with "firmware differs"**: your perf config values do not match what this module expects.
- Other tweaker apps that write CPU/governor settings can interfere with testing. Disable them while testing.
- To go back to stock: disable or remove the module in the manager and reboot.

## Build

```sh
./build.sh      # -> dist/perf_tweaks_khaje_<version>.zip
```

## License

MIT for the scripts in this repository. The perf HAL configuration files belong to their respective owners
and are only read from your own device at install time.

## Disclaimer

Modifying vendor configuration can cause instability. You are responsible for your device. No warranty.
