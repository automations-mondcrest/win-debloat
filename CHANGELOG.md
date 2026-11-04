# Changelog

## 1.0.2 - 2026-11-04
- Docs: now verified on a Windows 11 PC and a Windows 10 laptop (about 20 GB freed on the laptop). The restore point warning is unchanged.

## 1.0.1 - 2026-11-04
- Added a prominent System Restore point warning to the README and the dashboard. Documented that it is tested on one Windows 11 PC.

## 1.0.0 - 2026-11-04
- `debloat.ps1`: dry-run-by-default cleanup (temp files, startup entries, built-in apps, power plan, Docker cache, opt-in dev folders).
- `dashboard.ps1` + `Start-Dashboard.cmd`: point-and-click window with a Manual steps tab.
- Fixed: comma-list `-Only` via `powershell -File`; already-disabled startup entries no longer listed; dashboard buttons always visible; scan output line breaks.
