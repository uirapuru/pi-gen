# OpenTAKServer Stage - Dokumentacja Developerska

## Ogólny Przegląd

Stage `stage-ots` jest niestandardowym stage'em dla pi-gen, który automatyzuje instalację OpenTAKServer na Raspberry Pi OS. Bazuje na oficjalnym instalatorze z repozytorium https://github.com/brian7704/OpenTAKServer-Installer.

## Architektura Stage'a

### Struktura Katalogów

```
stage-ots/
├── 00-install-opentakserver/    # Moduł instalacyjny
│   ├── 00-packages               # Plik z listą pakietów apt
│   ├── 01-run.sh                 # Główny skrypt instalacyjny
│   └── ots-config.sh             # Helper post-instalacyjny
├── prerun.sh                     # Przygotowanie stage'a
├── EXPORT_IMAGE                  # Marker eksportu obrazu
├── README.md                     # Dokumentacja użytkownika
├── INSTRUKCJA.md                 # Instrukcja użytkownika (PL)
├── COMPATIBILITY.md              # Wymagania sprzętowe
├── stage-ots.config              # Zmienne konfiguracyjne
└── DEVELOPMENT.md                # Ta dokumentacja
```

## Proces Budowania

### 1. Faza Prerun (prerun.sh)

```bash
#!/bin/bash -e
if [ ! -d "${ROOTFS_DIR}" ]; then
    copy_previous
fi
```

- Sprawdza czy istnieje `ROOTFS_DIR`
- Jeśli nie, kopiuje zawartość z poprzedniego stage'a
- Pozwala na budowanie przyrostowe

### 2. Faza Instalacji Pakietów

Pi-gen automatycznie:
1. Czyta `00-packages`
2. Uruchamia `apt update`
3. Zainstalowuje pakiety z pliku

Obsługiwane formaty `00-packages`:
```
package1
package2  # komentarz
# komentarz na początku linii
package3
```

### 3. Faza Wykonania Skryptu (01-run.sh)

Główny skrypt `01-run.sh` wykonuje:

1. **Tworzenie Katalogów**
   - `~/ots/`
   - `~/.opentakserver_venv/`
   - `~/ots/logs/`
   - `~/ots/ca/`
   - `~/ots/mediamtx/recordings/`

2. **Instalacja OpenTAKServer**
   - Tworzy Python virtual environment
   - Instaluje `opentakserver` z PyPI
   - Generuje domyślną konfigurację

3. **Inicjalizacja Bazy Danych**
   - Uruchamia PostgreSQL
   - Tworzy użytkownika `ots`
   - Tworzy bazę danych `ots`
   - Uruchamia migracje bazy danych

4. **Konfiguracja RabbitMQ**
   - Włącza plugin MQTT
   - Włącza backend HTTP do autoryzacji
   - Restartuje serwis

5. **Tworzenie Usług Systemd**
   - `opentakserver.service`
   - `cot_parser.service`
   - `eud_handler.service`
   - `eud_handler_ssl.service`
   - Ustawia je na automatyczny start

## Zmienne Środowiskowe pi-gen

Skrypt korzysta z następujących zmiennych pi-gen:

| Zmienna | Opis | Domyślnie |
|---------|------|----------|
| `ROOTFS_DIR` | Ścieżka do root filesystem obrazu | Ustawiana przez pi-gen |
| `FIRST_USER_NAME` | Nazwa pierwszego użytkownika | `pi` |
| `BASE_DIR` | Katalog bazowy pi-gen | Ustawiana przez pi-gen |
| `WORK_DIR` | Katalog roboczy budowania | `$BASE_DIR/work` |
| `DEPLOY_DIR` | Katalog wyjściowy | `$BASE_DIR/deploy` |

## Funkcje on_chroot

Skrypt używa funkcji `on_chroot` z pi-gen do wykonywania komend w kontekście ROOTFS:

```bash
on_chroot <<- EOF
    # Komendy tutaj są uruchamiane w chroocie
    su - ${OTS_USER} -c "command here"
    service postgresql start
EOF
```

## Modyfikowanie Stage'a

### Dodanie Nowego Pakietu

Edytuj `00-install-opentakserver/00-packages`:
```
# Dodaj nową linię
new-package-name
```

### Zmiana Wersji OpenTAKServer

Edytuj `01-run.sh`:
```bash
# Zamiast
pip3 install opentakserver

# Użyj
pip3 install opentakserver==1.2.3
```

### Dodanie Nowego Serwisu Systemd

W `01-run.sh` dodaj blok:
```bash
on_chroot <<- EOF
    cat > /etc/systemd/system/my-service.service <<- 'SVCEOF'
        [Unit]
        Description=My Service
        After=network.target
        
        [Service]
        Type=simple
        User=${OTS_USER}
        ExecStart=/path/to/executable
        Restart=on-failure
        
        [Install]
        WantedBy=multi-user.target
    SVCEOF
    
    systemctl daemon-reload
    systemctl enable my-service
EOF
```

### Debugowanie Skryptu

Aby zobaczyć szczegóły buforze budowania:

```bash
# W katalogu pi-gen
VERBOSE=1 ./build.sh

# Lub sprawdź logi w work_dir
tail -f /path/to/pi-gen/work/build.log
```

## Punkty Integracji

### 1. System Budowania pi-gen

Pi-gen automatycznie:
- Skanuje katalogi `stage*` i `stage-*`
- Wykonuje `prerun.sh` każdego stage'a
- Czyta i instaluje pakiety z `00-packages`
- Uruchamia wszystkie `*-run.sh` w porządku numerycznym
- Eksportuje obrazy zaznaczone `EXPORT_IMAGE`

### 2. Zmiany w ROOTFS

Wszystkie polecenia w `on_chroot` modyfikują `/path/to/work/*/rootfs/`

### 3. Propagacja do Następnych Stage'ów

Plik `EXPORT_IMAGE` wskazuje aby:
- Obraz został skompresowany (jeśli `DEPLOY_COMPRESSION` ustawiona)
- Zawartość propagowana do następnych stage'ów

## Testowanie Stage'a

### Lokalnie

```bash
# Skopiuj stage-ots do pi-gen
cp -r stage-ots /path/to/pi-gen/

# Buduj obraz
cd /path/to/pi-gen
IMG_NAME="test-ots" ./build.sh
```

### Walidacja Skryptów

```bash
# Sprawdzenie shellscript
shellcheck stage-ots/prerun.sh
shellcheck stage-ots/00-install-opentakserver/01-run.sh

# Sprawdzenie pakietów
cat stage-ots/00-install-opentakserver/00-packages | grep -v '^#' | grep .
```

### Po Wgraniu Obrazu

```bash
# SSH do Raspberry Pi
ssh pi@raspberrypi.local

# Sprawdź usługi
systemctl status opentakserver

# Sprawdź bazy danych
sudo -u postgres psql -d ots -c "\dt"

# Sprawdź logi
journalctl -u opentakserver -n 50
```

## Znane Problemy i Rozwiązania

### Problem: pip timeout podczas instalacji

**Objawy**: Installation hangs on `pip install opentakserver`

**Rozwiązanie**: 
- Zwiększ timeout: `pip install --default-timeout=1000 opentakserver`
- Lub użyj innego mirror PyPI w konfiguracji

### Problem: PostgreSQL nie jest dostępny przy uruchamianiu

**Objawy**: Services fail to start during boot

**Rozwiązanie**:
- Dodaj `After=postgresql.service` do sekcji `[Unit]`
- Lub zwiększ `RestartSec` w sekcji `[Service]`

### Problem: Brak miejsca na dysku

**Objawy**: Build fails during Python package installation

**Rozwiązanie**:
- Użyj większej karty SD (minimum 8GB)
- Lub zwiększ `WORK_DIR` na dysku z większą przestrzenią

## Optymalizacje

### Zmniejszenie Rozmiaru Obrazu

Dodaj do `01-run.sh`:
```bash
# Usuń cache pip
pip cache purge

# Usuń documentation
rm -rf ~/.opentakserver_venv/share/doc

# Wyczyść pacjki systemowe
apt autoclean
apt autoremove
```

### Przyspieszenie Budowania

1. Zwiększ RAM w systemie budowania
2. Użyj szybszego dysku (SSD)
3. Cache pakietów: `APT_PROXY` w konfiguracji pi-gen

## Wkład i Pull Requests

Aby zasugerować ulepszeń:

1. Fork repozytorium pi-gen
2. Stwórz branch: `git checkout -b improve-stage-ots`
3. Zrób zmiany
4. Test build: `./build.sh`
5. Commit ze sensowną wiadomością
6. Push: `git push origin improve-stage-ots`
7. Utwórz Pull Request

## Referencje Techniczne

### Struktura Pi-gen

- [Pi-gen GitHub](https://github.com/RPI-Distro/pi-gen)
- [Raspberry Pi OS](https://www.raspberrypi.com/software/)

### OpenTAKServer

- [OpenTAKServer GitHub](https://github.com/brian7704/OpenTAKServer)
- [Installer Repo](https://github.com/brian7704/OpenTAKServer-Installer)
- [PyPI Package](https://pypi.org/project/opentakserver/)

### Standardy Systemd

- [Systemd.service Man Page](https://man7.org/linux/man-pages/man5/systemd.service.5.html)
- [Systemd Unit Files](https://wiki.debian.org/systemd)

## Changelog

### v1.0 (2026-02-27)

- ✅ Początkowa implementacja stage-ots
- ✅ Automatyczna instalacja OpenTAKServer
- ✅ Konfiguracja PostgreSQL
- ✅ Setup systemd services
- ✅ RabbitMQ configuration
- ✅ Helper skrypt do konfiguracji
- ✅ Dokumentacja użytkownika

## Licencja

Ten stage jest dostępny na licencji identycznej z pi-gen: [License](https://github.com/RPI-Distro/pi-gen/blob/master/LICENSE)

## Autorzy

OpenTAKServer Stage dla pi-gen został adaptowany z oficjalnego instalatora:
- **OpenTAKServer**: brian7704
- **OpenTAKServer-Installer**: brian7704
- **Pi-gen Stage Adaptation**: 2026-02-27

