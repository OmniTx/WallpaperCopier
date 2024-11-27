# Get the current date and time
$currentDate = Get-Date
$year = $currentDate.Year.ToString("0000")
$month = $currentDate.Month.ToString("00")
$day = $currentDate.Day.ToString("00")

# Get the wallpaper path
$wallpaperPath = "$env:AppData\Microsoft\Windows\Themes\TranscodedWallpaper"

# Get the base filename from the wallpaper path
$baseFilename = Split-Path $wallpaperPath -Leaf

# Check if destination directory exists and prompt user if not
$destinationDirectory = "D:\test"
if (!(Test-Path $destinationDirectory)) {
    $destinationDirectory = Read-Host "Enter the destination directory"
}

# Get existing files for the current day in the destination directory
$existingFilesToday = Get-ChildItem -Path $destinationDirectory -Filter "$baseFilename*_*$month$day$year*.jpeg"

# Initialize the daily run count
$runCount = 1

# Calculate the next part number for NN
if ($existingFilesToday) {
    $lastRunFile = $existingFilesToday | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $lastRunTime = $lastRunFile.LastWriteTime
    if (($currentDate - $lastRunTime).TotalMinutes -le 10) {
        $runCount = [int]($lastRunFile.BaseName -replace '.*_', '').Substring(0, 2) + 1
    }
}
$runCountFormatted = $runCount.ToString("00")

# Initialize the part number
$nextPartNumber = 1
$nextPartNumberFormatted = $nextPartNumber.ToString("00")

# Construct the new filename with formatted components
$underscore = "_"
$newFilename = "$baseFilename$underscore$runCountFormatted$month$day$year$nextPartNumberFormatted.jpeg"

# Increment the part number until a unique filename is found
while (Test-Path "$destinationDirectory\$newFilename") {
    $nextPartNumber++
    $nextPartNumberFormatted = $nextPartNumber.ToString("00")
    $newFilename = "$baseFilename$underscore$runCountFormatted$month$day$year$nextPartNumberFormatted.jpeg"
}

# Copy the wallpaper to the destination directory with the new filename
Copy-Item $wallpaperPath "$destinationDirectory\$newFilename"

Write-Host "Wallpaper copied successfully to $destinationDirectory\$newFilename"
