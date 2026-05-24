Set-StrictMode -Version Latest

function Invoke-WithRetry {
  param(
    [Parameter(Mandatory=$true)][scriptblock]$Action,
    [int]$MaxAttempts = 3,
    [int]$BaseDelaySeconds = 2
  )

  for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    try {
      return & $Action
    } catch {
      if ($attempt -ge $MaxAttempts) { throw }
      Start-Sleep -Seconds ($BaseDelaySeconds * $attempt)
    }
  }
}

function Get-TlpConfiguration {
  param(
    [Parameter(Mandatory=$true)][string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Configuration file not found: $Path"
  }

  $config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 20
  if (-not $config.Labels -or -not $config.Defaults) {
    throw "Configuration file must contain 'Defaults' and 'Labels' objects."
  }
  if (-not $config.ConfigVersion -or -not $config.Owner) {
    throw "Configuration file must contain ConfigVersion and Owner metadata."
  }

  $principalTypes = @("AuthenticatedUsers","TenantDomain","Literal")
  $privacyValues = @("Public","Private","Unspecified")
  $sharingValues = @("ExternalUserAndGuestSharing","ExternalUserSharingOnly","Disabled")
  foreach ($label in $config.Labels) {
    if (-not $label.Name -or $null -eq $label.Priority -or -not $label.Tooltip -or -not $label.Comment) {
      throw "Each label requires Name, Priority, Tooltip, and Comment."
    }
    if ($label.Encryption) {
      if ($principalTypes -notcontains $label.Encryption.PrincipalType) {
        throw "Unsupported PrincipalType '$($label.Encryption.PrincipalType)' on label '$($label.Name)'."
      }
      if ($label.Encryption.PrincipalType -eq "Literal" -and -not $label.Encryption.RightsDefinitions) {
        throw "Label '$($label.Name)' uses Literal principal but lacks RightsDefinitions."
      }
    }
    if ($label.Container -and $label.Container.Enabled) {
      if ($privacyValues -notcontains [string]$label.Container.Privacy) {
        throw "Unsupported Container.Privacy '$($label.Container.Privacy)' on label '$($label.Name)'."
      }
      if ($sharingValues -notcontains [string]$label.Container.ExternalSharing) {
        throw "Unsupported Container.ExternalSharing '$($label.Container.ExternalSharing)' on label '$($label.Name)'."
      }
    }
  }

  return $config
}

function Connect-TlpPurviewSession {
  param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Retail","USGovGCCHigh","USGovDoD")]
    [string]$CloudEnvironment
  )

  switch ($CloudEnvironment) {
    "Retail" {
      $sessionParams = @{
        ShowBanner = $false
      }
      Connect-IPPSSession @sessionParams
    }
    "USGovGCCHigh" {
      $sessionParams = @{
        ShowBanner = $false
        ConnectionUri = "https://ps.compliance.protection.office365.us/powershell-liveid/"
        AzureADAuthorizationEndpointUri = "https://login.microsoftonline.us/organizations"
      }
      Connect-IPPSSession @sessionParams
    }
    "USGovDoD" {
      $sessionParams = @{
        ShowBanner = $false
        ConnectionUri = "https://l5.ps.compliance.protection.office365.us/powershell-liveid/"
        AzureADAuthorizationEndpointUri = "https://login.microsoftonline.us/organizations"
      }
      Connect-IPPSSession @sessionParams
    }
  }
}

function Test-TlpPrerequisites {
  $requiredCommands = @("Get-Label","Set-Label","New-Label")
  foreach ($commandName in $requiredCommands) {
    if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
      throw "Missing required command '$commandName'. Ensure ExchangeOnlineManagement and Purview cmdlets are available."
    }
  }
}

function Invoke-LabelSet {
  param(
    [Parameter(Mandatory=$true)][string]$LabelName,
    [Parameter(Mandatory=$true)][hashtable]$Parameters
  )

  try {
    Invoke-WithRetry -Action { Set-Label -Identity $LabelName @Parameters | Out-Null }
  } catch {
    throw "Failed to configure label '$LabelName': $($_.Exception.Message)"
  }
}

function Assert-LabelConfiguration {
  param(
    [Parameter(Mandatory=$true)][string]$LabelName,
    [Parameter(Mandatory=$true)][hashtable]$Expected
  )

  $label = Invoke-WithRetry -Action { Get-Label -Identity $LabelName -ErrorAction Stop }
  foreach ($k in $Expected.Keys) {
    if ("$($label.$k)" -ne "$($Expected[$k])") {
      throw "Validation failed for '$LabelName': expected $k='$($Expected[$k])' but found '$($label.$k)'."
    }
  }
}

function New-OrUpdateTlpLabel {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Tooltip,
    [Parameter(Mandatory=$true)][string]$Comment,
    [Parameter(Mandatory=$true)][int]$Priority,
    [string]$ColorHex = $null
  )

  $adv = @{}
  if ($ColorHex) { $adv["Color"] = $ColorHex }

  $existing = Invoke-WithRetry -Action { Get-Label -Identity $Name -ErrorAction SilentlyContinue }
  if (-not $existing) {
    if ($adv.Count -gt 0) {
      Invoke-WithRetry -Action { New-Label -Name $Name -DisplayName $Name -Tooltip $Tooltip -Comment $Comment -AdvancedSettings $adv | Out-Null }
    } else {
      Invoke-WithRetry -Action { New-Label -Name $Name -DisplayName $Name -Tooltip $Tooltip -Comment $Comment | Out-Null }
    }
  } else {
    if ($adv.Count -gt 0) {
      Invoke-WithRetry -Action { Set-Label -Identity $Name -Tooltip $Tooltip -Comment $Comment -AdvancedSettings $adv | Out-Null }
    } else {
      Invoke-WithRetry -Action { Set-Label -Identity $Name -Tooltip $Tooltip -Comment $Comment | Out-Null }
    }
  }

  Invoke-WithRetry -Action { Set-Label -Identity $Name -Priority $Priority | Out-Null }
}
