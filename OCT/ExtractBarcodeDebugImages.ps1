$filenameSearchString = "FileName`":`""
$contentSearchString = "Contents`":`""
$imagesFound = $false

function ExtractSearchString {
    param (
        [string]$line,
        [string]$searchString
    )
    $stringIndex = $line.IndexOf($searchString)
    $textAfterSearchString = $line.Substring($stringIndex + $searchString.Length, $line.Length - $stringIndex - $searchString.Length)
    $text = $textAfterSearchString.Substring(0, $textAfterSearchString.IndexOf("`"")).Trim()
    return $text
}

function SaveFile {
    param (
        [string]$line
    )
    $line = $line.ToString()
 
    # search for the filename
    $filename = ExtractSearchString $line $filenameSearchString
 
    # search for the filecontent
    $content = ExtractSearchString $line $contentSearchString
 
    # extract file path
    $outputFolder = Split-Path -Path $filename
 
    # extract the file contents from the input string
    $fileInBytes = [Convert]::FromBase64String($content)
    
    # create target folder
    New-Item -ItemType Directory -Force -Path $outputFolder
 
    # write the byte stream into a new file
    [IO.File]::WriteAllBytes($filename, $fileInBytes)
}

Try {
    Get-ChildItem -Path ./eventstream/*.log |
        ForEach-Object {
            foreach ($line in [System.IO.File]::ReadLines("./eventstream/" + $_.Name)) {
                if ($line -match "BarcodeDebugImage.*Contents") {
                    $imagesFound = $true
                    SaveFile $line
                }
            }
        }
    
    # inform the user if barcode debug images were found
    if ($imagesFound) {
        Write-Host "All barcode debug images files successfully exported and stored." -ForegroundColor Green
    } else {
        Write-Host "No barcode debug images images found" -ForegroundColor Red
    }
}
Catch {
    Write-Host $_.Exception.Message`n -ForegroundColor Red
}