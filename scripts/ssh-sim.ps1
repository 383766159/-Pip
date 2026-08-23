param(
    [Parameter(Mandatory = $true)]
    [string]$MacHost,

    [string]$MacUser = $env:USERNAME,

    [string]$RepoPath = "~/Pip",

    [ValidateSet("run", "test", "shot")]
    [string]$Action = "run",

    [switch]$SkipPull
)

$ErrorActionPreference = "Stop"

$script = switch ($Action) {
    "run" { "scripts/sim-run.sh" }
    "test" { "scripts/sim-test.sh" }
    "shot" { "scripts/sim-shot.sh" }
}

$prefix = ""
if ($SkipPull) {
    $prefix = "PIP_SKIP_PULL=1 "
}

$remote = "${MacUser}@${MacHost}"
$command = "cd $RepoPath && ${prefix}bash $script"
Write-Host "ssh $remote `"$command`""
ssh $remote "$command"
