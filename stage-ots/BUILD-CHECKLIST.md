# ✓ Checklist Budowania - Stage-OTS

## Przed Budowaniem

### Przygotowanie Środowiska
- [ ] Zainstaluj wymagane zależności:
  ```bash
  sudo apt-get install coreutils quilt parted qemu-user-static debootstrap \
    zerofree zip dosfstools e2fsprogs libarchive-tools libcap2-bin grep \
    rsync xz-utils file git curl bc gpg pigz xxd arch-test bmap-tools
  ```
- [ ] Masz co najmniej 50GB wolnego miejsca na dysku
- [ ] Masz stabilne połączenie internetowe
- [ ] Posiadasz co najmniej 4GB RAM (8GB+ zalecane)

### Konfiguracja Pi-gen
- [ ] Klonujesz/aktualizujesz pi-gen: `git clone https://github.com/RPI-Distro/pi-gen.git`
- [ ] Jesteś na odpowiedniej gałęzi (`master` dla 32-bit, `arm64` dla 64-bit)
- [ ] Stage-ots znajduje się w `./stage-ots/` lub skopiujesz go tam
- [ ] Katalog pi-gen nie zawiera spacji w ścieżce

### Konfiguracja Stage-OTS
- [ ] Przeczytałeś [QUICKSTART.md](QUICKSTART.md)
- [ ] (Opcjonalnie) Dostosowałeś [stage-ots.config](stage-ots.config)
- [ ] Sprawdziłeś wymagania w [COMPATIBILITY.md](COMPATIBILITY.md)

## Podczas Budowania

### Proces Budowania
- [ ] Uruchamiasz: `./build.sh` z katalogu pi-gen
- [ ] Build postępuje bez błędów (sprawdzaj `./work/build.log`)
- [ ] Etapy stage0-stage4 przebiegają poprawnie
- [ ] Stage-ots instaluje się bez błędów:
  - [ ] Pakiety apt instalują się
  - [ ] OpenTAKServer instaluje się z PyPI
  - [ ] PostgreSQL inicjalizuje się
  - [ ] Usługi systemd są tworzone

### Monitorowanie
- [ ] Obserwujesz logi: `tail -f ./work/build.log`
- [ ] Notuj jakiekolwiek ostrzeżenia lub błędy
- [ ] Build zajmuje zwykle 60-120 minut

### Możliwe Problemy

#### Build za długo trwa
- [ ] To normalne - czekaj cierpliwie
- [ ] Możesz przyspieszać używając szybszego dysku

#### Out of memory
- [ ] Zwiększ swap: `fallocate -l 4G /swapfile`
- [ ] Lub użyj `WORK_DIR` na dysku z więcej RAM

#### "No space left on device"
- [ ] Usuń stare buildy: `rm -rf ./work/`
- [ ] Użyj dysku z większą przestrzenią
- [ ] Zmniejsz `WORK_DIR` lub zwiększ partycję

#### Timeout przy instalacji pip
- [ ] Zwiększ timeout w `01-run.sh`
- [ ] Sprawdź połączenie internetowe
- [ ] Spróbuj inna godzina (problemy z PyPI)

## Po Budowaniu

### Weryfikacja Obrazu
- [ ] Build zakończył się sukcesem (komunikat "Finished")
- [ ] Obraz znajduje się w `./deploy/`
- [ ] Obraz ma odpowiednia nazwę: `image_YYYY-MM-DD-rpi-ots-lite*`
- [ ] Rozmiar obrazu jest rozsądny (>2GB dla lite)

### Kompresja
- [ ] Obraz jest skompresowany zgodnie z `DEPLOY_COMPRESSION` (domyślnie .xz)
- [ ] SHA256SUMS.txt zawiera checksum

### Backup
- [ ] Zapisujesz obraz na bezpiecznym miejscu
- [ ] Zapisujesz SHA256SUMS.txt do weryfikacji

## Przygotowanie Karty SD

### Pobranie Obrazu na Linux/Mac
- [ ] Pobrałeś obraz: `deploy/image_*.img.xz`
- [ ] Sprawdzić checksum:
  ```bash
  sha256sum -c SHA256SUMS.txt
  ```
- [ ] Rozpakuj obraz:
  ```bash
  xz -d image_*.img.xz
  ```

### Wgranie na Kartę SD
- [ ] Karty SD jest co najmniej 8GB
- [ ] Identyfikujesz prawidłowe urządzenie:
  ```bash
  lsblk
  ```
- [ ] **UWAGA**: Upewnij się że wybierasz `/dev/sdX` a nie `/dev/sdXY`!
- [ ] Wgrywasz obraz:
  ```bash
  sudo dd if=image_*.img of=/dev/sdX bs=4M status=progress
  sudo sync
  ```
- [ ] Czekasz aż `sync` się zakończy (WAŻNE!)

### Weryfikacja Wgrycia
- [ ] Karty jest bezpiecznie ejectowana
- [ ] Ponownie włączysz kartę i czytasz zawartość (opcjonalnie)

## Po Zabootowaniu Raspberry Pi

### Pierwsza Praca
- [ ] Raspberry Pi uruchamia się prawidłowo
- [ ] Możesz zalogować się (domyślnie pi/raspberry)
- [ ] Sieć jest dostępna (ping google.com)

### Inicjalizacja Usług
- [ ] Czekasz kilka minut na inicjalizację (zwłaszcza PostgreSQL)
- [ ] Sprawdzasz status usług:
  ```bash
  systemctl status opentakserver
  systemctl status postgresql
  ```
- [ ] Wszystkie usługi są w stanie "active" lub "running"

### Weryfikacja Instalacji
- [ ] OpenTAKServer jest zainstalowany w `~/ots/`
- [ ] Python venv istnieje w `~/.opentakserver_venv/`
- [ ] Baza danych PostgreSQL jest dostępna
- [ ] RabbitMQ jest uruchomione

### Konfiguracja
- [ ] Wygeneruj certyfikaty:
  ```bash
  cd ~/stage-ots/00-install-opentakserver
  sudo -u pi bash ./ots-config.sh
  # Wybierz opcję 1
  ```
- [ ] Edytuj konfigurację: `nano ~/ots/config.yml`
- [ ] Zrestartuj usługi: `sudo systemctl restart opentakserver`

## Testowanie

### Sprawdzenie Usług
- [ ] OpenTAKServer: `systemctl status opentakserver`
- [ ] CoT Parser: `systemctl status cot_parser`
- [ ] EUD Handler: `systemctl status eud_handler`
- [ ] EUD Handler SSL: `systemctl status eud_handler_ssl`
- [ ] RabbitMQ: `systemctl status rabbitmq-server`
- [ ] PostgreSQL: `systemctl status postgresql`
- [ ] nginx: `systemctl status nginx`

### Sprawdzenie Logów
- [ ] Brak błędów w: `journalctl -u opentakserver -n 50`
- [ ] Brak błędów w: `journalctl -u cot_parser -n 50`
- [ ] Baza danych inicjalizuje się bez błędów

### Testowanie Konektywności
- [ ] Możesz ping'ować serwer
- [ ] Możesz SSH'ować się do serwera
- [ ] Porty są dostępne (jeśli nie za firewall'em):
  ```bash
  netstat -tlnp | grep LISTEN
  ```

## Rozwiązywanie Problemów

### Jeśli coś się nie udało

1. **Sprawdzić Logi**
   - [ ] `journalctl -u opentakserver -n 100 -e`
   - [ ] `tail -100 ~/ots/logs/opentakserver.log`
   - [ ] `sudo -u postgres psql -d ots -c "SELECT * FROM information_schema.tables;"`

2. **Diagnoza Usług**
   - [ ] `systemctl is-active postgresql`
   - [ ] `systemctl is-active rabbitmq-server`
   - [ ] `sudo -u postgres psql -c "\l"`

3. **Przebudować Stage**
   - [ ] Usuń cache: `rm -rf ./work/`
   - [ ] Uruchom ponownie: `./build.sh`

4. **Zgłosić Problem**
   - [ ] Zbierz logi
   - [ ] Notujesz dokładne komunikaty błędów
   - [ ] Opisujesz swoje środowisko (Pi model, OS, itd.)
   - [ ] Otwórz issue na GitHub

## Post-Wdrożenie

### Bezpieczeństwo
- [ ] Zmieniłeś domyślne hasła
- [ ] Wygenerowałeś SSL certyfikaty
- [ ] Skonfiguruj firewall (ufw, iptables)
- [ ] Włącz SSH key-based auth

### Monitoring
- [ ] Skonfiguruj log rotation
- [ ] Ustawiłeś monitoring usług
- [ ] Masz backupy bazy danych

### Dokumentacja
- [ ] Masz kopię [INSTRUKCJA.md](INSTRUKCJA.md)
- [ ] Notujesz swoje konfiguracje
- [ ] Dokumentujesz wszelkie zmiany

---

## Szybkie Komendy

```bash
# Budowanie
cd /path/to/pi-gen
./build.sh

# Sprawdzenie podczas budowania
tail -f ./work/build.log

# Po zabootowaniu
ssh pi@raspberrypi.local
sudo systemctl status opentakserver
journalctl -u opentakserver -f

# Wgranie obrazu (Linux/Mac)
sudo dd if=image_*.img of=/dev/sdX bs=4M status=progress && sudo sync

# Weryfikacja checksumu
sha256sum -c SHA256SUMS.txt
```

---

**Tip**: Zapisz ten checklist, może się przydać przy następnym buildzie!

**Ostatnia aktualizacja**: 2026-02-27

