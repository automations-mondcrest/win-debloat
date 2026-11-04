# Changelog

## 1.0.0 - 2026-11-04
- `debloat.ps1`: dry-run-by-default cleanup (temp files, startup entries, built-in apps, power plan, Docker cache, opt-in dev folders).
- `dashboard.ps1` + `Start-Dashboard.cmd`: point-and-click window with a Manual steps tab.
- Fixed: comma-list `-Only` via `powershell -File`; already-disabled startup entries no longer listed; dashboard buttons always visible; scan output line breaks.
