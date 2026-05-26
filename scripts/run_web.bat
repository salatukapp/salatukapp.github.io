@echo off
REM Launch Flutter web dev server for Salatuk.
REM Sets project dir + env vars in case the parent shell doesn't have them.

set JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot
set ANDROID_HOME=C:\Android
set PATH=%JAVA_HOME%\bin;C:\src\flutter\bin;%PATH%

cd /d "C:\Users\Omar Kaaki\SunniPrayerApp"
flutter run -d web-server --web-port=8080 --web-hostname=127.0.0.1
