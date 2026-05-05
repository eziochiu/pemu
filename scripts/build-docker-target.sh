#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-docker-target.sh --platform <ps4|switch> [options]

Build pEMU PS4 or Switch targets from inside a Docker container.

Options:
  --platform <name>     Required. One of: ps4, switch.
  --target <name>       Build a single core. May be repeated.
                        Allowed values: pfbneo, pgen, pnes, psnes, pgba.
  --debug               Use Debug builds. Default is Release.
  --build-dir <path>    Build directory relative to repo root. Default: cmake-build/<platform>.
  --output-dir <path>   Output directory relative to repo root. Default: dist/<platform>.
  --help                Show this help and exit.

Examples:
  ./scripts/build-docker-target.sh --platform ps4
  ./scripts/build-docker-target.sh --platform ps4 --target pgen --target pgba
  ./scripts/build-docker-target.sh --platform switch --debug --target pfbneo
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

platform=""
build_type="Release"
build_dir=""
output_dir=""
targets=()
valid_targets=("pfbneo" "pgen" "pnes" "psnes" "pgba")

contains_target() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --platform)
            [[ $# -ge 2 ]] || { echo "error: --platform requires a value" >&2; exit 1; }
            platform="$2"
            shift 2
            ;;
        --target)
            [[ $# -ge 2 ]] || { echo "error: --target requires a value" >&2; exit 1; }
            if ! contains_target "$2" "${valid_targets[@]}"; then
                echo "error: invalid target '$2'. Allowed: ${valid_targets[*]}" >&2
                exit 1
            fi
            targets+=("$2")
            shift 2
            ;;
        --debug)
            build_type="Debug"
            shift
            ;;
        --build-dir)
            [[ $# -ge 2 ]] || { echo "error: --build-dir requires a value" >&2; exit 1; }
            build_dir="$2"
            shift 2
            ;;
        --output-dir)
            [[ $# -ge 2 ]] || { echo "error: --output-dir requires a value" >&2; exit 1; }
            output_dir="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "error: unknown argument '$1'" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ "$platform" != "ps4" && "$platform" != "switch" ]]; then
    echo "error: --platform must be 'ps4' or 'switch'" >&2
    exit 1
fi

if [[ ${#targets[@]} -eq 0 ]]; then
    targets=("${valid_targets[@]}")
fi

if [[ -z "$build_dir" ]]; then
    build_dir="cmake-build/${platform}"
fi

if [[ -z "$output_dir" ]]; then
    output_dir="dist/${platform}"
fi

platform_flag="PLATFORM_PS4"
artifact_suffix="_pkg"
artifact_ext="pkg"
if [[ "$platform" == "switch" ]]; then
    platform_flag="PLATFORM_SWITCH"
    artifact_suffix=".nro"
    artifact_ext="nro"
fi

mkdir -p "${repo_root}/${build_dir}" "${repo_root}/${output_dir}"

cd "${repo_root}/${build_dir}"
cmake -G "Unix Makefiles" "-D${platform_flag}=ON" "-DCMAKE_BUILD_TYPE=${build_type}" ../..

if contains_target "pfbneo" "${targets[@]}"; then
    make pfbneo.deps
fi

artifacts=()
if [[ "$platform" == "ps4" ]]; then
    # PS4 packages are named from CONTENT_ID, not from the target name.
    # Clear stale packages so we can capture the package emitted by each target build.
    find "${repo_root}/${build_dir}" -maxdepth 1 -type f -name '*.pkg' -delete
fi

for target in "${targets[@]}"; do
    make -j"$(nproc)" "${target}${artifact_suffix}"
    if [[ "$platform" == "ps4" ]]; then
        artifact_path="$(find "${repo_root}/${build_dir}" -maxdepth 1 -type f -name '*.pkg' -printf '%T@ %p\n' | sort -n | tail -n 1 | cut -d' ' -f2-)"
    else
        artifact_path="${repo_root}/${build_dir}/src/cores/${target}/${target}.${artifact_ext}"
    fi
    if [[ -z "${artifact_path:-}" || ! -f "$artifact_path" ]]; then
        echo "error: expected artifact for ${target} was not produced" >&2
        exit 1
    fi
    artifacts+=("$artifact_path")
done

find "${repo_root}/${output_dir}" -maxdepth 1 -type f -name "*.${artifact_ext}" -delete
for artifact_path in "${artifacts[@]}"; do
    cp "$artifact_path" "${repo_root}/${output_dir}/"
done

echo "Artifacts copied to ${output_dir}"
