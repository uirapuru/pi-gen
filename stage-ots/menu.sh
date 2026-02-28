#!/bin/bash

# Pi-gen Stage-OTS - Menu Szybkiego Dostępu
# Wyświetla listę dostępnych dokumentów i narzędzi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     OpenTAKServer Stage dla Pi-gen - Menu Główne              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

show_menu() {
    echo "Dokumentacja:"
    echo "  1) README.md              - Przegląd stage'a"
    echo "  2) QUICKSTART.md          - Szybki start (5 minut)"
    echo "  3) INSTRUKCJA.md          - Pełna instrukcja użytkownika"
    echo "  4) COMPATIBILITY.md       - Wymagania sprzętowe"
    echo "  5) DEVELOPMENT.md         - Dokumentacja dla developerów"
    echo ""
    echo "Narzędzia:"
    echo "  6) Konfiguracja OTS       - Helper post-instalacyjny"
    echo "  7) Wyświetl strukturę     - Struktura katalogów"
    echo "  8) Status budowania       - Sprawdź status pi-gen"
    echo ""
    echo "  9) Wyjście"
    echo ""
    read -p "Wybierz opcję [1-9]: " choice

    case $choice in
        1)
            if command -v less &> /dev/null; then
                less "$SCRIPT_DIR/README.md"
            else
                cat "$SCRIPT_DIR/README.md" | more
            fi
            ;;
        2)
            if command -v less &> /dev/null; then
                less "$SCRIPT_DIR/QUICKSTART.md"
            else
                cat "$SCRIPT_DIR/QUICKSTART.md" | more
            fi
            ;;
        3)
            if command -v less &> /dev/null; then
                less "$SCRIPT_DIR/INSTRUKCJA.md"
            else
                cat "$SCRIPT_DIR/INSTRUKCJA.md" | more
            fi
            ;;
        4)
            if command -v less &> /dev/null; then
                less "$SCRIPT_DIR/COMPATIBILITY.md"
            else
                cat "$SCRIPT_DIR/COMPATIBILITY.md" | more
            fi
            ;;
        5)
            if command -v less &> /dev/null; then
                less "$SCRIPT_DIR/DEVELOPMENT.md"
            else
                cat "$SCRIPT_DIR/DEVELOPMENT.md" | more
            fi
            ;;
        6)
            if [ -x "$SCRIPT_DIR/00-install-opentakserver/ots-config.sh" ]; then
                sudo -u pi "$SCRIPT_DIR/00-install-opentakserver/ots-config.sh"
            else
                echo "Narzędzie dostępne tylko po zainstalowaniu obrazu"
            fi
            ;;
        7)
            tree "$SCRIPT_DIR" || find "$SCRIPT_DIR" -type f | sort
            ;;
        8)
            if [ -f "build.log" ]; then
                tail -50 build.log
            else
                echo "Brak logu budowania. Uruchom ./build.sh w katalogu pi-gen"
            fi
            ;;
        9)
            exit 0
            ;;
        *)
            echo "Niepoprawna opcja"
            ;;
    esac

    echo ""
    read -p "Naciśnij Enter aby kontynuować..."
    clear
    show_menu
}

clear
show_menu

