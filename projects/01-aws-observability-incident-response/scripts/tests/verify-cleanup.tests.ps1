# Offline tests. No AWS executable, credentials, or resources are used.
$ErrorActionPreference = "Stop"
$verifier = Join-Path $PSScriptRoot "../verify-cleanup.ps1"
$mockState = @{ Scenario = "clean"; Calls = 0 }

function Mock-PortfolioAws {
    $mockState.Calls++
    $global:LASTEXITCODE = 0
    if ($args[0] -eq "sts") {
        $arn = "arn:aws:sts::111122223333:assumed-role/aws-portfolio-deployer/offline-test"
        if ($mockState.Scenario -eq "wrong_identity") { $arn = "arn:aws:iam::111122223333:root" }
        return (@{ Arn = $arn } | ConvertTo-Json)
    }
    if ($args[1] -eq "describe-alarm-history") {
        if ($mockState.Scenario -eq "missing_history") { return '{}' }
        return '{"AlarmHistoryItems":[]}'
    }
    if ($mockState.Scenario -eq "access_denied") {
        $global:LASTEXITCODE = 1
        return '{}'
    }
    if ($mockState.Scenario -eq "invalid_count") { return 'null' }
    if ($mockState.Scenario -eq "resources_remain" -and $args[1] -eq "describe-instances") { return '1' }
    return '0'
}

$cases = @(
    @{ Name = "clean"; ExpectedError = $null },
    @{ Name = "wrong_identity"; ExpectedError = "Expected the assumed role" },
    @{ Name = "access_denied"; ExpectedError = "AWS read failed" },
    @{ Name = "missing_history"; ExpectedError = "missing AlarmHistoryItems" },
    @{ Name = "invalid_count"; ExpectedError = "Expected a numeric count" },
    @{ Name = "resources_remain"; ExpectedError = "Project resources remain" }
)

foreach ($case in $cases) {
    $mockState.Scenario = $case.Name
    $mockState.Calls = 0
    $failure = $null
    $result = $null
    try {
        $result = & $verifier -AwsCommand Mock-PortfolioAws
    }
    catch {
        $failure = $_.Exception.Message
    }
    if ($null -eq $case.ExpectedError) {
        if ($failure) { throw "Clean scenario failed: $failure" }
        $summary = $result | ConvertFrom-Json
        if (-not $summary.DeploymentRoleVerified -or -not $summary.AlarmHistoryReadSucceeded) {
            throw "Clean scenario did not report successful identity and history checks."
        }
        if ($mockState.Calls -ne 12) { throw "Expected all 12 reads, received $($mockState.Calls)." }
    }
    elseif (-not $failure -or -not $failure.Contains($case.ExpectedError)) {
        throw "Scenario $($case.Name) did not fail as expected: $failure"
    }
    if ($case.Name -eq "wrong_identity" -and $mockState.Calls -ne 1) {
        throw "Inventory was read before the deployment role was verified."
    }
    Write-Output "PASS: $($case.Name)"
}
Write-Output "Six offline cleanup-verifier scenarios passed."
