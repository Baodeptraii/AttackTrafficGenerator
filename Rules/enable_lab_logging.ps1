# Run in an elevated PowerShell console on the Windows endpoint

Write-Host "[1/6] Enabling Windows Security auditing..."
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Credential Validation" /success:enable /failure:enable
auditpol /set /subcategory:"Other Account Logon Events" /success:enable /failure:enable
auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable

Write-Host "[2/6] Enabling command line logging for Event ID 4688..."
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit" /v ProcessCreationIncludeCmdLine_Enabled /t REG_DWORD /d 1 /f

Write-Host "[3/6] Enabling PowerShell Script Block Logging (Event ID 4104)..."
reg add "HKLM\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" /v EnableScriptBlockLogging /t REG_DWORD /d 1 /f

Write-Host "[4/6] Validating key services..."
Get-Service WazuhSvc, Sysmon64 -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType | Format-Table -AutoSize

Write-Host "[5/6] Showing current audit status..."
auditpol /get /subcategory:"Logon"
auditpol /get /subcategory:"Credential Validation"
auditpol /get /subcategory:"Other Account Logon Events"
auditpol /get /subcategory:"Process Creation"

Write-Host "[6/6] Quick event checks..."
Write-Host "Recent Sysmon events:"
Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' -MaxEvents 5 |
  Select-Object Id, TimeCreated, ProviderName | Format-Table -AutoSize

Write-Host "Recent Security events:"
Get-WinEvent -LogName Security -MaxEvents 10 |
  Where-Object { $_.Id -in 4625, 4688, 4776 } |
  Select-Object Id, TimeCreated, ProviderName | Format-Table -AutoSize

Write-Host "Recent PowerShell operational events:"
Get-WinEvent -LogName 'Microsoft-Windows-PowerShell/Operational' -MaxEvents 10 |
  Where-Object { $_.Id -eq 4104 } |
  Select-Object Id, TimeCreated, ProviderName | Format-Table -AutoSize
