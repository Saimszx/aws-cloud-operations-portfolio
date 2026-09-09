[CmdletBinding()]
param(
    [string]$Profile = "aws-portfolio-deployer",
    [string]$AwsCommand = "aws"
)

# Read-only verification for the lab's fixed Region and default environment.
# A failed AWS call must never be interpreted as an empty resource inventory.
$ErrorActionPreference = "Stop"
$region = "us-east-2"
$project = "aws-observability-incident-response"
$prefix = "$project-lab"

function Invoke-PortfolioRead {
    param([string[]]$Arguments)

    $result = & $AwsCommand @Arguments --profile $Profile --region $region --output json --no-cli-pager
    if ($LASTEXITCODE -ne 0) {
        throw "AWS read failed: $($Arguments[0]) $($Arguments[1]). Verify the IAM login and role permissions, then retry."
    }
    if (-not $result) {
        throw "AWS returned no JSON for $($Arguments[0]) $($Arguments[1])."
    }
    return (($result -join "`n") | ConvertFrom-Json)
}

$identity = Invoke-PortfolioRead -Arguments @("sts", "get-caller-identity")
if ($identity.Arn -notmatch '^arn:aws:sts::[0-9]{12}:assumed-role/aws-portfolio-deployer/[^/]+$') {
    throw "Expected the assumed role aws-portfolio-deployer. No inventory checks were run."
}

# Success proves the read permission. Zero history records does not prove that
# a past alarm action or email delivery succeeded.
$history = Invoke-PortfolioRead -Arguments @(
    "cloudwatch", "describe-alarm-history", "--alarm-name", "$prefix-high-cpu"
)
if ($null -eq $history.AlarmHistoryItems) {
    throw "Alarm-history response is missing AlarmHistoryItems."
}

$tagFilters = @("--filters", "Name=tag:Project,Values=$project", "Name=tag:Environment,Values=lab")
$checks = @(
    @{ Name = "ActiveInstances"; Args = @("ec2", "describe-instances") + $tagFilters + @("Name=instance-state-name,Values=pending,running,shutting-down,stopping,stopped", "--query", "length(Reservations[].Instances[])") },
    @{ Name = "Vpcs"; Args = @("ec2", "describe-vpcs") + $tagFilters + @("--query", "length(Vpcs)") },
    @{ Name = "Subnets"; Args = @("ec2", "describe-subnets") + $tagFilters + @("--query", "length(Subnets)") },
    @{ Name = "InternetGateways"; Args = @("ec2", "describe-internet-gateways") + $tagFilters + @("--query", "length(InternetGateways)") },
    @{ Name = "RouteTables"; Args = @("ec2", "describe-route-tables") + $tagFilters + @("--query", "length(RouteTables)") },
    @{ Name = "SecurityGroups"; Args = @("ec2", "describe-security-groups") + $tagFilters + @("--query", "length(SecurityGroups)") },
    @{ Name = "RootVolumes"; Args = @("ec2", "describe-volumes", "--filters", "Name=tag:Name,Values=$prefix-root-volume", "--query", "length(Volumes)") },
    @{ Name = "LogGroups"; Args = @("logs", "describe-log-groups", "--log-group-name-prefix", "/portfolio/cloudops/lab/", "--query", "length(logGroups)") },
    @{ Name = "MetricAlarms"; Args = @("cloudwatch", "describe-alarms", "--alarm-name-prefix", "$prefix-", "--query", "length(MetricAlarms)") },
    @{ Name = "Dashboards"; Args = @("cloudwatch", "list-dashboards", "--dashboard-name-prefix", "$prefix-", "--query", "length(DashboardEntries)") }
)

$counts = [ordered]@{}
foreach ($check in $checks) {
    $count = Invoke-PortfolioRead -Arguments $check.Args
    if ($count -isnot [long] -and $count -isnot [int]) {
        throw "Expected a numeric count for $($check.Name)."
    }
    if ($count -lt 0) {
        throw "Invalid negative resource count for $($check.Name)."
    }
    $counts[$check.Name] = $count
}

[ordered]@{
    CheckedAtUtc = [DateTimeOffset]::UtcNow.ToString("o")
    Region = $region
    Environment = "lab"
    DeploymentRoleVerified = $true
    AlarmHistoryReadSucceeded = $true
    ResourceCounts = $counts
    Scope = "Tagged lab compute/network resources and named log groups, metric alarms, and dashboards. SNS and IAM resources require separate checks."
} | ConvertTo-Json -Depth 4

if (@($counts.Values | Where-Object { $_ -ne 0 }).Count -gt 0) {
    throw "Project resources remain. Review the counts and Terraform state; this script does not delete anything."
}
