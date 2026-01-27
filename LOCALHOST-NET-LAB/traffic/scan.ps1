Write-Host "[*] LOCALHOST NETWORK SCAN LAB STARTED"

$BASE = "C:\LOCALHOST-NET-LAB"
$CAP  = "$BASE\capture"

# --- T1016: Network Configuration Discovery ---
Write-Host "[*] T1016 - Network Configuration Discovery"
ipconfig /all
route print
netsh interface ip show config

# --- T1018: Host Discovery ---
Write-Host "[*] T1018 - Remote System Discovery (localhost)"
ping -n 2 127.0.0.1
nbtstat -A 127.0.0.1

# --- T1046: Network Service Discovery ---
Write-Host "[*] T1046 - Network Service Discovery"
$ports = @(80,445,3389,5985,8080)
foreach ($p in $ports) {
    Test-NetConnection 127.0.0.1 -Port $p | Out-Null
}

# --- T1049: Network Connections Discovery ---
Write-Host "[*] T1049 - Network Connections Discovery"
netstat -ano

# --- T1135: Network Share Discovery ---
Write-Host "[*] T1135 - Network Share Discovery"
net view \\127.0.0.1
net use \\127.0.0.1\ADMIN$ | Out-Null

# --- T1040: Network Sniffing ---
Write-Host "[*] T1040 - Starting pktmon capture"
pktmon start --capture --pkt-size 0

# --- T1021: Remote Services ---
Write-Host "[*] T1021 - Remote Services (self-access)"
Start-Process "mstsc.exe" "/v:127.0.0.1"
winrm identify -r:http://127.0.0.1:5985

# --- T1105: Ingress Tool Transfer ---
Write-Host "[*] T1105 - Ingress Tool Transfer"
certutil -urlcache -f http://127.0.0.1:8080/index.html "$BASE\downloaded.html"

# --- T1071: C2 Simulation ---
Write-Host "[*] T1071 - HTTP + DNS Beaconing"
curl http://127.0.0.1:8080/beacon | Out-Null
nslookup beacon.localhost

# --- T1095: ICMP Channel ---
Write-Host "[*] T1095 - ICMP Channel Simulation"
Start-Process "ping.exe" "-t 127.0.0.1"

Write-Host "[*] Scan completed. Stop pktmon manually when ready."
Write-Host "[*] To stop pktmon: pktmon stop"
Write-Host "[*] To export pcap: pktmon format PktMon.etl -o $CAP\loopback.pcap"
Write-Host "[*] LOCALHOST NETWORK SCAN LAB COMPLETED"


# # 1. Chạy HTTP server
# cd C:\LOCALHOST-NET-LAB\services\http
# python -m http.server 8080 --bind 127.0.0.1

# # 2. Mở PowerShell Admin, chạy scan
# cd C:\LOCALHOST-NET-LAB\traffic
# .\scan.ps1
