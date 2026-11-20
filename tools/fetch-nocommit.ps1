# Copies the third-party pieces that stay out of git.
# SynEdit is MPL 1.1. WebView2Loader.dll is Microsoft's BSD-3-Clause loader.
# Both may be downloaded and compiled. Neither is committed.
# See DEPENDENCIES.md and license-info/LICENSES.md.

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$NoCommit = Join-Path $Root 'no-commit'
New-Item -ItemType Directory -Force -Path $NoCommit | Out-Null

$SynDir = Join-Path $NoCommit 'SynEdit'
$SynCommit = '4f9aaa3ec804b6ad551897c9de0ce730019f7682'
if (-not (Test-Path (Join-Path $SynDir 'Source\SynEdit.pas'))) {
  git clone https://github.com/TurboPack/SynEdit.git $SynDir
}
$Have = (git -C $SynDir rev-parse HEAD).Trim()
if ($Have -ne $SynCommit) {
  git -C $SynDir fetch --depth 1 origin $SynCommit
  git -C $SynDir checkout --detach $SynCommit
}

$WvVersion = '1.0.3240.44'
$WvRoot = Join-Path $NoCommit 'webview2'
$Dll = Join-Path $WvRoot 'x64\WebView2Loader.dll'
if (-not (Test-Path $Dll)) {
  $Nupkg = Join-Path $env:TEMP "Microsoft.Web.WebView2.$WvVersion.nupkg"
  $Zip = Join-Path $env:TEMP "Microsoft.Web.WebView2.$WvVersion.zip"
  $Unpack = Join-Path $env:TEMP "Microsoft.Web.WebView2.$WvVersion"
  Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/$WvVersion" -OutFile $Nupkg
  Copy-Item $Nupkg $Zip -Force
  if (Test-Path $Unpack) { Remove-Item -Recurse -Force $Unpack }
  Expand-Archive -Path $Zip -DestinationPath $Unpack
  New-Item -ItemType Directory -Force -Path (Join-Path $WvRoot 'x64'), (Join-Path $WvRoot 'x86') | Out-Null
  Copy-Item (Join-Path $Unpack "runtimes\win-x64\native\WebView2Loader.dll") (Join-Path $WvRoot 'x64\WebView2Loader.dll')
  Copy-Item (Join-Path $Unpack "runtimes\win-x86\native\WebView2Loader.dll") (Join-Path $WvRoot 'x86\WebView2Loader.dll')
  $License = Get-ChildItem $Unpack -Recurse -Filter 'LICENSE*' | Select-Object -First 1
  if ($License) { Copy-Item $License.FullName (Join-Path $WvRoot 'LICENSE.txt') }
}

Write-Output "no-commit is ready."
Write-Output "SynEdit $SynCommit"
Write-Output "WebView2Loader $WvVersion"
