param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z]:[\\/]?$')]
    [string] $BootDrive
)

$ErrorActionPreference = 'Stop'
$root = $BootDrive.Substring(0, 2) + '\'
$drive = [System.IO.DriveInfo]::new($root)
$networkConfig = Join-Path $root 'network-config'
if (-not $drive.IsReady -or $drive.VolumeLabel -ne 'bootfs' -or
    -not (Test-Path -LiteralPath $networkConfig -PathType Leaf) -or
    -not (Test-Path -LiteralPath (Join-Path $root 'meta-data') -PathType Leaf)) {
    throw "Select the SD card's bootfs drive after flashing and before the first boot."
}

$country = (Read-Host 'Wi-Fi country code (for example GB)').Trim().ToUpperInvariant()
if ($country -cnotmatch '^[A-Z]{2}$') {
    throw 'Enter the two-letter country code where the Pi will be used.'
}
$ssid = Read-Host 'Wi-Fi network name'
if ([string]::IsNullOrEmpty($ssid)) {
    throw 'The Wi-Fi network name is required.'
}
$ssidYaml = ConvertTo-Json -InputObject $ssid -Compress
$secret = Read-Host 'Wi-Fi password' -AsSecureString
if ($secret.Length -eq 0) {
    $secret.Dispose()
    throw 'A Wi-Fi password is required.'
}

$secretPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
try {
    $passwordYaml = ConvertTo-Json -InputObject ([Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer)) -Compress
    $config = @"
network:
  version: 2
  renderer: NetworkManager
  wifis:
    wlan0:
      dhcp4: true
      optional: true
      regulatory-domain: "$country"
      access-points:
        ${ssidYaml}:
          password: $passwordYaml
"@
    [System.IO.File]::WriteAllText($networkConfig, $config + "`n")
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer)
    $secret.Dispose()
    Remove-Variable config, passwordYaml -ErrorAction SilentlyContinue
}

Write-Host "Wi-Fi configuration saved on $root. Eject the card and boot the Pi."
