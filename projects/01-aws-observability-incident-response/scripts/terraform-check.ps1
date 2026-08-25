[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$terraformDirectory = Join-Path $PSScriptRoot "..\terraform"

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    throw "Terraform was not found in PATH. Install Terraform and try again."
}

function Invoke-TerraformCommand {
    param(
        [Parameter(Mandatory)]
        [string[]]$TerraformArguments
    )

    & terraform @TerraformArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform command failed: terraform $($TerraformArguments -join ' ')"
    }
}

Push-Location $terraformDirectory
try {
    Invoke-TerraformCommand -TerraformArguments @("fmt", "-check", "-recursive")
    Invoke-TerraformCommand -TerraformArguments @("init", "-backend=false", "-input=false")
    Invoke-TerraformCommand -TerraformArguments @("validate", "-no-color")
}
finally {
    Pop-Location
}
