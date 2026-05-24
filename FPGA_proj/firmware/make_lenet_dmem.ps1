param(
    [string]$ParamMem = "..\mem\lenet_params.mem",
    [string]$InputTxt = "..\mnist_int8_digit7_sample0_32x32.txt",
    [string]$OutputMem = "lenet_digit7_dmem.mem"
)

$wordCount = 32768
$inputBaseByte = 0x00010000
$inputBaseWord = $inputBaseByte / 4
$expectedLabelByte = 0x00010EFC
$expectedLabelWord = $expectedLabelByte / 4
$mem = New-Object 'uint32[]' $wordCount

if (-not (Test-Path $ParamMem)) {
    throw "Parameter memory file not found: $ParamMem"
}
if (-not (Test-Path $InputTxt)) {
    throw "Input text file not found: $InputTxt"
}

$paramLines = Get-Content $ParamMem
$paramWordIndex = 0
foreach ($rawLine in $paramLines) {
    $line = $rawLine.Trim()
    if ($line.Length -eq 0) { continue }
    if ($line.StartsWith("@")) {
        $paramWordIndex = [Convert]::ToInt32($line.Substring(1), 16)
        continue
    }
    $mem[$paramWordIndex] = [Convert]::ToUInt32($line, 16)
    $paramWordIndex++
}

$pixels = New-Object System.Collections.Generic.List[int]
$expectedLabel = $null
foreach ($line in (Get-Content $InputTxt)) {
    if ($line -match '^Label:\s*(\d+)') {
        $expectedLabel = [int]$matches[1]
    }
    if ($line -match '^r\s*\d+:') {
        $payload = ($line -split ':', 2)[1].Trim()
        foreach ($token in ($payload -split '\s+')) {
            if ($token.Length -gt 0) {
                [void]$pixels.Add([int]$token)
            }
        }
    }
}

if ($pixels.Count -ne 1024) {
    throw "Expected 1024 input pixels, got $($pixels.Count)"
}
if ($null -eq $expectedLabel) {
    throw "Expected label was not found in: $InputTxt"
}

for ($i = 0; $i -lt $pixels.Count; $i += 4) {
    $b0 = [uint32]($pixels[$i] -band 0xff)
    $b1 = [uint32]($pixels[$i + 1] -band 0xff)
    $b2 = [uint32]($pixels[$i + 2] -band 0xff)
    $b3 = [uint32]($pixels[$i + 3] -band 0xff)
    $mem[$inputBaseWord + ($i / 4)] = $b0 -bor ($b1 -shl 8) -bor ($b2 -shl 16) -bor ($b3 -shl 24)
}

$mem[$expectedLabelWord] = [uint32]$expectedLabel

$lines = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $wordCount; $i++) {
    [void]$lines.Add(("{0:x8}" -f $mem[$i]))
}
[System.IO.File]::WriteAllLines($OutputMem, $lines)

Write-Host "Wrote $OutputMem"
Write-Host "Param words loaded: $paramWordIndex"
Write-Host ("Input base byte: 0x{0:x8}, word: {1}" -f $inputBaseByte, $inputBaseWord)
Write-Host ("Expected label: {0}, byte: 0x{1:x8}, word: {2}" -f $expectedLabel, $expectedLabelByte, $expectedLabelWord)
