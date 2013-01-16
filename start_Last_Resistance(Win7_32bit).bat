set ns2path=""
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 4920" /v "InstallLocation"') do set "ns2path=%%b"
Start "Last Resistance MOD" /D "%ns2path%" "%ns2path%\ns2.exe" -game "%cd%" -hotload
