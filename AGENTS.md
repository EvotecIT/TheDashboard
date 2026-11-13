# TheDashboard

PowerShell module that builds one HTML dashboard over HTML reports produced by
other tools (Testimo, ADEssentials, GPOZaurr, PingCastle and similar), with
menus, report history, gauges, retention limits and SharePoint-friendly repair.

## Layout

- `Public/`: exported functions (`Start-TheDashboard`, `New-Dashboard*`,
  `Repair-Dashboard*`), one per file.
- `Private/`: internal helpers, one per file.
- `TheDashboard.psd1` / `TheDashboard.psm1`: source manifest and loader that
  dot-sources `Public/` and `Private/`.
- `Tests/`: Pester 5 generation tests. `Tests/Fixtures/` holds test helpers.
- `Build/Manage-TheDashboard.ps1`: manifest check, build and publish through PSPublishModule.
- `Examples/`: usage scripts. `Data/`: README screenshots.

## Build and test

```powershell
./Tests/Invoke-GenerationTests.ps1                                  # Pester suite against the source module
./Build/Manage-TheDashboard.ps1 -ConfigurationGateMode Manifest     # validate the manifest
./Build/Manage-TheDashboard.ps1 -ConfigurationGateMode Build -SignModule $false
```

- Tests need Pester 5.7.1+, PSWriteColor 1.0.3, PSSharedGoods 0.0.313 and
  PSWriteHTML 1.41.0 (the versions CI installs). The source module relies on
  PSWriteColor's logging helpers, which the build merges into the package.
- CI runs the suite on Windows in both Windows PowerShell 5.1 and PowerShell 7.
- Release-only: `-ConfigurationGateMode Publish` signs and publishes to the
  PowerShell Gallery and GitHub.

## Generated files

The build merges `Public/` and `Private/` plus functions from approved modules
(PSSharedGoods, PSWriteColor) into the packaged module and rewrites
`FunctionsToExport` in `TheDashboard.psd1`. Add a public function by adding a
file under `Public/`; don't hand-maintain the export list.

## Conventions

- Support Windows PowerShell 5.1 and PowerShell 7 (`CompatiblePSEditions`
  Desktop and Core). No PowerShell 7-only syntax.
- K&R/OTBS braces, full parameter names, comment-based help inside the function.
- Report identity is the original filename before naming replacements. A
  trailing `_yyyy-MM-dd_HHmmss`, `_yyyy-MM-dd_HH_mm_ss` or `_yyyy-MM-dd-HHmmss`
  marks a version of the same report; naming rules change labels only and never
  merge independent reports. Keep README examples in step with this behaviour.

## Gotchas

- Generation tests write report fixtures under Pester `TestDrive:`.
  Don't point them, or `Examples/`, at real report shares.
