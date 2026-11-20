# Builds NowYouSee.exe (Win64).  Usage: build-delphi.ps1 [-Config Release|Debug]
#
# Prefers Delphi 12 (Studio 23.0). Falls back to Delphi 13 (Studio 37.0),
# which compiles this Delphi 12 project as it is.
#
# The project's post-build step copies WebView2Loader.dll beside the exe,
# so a build from the IDE gets it too.
param(
  [ValidateSet('Release', 'Debug')]
  [string]$Config = 'Release'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Third-party pieces that are not in the repo. See DEPENDENCIES.md.
& (Join-Path $Root 'tools\fetch-nocommit.ps1')

$Studios = @(
  'C:\Program Files (x86)\Embarcadero\Studio\23.0',
  'C:\Program Files (x86)\Embarcadero\Studio\37.0'
)
$Bds = $Studios | Where-Object { Test-Path (Join-Path $_ 'bin\rsvars.bat') } | Select-Object -First 1
if (-not $Bds) { throw 'Delphi was not found. Expected Studio 23.0 (Delphi 12) or 37.0 (Delphi 13).' }

cmd /c "`"$Bds\bin\rsvars.bat`" && msbuild `"$Root\src\delphi\NowYouSee.dproj`" /t:Build /p:Config=$Config /p:Platform=Win64 /nologo /v:minimal"
if ($LASTEXITCODE -ne 0) { throw "msbuild exited $LASTEXITCODE" }

Write-Output "Built $Root\src\delphi\Win64\$Config\NowYouSee.exe"
