param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$url
)

# Larousse online dictionary DOM
$html = Invoke-WebRequest $url
$html.AllElements | Where-Object { $_.class -eq "AdresseDefinition" } | ForEach-Object { "Mot     : " + $_.innerText.Trim() }
$html.AllElements | Where-Object { $_.class -eq "CatgramDefinition" } | ForEach-Object { "Genre   : " + ($_.innerHTML -Replace '\s*<.*>','') }
$html.AllElements | Where-Object { $_.class -eq "OrigineDefinition" } | ForEach-Object { "Origine : " + $_.innerText }
$id = 1;
$html.AllElements | Where-Object { $_.class -eq "DivisionDefinition" } | ForEach-Object {
    $def = ($_.innerText).Split("`n")[-1]
    $o = New-Object System.Object
    $o | Add-Member -Type NoteProperty -Name '#' -Value ($id++)
    $o | Add-Member -Type NoteProperty -Name Definition -Value $def
    Write-Output $o
} | Format-Table -AutoSize

