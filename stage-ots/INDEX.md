# 📑 Index - Stage-OTS Documentation

## 🚀 Szybki Start

**Nowy użytkownik?** Zacznij tutaj:
→ [QUICKSTART.md](QUICKSTART.md) - 5 minut do uruchomienia

## 📚 Dokumentacja

### Dla Użytkowników
| Dokument | Opis | Czytaj jeśli... |
|----------|------|-----------------|
| [README.md](README.md) | Przegląd stage'a | Chcesz wiedzieć co to robi |
| [INSTRUKCJA.md](INSTRUKCJA.md) | Pełna instrukcja (PL) | Chcesz szczegółowe informacje |
| [QUICKSTART.md](QUICKSTART.md) | Szybki start | Chcesz zbudować obraz |
| [COMPATIBILITY.md](COMPATIBILITY.md) | Wymagania sprzętu | Chcesz sprawdzić czy się nadaje |

### Dla Developerów
| Dokument | Opis | Czytaj jeśli... |
|----------|------|-----------------|
| [DEVELOPMENT.md](DEVELOPMENT.md) | Dokumentacja dev | Chcesz zmodyfikować stage |
| [INDEX.md](INDEX.md) | Ten dokument | Szukasz informacji o plikach |

## 📁 Struktura Katalogów

```
stage-ots/
├── 00-install-opentakserver/          # Moduł instalacyjny
│   ├── 00-packages                     # Pakiety apt
│   ├── 01-run.sh                       # Główny skrypt instalacyjny
│   └── ots-config.sh                   # Helper post-instalacyjny
│
├── prerun.sh                           # Przygotowanie stage'a
├── EXPORT_IMAGE                        # Marker eksportu
│
├── 📄 Dokumentacja
├── README.md                           # Przegląd
├── QUICKSTART.md                       # 5 minut
├── INSTRUKCJA.md                       # Pełna instrukcja
├── COMPATIBILITY.md                    # Wymagania
├── DEVELOPMENT.md                      # Dla developerów
├── INDEX.md                            # Ten plik
│
└── ⚙️ Konfiguracja
    ├── stage-ots.config                # Zmienne konfiguracyjne
    └── menu.sh                         # Menu główne
```

## 🔧 Kluczowe Pliki

### Skrypty Instalacyjne

#### `prerun.sh`
- Przygotowuje ROOTFS
- Kopiuje zawartość z poprzedniego stage'a
- **Edytuj kiedy**: Chcesz zmienić przygotowanie

#### `00-install-opentakserver/00-packages`
- Lista pakietów apt do zainstalowania
- **Edytuj kiedy**: Chcesz dodać/usunąć pakiety systemowe

#### `00-install-opentakserver/01-run.sh`
- Główna logika instalacji
- Instaluje OpenTAKServer z PyPI
- Konfiguruje PostgreSQL, RabbitMQ, nginx
- Tworzy usługi systemd
- **Edytuj kiedy**: Chcesz zmienić proces instalacji

#### `00-install-opentakserver/ots-config.sh`
- Helper post-instalacyjny (uruchamiany ręcznie po starcie)
- Menu do konfiguracji OTS
- Generowanie certyfikatów
- Sprawdzanie statusu
- **Edytuj kiedy**: Chcesz dodać nowe opcje konfiguracji

## 📖 Przewodniki po Zadaniach

### Zainstalować stage-ots

1. Czytaj: [QUICKSTART.md](QUICKSTART.md)
2. Kroki:
   ```bash
   git clone https://github.com/RPI-Distro/pi-gen.git
   cd pi-gen
   cp -r /path/to/stage-ots .
   ./build.sh
   ```

### Zmodyfikować instalację

1. Czytaj: [DEVELOPMENT.md](DEVELOPMENT.md)
2. Edytuj: Odpowiedni plik w `00-install-opentakserver/`
3. Testuj: `shellcheck 00-install-opentakserver/*.sh`

### Wdrożyć OpenTAKServer

1. Czytaj: [INSTRUKCJA.md](INSTRUKCJA.md) - sekcja "Po Zainstalowaniu Obrazu"
2. Kroki:
   ```bash
   ssh pi@raspberrypi.local
   ~/stage-ots/00-install-opentakserver/ots-config.sh
   ```

### Debugować problemy

1. Czytaj: [INSTRUKCJA.md](INSTRUKCJA.md) - sekcja "Rozwiązywanie Problemów"
2. Sprawdź:
   ```bash
   systemctl status opentakserver
   journalctl -u opentakserver -f
   ```

## 🔗 Powiązane Zasoby

### Oficjalne Repozytoria
- **OpenTAKServer**: https://github.com/brian7704/OpenTAKServer
- **Installer**: https://github.com/brian7704/OpenTAKServer-Installer
- **Pi-gen**: https://github.com/RPI-Distro/pi-gen

### Dokumentacja
- **TAK.gov**: https://tak.gov/
- **PyPI - opentakserver**: https://pypi.org/project/opentakserver/
- **Raspberry Pi OS**: https://www.raspberrypi.com/software/

### Narzędzia
- **Systemd**: https://systemd.io/
- **PostgreSQL**: https://www.postgresql.org/
- **RabbitMQ**: https://www.rabbitmq.com/
- **nginx**: https://nginx.org/

## ❓ FAQ

### P: Ile czasu trwa budowanie?
**O**: 60-120 minut w zależności od sprzętu. Na szybszych maszynach ~60 minut.

### P: Czy mogę budować na Raspberry Pi?
**O**: Tak, ale będzie to bardzo wolne. Zalecam machinę z szybszym CPU i więcej RAM.

### P: Jaka jest minimalna wielkość karty SD?
**O**: 8GB dla lite, 16GB+ dla pełnej instalacji.

### P: Jak zaktualizować OpenTAKServer?
**O**: Zobacz [INSTRUKCJA.md](INSTRUKCJA.md) - sekcja "Aktualizacja OpenTAKServer"

### P: Czy mogę uruchomić na 32-bitowym Pi?
**O**: Tak, ale 64-bitowy jest zdecydowanie zalecany dla lepszej wydajności.

## 🐛 Raportowanie Problemów

Jeśli natrafisz na problem:

1. Sprawdź [INSTRUKCJA.md](INSTRUKCJA.md) - sekcja "Rozwiązywanie Problemów"
2. Przejrzyj logi: `journalctl -u opentakserver -n 100`
3. Zgłoś issue na GitHub z:
   - Wersją Raspberry Pi OS
   - Modelem Raspberry Pi
   - Pełnym komunikatem błędu
   - Znaczącymi liniami z logu

## 🤝 Wkład

Chcesz ulepszyć stage-ots?

1. Fork repozytorium pi-gen
2. Stwórz branch: `git checkout -b improve-ots`
3. Dokonaj zmian
4. Test: `shellcheck stage-ots/00-install-opentakserver/*.sh`
5. Commit i Push
6. Pull Request na GitHub

## 📝 Historia Zmian

### v1.0 (2026-02-27)
- ✅ Początkowa implementacja
- ✅ Automatyczna instalacja OpenTAKServer
- ✅ PostgreSQL i RabbitMQ
- ✅ Systemd services
- ✅ Kompletna dokumentacja
- ✅ Helper narzędzia

## 📄 Licencja

Stage-OTS jest dostępny na tej samej licencji co Pi-gen (GPLv2+)

---

**Ostatnia aktualizacja**: 2026-02-27  
**Wersja**: 1.0  
**Autor**: Stage Adaptation for pi-gen

