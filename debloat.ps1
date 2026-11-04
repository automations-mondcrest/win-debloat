<#
.SYNOPSIS
  Safe, reversible Windows 11 cleanup. Dry run by default: nothing changes without -Apply.
.EXAMPLE
  .\debloat.ps1                      # report only
  .\debloat.ps1 -Apply               # run all safe steps
  .\debloat.ps1 -Apply -Only Temp,Startup
  .\debloat.ps1 -Apply -DevCaches -Root C:\Users\me\Projects
#>
[CmdletBinding()]
param(
  [switch]$Apply,
  [string[]]$Only,  # Temp,Startup,Apps,Power,Docker,Dev (comma list also works via powershell -File)
  [string[]]$StartupOff = @('Teams','Discord','Steam','Spotify','Opera GX Stable','Opera GX Browser Assistant','BraveSoftware Update','RobloxPlayerBeta','Microsoft.Lists','Docker Desktop','OneDriveSetup'),
  [string[]]$Apps = @('Microsoft.BingNews','Microsoft.BingWeather','Microsoft.BingSearch','Clipchamp.Clipchamp','Microsoft.Todos','Microsoft.ZuneMusic','Microsoft.ZuneVideo','Microsoft.People','Microsoft.WindowsMaps','Microsoft.MixedReality.Portal','Microsoft.PowerAutomateDesktop','Microsoft.MicrosoftOfficeHub','Microsoft.GetHelp','Microsoft.WindowsFeedbackHub','Microsoft.WidgetsPlatformRuntime','Microsoft.YourPhone','MSTeams'),
  [int]$TempDays = 2,
  [string]$Root = (Join-Path $env:USERPROFILE 'Projects')  # where -Only Dev looks for node_modules/.venv/.next
)
# ponytail: Xbox apps are left alone on purpose (Minecraft/Game Pass sign-in needs them).
# ponytail: Docker volumes are never pruned. Only build cache + unused images.

if ($Only) {
  $Only = $Only -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  $bad = $Only | Where-Object { 'Temp','Startup','Apps','Power','Docker','Dev' -notcontains $_ }
  if ($bad) { throw "Unknown step(s): $($bad -join ', '). Valid: Temp,Startup,Apps,Power,Docker,Dev" }
}
$on = { param($s) (-not $Only) -or ($Only -contains $s) }
$mode = if ($Apply) { 'APPLY' } else { 'DRY RUN' }
$freeBefore = (Get-PSDrive C).Free
function Step($t) { Write-Host "`n== $t [$mode]" -ForegroundColor Cyan }
function GB($b) { [math]::Round($b / 1GB, 2) }
function Size($p) { (Get-ChildItem $p -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum }

if (& $on 'Temp') {
  Step "Temp files older than $TempDays days"
  $cut = (Get-Date).AddDays(-$TempDays)
  $old = Get-ChildItem $env:TEMP -Force -ErrorAction SilentlyContinue | Where-Object LastWriteTime -lt $cut
  $bytes = ($old | ForEach-Object { if ($_.PSIsContainer) { Size $_.FullName } else { $_.Length } } | Measure-Object -Sum).Sum
  "{0} items, {1} GB" -f @($old).Count, (GB $bytes)
  if ($Apply) { $old | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
}

if (& $on 'Startup') {
  Step 'Startup entries (disabled the same way Task Manager does; re-enable there)'
  $disabled = [byte[]](3,0,0,0,0,0,0,0,0,0,0,0)
  $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
  $sa  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
  $have = (Get-ItemProperty $run).PSObject.Properties.Name
  $state = Get-ItemProperty $sa -ErrorAction SilentlyContinue
  foreach ($n in $have) {
    $already = $state -and $state.$n -and ($state.$n[0] -in 1,3,7)  # odd first byte = disabled
    if (-not $already -and ($StartupOff -contains $n -or $n -like 'MicrosoftEdgeAutoLaunch*')) {
      "would disable: $n"
      if ($Apply) { Set-ItemProperty $sa -Name $n -Value $disabled -Type Binary }
    }
  }
}

if (& $on 'Apps') {
  Step 'Built-in apps (current user only; Store can reinstall)'
  foreach ($a in $Apps) {
    $p = Get-AppxPackage -Name $a -ErrorAction SilentlyContinue
    if ($p) { "would remove: $a"; if ($Apply) { $p | Remove-AppxPackage -ErrorAction SilentlyContinue } }
  }
}

if (& $on 'Power') {
  Step 'Power plan -> High performance'
  $hp = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
  powercfg /getactivescheme
  if ($Apply) { powercfg /setactive $hp }
}

if ((& $on 'Docker') -and (Get-Command docker -ErrorAction SilentlyContinue)) {
  Step 'Docker build cache + unused images (volumes untouched)'
  docker system df 2>$null
  if ($Apply) { docker builder prune -a -f 2>$null; docker image prune -a -f 2>$null }
}

if ($Only -contains 'Dev') {  # opt-in: deletes rebuildable dev folders
  Step "Rebuildable dev folders under $Root"
  Get-ChildItem $Root -Recurse -Directory -Force -Include node_modules,.venv,.next -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch 'node_modules\\.+\\node_modules' } | ForEach-Object {
      "{0,6} GB  {1}" -f (GB (Size $_.FullName)), $_.FullName
      if ($Apply) { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Write-Host "`nFree on C: before $(GB $freeBefore) GB, now $(GB (Get-PSDrive C).Free) GB" -ForegroundColor Green
if (-not $Apply) { Write-Host 'Dry run only. Re-run with -Apply to make changes.' }
