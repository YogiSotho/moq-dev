param(
    [string]$RelayUrl = 'http://localhost:4443/anon',
    [string]$Broadcast = 'bbb',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

function Assert-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found in PATH: $Name"
    }
}

function Start-DemoTerminal {
    param(
        [string]$Title,
        [string]$WorkingDirectory,
        [string]$Command
    )

    $shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        'pwsh'
    } else {
        'powershell'
    }

    $fullCommand = "Set-Location -LiteralPath '$WorkingDirectory'; `$Host.UI.RawUI.WindowTitle = 'moq demo - $Title'; $Command"

    if ($WhatIf) {
        Write-Host "Would launch $Title in $WorkingDirectory"
        Write-Host "  $fullCommand"
        return
    }

    Start-Process -FilePath $shell -WorkingDirectory $WorkingDirectory -ArgumentList @(
        '-NoExit'
        '-Command'
        $fullCommand
    ) | Out-Null
}

function Wait-ForUrl {
    param(
        [string]$Url,
        [int]$TimeoutSeconds = 120
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            Invoke-WebRequest -Uri $Url -UseBasicParsing | Out-Null
            return
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }

    throw "Timed out waiting for $Url"
}

$root = Split-Path -Parent $PSScriptRoot
$relayDir = Join-Path $PSScriptRoot 'relay'
$pubDir = Join-Path $PSScriptRoot 'pub'
$webDir = Join-Path $PSScriptRoot 'web'
$pubMediaDir = Join-Path $pubDir 'media'
$mediaFile = Join-Path $pubMediaDir "$Broadcast.mp4"
$certificateUrl = 'http://localhost:4443/certificate.sha256'

Assert-Command cargo
Assert-Command bun
Assert-Command ffmpeg

if (-not (Test-Path $pubMediaDir)) {
    New-Item -ItemType Directory -Path $pubMediaDir | Out-Null
}

if (-not (Test-Path $mediaFile)) {
    $downloadUrl = "https://vid.moq.dev/$Broadcast.mp4"
    if ($WhatIf) {
        Write-Host "Would download demo media: $downloadUrl"
    } else {
        Write-Host "Downloading demo media: $downloadUrl"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $mediaFile
    }
}

Start-DemoTerminal -Title 'relay' -WorkingDirectory $relayDir -Command 'cargo run --bin moq-relay -- localhost.toml'

if (-not $WhatIf) {
    Write-Host 'Waiting for relay certificate endpoint...'
    Wait-ForUrl -Url $certificateUrl
}

$publisherCommand = @(
    'cargo build --bin moq-cli'
    "ffmpeg -hide_banner -v quiet -stream_loop -1 -re -i '$mediaFile' -c copy -f mp4 -movflags cmaf+separate_moof+delay_moov+skip_trailer+frag_every_frame - | cargo run --bin moq-cli -- publish --url '$RelayUrl' --name '$Broadcast' fmp4"
) -join '; '

Start-DemoTerminal -Title 'publisher' -WorkingDirectory $root -Command $publisherCommand

$webCommand = @(
    'bun install'
    "`$env:VITE_RELAY_URL = '$RelayUrl'"
    'bun --bun vite --open'
) -join '; '

Start-DemoTerminal -Title 'web' -WorkingDirectory $webDir -Command $webCommand

Write-Host 'Started relay, publisher, and web demo in separate terminals.'
Write-Host 'If you want to reproduce the offline UI state, stop the publisher terminal after the page loads.'