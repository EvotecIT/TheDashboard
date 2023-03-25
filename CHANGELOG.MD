### 0.0.10 - 2023.03.25
- Allow new way to define the dashboard using `New-Dashboard*` cmdlets
- Better handling of naming when not doing replacements
- Rearranged some code to make it work nicer
- Added some more output

### 0.0.9 - 2022.12.19
- Fixes ordering of reports in menu - should be alphabetical from now on
- Improves performance of report generation by generating only new reports and not all reports
  - Using the `-Force` flag will generate all reports. Keep in mind it can take very long time to generate all reports in some environments