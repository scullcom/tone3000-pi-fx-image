param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z]:[\\/]?$')]
    [string] $BootDrive,

    [ValidatePattern('^[a-z0-9_-]{1,32}$')]
    [string] $Layout = 'gb',

    [AllowEmptyString()]
    [ValidatePattern('^[A-Za-z0-9_-]{0,48}$')]
    [string] $Variant = ''
)

$ErrorActionPreference = 'Stop'
$root = $BootDrive.Substring(0, 2) + '\'
$drive = [System.IO.DriveInfo]::new($root)
$keyboardConfig = Join-Path $root 'tone3000-keyboard.txt'
if (-not $drive.IsReady -or $drive.VolumeLabel -ne 'bootfs' -or
    -not (Test-Path -LiteralPath $keyboardConfig -PathType Leaf)) {
    throw "Select the tone3000 kiosk image's bootfs drive after flashing."
}

$layoutCode = $Layout.ToLowerInvariant()
[System.IO.File]::WriteAllText($keyboardConfig, "$layoutCode`n$Variant`n", [System.Text.Encoding]::ASCII)
Write-Host "Keyboard layout $layoutCode saved on $root. Eject the card and boot the Pi."
