# OpenTAKServer Stage - Instrukcja Użytkownika

## Przegląd

Stage `stage-ots` zawiera skrypty automatyzujące instalację i konfigurację OpenTAKServer na Raspberry Pi OS. OpenTAKServer to otwarty serwer TAK (Tactical Assault Kit) umożliwiający komunikację taktyczną i wymianę danych w czasie rzeczywistym.

## Struktura Plików

```
stage-ots/
├── 00-install-opentakserver/
│   ├── 00-packages           # Lista pakietów do zainstalowania via apt
│   ├── 01-run.sh             # Główny skrypt instalacyjny
│   └── ots-config.sh         # Helper do konfiguracji post-instalacyjnej
├── COMPATIBILITY.md          # Wymagania sprzętowe i kompatybilność
├── EXPORT_IMAGE              # Marker eksportu obrazu
├── prerun.sh                 # Skrypt przygotowacyjny
├── README.md                 # Dokumentacja stage'a
└── stage-ots.config          # Plik konfiguracyjny
```

## Jak Używać Stage-OTS

### 1. Przygotowanie

Upewnij się, że:
- Klonujesz pi-gen ze wsparciu dla twojej wersji Raspberry Pi OS
- Masz wystarczającą ilość miejsca (minimum 4GB dla samego stage'a)
- Masz stabilne połączenie internetowe (wymagane do pobrania pakietów)

### 2. Budowanie Obrazu

```bash
# Przejdź do katalogu pi-gen
cd /path/to/pi-gen

# (Opcjonalnie) Dostosuj konfigurację
nano stage-ots/stage-ots.config

# Uruchom budowanie
./build.sh
```

System automatycznie zbuduje wszystkie stage'i od stage0 do stage-ots.

### 3. Po Zainstalowaniu Obrazu

Po wgraniu obrazu na kartę SD i starcie Raspberry Pi:

1. **Czekaj na inicjalizację bazy danych**
   - Przy pierwszym uruchomieniu PostgreSQL inicjalizuje bazę danych OTS
   - Może to potrwać kilka minut

2. **Zweryfikuj status usług**
   ```bash
   sudo systemctl status opentakserver
   sudo systemctl status rabbitmq-server
   sudo systemctl status postgresql
   ```

3. **Konfiguracja OpenTAKServer**
   - Konfiguracja znajduje się w `~/ots/config.yml`
   - Edytuj według potrzeb

4. **Generowanie Certyfikatów** (ważne!)
   ```bash
   # Korzystając z helper skryptu
   cd /home/pi/stage-ots/00-install-opentakserver
   sudo -u pi ./ots-config.sh
   # Wybierz opcję 1 do generowania certyfikatów
   ```

   lub

   ```bash
   # Ręcznie
   source ~/.opentakserver_venv/bin/activate
   cd ~/.opentakserver_venv/lib/python3.*/site-packages/opentakserver
   flask ots create-ca
   deactivate
   ```

## Zainstalowane Komponenty

### Aplikacje
- **OpenTAKServer** - Serwer TAK z Python 3
- **PostgreSQL** - System zarządzania bazą danych
- **RabbitMQ** - Broker wiadomości (AMQP)
- **nginx** - Reverse proxy i serwer HTTP/HTTPS
- **FFmpeg** - Biblioteka do przetwarzania mediów
- **Python 3 Virtual Environment** - Izolowane środowisko Pythona

### Usługi Systemd (automatycznie uruchamiane)
- `opentakserver` - Główna aplikacja serwerowa
- `cot_parser` - Parser wiadomości CoT
- `eud_handler` - Obsługa urządzeń użytkownika
- `eud_handler_ssl` - Obsługa urządzeń z SSL
- `rabbitmq-server` - Broker wiadomości
- `nginx` - Serwer HTTP/HTTPS
- `postgresql` - Baza danych

## Ścieżki Instalacji

```
Użytkownik: pi (domyślny użytkownik Raspberry Pi OS)

~/ots/                           # Katalog główny OpenTAKServer
├── config.yml                   # Plik konfiguracyjny
├── ca/                          # Certyfikaty SSL i klucze
├── logs/                        # Pliki dziennika
├── mediamtx/                    # (opcjonalnie) Serwer streamowania
│   └── recordings/              # Nagrania mediów
└── ...

~/.opentakserver_venv/           # Virtual environment Pythona
```

## Rozwiązywanie Problemów

### Usługa nie uruchamia się
```bash
# Sprawdź status
sudo systemctl status opentakserver -l

# Wyświetl logi
journalctl -u opentakserver -n 50 -f

# Spróbuj uruchomić ręcznie
source ~/.opentakserver_venv/bin/activate
opentakserver
```

### Baza danych nie jest dostępna
```bash
# Sprawdź status PostgreSQL
sudo systemctl status postgresql

# Zaloguj się do bazy danych
sudo -u postgres psql -d ots

# Wyświetl użytkowników
\du

# Wyświetl bazy danych
\l
```

### Problemy z portami
```bash
# Sprawdź, które porty są w użyciu
sudo netstat -tlnp | grep LISTEN

# Typowe porty OTS:
# 8080, 8443 - HTTP/HTTPS
# 5432 - PostgreSQL
# 5672, 15672 - RabbitMQ
# 80, 443 - nginx
```

## Konfiguracja Zaawansowana

### Zmiana Portu OpenTAKServer
Edytuj `~/ots/config.yml`:
```yaml
COT_PORT: 8087  # Zmień na preferowany port
```

### Włączenie SSL dla nginx
```bash
# Skopiuj/generuj certyfikaty
sudo cp ~/ots/ca/certs/opentakserver/opentakserver.pem /etc/nginx/certs/

# Edytuj konfigurację nginx
sudo nano /etc/nginx/sites-available/ots_https

# Przeładuj nginx
sudo systemctl reload nginx
```

### Zwiększenie Limitu Połączeń RabbitMQ
Edytuj `/etc/rabbitmq/rabbitmq.conf`:
```
vm_memory_high_watermark.relative = 0.6
channel_max = 4096
```

## Aktualizacja OpenTAKServer

```bash
source ~/.opentakserver_venv/bin/activate

# Aktualizuj pakiet
pip install --upgrade opentakserver

# Uruchom migracje bazy danych
cd ~/.opentakserver_venv/lib/python3.*/site-packages/opentakserver
flask db upgrade

# Zrestartuj usługę
sudo systemctl restart opentakserver
deactivate
```

## Przydatne Komendy

```bash
# Sprawdzenie statusu wszystkich usług
systemctl status opentakserver cot_parser eud_handler eud_handler_ssl rabbitmq-server nginx postgresql

# Wyświetlenie logów w czasie rzeczywistym
journalctl -u opentakserver -f

# Restartowanie OpenTAKServer
sudo systemctl restart opentakserver

# Sprawdzenie wersji Python
python3 --version

# Sprawdzenie konfiguracji nginx
sudo nginx -t

# Sprawdzenie dostępu do bazy danych
sudo -u postgres psql -c "SELECT version();"
```

## Ujednolicenie z pi-gen

Ten stage jest zgodny z standardową strukturą pi-gen:
- Automatycznie kopiuje zawartość z poprzedniego stage'a
- Eksportuje obraz jako EXPORT_IMAGE
- Obsługuje zmienne środowiskowe pi-gen (FIRST_USER_NAME, ROOTFS_DIR itd.)
- Integruje się z systemem budowania ./build.sh

## Wsparcie i Zasoby

- **Oficjalny Serwer OpenTAKServer**: https://github.com/brian7704/OpenTAKServer
- **Installer Raspberry Pi**: https://github.com/brian7704/OpenTAKServer-Installer
- **Dokumentacja TAK**: https://tak.gov/
- **Forum Społeczności**: https://gitter.im/atak-community/

## Licencja

OpenTAKServer jest dostępny na licencji Eclipse Public License 1.0
Pi-gen jest dostępny na licencji Pi-gen

## Uwagi Bezpieczeństwa

⚠️ **WAŻNE**: Przed uruchomieniem serwera w sieci produkcyjnej:

1. ✅ Zmień domyślne hasła RabbitMQ i PostgreSQL
2. ✅ Wygeneruj odpowiednie certyfikaty SSL
3. ✅ Skonfiguruj firewall (ufw, iptables)
4. ✅ Włącz uwierzytelnianie SSL dla klientów TAK
5. ✅ Regularne wykonuj kopie zapasowe bazy danych
6. ✅ Monitoruj pliki dziennika pod kątem błędów

## Aktualny Commit OpenTAKServer-Instalatora

Skrypt instalacyjny jest oparty na:
https://github.com/brian7704/OpenTAKServer-Installer/blob/master/raspberry_pi_installer.sh

Ostatnia aktualizacja: 2026-02-27

