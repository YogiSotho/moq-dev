param(
	[string]$Command = 'just ci',
	[switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$repoRootWindows = $repoRoot.ProviderPath
$repoRootForWsl = $repoRootWindows.Replace('\', '/')

$wslPath = & wsl.exe wslpath -a $repoRootForWsl
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($wslPath)) {
	throw "Failed to convert repository path for WSL: $repoRootWindows"
}

$escapedRepoRoot = $wslPath.Trim().Replace("'", "'\''")
$workspaceCleanup = "find . -mindepth 2 -maxdepth 3 -type d -name node_modules -not -path './node_modules' -prune -exec rm -rf {} +"
$escapedCommand = $Command.Replace("'", "'\''")
$nixCommand = "nix --extra-experimental-features 'nix-command flakes' develop --command"
$wslCommand = @(
	"cd '$escapedRepoRoot' &&"
	$workspaceCleanup + ' &&'
	'if BUN_BIN=$(command -v bun 2>/dev/null); then'
	('  ' + $nixCommand + ' env PATH="$(dirname "$BUN_BIN"):$PATH" bash -lc ' + "'$escapedCommand'")
	'else'
	('  ' + $nixCommand + ' bash -lc ' + "'$escapedCommand'")
	'fi'
) -join "`n"

Write-Host "Running pre-push checks in WSL from $wslPath"
Write-Host "Command: $Command"

if ($DryRun) {
	Write-Host 'Dry run only. Skipping execution.'
	exit 0
}

& wsl.exe bash -lc $wslCommand
exit $LASTEXITCODEparam(
	[string]$Command = 'just ci',
	[switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$repoRootWindows = $repoRoot.ProviderPath
$repoRootForWsl = $repoRootWindows.Replace('\', '/')

$wslPath = & wsl.exe wslpath -a $repoRootForWsl
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($wslPath)) {
	throw "Failed to convert repository path for WSL: $repoRootWindows"
}

$escapedRepoRoot = $wslPath.Trim().Replace("'", "'\''")
$workspaceCleanup = "find . -mindepth 2 -maxdepth 3 -type d -name node_modules -not -path './node_modules' -prune -exec rm -rf {} +"
$escapedCommand = $Command.Replace("'", "'\''")
$nixCommand = "nix --extra-experimental-features 'nix-command flakes' develop --command"
$wslCommand = @(
	"cd '$escapedRepoRoot' &&"
	$workspaceCleanup + ' &&'
	'if BUN_BIN=$(command -v bun 2>/dev/null); then'
	('  ' + $nixCommand + ' env PATH="$(dirname "$BUN_BIN"):$PATH" bash -lc ' + "'$escapedCommand'")
	'else'
	('  ' + $nixCommand + ' bash -lc ' + "'$escapedCommand'")
	'fi'
) -join "`n"

Write-Host "Running pre-push checks in WSL from $wslPath"
Write-Host "Command: $Command"

if ($DryRun) {
	Write-Host 'Dry run only. Skipping execution.'
	exit 0
}

& wsl.exe bash -lc $wslCommand
exit $LASTEXITCODE