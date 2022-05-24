param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$wordFile
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
if ([IO.Path]::IsPathRooted($wordFile)) { $wordFilePath = $wordFile } else { $wordFilePath = (Resolve-Path (Join-Path $scriptPath $wordFile) -ea SilentlyContinue).Path }
$hs = New-Object System.Collections.Generic.HashSet[string]
Write-Host -ForegroundColor Yellow "Trying to open word file $wordFilePath ..."
$reader = [System.IO.File]::OpenText("$wordFilePath")
if ($reader -eq $null) { break }
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
Write-Host -ForegroundColor Yellow "Reading words ..."
try {
    while (($word = $reader.ReadLine()) -ne $null)
    {
        if ($word -cmatch "^[a-z][^-]*$")
        {
            $t = $hs.Add($word)
        }
    }
}
finally {
    Write-Host -ForegroundColor Yellow "Closing word file  ..."
    $reader.Close()
}
$ls = New-Object System.Collections.Generic.List[string] $hs
Write-Host -ForegroundColor Yellow "Sorting $($hs.Count) words ..."
$ls.Sort()
$outputFile = "{0}\{1}-unique.txt" -f [IO.Path]::GetDirectoryName($wordFilePath), [IO.Path]::GetFileNameWithoutExtension("$wordFile")
Write-Host -ForegroundColor Yellow "Trying to create output word file $outputFile ..."
$f = New-Object System.IO.StreamWriter ($outputFile)
$longest = 0
try
{
    foreach ($word in $ls)
    {
        if (-not [string]::IsNullOrWhiteSpace($word))
        {
            $f.WriteLine($word);
            if ($longest -lt $word.Length) { $longest = $word.Length; $longestWord = $word }
        }
    }
}
finally
{
    Write-Host -ForegroundColor Yellow "Closing output file  ..."
    Write-Host -ForegroundColor Yellow "Longest word: $longestWord ($longest chars)"
    $f.Close()
}
Write-Host -ForegroundColor Yellow "Done ($($stopwatch.ElapsedMilliseconds)ms)."
