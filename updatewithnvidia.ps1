# Temporary, scoped policy bypass
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Trust PSGallery and install PSWindowsUpdate
$repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if ($repo -and $repo.InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}
Install-Module PSWindowsUpdate -Scope AllUsers -Force -Confirm:$false

function Get-RandomMessage {
    param([string]$Category)
    $messages = @{
        "WingetUpdate" = @(
            "✔ Winget sources refreshed. They smell lemony fresh 🍋",
            "📡 Winget now knows about more shiny things to install.",
            "✨ Source update done. Packages now up-to-date-ish.",
            "🔮 Winget sources consulted the oracle, knowledge expanded."
        )
        "WingetFail" = @(
            "⚠ Winget is MIA. Probably out getting coffee ☕",
            "😬 No winget found. Pretend you didn’t see this.",
            "🤷 Skipping winget updates. YOLO.",
            "🚫 Winget not in PATH. Clearly it’s slacking."
        )
        "UpgradeDone" = @(
            "✔ Everything’s upgraded. Your PC is now 0.3% faster 💨",
            "🎉 Apps upgraded. Expect 10% more good vibes.",
            "📦 Software patched. Hackers now 17% more confused.",
            "🚀 Upgrade complete. Your mouse cursor gained +1 speed."
        )
        "UpgradeFail" = @(
            "⚠ Winget upgrade failed. Old versions still lurking like ninjas.",
            "😬 Couldn’t upgrade. Apps remain vintage classics.",
            "📼 Upgrades skipped. Your system is retro now.",
            "🤡 Upgrade failed. But hey, nostalgia’s cool."
        )
        "DriverSkip" = @(
            "🎉 NVIDIA App already here. Skipping driver chaos.",
            "🙃 NVIDIA stuff installed. Not touching it.",
            "😎 Found NVIDIA App, skipping re-installation ceremony.",
            "✔ NVIDIA already good. Leaving it alone like a sleeping cat 🐱"
        )
        "DownloadStart" = @(
            "⬇ Downloading NVIDIA driver. Buckle up.",
            "📡 Initiating download… bandwidth engaged.",
            "⚡ Pulling NVIDIA bits from the cloud of doom.",
            "🐢 or 🐇? We’ll see how fast this download is."
        )
        "DownloadDone" = @(
            "✔ Driver downloaded. Bits landed safely on disk.",
            "📂 File acquired. Probably not malware (probably).",
            "🎯 Download complete. Installer locked and loaded.",
            "💾 NVIDIA driver downloaded. Time to unleash frames."
        )
        "DownloadFail" = @(
            "💥 Download failed. Internet gremlins strike again.",
            "🚫 Couldn’t fetch driver. Clouds not cooperating.",
            "😭 File refused to download. Rage quit imminent.",
            "⚠ Epic fail. NVIDIA said no soup for you."
        )
        "InstallStart" = @(
            "⚙ Installing NVIDIA driver. Stealth mode: engaged.",
            "🔧 Deploying NVIDIA wizardry…",
            "🕹 Giving your GPU new superpowers.",
            "🎩 Poof! Watch as drivers magically appear."
        )
        "InstallGood" = @(
            "🎊 Driver installed successfully. Time to flex frames 💪",
            "✔ NVIDIA driver in place. FPS fairy approves.",
            "🚀 Install done. GPU feels buff now.",
            "🥳 NVIDIA driver installed. Go melt some pixels."
        )
        "InstallFail" = @(
            "💀 Install failed. GPU remains mediocre.",
            "⚠ Installer choked. Consult logs and weep.",
            "🤡 NVIDIA said nope. Try again later.",
            "🚫 Driver didn’t install. Sad trombone 🎺"
        )
        "SFC" = @(
            "🩺 Running SFC. Doctor Windows is in.",
            "🧹 Cleaning up system files…",
            "🔎 SFC scanning for weird gremlins.",
            "💉 Injecting stability serum into Windows."
        )
        "DISM" = @(
            "🧘 Running DISM /RestoreHealth. Yoga for Windows.",
            "🔧 DISM repairing the Windows soul.",
            "⚙ DISM: applying duct tape to your OS.",
            "🪛 Fixing corruption. Windows feels seen."
        )
        "Finish" = @(
            "🏁 Script complete. Nothing exploded = success!",
            "🎉 All done! Treat yourself to cookies 🍪",
            "🚀 Mission accomplished. Your PC is slightly less cursed.",
            "✔ Done! Now back to memes."
        )
    }
    return ($messages[$Category] | Get-Random)
}

# ------------------------ Maintenance ------------------------
Write-Host "[Maintenance] Updating winget sources..."
try {
    winget source update
    Write-Host (Get-RandomMessage "WingetUpdate")
} catch {
    Write-Warning (Get-RandomMessage "WingetFail")
}

Write-Host "[Maintenance] Upgrading all packages via winget..."
try {
    winget upgrade --all --include-unknown --silent --accept-package-agreements --accept-source-agreements
    Write-Host (Get-RandomMessage "UpgradeDone")
} catch {
    Write-Warning (Get-RandomMessage "UpgradeFail")
}

# ------------------------ NVIDIA Install ------------------------
[CmdletBinding()]
param(
    [string]$Url = "https://us.download.nvidia.com/Windows/581.15/581.15-desktop-win10-win11-64bit-international-dch-whql.exe",
    [string]$OutFile
)

$LogDir  = Join-Path $env:ProgramData "NVIDIA-FastInstall"
$null    = New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction SilentlyContinue
$LogFile = Join-Path $LogDir "nvidia_fastinstall.log"

function Test-NvidiaAppInstalled {
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    foreach ($k in $keys) {
        Get-ChildItem $k -ErrorAction SilentlyContinue | ForEach-Object {
            $dn = (Get-ItemProperty $_.PsPath -ErrorAction SilentlyContinue).DisplayName
            if ($dn -and $dn -match 'NVIDIA App') { return $true }
        }
    }
    return $false
}

if (Test-NvidiaAppInstalled) {
    Write-Host (Get-RandomMessage "DriverSkip")
} else {
    if (-not $OutFile) {
        $FileName = Split-Path $Url -Leaf
        $OutFile = Join-Path $env:TEMP $FileName
    }

    Write-Host (Get-RandomMessage "DownloadStart")
    try {
        if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
        (New-Object System.Net.WebClient).DownloadFile($Url, $OutFile)
        Write-Host (Get-RandomMessage "DownloadDone")
    } catch {
        Write-Warning (Get-RandomMessage "DownloadFail")
    }

    Write-Host (Get-RandomMessage "InstallStart")
    $argsList = @("-s -noreboot", "/s /noreboot")
    $installed = $false
    foreach ($arg in $argsList) {
        $p = Start-Process -FilePath $OutFile -ArgumentList $arg -PassThru -Wait -WindowStyle Hidden
        if ($p.ExitCode -in 0, 1641, 3010) { $installed = $true; break }
    }

    if ($installed) {
        Write-Host (Get-RandomMessage "InstallGood")
    } else {
        Write-Warning (Get-RandomMessage "InstallFail")
    }
}

# ------------------------ Health Checks ------------------------
Write-Host (Get-RandomMessage "SFC")
sfc /scannow

Write-Host (Get-RandomMessage "DISM")
DISM /Online /Cleanup-Image /RestoreHealth

Write-Host (Get-RandomMessage "Finish")
