#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./scripts/build-ps4.sh [options]

Build pEMU PS4 packages in Docker on a Linux host.
Default behavior: build all PS4 cores and copy .pkg files to dist/ps4/.

Options:
  --target <name>       Build a single core. May be repeated.
                        Allowed values: pfbneo, pgen, pnes, psnes, pgba.
  --debug               Use Debug instead of Release.
  --image <tag>         Docker image tag. Default: pemu-ps4-builder:latest
  --no-build-image      Skip docker build and reuse the existing image.
  --help                Show this help and exit.

Examples:
  ./scripts/build-ps4.sh
  ./scripts/build-ps4.sh --target pgen
  ./scripts/build-ps4.sh --target pfbneo --target pgba --debug
  ./scripts/build-ps4.sh --no-build-image --image pemu-ps4-builder:dev

Output:
  dist/ps4/*.pkg

Prerequisite:
  Docker must be installed and accessible from this shell.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
image="pemu-ps4-builder:latest"
build_image=1
build_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            [[ $# -ge 2 ]] || { echo "error: --target requires a value" >&2; exit 1; }
            build_args+=("$1" "$2")
            shift 2
            ;;
        --debug|--help)
            build_args+=("$1")
            shift
            ;;
        --image)
            [[ $# -ge 2 ]] || { echo "error: --image requires a value" >&2; exit 1; }
            image="$2"
            shift 2
            ;;
        --no-build-image)
            build_image=0
            shift
            ;;
        *)
            echo "error: unknown argument '$1'" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ " ${build_args[*]} " == *" --help "* ]]; then
    usage
    exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "error: docker is required but was not found in PATH" >&2
    exit 1
fi

cd "$repo_root"
git submodule update --init --recursive

if [[ "$build_image" -eq 1 ]]; then
    docker build -f Dockerfile.ps4 -t "$image" .
fi

docker run --rm \
    -v "${repo_root}:/workspace" \
    -w /workspace \
    "$image" \
    ./scripts/build-docker-target.sh --platform ps4 "${build_args[@]}"
