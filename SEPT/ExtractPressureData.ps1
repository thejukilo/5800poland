$dataSearchString = "pressureData`":`""
$workOrderIdSearchString = "workOrderId`":`""
$pipettingActionSearchString = "pipettingAction`":`""
$processStepSearchString = "processStep`":`""
$timestampSearchString = "timestamp`":`""
$fileNameExtension = "abcdefghijklmnopqrstuvwxyz"
$rootPath = "./PressureData/"
$fileNameExtensionCounter = 0
$sampleTransferPipettorDataFound = $false
$processHeadDataFound = $false

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

function GetUniquePath {
    param (
        [string]$path
    )

    if (Test-Path $path -PathType leaf) {
        $fileNameWithoutExtension = $path.Substring(0, $path.LastIndexOf('.'))
        $newFileName = $fileNameWithoutExtension + "_" + $fileNameExtension[$fileNameExtensionCounter]
        $Script:fileNameExtensionCounter++
        return $newFileName + [System.IO.Path]::GetExtension($path)
    }

    return $path
}

function WritePressureData {
    param (
        [string]$line,
        [string]$filePath,
        [string]$filename
    )

    $fullPath = $filePath + "\" + $filename
    $fullPath = GetUniquePath $fullPath

    # search for the data
    $data = ExtractSearchString $line $dataSearchString

    $fileInBytes = [Convert]::FromBase64String($data)
    New-Item -ItemType Directory -Force -Path $filePath
    [IO.File]::WriteAllBytes($fullPath, $fileInBytes)
}

function GetPath {
    param (
        [string]$line,
        [string]$dataType
    )
    # search for the run id
    $workOrderId = ExtractSearchString $line $workOrderIdSearchString

    return $rootPath + "WorkOrderId_" + $workOrderId + "\" + $dataType
}

function GetTimestamp {
    param (
        [string]$line
    )
    $timeStamp = ExtractSearchString $line $timestampSearchString
    $formattedTimestamp = [datetime]::Parse($timeStamp).ToUniversalTime().ToString("yyyy-MM-dd_HH.mm.ss.fff")
    return $formattedTimestamp
}

Try {
    # Delete PressureData folder before extracting data
    if (Test-Path $rootPath) {
        Remove-Item $rootPath -Recurse -ErrorAction Ignore
    }

    Get-ChildItem -Path ./eventstream/*.log |
        ForEach-Object {
            foreach ($line in [IO.File]::ReadLines("./eventstream/" + $_.Name)) {
                if ($line -match "PressureDataCollectedForSampleTransferPipettor") {
                    $sampleTransferPipettorDataFound = $true
                    $timestamp = GetTimestamp $line
                    $path = GetPath $line "SampleTransferPipettor"
                    $pipettingActionName = ExtractSearchString $line $pipettingActionSearchString
                    $filename = $timestamp + "_" + $pipettingActionName + ".arf"
                    WritePressureData $line $path $filename
                }
                elseif ($line -match "PressureDataCollectedForProcessHead") {
                    $processHeadDataFound = $true
                    $timestamp = GetTimestamp $line
                    $path = GetPath $line "ProcessHead"
                    $processStepName = ExtractSearchString $line $processStepSearchString
                    $pipettingActionName = ExtractSearchString $line $pipettingActionSearchString
                    $filename = $timestamp + "_" + $processStepName + "_" + $pipettingActionName + ".arf"
                    WritePressureData $line $path $filename
                }
            }
        }
        
    # inform the user if sample transfer pipettor pressure data was found
    if ($sampleTransferPipettorDataFound) {
        Write-Host "All PressureData files for the SampleTransferPipettor successfully exported and stored" -ForegroundColor Green
    } else {
        Write-Host "No PressureData for the SampleTransferPipettor found" -ForegroundColor Red
    }

    # inform the user if process head pressure data was found
    if ($processHeadDataFound) {
        Write-Host "All PressureData files for the ProcessHead successfully exported and stored" -ForegroundColor Green
    } else {
        Write-Host "No PressureData for the ProcessHead found" -ForegroundColor Red
    }
}
Catch {
    Write-Host $_.Exception.Message`n -ForegroundColor Red
}