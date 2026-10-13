flutter emulators --launch Pixel_8
Write-Host "Menunggu emulator siap..."
& "$env:ANDROID_HOME\platform-tools\adb.exe" wait-for-device
Start-Sleep -Seconds 5
flutter run --dart-define-from-file=env.json