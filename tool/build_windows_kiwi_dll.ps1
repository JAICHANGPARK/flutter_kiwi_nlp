[CmdletBinding()]
param(
  [string]$KiwiSrc = "",
  [string]$KiwiRef = "v0.22.2",
  [string]$KiwiRepo = "https://github.com/bab2min/Kiwi",
  [string]$Arch = "",
  [int]$Jobs = 0,
  [switch]$Rebuild
)

$ErrorActionPreference = "Stop"
trap {
  Write-Host "[windows] ERROR: $($_.Exception.Message)"
  exit 1
}

function Test-Truthy {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $false
  }

  switch ($Value.ToLowerInvariant()) {
    "1" { return $true }
    "true" { return $true }
    "yes" { return $true }
    "on" { return $true }
    default { return $false }
  }
}

function Assert-Command {
  param([string]$Name)

  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "[windows] Required command not found: $Name"
  }
}

function Resolve-DefaultArch {
  if (-not [string]::IsNullOrWhiteSpace($env:CMAKE_GENERATOR_PLATFORM)) {
    return $env:CMAKE_GENERATOR_PLATFORM
  }

  if (-not [string]::IsNullOrWhiteSpace($env:Platform)) {
    return $env:Platform
  }

  switch ($env:PROCESSOR_ARCHITECTURE.ToUpperInvariant()) {
    "AMD64" { return "x64" }
    "ARM64" { return "arm64" }
    "X86" { return "Win32" }
    default { return "x64" }
  }
}

function Normalize-Arch {
  param([string]$RawArch)

  switch ($RawArch.ToLowerInvariant()) {
    "x64" { return "x64" }
    "amd64" { return "x64" }
    "x86_64" { return "x64" }
    "win32" { return "Win32" }
    "x86" { return "Win32" }
    "arm64" { return "arm64" }
    default { return $RawArch }
  }
}

function Resolve-KiwiCpuArch {
  param([string]$WindowsArch)

  switch ($WindowsArch.ToLowerInvariant()) {
    "x64" { return "x86_64" }
    "win32" { return "x86" }
    "arm64" { return "arm64" }
    default { return $WindowsArch }
  }
}

function Try-DownloadPrebuilt {
  param(
    [string]$Ref,
    [string]$WindowsArch,
    [string]$OutDllPath,
    [string]$BuildRoot
  )

  if ([string]::IsNullOrWhiteSpace($Ref)) {
    return $false
  }
  if (-not $Ref.StartsWith("v")) {
    return $false
  }

  $releaseArch = switch ($WindowsArch.ToLowerInvariant()) {
    "x64" { "x64" }
    "win32" { "Win32" }
    default { $null }
  }
  if ($null -eq $releaseArch) {
    return $false
  }

  $versionNoV = $Ref.Substring(1)
  if ([string]::IsNullOrWhiteSpace($versionNoV)) {
    return $false
  }

  $asset = "kiwi_win_${releaseArch}_v${versionNoV}.zip"
  $url = "https://github.com/bab2min/Kiwi/releases/download/$Ref/$asset"
  $downloadDir = Join-Path $BuildRoot "download"
  $extractDir = Join-Path $BuildRoot "extract-$releaseArch"
  $archivePath = Join-Path $downloadDir $asset
  $candidate = Join-Path $extractDir "lib\kiwi.dll"

  try {
    New-Item -ItemType Directory -Force $downloadDir | Out-Null
    New-Item -ItemType Directory -Force `
      (Split-Path -Parent $OutDllPath) | Out-Null
    Write-Host "[windows] Try prebuilt asset: $asset"
    Invoke-WebRequest -Uri $url -OutFile $archivePath -UseBasicParsing

    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $extractDir
    Expand-Archive -Path $archivePath -DestinationPath $extractDir -Force

    if (-not (Test-Path $candidate)) {
      throw "Prebuilt asset missing kiwi.dll at $candidate"
    }

    Copy-Item -Force $candidate $OutDllPath
    Write-Host "[windows] Generated from prebuilt: $OutDllPath"
    return $true
  } catch {
    Write-Host "[windows] Prebuilt asset failed; fallback to source build."
    return $false
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = (Resolve-Path (Join-Path $scriptDir "..")).Path
$defaultKiwiSrc = Join-Path $rootDir ".tmp\kiwi-src-windows"
$androidKiwiSrc = Join-Path $rootDir ".tmp\kiwi-src-android"
if (Test-Path (Join-Path $androidKiwiSrc ".git")) {
  $defaultKiwiSrc = $androidKiwiSrc
}

if ([string]::IsNullOrWhiteSpace($KiwiSrc)) {
  $KiwiSrc = $defaultKiwiSrc
}

if ([string]::IsNullOrWhiteSpace($Arch)) {
  $Arch = Resolve-DefaultArch
}

if ($Jobs -le 0) {
  $Jobs = [Environment]::ProcessorCount
}

$buildRoot = Join-Path $rootDir ".tmp\kiwi-windows-build"
$outDll = Join-Path $rootDir "windows\prebuilt\kiwi.dll"
$skipExisting = $true

if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_KIWI_WINDOWS_KIWI_SRC)) {
  $KiwiSrc = $env:FLUTTER_KIWI_WINDOWS_KIWI_SRC
}
if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_KIWI_WINDOWS_KIWI_REF)) {
  $KiwiRef = $env:FLUTTER_KIWI_WINDOWS_KIWI_REF
}
if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_KIWI_WINDOWS_ARCH)) {
  $Arch = $env:FLUTTER_KIWI_WINDOWS_ARCH
}
if ($Rebuild -or (Test-Truthy $env:FLUTTER_KIWI_WINDOWS_REBUILD)) {
  $skipExisting = $false
}

if (Test-Truthy $env:FLUTTER_KIWI_SKIP_WINDOWS_LIBRARY_BUILD) {
  if ((Test-Path $outDll) -and ((Get-Item $outDll).Length -gt 0)) {
    Write-Host "[windows] Skip auto-build " `
      "(FLUTTER_KIWI_SKIP_WINDOWS_LIBRARY_BUILD=true)."
    exit 0
  }
  throw "[windows] Skip requested, but output is missing: $outDll"
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
  Write-Host "[windows] Skip auto-build (requires Windows host)."
  exit 0
}

$Arch = Normalize-Arch $Arch
$kiwiCpuArch = Resolve-KiwiCpuArch $Arch

Assert-Command "cmake"
Assert-Command "git"

if (
  $skipExisting -and (Test-Path $outDll) -and
  ((Get-Item $outDll).Length -gt 0)
) {
  Write-Host "[windows] Reusing existing library: $outDll"
  exit 0
}

if (
  Try-DownloadPrebuilt -Ref $KiwiRef -WindowsArch $Arch `
    -OutDllPath $outDll -BuildRoot $buildRoot
) {
  exit 0
}

if (Test-Path (Join-Path $KiwiSrc "CMakeLists.txt")) {
  Write-Host "[windows] Reusing Kiwi source: $KiwiSrc"
} else {
  Write-Host "[windows] Cloning Kiwi source ($KiwiRef) to: $KiwiSrc"
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $KiwiSrc
  New-Item -ItemType Directory -Force (Split-Path -Parent $KiwiSrc) | Out-Null
  & git "-c" "filter.lfs.required=false" `
    "-c" "filter.lfs.smudge=" `
    "-c" "filter.lfs.process=" `
    "clone" "--depth" "1" "--branch" $KiwiRef `
    "--recurse-submodules" $KiwiRepo $KiwiSrc
}

if (-not (Test-Path (Join-Path $KiwiSrc "CMakeLists.txt"))) {
  throw "[windows] Invalid Kiwi source (missing CMakeLists.txt): $KiwiSrc"
}

if (
  (Test-Path (Join-Path $KiwiSrc ".git")) -and
  (Test-Path (Join-Path $KiwiSrc ".gitmodules"))
) {
  & git "-C" $KiwiSrc "submodule" "update" "--init" "--recursive"
}

$buildDir = Join-Path $buildRoot $Arch
Write-Host "[windows] Configure arch=$Arch (kiwi cpu arch=$kiwiCpuArch)"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $buildDir

$configureArgs = @(
  "-S", $KiwiSrc,
  "-B", $buildDir,
  "-DCMAKE_BUILD_TYPE=Release",
  "-DKIWI_CPU_ARCH=$kiwiCpuArch",
  "-DKIWI_BUILD_DYNAMIC=ON",
  "-DKIWI_BUILD_CLI=OFF",
  "-DKIWI_BUILD_EVALUATOR=OFF",
  "-DKIWI_BUILD_MODEL_BUILDER=OFF",
  "-DKIWI_BUILD_TEST=OFF",
  "-DKIWI_JAVA_BINDING=OFF",
  "-DKIWI_USE_CPUINFO=OFF"
)
& cmake @configureArgs

Write-Host "[windows] Build arch=$Arch"
$buildArgs = @(
  "--build", $buildDir,
  "--config", "Release",
  "--target", "kiwi",
  "--parallel", $Jobs.ToString()
)
& cmake @buildArgs

$dllFile = Get-ChildItem -Path $buildDir -Recurse -File |
  Where-Object { $_.Name -ieq "kiwi.dll" } |
  Select-Object -First 1
if ($null -eq $dllFile) {
  throw "[windows] kiwi.dll not found under $buildDir"
}

New-Item -ItemType Directory -Force (Split-Path -Parent $outDll) | Out-Null
Copy-Item -Force $dllFile.FullName $outDll
Write-Host "[windows] Generated: $outDll"
