#!/bin/bash

# ========================================
# Kenzi Tema Installer Script v1.0
# Auto installer untuk Pterodactyl Panel
# Panel Legal By Kenzi
# ========================================

# Warna untuk output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function untuk print banner
print_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║         KENZI TEMA INSTALLER          ║"
    echo "║         Panel Legal By Kenzi          ║"
    echo "║              Version 1.0              ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function untuk cek root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ Error: Script ini harus dijalankan sebagai root!${NC}"
        echo "   Gunakan: sudo bash $0"
        exit 1
    fi
}

# Function untuk cek Pterodactyl
check_pterodactyl() {
    echo -e "${YELLOW}[1/6] 🔍 Memeriksa instalasi Pterodactyl...${NC}"
    
    if [ ! -d "/var/www/pterodactyl" ]; then
        echo -e "${RED}❌ Error: Pterodactyl tidak ditemukan di /var/www/pterodactyl${NC}"
        echo "   Pastikan Pterodactyl sudah terinstall dengan benar"
        exit 1
    fi
    
    if [ ! -f "/var/www/pterodactyl/.env" ]; then
        echo -e "${RED}❌ Error: File .env tidak ditemukan!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Pterodactyl ditemukan${NC}"
}

# Function untuk backup
backup_theme() {
    echo -e "${YELLOW}[2/6] 💾 Membackup tema lama...${NC}"
    
    BACKUP_DIR="/root/kenzi-tema-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p $BACKUP_DIR
    
    if [ -f "/var/www/pterodactyl/.env" ]; then
        cp /var/www/pterodactyl/.env $BACKUP_DIR/
    fi
    
    echo -e "${GREEN}✅ Backup tersimpan di: $BACKUP_DIR${NC}"
}

# Function untuk download tema
download_theme() {
    echo -e "${YELLOW}[3/6] 📥 Mendownload file tema...${NC}"
    
    # Buat folder themes jika belum ada
    mkdir -p /var/www/pterodactyl/public/themes/custom
    
    # Download file CSS
    curl -s -o /var/www/pterodactyl/public/themes/custom/kenzitema.css \
        https://raw.githubusercontent.com/kenzidev5/kenzi-tema/main/assets/css/kenzitema.css || {
        echo -e "${RED}❌ Gagal mendownload file tema${NC}"
        exit 1
    }
    
    # Cek apakah file berhasil didownload
    if [ -f "/var/www/pterodactyl/public/themes/custom/kenzitema.css" ]; then
        echo -e "${GREEN}✅ File tema berhasil didownload${NC}"
    else
        echo -e "${RED}❌ File tema gagal didownload${NC}"
        exit 1
    fi
}

# Function untuk konfigurasi .env
configure_env() {
    echo -e "${YELLOW}[4/6] ⚙️ Mengkonfigurasi .env...${NC}"
    
    cd /var/www/pterodactyl
    
    # Cek apakah APP_THEME sudah ada di .env
    if grep -q "^APP_THEME=" .env; then
        # Update nilai yang ada
        sed -i 's|^APP_THEME=.*|APP_THEME=custom/kenzitema|' .env
        echo -e "${GREEN}✅ APP_THEME diupdate menjadi custom/kenzitema${NC}"
    else
        # Tambah baris baru
        echo "APP_THEME=custom/kenzitema" >> .env
        echo -e "${GREEN}✅ APP_THEME ditambahkan ke .env${NC}"
    fi
}

# Function untuk clear cache
clear_cache() {
    echo -e "${YELLOW}[5/6] 🧹 Membersihkan cache...${NC}"
    
    cd /var/www/pterodactyl
    
    # Clear Laravel cache
    php artisan view:clear > /dev/null 2>&1
    php artisan config:clear > /dev/null 2>&1
    php artisan cache:clear > /dev/null 2>&1
    
    # Set permission
    chown -R www-data:www-data /var/www/pterodactyl/public/themes
    chmod -R 755 /var/www/pterodactyl/public/themes
    
    echo -e "${GREEN}✅ Cache berhasil dibersihkan${NC}"
}

# Function untuk restart service
restart_services() {
    echo -e "${YELLOW}[6/6] 🔄 Merestart service...${NC}"
    
    # Cek web server yang digunakan
    if systemctl is-active --quiet nginx; then
        systemctl restart nginx
        echo -e "${GREEN}✅ Nginx direstart${NC}"
    elif systemctl is-active --quiet apache2; then
        systemctl restart apache2
        echo -e "${GREEN}✅ Apache direstart${NC}"
    fi
    
    # Restart PHP-FPM (sesuaikan versi)
    if systemctl is-active --quiet php8.1-fpm; then
        systemctl restart php8.1-fpm
    elif systemctl is-active --quiet php8.0-fpm; then
        systemctl restart php8.0-fpm
    elif systemctl is-active --quiet php7.4-fpm; then
        systemctl restart php7.4-fpm
    fi
    
    echo -e "${GREEN}✅ Service direstart${NC}"
}

# Function untuk tampilkan hasil
show_result() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║         INSTALASI SELESAI!             ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${GREEN}✅ Tema Kenzi berhasil diinstall!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Informasi:${NC}"
    echo "   • Lokasi tema: /var/www/pterodactyl/public/themes/custom/kenzitema.css"
    echo "   • Backup: $BACKUP_DIR"
    echo ""
    echo -e "${YELLOW}🔄 Langkah selanjutnya:${NC}"
    echo "   1. Refresh halaman panel Anda (Ctrl+F5)"
    echo "   2. Jika tema tidak muncul, cek:"
    echo "      - Browser cache (clear cache)"
    echo "      - Permission folder themes"
    echo ""
    echo -e "${YELLOW}📞 Butuh bantuan?${NC}"
    echo "   Kontak: kenzidev5"
    echo "   Panel Legal By Kenzi"
    echo ""
    
    # Tanya user apakah ingin revert jika gagal
    echo -e "${YELLOW}Apakah tema tampil dengan benar? (y/n)${NC}"
    read -p "Jawab: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Mengembalikan ke tema default...${NC}"
        cd /var/www/pterodactyl
        sed -i 's|^APP_THEME=.*|APP_THEME=default|' .env
        php artisan view:clear
        echo -e "${GREEN}✅ Tema dikembalikan ke default${NC}"
    fi
}

# Function untuk uninstall
uninstall() {
    echo -e "${YELLOW}🗑️  Uninstall tema Kenzi...${NC}"
    
    cd /var/www/pterodactyl
    
    # Hapus file tema
    rm -f /var/www/pterodactyl/public/themes/custom/kenzitema.css
    
    # Kembalikan ke tema default
    sed -i 's|^APP_THEME=.*|APP_THEME=default|' .env
    
    # Clear cache
    php artisan view:clear
    php artisan config:clear
    
    echo -e "${GREEN}✅ Tema berhasil diuninstall${NC}"
}

# Menu utama
main() {
    print_banner
    
    echo -e "${YELLOW}Pilih opsi:${NC}"
    echo "1) Install Tema Kenzi"
    echo "2) Uninstall Tema Kenzi"
    echo "3) Keluar"
    echo ""
    read -p "Pilihan [1-3]: " option
    
    case $option in
        1)
            check_root
            check_pterodactyl
            backup_theme
            download_theme
            configure_env
            clear_cache
            restart_services
            show_result
            ;;
        2)
            check_root
            uninstall
            restart_services
            echo -e "${GREEN}✅ Uninstall selesai!${NC}"
            ;;
        3)
            echo -e "${BLUE}Terima kasih! Panel Legal By Kenzi${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 2
            main
            ;;
    esac
}

# Jalankan main function
main