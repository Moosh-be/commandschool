# Fix Show-PageContent + message page 8
$f = 'shell/lib/Formatter.psm1'
$c = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)

# Fix 1: Show-PageContent affiche TopBorder au lieu de "│"
$old1 = '$pageNumStr = $PageNumber.ToString()
    $totalStr = $TotalPages.ToString()
    $padding = " " * ($TotalPages.ToString().Length - $pageNumStr.Length + 2)
    Write-Host "│${padding}$($PageNumber) / $TotalPages   " -ForegroundColor DarkGray
    Write-Host $BottomBorder -ForegroundColor DarkGray'
$new1 = 'Write-Host $TopBorder -ForegroundColor DarkGray
    $pageNumStr = $PageNumber.ToString()
    $totalStr = $TotalPages.ToString()
    $padding = " " * ($TotalPages.ToString().Length - $pageNumStr.Length + 2)
    Write-Host "│${padding}$($PageNumber) / $TotalPages   " -ForegroundColor DarkGray
    Write-Host $BottomBorder -ForegroundColor DarkGray'
$c = $c.Replace($old1, $new1)

# Fix 2: Page 8 message
$c = $c.Replace('Appuyez sur Echap pour quitter, sur Enter pour le menu...', 'Appuyez sur Echap pour quitter.')

[System.IO.File]::WriteAllText($f, $c, [System.Text.Encoding]::UTF8)
Write-Host 'OK'
