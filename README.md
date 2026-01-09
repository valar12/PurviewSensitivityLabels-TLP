# TLP Sensitivity Labels (Microsoft Purview)

This PowerShell script creates or updates **TLP 2.0–aligned** sensitivity labels in Microsoft Purview and applies baseline **encryption, header markings, and Sites & Groups defaults**.  
It is **idempotent** (safe to re-run) and supports **Retail (Commercial/GCC)** and **US Gov (GCC High / DoD)** environments.

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
