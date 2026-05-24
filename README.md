# TLP Sensitivity Labels (Microsoft Purview)

**Current release:** `v1.2.0` (2026-05-24)

This PowerShell script creates or updates **TLP 2.0–aligned** sensitivity labels in Microsoft Purview and applies baseline **encryption, header markings, and Sites & Groups defaults**.  
It is **idempotent** (safe to re-run), includes post-change validation checks, and supports **Retail (Commercial/GCC)** and **US Gov (GCC High / DoD)** environments.

TLP reference: https://www.cisa.gov/tlp

---

## What it creates

Labels (with priority order):

- `Public` — TLP:CLEAR  
- `General` — TLP:GREEN  
- `Confidential – External` — TLP:AMBER  
- `Confidential – Internal` — TLP:AMBER+STRICT  
- `Confidential – View Only` — TLP:RED  

### Protections
- **Confidential – Ext**: Encrypted, broad rights for `AuthenticatedUsers`, header marking.
- **Confidential – Int**: Encrypted, rights scoped to tenant primary domain, header marking.
- **Confidential – View Only**: Encrypted, `VIEW` only, header marking.

### Validation behavior
- Script fails fast (`$ErrorActionPreference = Stop`) when a label action fails.
- Script validates key encryption/header settings after applying labels to catch drift or unsupported parameter behavior early.

### Modular structure
- `Create-Purview-SensitivityLabels-TLP2.0`: orchestration entrypoint.
- `TlpLabelModule.ps1`: reusable helper functions for session connection, label updates, and configuration assertions.
- `TlpLabelConfig.json`: JSON-driven customization for defaults, labels, encryption, container settings, and validation.

### JSON customizations
- By default, the script reads `TlpLabelConfig.json` from the script directory.
- You can provide a different file path with `-ConfigurationPath`.
- Configuration metadata supports governance fields: `ConfigVersion`, `Owner`, `LastReviewed`, and `ChangeTicket`.

### Drift detection and dry-run
- Use `-DryRun` to compare desired state from JSON against tenant labels without applying changes.
- Use `-DryRun -FailOnDrift` in automation pipelines to fail fast when drift is detected.
- Each run writes `TlpLabelExecutionReport.json` with changed/unchanged/failed labels.

### Prerequisite checks
- Script performs prechecks for required Purview cmdlets (`Get-Label`, `Set-Label`, `New-Label`) after connecting.

### Post-run live verification (operator playbook)
- `Get-Label -Identity "Confidential – External" | Format-List Name,Priority,EncryptionEnabled,EncryptionRightsDefinitions,ApplyContentMarkingHeaderText`
- `Get-Label -Identity "Confidential – Internal" | Format-List Name,Priority,EncryptionEnabled,EncryptionRightsDefinitions,SiteAndGroupProtectionPrivacy,SiteExternalSharingControlType`
- `Get-Label -Identity "Confidential – View Only" | Format-List Name,Priority,EncryptionEnabled,EncryptionRightsDefinitions,ApplyContentMarkingHeaderText`

### CI quality checks (recommended)
- Validate JSON format and required fields before deployment.
- Run `PSScriptAnalyzer` on the script/module.
- Add Pester tests with mocked `Get-Label` / `Set-Label` / `New-Label` to validate logic paths offline.

### Usage examples and testing
- See `USAGE.md` for end-to-end examples (Retail/GCC High/DoD/custom config), dry-run/CI drift-gating patterns, and testing guidance.

### Containers (Sites & Groups)
- `Public`: Public, guests allowed, external + guest sharing.
- `General`: Guests allowed, external users only.
- `Confidential – External`: Private, guests allowed, external users only.
- `Confidential – Internal`: Private, no guests, sharing disabled.
- `Confidential – View Only`: No container settings applied.

---

### Requirements

- PowerShell (run **as Administrator**)
- `ExchangeOnlineManagement` module
- Purview / Compliance admin permissions


### What it does not do is prepare the tenant
This guy did it better

https://github.com/GarthVDW/M365-Purview-DLP-Enable-Sensitivity-Labels

Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell
