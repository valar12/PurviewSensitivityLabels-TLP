# Usage Guide

This page provides practical usage examples for `Create-Purview-SensitivityLabels-TLP2.0` and testing guidance.

## Prerequisites

- PowerShell running as Administrator.
- `ExchangeOnlineManagement` installed.
- Permissions to manage Microsoft Purview sensitivity labels.
- A valid configuration JSON (default: `TlpLabelConfig.json`).

## Basic execution

### 1) Apply labels with default config (Retail)

```powershell
.\Create-Purview-SensitivityLabels-TLP2.0 -TenantPrimaryDomain "contoso.com"
```

### 2) Apply labels in GCC High

```powershell
.\Create-Purview-SensitivityLabels-TLP2.0 `
  -TenantPrimaryDomain "contoso.com" `
  -CloudEnvironment USGovGCCHigh
```

### 3) Apply labels in DoD

```powershell
.\Create-Purview-SensitivityLabels-TLP2.0 `
  -TenantPrimaryDomain "contoso.com" `
  -CloudEnvironment USGovDoD
```

### 4) Use a custom JSON configuration file

```powershell
.\Create-Purview-SensitivityLabels-TLP2.0 `
  -TenantPrimaryDomain "contoso.com" `
  -ConfigurationPath ".\Configs\TlpLabelConfig-Prod.json"
```

## Drift detection and CI gating

### 5) Dry-run (no changes applied)

```powershell
.\Create-Purview-SensitivityLabels-TLP2.0 `
  -TenantPrimaryDomain "contoso.com" `
  -DryRun
```

### 6) Dry-run with fail-on-drift (CI/CD safe gate)

```powershell
.\Create-Purview-SensitivityLabels-TLP2.0 `
  -TenantPrimaryDomain "contoso.com" `
  -DryRun `
  -FailOnDrift
```

If drift exists, the script throws and can fail the pipeline.

## Output artifacts

Every run writes:

- `TlpLabelExecutionReport.json`

This report includes:

- UTC timestamp
- cloud environment
- configuration version
- changed labels
- unchanged labels
- failed labels

## Post-run verification examples

### Verify external label

```powershell
Get-Label -Identity "Confidential – External" |
  Format-List Name,Priority,EncryptionEnabled,EncryptionRightsDefinitions,ApplyContentMarkingHeaderText
```

### Verify internal label

```powershell
Get-Label -Identity "Confidential – Internal" |
  Format-List Name,Priority,EncryptionEnabled,EncryptionRightsDefinitions,SiteAndGroupProtectionPrivacy,SiteExternalSharingControlType
```

### Verify view-only label

```powershell
Get-Label -Identity "Confidential – View Only" |
  Format-List Name,Priority,EncryptionEnabled,EncryptionRightsDefinitions,ApplyContentMarkingHeaderText
```

## Testing guidance

## 1) Static checks (offline)

Run PowerShell script analysis:

```powershell
Invoke-ScriptAnalyzer -Path .\Create-Purview-SensitivityLabels-TLP2.0
Invoke-ScriptAnalyzer -Path .\TlpLabelModule.ps1
```

Validate JSON parses cleanly:

```powershell
Get-Content .\TlpLabelConfig.json -Raw | ConvertFrom-Json | Out-Null
```

## 2) Unit tests with Pester (recommended)

Create tests that mock:

- `Get-Label`
- `Set-Label`
- `New-Label`
- `Connect-IPPSSession`

Key test cases:

- config schema rejection for invalid values
- dry-run reports drift without calling `Set-Label`
- `-FailOnDrift` throws when drift exists
- retry logic retries transient failures
- validation fails when expected properties are not applied

## 3) Integration test flow (tenant)

1. Run dry-run in a non-production tenant.
2. Review `TlpLabelExecutionReport.json`.
3. Apply changes.
4. Run dry-run again and confirm no drift.
5. Validate labels with `Get-Label` spot checks.

