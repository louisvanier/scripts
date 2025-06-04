@echo off
echo Running Wix Link Checker...
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0wix-outgoing-links-crawler.ps1"
pause
