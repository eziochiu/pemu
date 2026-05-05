# PS4 Docker Build And Install

This guide covers how to build `pemu` PS4 packages with Docker on Linux or Windows, and how to install the resulting homebrew packages on a PS4 that is already able to install homebrew packages.

It does not cover console jailbreaks, exploits, HEN setup, or other steps required to make a retail PS4 accept homebrew content.

## Build

### Linux

```bash
./scripts/build-ps4.sh
./scripts/build-ps4.sh --target pgen
./scripts/build-ps4.sh --target pfbneo --target pgba --debug
```

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-ps4.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\build-ps4.ps1 -Target pgen
```

### Output

- Packages are copied to `dist/ps4/`.
- The raw CMake build tree stays under `cmake-build/ps4/`.

## Install On PS4

This section assumes the PS4 is already in a state where it can install homebrew `.pkg` files.

1. Copy the desired `.pkg` from `dist/ps4/` to a USB drive or your usual package-install path.
2. Install the package on the PS4 with your normal homebrew package installer.
3. Copy ROMs and BIOS files into the data directories listed below.

The Docker scripts only deliver standalone `.pkg` files. The release packaging logic in `libcross2d` can also bundle extra data under `data/<project>`, but for these scripts the important runtime paths are the application's `/data/<app>/...` directories.

## Runtime Paths

| Core | Package artifact | ROM directories | BIOS / notes |
| --- | --- | --- | --- |
| `pfbneo` | `pfbneo*.pkg` | Default root is `/data/pfba/`. Common folders include `/data/pfba/arcade/`, `/data/pfba/megadrive/`, `/data/pfba/sms/`, `/data/pfba/gamegear/`, `/data/pfba/nes/`, `/data/pfba/pce/`, `/data/pfba/sg1000/`. | Uses pFBN-specific system ids. The ROM path set is generated from the app config and can be adjusted in the app config after first launch. |
| `pgen` | `pgen*.pkg` | `/data/pgen/gamegear/`, `/data/pgen/megadrive/`, `/data/pgen/mastersystem/`, `/data/pgen/sg1000/`, `/data/pgen/megacd/` | Put BIOS files in `/data/pgen/bios/`. Expected filenames include `ggenie.bin`, `areplay.bin`, `sk.bin`, `sk2chip.bin`, `bios_CD_U.bin`, `bios_CD_E.bin`, `bios_CD_J.bin`, `bios_MD.bin`, `bios_U.sms`, `bios_E.sms`, `bios_J.sms`, `bios.gg`. |
| `pnes` | `pnes*.pkg` | `/data/pnes/roms/` | No extra BIOS path is documented in this repo. |
| `psnes` | `psnes*.pkg` | `/data/psnes/roms/` | Cheats go alongside the app's data layout if you use them. |
| `pgba` | `pgba*.pkg` | `/data/pgba/gb/`, `/data/pgba/gbc/`, `/data/pgba/gba/` | Put `gba_bios.bin` in `/data/pgba/bios/`. |

## pfbneo Notes

`pfbneo` uses a different application data root from the other cores: `/data/pfba/`.

Its default ROM paths are created in code from that root, including:

```text
/data/pfba/arcade/
/data/pfba/gamegear/
/data/pfba/megadrive/
/data/pfba/sms/
/data/pfba/nes/
/data/pfba/ngp/
/data/pfba/pce/
/data/pfba/sg1000/
```

Unlike the other pEMU cores, `pfbneo` associates each configured ROM path with a specific FBNeo hardware id. The special `Arcade` entry uses `0x12341234`, and arcade ROMs found there derive their actual hardware from the FBNeo driver database.

## Tips

- First launch is a good time to let each app create its data folders automatically.
- If a core does not detect your ROMs immediately, verify the exact directory name and restart the app after copying files.
- `pfbneo` is the least uniform core in this repo, so prefer its documented directory names over guessing from the package name.
