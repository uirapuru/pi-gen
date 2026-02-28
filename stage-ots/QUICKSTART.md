# Szybki Start - OpenTAKServer Stage dla Pi-gen

## ⚡ 5 Minut Konfiguracji

### 1. Klonuj lub aktualizuj pi-gen

```bash
git clone https://github.com/RPI-Distro/pi-gen.git
cd pi-gen
```

### 2. Dodaj stage-ots (jeśli nie jest już w pi-gen)

```bash
# Jeśli posiadasz stage-ots lokalnie
cp -r /path/to/stage-ots .

# Lub
git clone https://github.com/brian7704/OpenTAKServer-Installer.git
```

### 3. (Opcjonalnie) Dostosuj konfigurację

```bash
nano stage-ots/stage-ots.config
# Lub po prostu użyj ustawień domyślnych
```

### 4. Buduj obraz

```bash
# Wymagane narzędzia (na Ubuntu/Debian):
sudo apt-get install coreutils quilt parted qemu-user-static debootstrap zerofree zip \
  dosfstools e2fsprogs libarchive-tools libcap2-bin grep rsync xz-utils file git curl bc \
  gpg pigz xxd arch-test bmap-tools

# Zaloguj się do pi-gen
./build.sh
```

### 5. Czekaj na zakończenie

Build trwa zwykle 60-120 minut (w zależności od sprzętu).
Obraz zostanie zapisany w `./deploy/`

---

## 📝 Po Zainstalowaniu Obrazu

```bash
# 1. Wgraj obraz na kartę SD
sudo dd if=deploy/image_YYYY-MM-DD-rpi-ots-lite.img of=/dev/sdX bs=4M status=progress
sudo sync

# 2. Wgraj kartę do Raspberry Pi i uruchom

# 3. Zaloguj się (domyślnie pi:raspberry)
ssh pi@raspberrypi.local

# 4. Czekaj na inicjalizację (może potrwać kilka minut)
watch -n 5 'systemctl status opentakserver'

# 5. Wygeneruj certyfikaty (WAŻNE!)
cd ~/stage-ots/00-install-opentakserver
sudo -u pi bash ./ots-config.sh
# Wybierz opcję 1
```

---

## 🔍 Szybka Diagnostyka

```bash
# Sprawdzenie usług
systemctl status opentakserver
systemctl status rabbitmq-server
systemctl status postgresql

# Logi
journalctl -u opentakserver -n 20 -f

# Dostęp do bazy danych
sudo -u postgres psql -d ots -c "SELECT COUNT(*) FROM information_schema.tables;"

# Konfiguracja
cat ~/ots/config.yml
```

---

## 🚨 Typowe Problemy

| Problem | Rozwiązanie |
|---------|-------------|
| `Connection refused` | Czekaj kilka minut na uruchomienie usług, sprawdź `journalctl` |
| `Permission denied` | Użyj `sudo -u pi` przy uruchamianiu komend OTS |
| `Database not ready` | PostgreSQL inicjalizuje się przy pierwszym uruchomieniu |
| `No space left` | Użyj karty SD co najmniej 8GB |
| `Port already in use` | Zmień port w `~/ots/config.yml` |

---

## 📚 Pełna Dokumentacja

- **Użytkownik**: Zobacz `INSTRUKCJA.md`
- **Deweloper**: Zobacz `DEVELOPMENT.md`
- **Kompatybilność**: Zobacz `COMPATIBILITY.md`
- **Ogólnie**: Zobacz `README.md`

---

## 🔗 Przydatne Linki

- 🌐 [OpenTAKServer](https://github.com/brian7704/OpenTAKServer)
- 📦 [Installer](https://github.com/brian7704/OpenTAKServer-Installer)
- 🍓 [Pi-gen](https://github.com/RPI-Distro/pi-gen)
- 🎯 [TAK.gov](https://tak.gov/)

---

## 💡 Wskazówka Pro

Obsługiwane polecenia po zainstalowaniu:

```bash
# Statusy wszystkich OTS usług
for svc in opentakserver cot_parser eud_handler eud_handler_ssl; do
  echo "=== $svc ===" 
  sudo systemctl status $svc --no-pager | head -3
done

# Logi w jednym oknie
watch -n 2 'tail -20 ~/ots/logs/opentakserver.log'

# Restart całego stacku
sudo systemctl restart opentakserver cot_parser eud_handler eud_handler_ssl
```

---

**Ostatnia aktualizacja**: 2026-02-27  
**Wersja**: 1.0

