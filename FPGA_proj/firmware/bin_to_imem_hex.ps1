param(
    [Parameter(Mandatory=$true)][string]$InputBin,
    [Parameter(Mandatory=$true)][string]$OutputHex
)

$bytes = [System.IO.File]::ReadAllBytes($InputBin)
$lines = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $bytes.Length; $i += 4) {
    $b0 = if ($i -lt $bytes.Length) { [uint32]$bytes[$i] } else { 0 }
    $b1 = if (($i + 1) -lt $bytes.Length) { [uint32]$bytes[$i + 1] } else { 0 }
    $b2 = if (($i + 2) -lt $bytes.Length) { [uint32]$bytes[$i + 2] } else { 0 }
    $b3 = if (($i + 3) -lt $bytes.Length) { [uint32]$bytes[$i + 3] } else { 0 }
    $word = $b0 -bor ($b1 -shl 8) -bor ($b2 -shl 16) -bor ($b3 -shl 24)
    [void]$lines.Add(("{0:x8}" -f $word))
}

[System.IO.File]::WriteAllLines($OutputHex, $lines)
