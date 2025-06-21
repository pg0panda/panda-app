@shift
@echo off
color a
title WELCOME %username% - Ultimate Cleaner

cls
echo MSGBOX "Welcome to the ultimate cleaning tool created by Panda!" ,48,"CREATED BY Panda" > %temp%\TEMPmessage.vbs
call %temp%\TEMPmessage.vbs
del %temp%\TEMPmessage.vbs

echo.
echo ===========================================
echo            Starting Ultimate Cleanup
echo ===========================================
echo.

echo [+] Resetting Network Configurations...
ipconfig /release
ipconfig /renew
ipconfig /flushdns
ipconfig /registerdns
netsh int ip reset all
netsh winsock reset
netsh advfirewall reset
nbtstat -r
nbtstat -rr
echo.

echo [+] Terminating Processes and Stopping Services...
:: Processes to kill
for %%P in (
    Auxillary.exe TP3Helper.exe tp3helper.dat androidemulator.exe
    aow_exe.exe QMEmulatorService.exe RuntimeBroker.exe adb.exe
    GameLoader.exe TBSWebRenderer.exe AppMarket.exe ninja.vmp.exe
    syzs_dl_svr.exe TUpdate.exe chrome.exe opera.exe firefox.exe
    service.exe MsMpEng.exe :: Defender Antimalware Service - CAUTION!
) do (
    taskkill /F /IM %%P >nul 2>&1
)

:: Services to stop
for %%S in (
    QMEmulatorService aow_drv aow_exe aow_drv_x64_ev
    AndroidEmulator aow_drv_x64 Tensafe
    WindowsUpdate :: Optional: Stop Windows Update service
    DoSvc :: Delivery Optimization
) do (
    net stop %%S >nul 2>&1
)
echo.

echo [+] Clearing Event Logs...
for /F "tokens=*" %%L in ('wevtutil el') do (
    wevtutil cl "%%L" >nul 2>&1
)
echo.

echo [+] Cleaning Temporary Files and Caches...

:: Core Temporary Dirs & Files to delete and recreate
for %%D in (
    "%temp%" "%windir%\Temp" "%userprofile%\AppData\Local\Temp"
    "%userprofile%\AppData\Local\Microsoft\Windows\Temporary Internet Files"
    "%userprofile%\AppData\Local\Microsoft\Windows\Caches"
    "%systemdrive%\ProgramData\Microsoft\Windows\Caches"
    "%userprofile%\AppData\Local\Microsoft\Windows\WER"
    "%userprofile%\AppData\Local\Microsoft\Windows\WER\ReportArchive"
    "%userprofile%\AppData\Local\Microsoft\Windows\WER\ReportQueue"
    "%userprofile%\AppData\Local\Microsoft\Windows\WER\ERC"
    "%systemdrive%\ProgramData\Microsoft\Windows\WER\ReportQueue"
    "%systemdrive%\ProgramData\Microsoft\Windows\WER\ReportArchive"
    "%userprofile%\AppData\Local\Microsoft\Windows\Explorer\ThumbCacheToDelete"
    "%userprofile%\AppData\Local\Google\Chrome\User Data\Default\Cache" :: Chrome cache
    "%userprofile%\AppData\Local\Opera Software\Opera Stable\Cache" :: Opera cache
    "%userprofile%\AppData\Local\Mozilla\Firefox\Profiles" :: Firefox cache (more complex, targets profile folders)
    "%userprofile%\AppData\Local\Microsoft\Edge\User Data\Default\Cache" :: Edge cache
    "%userprofile%\AppData\Local\RoamCache" :: General RoamCache
) do (
    if exist "%%D\" (
        rmdir /s /q "%%D\"
        md "%%D\"
    )
)

:: Specific file types in common locations
for %%F in (
    "%systemdrive%\*.tmp" "%systemdrive%\*._mp" "%systemdrive%\*.log"
    "%systemdrive%\*.gid" "%systemdrive%\*.chk" "%systemdrive%\*.old"
    "%systemdrive%\*.SWP" "%windir%\*.bak" "%windir%\Prefetch\*.*"
    "%userprofile%\AppData\Local\Microsoft\Windows\Explorer\*.db"
    "%userprofile%\AppData\Local\Microsoft\Windows\Explorer\*.etl"
    "%userprofile%\Cookies\*.*" "%userprofile%\Recent\*.*"
    "%userprofile%\AppData\Roaming\Microsoft\Windows\Recent\*.*"
    "%userprofile%\AppData\Local\Microsoft\Windows\History\*.*"
    "%userprofile%\AppData\Roaming\Microsoft\Windows\Cookies\*.*"
    "%userprofile%\AppData\Local\Temp\Excel8.0\*.exd"
    "%userprofile%\AppData\Roaming\Microsoft\Office\*.tmp"
    "C:\ProgramData\Tencent\*.*" "C:\Users\%username%\AppData\Local\Tencent\*.*"
    "C:\Users\%username%\AppData\Roaming\Tencent\*.*" "C:\aow_drv.log"
    "%systemdrive%\hiberfil.sys" :: Hibernate file - CAUTION!
    "%systemdrive%\pagefile.sys" :: Paging file - CAUTION!
    "%SystemRoot%\MEMORY.DMP" "%SystemRoot%\Minidump\*.dmp"
) do (
    del /f /s /q "%%F" >nul 2>&1
)

:: Clear Recycle Bin for all common drives
for %%L in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%L:\$Recycle.Bin\" rmdir /s /q "%%L:\$Recycle.Bin\" >nul 2>&1
)

:: Run Windows Disk Cleanup Utility
echo [+] Running Windows Disk Cleanup (Deep Scan)...
%SystemRoot%\System32\Cmd.exe /c Cleanmgr /sageset:16 & Cleanmgr /sagerun:16
for %%L in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    c:\windows\SYSTEM32\cleanmgr.exe /d%%L >nul 2>&1
)
echo.

echo [+] Running Component Cleanup (Dism)...
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase >nul 2>&1
echo.

echo [+] Clearing Windows Store Cache...
start "" /min wsreset.exe
ping -n 5 127.0.0.1 >nul :: Give it some time to run
taskkill /IM wsreset.exe /F >nul 2>&1 :: Try to kill if it's stuck
echo.

echo [+] Clearing Font Cache...
net stop FontCache >nul 2>&1
del /q /f "%windir%\ServiceProfiles\LocalService\AppData\Local\FontCache\*.dat" >nul 2>&1
net start FontCache >nul 2>&1
echo.

echo [+] Clearing Browser Data (Internet Explorer / Legacy Edge / System Web Caches)...
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 1
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 2
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 16
echo.

echo [+] Removing Autorun.inf from Drives...
for %%V in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%V:\autorun.inf" (
        attrib -s -h -r "%%V:\autorun.inf" >nul 2>&1
        del "%%V:\autorun.inf" >nul 2>&1
    )
)
echo.

echo [+] Checking and Repairing System Files and Disks...
sfc /scannow
DISM.exe /Online /Cleanup-image /Restorehealth
net start uxsms
echo.

echo [+] Performing Disk Checks (chkdsk)... This might take a while.
for %%L in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    :: Only check if the drive exists and is a local disk
    :: Use 'if exist' to avoid errors on non-existent drive letters
    if exist "%%L:\" (
        echo     Scanning Drive %%L:
        chkdsk %%L: /F >nul 2>&1 :: /F attempts to fix errors
    )
)
echo.

echo ===========================================
echo            Ultimate Cleanup Complete!
echo ===========================================
echo.

echo MSGBOX "Ultimate Cleanup processed successfully! Restart your PC for best results." ,48,"CREATED BY Panda" > %temp%\TEMPmessage.vbs
call %temp%\TEMPmessage.vbs
del %temp%\TEMPmessage.vbs