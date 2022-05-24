param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$wordFile,
    [string]$database
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
if ([IO.Path]::IsPathRooted($wordFile)) { $wordFilePath = $wordFile } else { $wordFilePath = (Resolve-Path (Join-Path $scriptPath $wordFile) -ea SilentlyContinue).Path }
if ([IO.Path]::IsPathRooted($database)) { $databasePath = $database } else { $databasePath = (Resolve-Path (Join-Path $scriptPath $database) -ea SilentlyContinue).Path }
$adOpenStatic = 3
$adLockOptimistic = 3
$conn = New-Object -comobject ADODB.Connection
$rs = New-Object -comobject ADODB.Recordset
Write-Host -ForegroundColor Yellow "Trying to open database $databasePath ..."
$conn.Open("Provider=Microsoft.ACE.OLEDB.12.0; Data Source=$databasePath")
if ($conn.State -eq 0) { break }
$rs.Open("Select * from WORDS", $conn, $adOpenStatic, $adLockOptimistic)
if ($rs.RecordCount -ne 0) { Write-Error "The database is not empty: $($rs.RecordCount) records`n"; break }
Write-Host -ForegroundColor Yellow "Trying to open word file $wordFilePath ..."
$reader = [System.IO.File]::OpenText("$wordFilePath")
if ($reader -eq $null) { break }
$column = New-Object System.Collections.ArrayList
$count = 0
1..30 | ForEach-Object { $t = $column.Add($rs.Fields.Item("C$($_)")) }
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
Write-Host -ForegroundColor Yellow "Reading words ..."
try
{
    while (($word = $reader.ReadLine()) -ne $null)
    {
        if ($count++ % 5000 -eq 0) { Write-Host "$($stopwatch.ElapsedMilliseconds / 1000)s $word" }
        $rs.AddNew()
        $rs.Fields.Item("WORD").Value = $word
        $rs.Fields.Item("LEN").Value = $($word.Length)
        $idx = 0; $word.GetEnumerator() | ForEach-Object {
            $column[$idx].Value = "$_"
            $idx++
        }
        $rs.Update()
    }
}
finally
{
    Write-Host -ForegroundColor Yellow "Closing word file  ..."
    $reader.Close()
    Write-Host -ForegroundColor Yellow "Closing recordset  ..."
    $rs.Close()
    Write-Host -ForegroundColor Yellow "Closing database  ..."
    $conn.Close()
}
Write-Host -ForegroundColor Yellow "Done ($($stopwatch.ElapsedMilliseconds)ms)."
