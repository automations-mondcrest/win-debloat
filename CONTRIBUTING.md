# Contributing

Keep it small and safe: dry run stays the default, nothing is downloaded, nothing needs a third-party module.

1. Fork, branch, change `debloat.ps1` or `dashboard.ps1`.
2. Run `.\debloat.ps1` (dry run) and `powershell -STA -File .\dashboard.ps1 -SelfTest` before opening a pull request.
3. New cleanup steps must be reversible or opt-in, and must be listed in the README table.

A Mondcrest Automations quality-of-life project.
