# AttackTrafficGenerator

Bộ kịch bản mô phỏng hành vi tấn công dành cho **lab Windows/SOC**, tập trung vào việc tạo **telemetry rõ ràng** để kiểm thử pipeline giám sát như **Sysmon**, **Wazuh/OSSEC**, SIEM và các rule phát hiện dựa trên **MITRE ATT&CK**.

Repo này kết hợp:

- Các file YAML mô tả **Atomic Red Team-style scenarios**
- Script PowerShell để bật logging trên Windows endpoint
- Rule mẫu cho **Sysmon** và **Wazuh**
- Mock HTTP/exfil server để sinh lưu lượng localhost an toàn
- Dữ liệu mẫu phục vụ collection, staging, exfiltration và web attack lab

> [!WARNING]
> Chỉ sử dụng trong **môi trường lab, sandbox hoặc máy ảo được kiểm soát**. Không chạy trên hệ thống production hay hạ tầng không được phép.

---

## Mục tiêu của repo

- Sinh lưu lượng và hành vi gần với TTP thực tế nhưng vẫn **an toàn cho lab**
- Tạo log phục vụ tuning detection cho:
  - Windows Security Events
  - Sysmon Process / Network / File / Registry events
  - PowerShell Script Block Logging
  - Wazuh frequency rules và custom rules
  - Web access log cho các bài test web attack
- Hỗ trợ xây dựng các bài lab theo từng nhóm kỹ thuật ATT&CK: reconnaissance, credential access, discovery, exfiltration, destructive impact, web exploitation

---

## Các kịch bản chính

| File | Kịch bản | Kỹ thuật / mục tiêu chính |
|---|---|---|
| `AKIRA.yaml` | Mô phỏng **Akira ransomware / double extortion** | collect → stage/archive → exfil localhost → inhibit recovery → encrypt simulation |
| `APT32.yaml` | Mô phỏng **APT32 espionage chain v2** | phishing, process injection, credential access, collection, staging, correlation |
| `BRUTEFORCE.yaml` | Mô phỏng **brute force trên SSH/FTP/RDP** | password guessing, password spraying, credential stuffing |
| `NMAP.yaml` | Mô phỏng **active network scanning bằng Nmap** | host discovery, port scan, service/version detection, OS fingerprinting |
| `SCAN.yaml` | Mô phỏng **localhost discovery/scanning** | T1016, T1018, T1046, T1049, T1135, T1040, T1021, T1105, T1071, T1095 |
| `WEBFLOOD.yaml` | Mô phỏng **web attack flood / noisy web probing** | directory fuzzing, malicious user-agent, LFI, SQLi/XSS fuzzing |
| `WIPER.yaml` | Mô phỏng **Ember Bear destructive/wiper scenario** | discovery, reconnaissance, service disruption, overwrite, recovery deletion, shutdown |

Ngoài các file YAML, repo còn có các file `.docx` mô tả scenario để bạn đọc nhanh bối cảnh và luồng lab.

---

## Thành phần hỗ trợ detection

### 1) Bật logging trên Windows endpoint

File `enable_lab_logging.ps1` giúp cấu hình nhanh endpoint để sinh và quan sát telemetry quan trọng:

- Bật audit cho:
  - Logon
  - Credential Validation
  - Other Account Logon Events
  - Process Creation
- Bật command line logging cho Event ID **4688**
- Bật PowerShell Script Block Logging cho Event ID **4104**
- Kiểm tra nhanh Sysmon / Security / PowerShell events sau khi cấu hình

Chạy bằng PowerShell **Run as Administrator**:

```powershell
powershell -ExecutionPolicy Bypass -File .\enable_lab_logging.ps1
```

---

### 2) Sysmon configuration

Repo có các file cấu hình/rule phục vụ Sysmon:

- `sysmon_lab_art_rules.xml`
- `webflood_sysmon.xml`

Các rule này tập trung bắt các nhóm hành vi như:

- Process creation
- Network connections tới port lab / exfil
- LSASS safe-touch / process access
- Registry Run persistence
- File creation artifacts
- Web-focused Sysmon filtering cho bài WEBFLOOD

---

### 3) Wazuh / OSSEC rules

Các file sau hỗ trợ phát hiện và correlation trong Wazuh/OSSEC:

- `wazuh_local_rules_art_lab.xml`
- `webflood_wazuh_rules.xml`
- `add_local_rule.xml`
- `ossec_agent_windows_eventchannels_snippet.xml`

Các nhóm detection nổi bật:

- Nmap execution / network scan
- Packet capture bằng `pktmon`
- Internal RCE / Impacket-style behavior
- Password spraying / brute-force patterns
- Webshell access
- Upload + access chain
- LFI / sensitive file access
- Command injection attempt

---

## Cấu trúc repo

```text
AttackTrafficGenerator/
├── AKIRA.yaml
├── APT32.yaml
├── BRUTEFORCE.yaml
├── NMAP.yaml
├── SCAN.yaml
├── WEBFLOOD.yaml
├── WIPER.yaml
├── enable_lab_logging.ps1
├── sysmon_lab_art_rules.xml
├── wazuh_local_rules_art_lab.xml
├── webflood_sysmon.xml
├── webflood_wazuh_rules.xml
├── add_local_rule.xml
├── ossec_agent_windows_eventchannels_snippet.xml
├── webserver.txt
├── ExfilServer/
│   └── index.html
├── LOCALHOST-NET-LAB/
│   ├── services/
│   │   └── http/
│   │       ├── beacon/
│   │       └── index.html
│   └── traffic/
│       └── scan.ps1
└── TestData/
    ├── Backup/
    ├── Documents/
    └── Images/
```

---

## Yêu cầu môi trường

### Windows endpoint

Khuyến nghị:

- Windows 10/11 lab VM
- PowerShell chạy với quyền Administrator
- Sysmon đã cài
- Wazuh agent hoặc OSSEC agent đã cài và gửi log về manager
- Python 3 để chạy mock HTTP server nội bộ
- Atomic Red Team / Invoke-AtomicTest (nếu bạn dùng workflow ART để nạp và chạy các file YAML)

### Web lab cho `WEBFLOOD.yaml`

Kịch bản WEBFLOOD phù hợp hơn nếu có thêm một web server riêng để tạo access log và HTTP attack surface. Repo đã có `webserver.txt` làm hướng dẫn dựng lab theo mô hình:

- Ubuntu Server
- Apache2
- PHP
- MariaDB
- Một web app PHP đơn giản có các điểm lab như login, search, upload

---

## Bắt đầu nhanh

### Bước 1: Clone repo

```bash
git clone https://github.com/Baodeptraii/AttackTrafficGenerator.git
cd AttackTrafficGenerator
```

### Bước 2: Bật logging trên Windows endpoint

```powershell
powershell -ExecutionPolicy Bypass -File .\enable_lab_logging.ps1
```

### Bước 3: Nạp Sysmon / Wazuh rules

Tùy kiến trúc lab của bạn:

- Import hoặc merge `sysmon_lab_art_rules.xml` / `webflood_sysmon.xml` vào cấu hình Sysmon
- Thêm `wazuh_local_rules_art_lab.xml`, `webflood_wazuh_rules.xml`, `add_local_rule.xml` vào custom rules của Wazuh
- Thêm snippet trong `ossec_agent_windows_eventchannels_snippet.xml` để agent thu đúng EventChannel cần thiết

> Nên restart dịch vụ liên quan sau khi cập nhật cấu hình để rule và collection có hiệu lực.

### Bước 4: Khởi động mock services nội bộ nếu scenario cần

#### Exfil localhost server

```powershell
cd .\ExfilServer
python -m http.server 8081
```

#### Localhost HTTP service cho scan lab

```powershell
cd .\LOCALHOST-NET-LAB\services\http
python -m http.server 8080 --bind 127.0.0.1
```

### Bước 5: Chạy scenario

Có hai cách sử dụng phổ biến:

#### Cách A — Chạy trực tiếp script lab có sẵn

Ví dụ bài localhost scan:

```powershell
powershell -ExecutionPolicy Bypass -File .\LOCALHOST-NET-LAB\traffic\scan.ps1
```

Script này tạo nhiều nhóm hành vi mạng trên `127.0.0.1`, gồm discovery, service probing, share discovery, packet capture, HTTP/DNS beaconing và ICMP channel simulation.

#### Cách B — Dùng workflow Atomic Red Team của bạn

Các file YAML trong repo được viết theo phong cách **Atomic Red Team scenario definitions**. Bạn có thể:

- đọc/tuỳ biến scenario trong từng file YAML
- đưa chúng vào bộ lab ART nội bộ của bạn
- chạy từng bước theo đúng quy trình `Invoke-AtomicTest`/runner mà lab của bạn đang dùng

> Do mỗi lab dùng runner hoặc đường dẫn Atomics khác nhau, README này không ép một câu lệnh cố định cho mọi môi trường.

---

## Gợi ý thứ tự test

### 1) Kiểm tra pipeline logging trước

Chạy trước:

```powershell
powershell -ExecutionPolicy Bypass -File .\enable_lab_logging.ps1
```

Xác nhận bạn nhìn thấy các event như:

- 4625
- 4688
- 4776
- 4104
- Sysmon Event ID 1 / 3 / 10 / 11 / 13

### 2) Chạy bài nhẹ trước

Khuyến nghị bắt đầu theo thứ tự:

1. `SCAN.yaml` hoặc `LOCALHOST-NET-LAB/traffic/scan.ps1`
2. `NMAP.yaml`
3. `BRUTEFORCE.yaml`
4. `APT32.yaml`
5. `AKIRA.yaml`
6. `WIPER.yaml`
7. `WEBFLOOD.yaml`

### 3) So khớp log với detection

Sau khi chạy scenario, kiểm tra:

- Sysmon logs trên endpoint
- Windows Security logs
- PowerShell Operational logs
- Alerts/rules trên Wazuh manager
- Access log web lab nếu chạy WEBFLOOD

---

## Một vài scenario nổi bật

### Akira ransomware lab

`AKIRA.yaml` mô phỏng mô hình **double extortion** trong lab an toàn:

- collect dữ liệu
- archive/stage
- exfil qua HTTP localhost
- inhibit recovery
- encrypt simulation + ransom note

Scenario này phù hợp để kiểm thử correlation từ **collection → exfiltration → impact**.

### APT32 espionage v2

`APT32.yaml` mô phỏng partial attack chain trên một host Windows, có thêm:

- process injection
- LSASS safe-touch
- collection / staging tách riêng
- correlation markers
- cleanup step

Phù hợp để lab detection logic nhiều bước thay vì chỉ phát hiện một process đơn lẻ.

### Brute force credential attack

`BRUTEFORCE.yaml` tập trung tạo failed authentication volume cao trên localhost để test:

- frequency rules của Wazuh
- phát hiện password spraying
- phát hiện brute-force đa giao thức (SSH / FTP / RDP)

### WEBFLOOD

`WEBFLOOD.yaml` dùng cho môi trường web lab có access log, giúp tạo lượng log lớn và nhiều nhiễu:

- 404 flood / directory fuzzing
- malicious scanners user-agent
- LFI attempt
- SQLi / XSS fuzzing
- upload / webshell-style access chain

---

## Dữ liệu mẫu và lab assets

### `TestData/`

Chứa dữ liệu mẫu để phục vụ các bước:

- collection
- staging
- archiving
- exfiltration
- destructive testing trong môi trường lab

### `ExfilServer/`

Mock HTTP content đơn giản để phục vụ localhost exfil / transfer simulation.

### `LOCALHOST-NET-LAB/`

Bộ lab cục bộ để sinh network telemetry ngay trên một máy Windows:

- `services/http/`: dịch vụ HTTP localhost và beacon content
- `traffic/scan.ps1`: script tạo traffic, discovery, beaconing, sniffing

---

## Lưu ý an toàn

- Chỉ chạy trên **VM hoặc mạng lab cô lập**
- Không trỏ scan / brute-force / web fuzzing vào hệ thống thật
- Kiểm tra lại rule, port, log path trước khi chạy
- Nếu dùng bài WEBFLOOD, nên giới hạn scope tới web lab của riêng bạn
- Với scenario destructive (ví dụ WIPER), luôn chuẩn bị snapshot VM để rollback

---

## Use cases phù hợp

Repo này phù hợp cho:

- SOC lab / blue team lab
- Detection engineering
- Rule tuning cho Wazuh / Sysmon / SIEM
- Đào tạo MITRE ATT&CK hands-on
- Sinh dữ liệu phục vụ demo correlation / incident simulation

---

## Miễn trừ trách nhiệm

Nội dung trong repo này phục vụ **mục đích học tập, nghiên cứu, detection engineering và mô phỏng trong môi trường được cấp phép**. Người sử dụng chịu trách nhiệm tự đảm bảo phạm vi triển khai là hợp pháp, an toàn và được cho phép.
