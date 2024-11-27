Add-Type -AssemblyName PresentationCore,PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a XAML string for the UI with light and dark mode styling
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Wallpaper Copier" Height="250" Width="400" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style x:Key="LightMode" TargetType="Window">
            <Setter Property="Background" Value="White"/>
            <Setter Property="Foreground" Value="Black"/>
        </Style>
        <Style x:Key="DarkMode" TargetType="Window">
            <Setter Property="Background" Value="#2D2D30"/>
            <Setter Property="Foreground" Value="White"/>
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="{Binding RelativeSource={RelativeSource AncestorType=Window}, Path=Foreground}"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="{Binding RelativeSource={RelativeSource AncestorType=Window}, Path=Background}"/>
            <Setter Property="Foreground" Value="{Binding RelativeSource={RelativeSource AncestorType=Window}, Path=Foreground}"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{Binding RelativeSource={RelativeSource AncestorType=Window}, Path=Background}"/>
            <Setter Property="Foreground" Value="{Binding RelativeSource={RelativeSource AncestorType=Window}, Path=Foreground}"/>
            <Setter Property="BorderBrush" Value="{Binding RelativeSource={RelativeSource AncestorType=Window}, Path=Foreground}"/>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        
        <TextBlock Text="Select the destination directory:" Margin="10" Grid.Row="0" Grid.ColumnSpan="3"/>
        
        <TextBox Name="TextBox" Margin="10" Grid.Row="1" Grid.Column="0"/>
        <Button Name="BrowseButton" Content="Browse..." Width="75" Margin="10" Grid.Row="1" Grid.Column="1"/>
        
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Grid.Row="2" Grid.ColumnSpan="3" Margin="10">
            <Button Name="CopyButton" Content="Copy Wallpaper" Width="100" Margin="5"/>
        </StackPanel>

        <Button Name="ThemeSwitchButton" Content="☀️" Width="30" Height="30" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="10" Grid.Column="1"/>
        <Button Name="AboutButton" Content="ℹ️" Width="30" Height="30" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="10" Grid.Column="2"/>
    </Grid>
</Window>
"@

# Load the XAML
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$window = [Windows.Markup.XamlReader]::Load($reader)

# Define the path to the temporary file
$tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "WallpaperCopier_Settings.json")

# Load settings from the temporary file if it exists
if (Test-Path $tempFile) {
    $settings = Get-Content $tempFile | ConvertFrom-Json
    $lastDirectory = $settings.LastDirectory
    $lastTheme = $settings.LastTheme
} else {
    $settings = @{
        LastDirectory = ""
        LastTheme = "Light"
    }
    $lastDirectory = $settings.LastDirectory
    $lastTheme = $settings.LastTheme
}

# Find controls
$textBox = $window.FindName("TextBox")
$browseButton = $window.FindName("BrowseButton")
$copyButton = $window.FindName("CopyButton")
$themeSwitchButton = $window.FindName("ThemeSwitchButton")
$aboutButton = $window.FindName("AboutButton")

# Set the initial text box value to the last directory
$textBox.Text = $lastDirectory

# Apply the last theme state
if ($lastTheme -eq "Dark") {
    $window.Style = $window.Resources["DarkMode"]
    $themeSwitchButton.Content = "🌙"
} else {
    $window.Style = $window.Resources["LightMode"]
    $themeSwitchButton.Content = "☀️"
}

# Function to save settings to the temporary file
function Save-Settings {
    $settings = @{
        LastDirectory = $textBox.Text.Trim()
        LastTheme = if ($window.Style -eq $window.Resources["DarkMode"]) { "Dark" } else { "Light" }
    }
    $settings | ConvertTo-Json -Compress | Set-Content -Path $tempFile
}

# Define About button click event
$aboutButton.Add_Click({
    $info = @"
Wallpaper Copier
Version 1.0
Developed by ImranAh.
Contact: itsimran.official001@gmail.com
GitHub: OmniTx
"@
    [System.Windows.MessageBox]::Show($info, "About Wallpaper Copier")
})

# Define ThemeSwitch button click event
$themeSwitchButton.Add_Click({
    if ($window.Style -eq $window.Resources["LightMode"]) {
        $window.Style = $window.Resources["DarkMode"]
        $themeSwitchButton.Content = "🌙"
    } else {
        $window.Style = $window.Resources["LightMode"]
        $themeSwitchButton.Content = "☀️"
    }
    Save-Settings
})

# Define Browse button click event
$browseButton.Add_Click({
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.RootFolder = 'MyComputer'
    $result = $folderBrowser.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBox.Text = $folderBrowser.SelectedPath
        Save-Settings
    }
})

# Define Copy button click event
$copyButton.Add_Click({
    $destinationDirectory = $textBox.Text.Trim()
    if (!(Test-Path $destinationDirectory)) {
        [System.Windows.MessageBox]::Show("Directory does not exist!")
        return
    }

    # Save the current settings to the temporary file
    Save-Settings

    # Get the current date and time
    $currentDate = Get-Date
    $year = $currentDate.Year.ToString("0000")
    $month = $currentDate.Month.ToString("00")
    $day = $currentDate.Day.ToString("00")

    # Get the wallpaper path
    $wallpaperPath = "$env:AppData\Microsoft\Windows\Themes\TranscodedWallpaper"

    # Get the base filename from the wallpaper path
    $baseFilename = Split-Path $wallpaperPath -Leaf

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

    [System.Windows.MessageBox]::Show("Wallpaper copied successfully to $destinationDirectory\$newFilename")
})

# Handle window closed event 
$window.Add_Closed({
    exit
})

# Show the window
$window.ShowDialog()
