<#
.SYNOPSIS
  Point-and-click window for debloat.ps1. Double-click Start-Dashboard.cmd to open it.
#>
param([switch]$SelfTest)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$engine = Join-Path $PSScriptRoot 'debloat.ps1'
$script:proc = $null
$script:log  = Join-Path $env:TEMP 'win-debloat-run.txt'

$steps = @(
  @{ Key='Temp';    Text='Delete old temporary files (older than 2 days)'; On=$true },
  @{ Key='Startup'; Text='Stop chat, game and browser helper apps starting with Windows'; On=$true },
  @{ Key='Apps';    Text='Remove built-in apps you probably never use (News, Weather, Clipchamp...)'; On=$true },
  @{ Key='Power';   Text='Switch to the High performance power plan'; On=$true },
  @{ Key='Docker';  Text='Docker users: clear build cache and unused images (your data is kept)'; On=$true },
  @{ Key='Dev';     Text='Developers only: delete node_modules, .venv and .next in your Projects folder'; On=$false }
)

function New-Btn($text, $x, $y, $w, $click) {
  $b = New-Object Windows.Forms.Button; $b.Text = $text
  $b.Location = "$x,$y"; $b.Size = "$w,34"; $b.add_Click($click); $b
}

$form = New-Object Windows.Forms.Form
$form.Text = 'win-debloat | Mondcrest Automations'
$form.Size = '760,640'; $form.StartPosition = 'CenterScreen'; $form.Font = 'Segoe UI,10'

$tabs = New-Object Windows.Forms.TabControl; $tabs.Dock = 'Fill'
$t1 = New-Object Windows.Forms.TabPage 'Clean up'
$t2 = New-Object Windows.Forms.TabPage 'Manual steps'
$tabs.TabPages.AddRange(@($t1, $t2)); $form.Controls.Add($tabs)

# ---- Tab 1: Clean up ----
$intro = New-Object Windows.Forms.Label
$intro.Text = "A quality-of-life tool by Mondcrest Automations.`r`nTick what you want, press Scan to preview (nothing changes), then Clean up."
$intro.Location = '12,10'; $intro.Size = '700,44'; $t1.Controls.Add($intro)

$checks = @{}
$y = 60
foreach ($s in $steps) {
  $c = New-Object Windows.Forms.CheckBox; $c.Text = $s.Text; $c.Checked = $s.On
  $c.Location = "16,$y"; $c.Size = '700,24'; $t1.Controls.Add($c); $checks[$s.Key] = $c; $y += 28
}

$out = New-Object Windows.Forms.TextBox
$out.Multiline = $true; $out.ReadOnly = $true; $out.ScrollBars = 'Vertical'
$out.Font = 'Consolas,9'; $out.Location = '12,290'; $out.Size = '706,250'
$out.Text = 'Press Scan to see what would happen.'; $t1.Controls.Add($out)

$status = New-Object Windows.Forms.Label
$status.Location = '12,548'; $status.Size = '706,22'; $t1.Controls.Add($status)

function Selected { ($steps | Where-Object { $checks[$_.Key].Checked } | ForEach-Object { $_.Key }) -join ',' }

function Start-Run([bool]$apply) {
  $sel = Selected
  if (-not $sel) { [Windows.Forms.MessageBox]::Show('Tick at least one option.') | Out-Null; return }
  $a = "-NoProfile -ExecutionPolicy Bypass -File `"$engine`" -Only $sel"
  if ($apply) { $a += ' -Apply' }
  Remove-Item $script:log -ErrorAction SilentlyContinue
  $out.Text = 'Working...'; $scan.Enabled = $false; $clean.Enabled = $false
  $status.Text = if ($apply) { 'Cleaning up, please wait...' } else { 'Scanning (no changes)...' }
  $script:proc = Start-Process powershell -ArgumentList $a -WindowStyle Hidden -PassThru -RedirectStandardOutput $script:log
  $timer.Start()
}

$scan  = New-Btn 'Scan (safe preview)' 12 574 180 { Start-Run $false }
$clean = New-Btn 'Clean up' 204 574 160 {
  $m = "This will make the changes listed by Scan.`r`n`r`nCreate a restore point first (Manual steps tab). Continue?"
  if ($checks['Dev'].Checked) { $m = "Developer option is ticked: node_modules, .venv and .next folders will be DELETED.`r`n`r`n" + $m }
  if ([Windows.Forms.MessageBox]::Show($m, 'Confirm', 'YesNo', 'Warning') -eq 'Yes') { Start-Run $true }
}
$t1.Controls.AddRange(@($scan, $clean))

$timer = New-Object Windows.Forms.Timer; $timer.Interval = 600
$timer.add_Tick({
  try {
    $fs = [IO.File]::Open($script:log, 'Open', 'Read', 'ReadWrite')
    $txt = (New-Object IO.StreamReader $fs).ReadToEnd(); $fs.Close()
    if ($txt) { $out.Text = $txt; $out.SelectionStart = $out.Text.Length; $out.ScrollToCaret() }
  } catch {}
  if ($script:proc -and $script:proc.HasExited) {
    $timer.Stop(); $scan.Enabled = $true; $clean.Enabled = $true; $status.Text = 'Done.'
  }
})

# ---- Tab 2: Manual steps ----
$panel = New-Object Windows.Forms.FlowLayoutPanel
$panel.Dock = 'Fill'; $panel.AutoScroll = $true; $panel.FlowDirection = 'TopDown'; $panel.WrapContents = $false
$t2.Controls.Add($panel)

function Add-Step($title, $why, $btnText, $action) {
  $g = New-Object Windows.Forms.GroupBox; $g.Text = $title; $g.Size = '690,92'
  $l = New-Object Windows.Forms.Label; $l.Text = $why; $l.Location = '10,22'; $l.Size = '670,36'
  $b = New-Object Windows.Forms.Button; $b.Text = $btnText; $b.Location = '10,56'; $b.Size = '300,30'
  $b.add_Click($action.GetNewClosure()); $g.Controls.AddRange(@($l, $b)); $panel.Controls.Add($g)
}
function Copy-Cmd($t) { Set-Clipboard -Value $t; [Windows.Forms.MessageBox]::Show("Copied. Paste it into an admin PowerShell:`r`n`r`n$t") | Out-Null }

Add-Step '1. Make a restore point first' 'A safety net you can roll back to if anything goes wrong.' 'Open System Protection' { Start-Process SystemPropertiesProtection.exe }
Add-Step '2. Remove the old Windows copy (Windows.old)' 'Storage > Temporary files > tick "Previous Windows installation(s)" > Remove files. Frees 10-25 GB.' 'Open Storage settings' { Start-Process 'ms-settings:storagesense' }
Add-Step '3. Turn on Storage Sense' 'Same page: switch Storage Sense on so Windows keeps tidying itself.' 'Open Storage settings' { Start-Process 'ms-settings:storagesense' }
Add-Step '4. Shrink the Windows update store (needs admin)' 'Opens an administrator window and runs the official Microsoft cleanup. Click Yes on the prompt.' 'Run as administrator' {
  Start-Process powershell -Verb RunAs -ArgumentList '-NoExit','-Command','Dism.exe /online /Cleanup-Image /StartComponentCleanup'
}
Add-Step '5. Check startup apps yourself' 'Switch off anything you do not need at boot. Leave OneDrive and Windows Security alone.' 'Open Startup apps' { Start-Process 'ms-settings:startupapps' }
Add-Step '6. Uninstall apps you do not use' 'Sort by size and remove old browsers, launchers and tools.' 'Open Installed apps' { Start-Process 'ms-settings:appsfeatures' }
Add-Step '7. Update Windows and drivers' 'Install pending updates. For chipset and network drivers, download from your PC or motherboard maker, not "driver updater" tools.' 'Open Windows Update' { Start-Process 'ms-settings:windowsupdate' }
Add-Step '8. Docker users: shrink the disk file' 'After the Docker step, quit Docker Desktop, then run in an admin PowerShell: wsl --shutdown, then Optimize-VHD on docker_data.vhdx.' 'Copy the commands' {
  Copy-Cmd 'wsl --shutdown; Optimize-VHD -Path "$env:LOCALAPPDATA\Docker\wsl\disk\docker_data.vhdx" -Mode Full'
}
Add-Step '9. Restart your PC' 'Startup and service changes fully apply after a reboot.' 'Restart now' {
  if ([Windows.Forms.MessageBox]::Show('Restart now? Save your work first.', 'Restart', 'YesNo') -eq 'Yes') { Restart-Computer }
}

if ($SelfTest) {
  "tabs=$($tabs.TabPages.Count) checks=$($checks.Count) manual=$($panel.Controls.Count) engine=$(Test-Path $engine)"
  return
}
$form.ShowDialog() | Out-Null
