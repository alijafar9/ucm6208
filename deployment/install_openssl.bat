@echo off
echo 🔐 Installing OpenSSL for HTTPS support...
echo.

echo 📥 Downloading OpenSSL...
powershell -Command "& {Invoke-WebRequest -Uri 'https://slproweb.com/download/Win32OpenSSL-3_1_4.exe' -OutFile 'openssl_installer.exe'}"

if exist openssl_installer.exe (
    echo ✅ OpenSSL installer downloaded successfully
    echo.
    echo 🚀 Starting OpenSSL installer...
    echo ⚠️ Please follow the installation wizard
    echo 💡 Default installation path is recommended
    echo.
    start /wait openssl_installer.exe
    
    echo.
    echo 🧹 Cleaning up installer...
    del openssl_installer.exe
    
    echo.
    echo ✅ OpenSSL installation completed!
    echo 💡 You can now run start_server.py for HTTPS support
) else (
    echo ❌ Failed to download OpenSSL installer
    echo 💡 Please download manually from: https://slproweb.com/products/Win32OpenSSL.html
)

echo.
pause 