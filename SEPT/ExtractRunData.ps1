$contentSearchString = "FileContent`":`""
$filenameSearchString = "FileName`":`""
$runIdSearchString = "RunId`":`""
$sealerTemperaturesFound = $false
$analyticCyclerTemperaturesFound = $false
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
        [string]$line,
        [string]$filePath
    )
    $line = $line.ToString()
    # search for the filename
    $filename = ExtractSearchString $line $filenameSearchString

    # search for the filecontent
    $content = ExtractSearchString $line $contentSearchString

    $fileInBytes = [Convert]::FromBase64String($content)
    New-Item -ItemType Directory -Force -Path $filePath
    [IO.File]::WriteAllBytes($filePath + "\" + $filename, $fileInBytes)
}

function ReadRunId {
    param (
        [string]$line
    )
    $line = $line.ToString()
    # search for the run id
    $runId = ExtractSearchString $line $runIdSearchString
    return ".\RunData_" + $runId
}

Try {
    Get-ChildItem -Path ./eventstream/*.log |
        ForEach-Object {
            foreach ($line in [IO.File]::ReadLines("./eventstream/" + $_.Name)) {
                if ($line -match "AnalyticCyclerPhotometerImage.*FileContent") {
                    $imagesFound = $true
                    $path = ReadRunId $line
                    $photosPath = $path + "\Photos\"
                    SaveFile $line $photosPath
                }
                elseif ($line -match "SealerTemperaturesCollected") {
                    $sealerTemperaturesFound = $true
                    $path = ReadRunId $line
                    SaveFile $line $path
                }
                elseif ($line -match "AnalyticCyclerTemperaturesCollected") {
                    $analyticCyclerTemperaturesFound = $true
                    $path = ReadRunId $line
                    SaveFile $line $path
                }
            }
        }

    # inform the user if the sealer temperature was found
    if ($sealerTemperaturesFound) {
        Write-Host "SealerTemperature tracking file successfully exported and stored" -ForegroundColor Green 
    } else {
        Write-Host "No SealerTemperature tracking file found" -ForegroundColor Red
    }

    # inform the user if the analytic cycler temperature was found
    if ($analyticCyclerTemperaturesFound) {
        Write-Host "AnalyticCyclerTemperature tracking file successfully exported and stored" -ForegroundColor Green
    } else {
        Write-Host "No AnalyticCyclerTemperature tracking file found" -ForegroundColor Red
    }

    # inform the user if photometer images were found
    if ($imagesFound) {
        Write-Host "All Photometer files successfully exported and stored." -ForegroundColor Green
    } else {
        Write-Host "No Photometer images found" -ForegroundColor Red
    }
}
Catch {
    Write-Host $_.Exception.Message`n -ForegroundColor Red
}