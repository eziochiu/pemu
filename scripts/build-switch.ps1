param(
    [string[]]$Target,
    [switch]$Debug,
    [string]$Image = "pemu-switch-builder:latest",
    [switch]$NoBuildImage,
    [switch]$Help
)

function Show-Usage {
    @"
Usage: powershell -ExecutionPolicy Bypass -File .\scripts\build-switch.ps1 [options]

Build pEMU Nintendo Switch homebrew in Docker on a Windows host.
Default behavior: build all Switch cores and copy .nro files to dist/switch/.

Options:
  -Target <name>        Build a single core. May be repeated.
                        Allowed values: pfbneo, pgen, pnes, psnes, pgba.
  -Debug                Use Debug instead of Release.
  -Image <tag>          Docker image tag. Default: pemu-switch-builder:latest
  -NoBuildImage         Skip docker build and reuse the existing image.
  -Help                 Show this help and exit.

Examples:
  powershell -ExecutionPolicy Bypass -File .\scripts\build-switch.ps1
  powershell -ExecutionPolicy Bypass -File .\scripts\build-switch.ps1 -Target pgba
  powershell -ExecutionPolicy Bypass -File .\scripts\build-switch.ps1 -Target pfbneo -Debug

Output:
  dist/switch/*.nro

Prerequisite:
  Docker Desktop (or a compatible Docker CLI) must be installed.
"@
}

if ($Help) {
    Show-Usage
    exit 0
}

$validTargets = @("pfbneo", "pgen", "pnes", "psnes", "pgba")
if ($Target) {
    foreach ($item in $Target) {
        if ($validTargets -notcontains $item) {
            throw "Invalid target '$item'. Allowed values: $($validTargets -join ', ')"
        }
    }
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "docker was not found in PATH"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path

Push-Location $repoRoot
try {
    & git submodule update --init --recursive
    if ($LASTEXITCODE -ne 0) {
        throw "git submodule update failed"
    }

    if (-not $NoBuildImage) {
        & docker build -f Dockerfile.switch -t $Image .
        if ($LASTEXITCODE -ne 0) {
            throw "docker build failed"
        }
    }

    $containerArgs = @("./scripts/build-docker-target.sh", "--platform", "switch")
    if ($Debug) {
        $containerArgs += "--debug"
    }
    if ($Target) {
        foreach ($item in $Target) {
            $containerArgs += @("--target", $item)
        }
    }

    & docker run --rm `
        -v "${repoRoot}:/workspace" `
        -w /workspace `
        $Image `
        @containerArgs
    if ($LASTEXITCODE -ne 0) {
        throw "docker run failed"
    }
}
finally {
    Pop-Location
}
