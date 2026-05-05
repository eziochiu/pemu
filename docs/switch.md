# Nintendo Switch Docker Build And Install

This guide covers how to build `pemu` Nintendo Switch homebrew with Docker on Linux or Windows, and how to install the resulting `.nro` files on a Switch that is already able to launch homebrew from the Homebrew Menu.

It does not cover console exploits, boot chain setup, or any steps required to enable homebrew on retail hardware.

## Build

### Linux

```bash
./scripts/build-switch.sh
./scripts/build-switch.sh --target pgba
./scripts/build-switch.sh --target pfbneo --debug
```

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-switch.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\build-switch.ps1 -Target pgba
```

### Output

- Homebrew executables are copied to `dist/switch/`.
- The raw CMake build tree stays under `cmake-build/switch/`.

## Install On Switch

This section assumes the Switch already launches homebrew `.nro` files from the Homebrew Menu.

1. Copy the desired `.nro` from `dist/switch/` to the matching directory on the SD card.
2. Copy ROMs and BIOS files into the matching app directory.
3. Launch the app from the Homebrew Menu.

For consistency, treat every core as living under `/switch/<app>/`, even though some upstream README files describe this as copying either a single `.nro` or a whole directory.

## Runtime Paths

| Core | NRO path | ROM directories | BIOS / notes |
| --- | --- | --- | --- |
| `pfbneo` | `/switch/pfbn/pfbneo.nro` | Default root is `/switch/pfbn/`. Common folders include `/switch/pfbn/arcade/`, `/switch/pfbn/megadrive/`, `/switch/pfbn/sms/`, `/switch/pfbn/gamegear/`, `/switch/pfbn/nes/`, `/switch/pfbn/pce/`, `/switch/pfbn/sg1000/`. | Uses pFBN-specific system ids. The ROM path set is generated from the app config and can be adjusted after first launch. |
| `pgen` | `/switch/pgen/pgen.nro` | `/switch/pgen/gamegear/`, `/switch/pgen/megadrive/`, `/switch/pgen/mastersystem/`, `/switch/pgen/sg1000/`, `/switch/pgen/megacd/` | Put BIOS files in `/switch/pgen/bios/`. Expected filenames include `ggenie.bin`, `areplay.bin`, `sk.bin`, `sk2chip.bin`, `bios_CD_U.bin`, `bios_CD_E.bin`, `bios_CD_J.bin`, `bios_MD.bin`, `bios_U.sms`, `bios_E.sms`, `bios_J.sms`, `bios.gg`. |
| `pnes` | `/switch/pnes/pnes.nro` | `/switch/pnes/roms/` | No extra BIOS path is documented in this repo. |
| `psnes` | `/switch/psnes/psnes.nro` | `/switch/psnes/roms/` | Cheats and saves follow the app data layout. |
| `pgba` | `/switch/pgba/pgba.nro` | `/switch/pgba/gb/`, `/switch/pgba/gbc/`, `/switch/pgba/gba/` | Put `gba_bios.bin` in `/switch/pgba/bios/`. |

## pfbneo Notes

`pfbneo` uses `/switch/pfbn/` as its data root on Switch. This differs from the executable name and from the other cores.

Its default ROM paths include:

```text
/switch/pfbn/arcade/
/switch/pfbn/gamegear/
/switch/pfbn/megadrive/
/switch/pfbn/sms/
/switch/pfbn/nes/
/switch/pfbn/ngp/
/switch/pfbn/pce/
/switch/pfbn/sg1000/
```

Common console folders such as `arcade`, `megadrive`, and `sms` are created from the internal config. The `Arcade` folder is special because the app maps it through FBNeo's internal driver database.

## Tips

- Let the app run once if you want it to create missing folders for you.
- Keep ROMs in the exact folder names shown above; several cores expect those names directly.
- If you update a `.nro`, replacing only the executable is usually enough unless you are also changing ROMs or BIOS files.
