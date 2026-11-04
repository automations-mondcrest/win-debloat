# win-debloat

> **A quality-of-life side project.** Built and shared by [Mondcrest Automations](https://mondcrest.com), a B2B AI agency. It is not part of our agency services.

One PowerShell script for a safe, reversible Windows 11 cleanup. **Dry run by default**: it only reports until you pass `-Apply`.

```powershell
.\debloat.ps1                         # report what it would do
.\debloat.ps1 -Apply                  # temp files, startup, apps, power plan, Docker cache
.\debloat.ps1 -Apply -Only Temp,Power # just some steps
.\debloat.ps1 -Apply -Only Dev -Root C:\code   # also delete node_modules/.venv/.next (opt-in)
```

| Step | What it does | Undo |
|---|---|---|
| Temp | Deletes `%TEMP%` items older than 2 days | n/a |
| Startup | Disables listed per-user startup apps (Task Manager method) | Task Manager > Startup apps |
| Apps | Removes listed built-in apps for the current user | Microsoft Store |
| Power | Sets High performance plan | `powercfg /setactive` |
| Docker | Prunes build cache and unused images. **Never volumes** | rebuild images |
| Dev | Deletes `node_modules`, `.venv`, `.next` under `-Root` (opt-in only) | `npm install` / recreate venv |

Edit the lists with `-StartupOff` and `-Apps`. Xbox apps are left alone on purpose.

## Not automated (needs admin, run yourself)
```powershell
Dism.exe /online /Cleanup-Image /AnalyzeComponentStore
Dism.exe /online /Cleanup-Image /StartComponentCleanup
```
Remove `Windows.old` via Settings > System > Storage > Temporary files. After Docker pruning, run `wsl --shutdown` and `Optimize-VHD` on `docker_data.vhdx` to reclaim the disk file.

## Safety
No registry hacks, no telemetry service tweaks, no remote scripts, nothing downloaded. Read `debloat.ps1` before running; it is one file. Create a restore point first.

MIT licensed.
