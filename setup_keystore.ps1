# Interactive Secure Keystore Setup Script
Write-Host "=== Secure Upload Keystore Generator for dr_islam_magdy ===" -ForegroundColor Cyan
$secureStorePassword = Read-Host "Enter Keystore Password (input will be masked)" -AsSecureString
$secureKeyPassword = Read-Host "Enter Key Password (input will be masked)" -AsSecureString

$BSTR1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureStorePassword)
$storePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR1)

$BSTR2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKeyPassword)
$keyPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2)

$keystorePath = "android/app/upload-keystore.jks"
$alias = "upload"

Write-Host "Generating keystore at $keystorePath..." -ForegroundColor Yellow
keytool -genkey -v -keystore $keystorePath -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias $alias -dname "CN=Dr. Islam Magdy, OU=Clinic, O=Dr Islam Magdy, L=Cairo, C=EG" -storepass $storePassword -keypass $keyPassword

if ($LASTEXITCODE -eq 0) {
    Write-Host "Keystore generated successfully!" -ForegroundColor Green

    $keyPropertiesContent = @"
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$alias
storeFile=upload-keystore.jks
"@
    Set-Content -Path "android/key.properties" -Value $keyPropertiesContent
    Write-Host "Created android/key.properties successfully!" -ForegroundColor Green
} else {
    Write-Host "Error generating keystore using keytool." -ForegroundColor Red
}
