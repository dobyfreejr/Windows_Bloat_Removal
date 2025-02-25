# PowerShell Script to Free Up Disk Space on Lenovo (Without Removing Xbox)

# Run as Admin Check
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator!" -ForegroundColor Red
    Exit
}

Write-Host "Starting Deep Cleanup..." -ForegroundColor Green

# 1️⃣ Disable Hibernation (Frees 5-10GB)
Write-Host "Disabling Hibernation..."
powercfg -h off

# 2️⃣ Delete Old Windows Update Backups (Frees 10-20GB)
Write-Host "Cleaning Up Old Windows Updates..."
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase

# 3️⃣ Delete Old System Restore Points (Frees 5-20GB)
Write-Host "Removing Old Restore Points..."
vssadmin delete shadows /for=C: /all /quiet

# 4️⃣ Remove Windows Optional Features You Don’t Use
Write-Host "Disabling Unused Windows Features..."
Disable-WindowsOptionalFeature -Online -FeatureName "FaxServicesClientPackage" -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName "MSRDC-Infrastructure" -NoRestart

# 5️⃣ Clean Temporary Files & Windows Temp Folders (Frees 5GB+)
Write-Host "Cleaning Temporary Files..."
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
cleanmgr /sagerun:1

# 6️⃣ Uninstall Lenovo Bloatware (Except Essential Drivers)
Write-Host "Removing Lenovo Bloatware..."
$lenovoApps = @(
    "Lenovo Vantage",
    "Lenovo Utility",
    "McAfee",
    "Lenovo Hotkeys",
    "Dolby Audio",
    "Lenovo System Interface Foundation"
)

foreach ($app in $lenovoApps) {
    Get-AppxPackage -Name "*$app*" | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%$app%'" | ForEach-Object { $_.Uninstall() }
}

# 7️⃣ Remove Pre-Installed Microsoft Bloatware (Keeps Xbox!)
Write-Host "Removing Unwanted Microsoft Apps..."
$msApps = @(
    "Microsoft.3DBuilder",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Messaging",
    "Microsoft.MixedReality.Portal",
    "Microsoft.Office.OneNote",
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.SolitaireCollection",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

foreach ($app in $msApps) {
    Get-AppxPackage -Name "*$app*" | Remove-AppxPackage -ErrorAction SilentlyContinue
}

# 8️⃣ Scan for Large Hidden Files Over 2GB
Write-Host "Scanning for Large Hidden Files (Over 2GB)..."
$largeFiles = Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 2GB }
$largeFiles | Select-Object FullName, @{Name="Size(GB)"; Expression={[math]::Round($_.Length / 1GB, 2)}} | Sort-Object "Size(GB)" -Descending | Format-Table -AutoSize

Write-Host "Deep Cleanup Complete! Review Large Files Above & Delete Unnecessary Ones." -ForegroundColor Green
