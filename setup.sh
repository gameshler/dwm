#!/bin/sh

setupDWM() {
    printf "Installing DWM..."
    pacman -S --needed --noconfirm base-devel libx11 libxinerama libxft imlib2 git unzip flameshot nwg-look feh mate-polkit alsa-utils ghostty rofi xclip xarchiver thunar tumbler tldr gvfs thunar-archive-plugin dunst feh nwg-look dex xscreensaver xorg-xprop polybar picom xdg-user-dirs xdg-desktop-portal-gtk pipewire pavucontrol gnome-keyring flatpak networkmanager network-manager-applet
}

makeDWM() {
    [ ! -d "$HOME/.local/share" ] && mkdir -p "$HOME/.local/share/"
    if [ ! -d "$HOME/.local/share/dwm-titus" ]; then
        printf "%b\n" "DWM-Titus not found, cloning repository..."
        cd "$HOME/.local/share/" && git clone https://github.com/gameshler/my-dwm.git
        cd my-dwm/
    else
        printf "%b\n" "DWM-Titus directory already exists, replacing.."
        cd "$HOME/.local/share/dwm-titus" && git pull
    fi
    sudo make clean install
}

install_nerd_font() {

    FONT_NAME="JetBrainsMono Nerd Font Mono"
    FONT_DIR="$HOME/.local/share/fonts"
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    FONT_INSTALLED=$(fc-list | grep -i "JetBrainsMono")

    if [ -n "$FONT_INSTALLED" ]; then
        printf "%b\n" "JetBrains Nerd-fonts are already installed."
        return 0
    fi

    printf "%b\n" "Installing JetBrains Nerd-fonts"

    if [ ! -d "$FONT_DIR" ]; then
        mkdir -p "$FONT_DIR" || {
            printf "%b\n" "Failed to create directory: $FONT_DIR"
            return 1
        }
    fi
    printf "%b\n" "Installing font '$FONT_NAME'"
    TEMP_DIR=$(mktemp -d)
    curl -sSLo "$TEMP_DIR"/"${FONT_NAME}".zip "$FONT_URL"
    unzip "$TEMP_DIR"/"${FONT_NAME}".zip -d "$TEMP_DIR"
    mkdir -p "$FONT_DIR"/"$FONT_NAME"
    mv "${TEMP_DIR}"/*.ttf "$FONT_DIR"/"$FONT_NAME"
    fc-cache -fv
    rm -rf "${TEMP_DIR}"
    printf "%b\n" "'$FONT_NAME' installed successfully."
}

clone_config_folders() {
    [ ! -d ~/.config ] && mkdir -p ~/.config
    [ ! -d ~/.local/bin ] && mkdir -p ~/.local/bin
    cp -rf "$HOME/.local/share/my-dwm/scripts/." "$HOME/.local/bin/"

    for dir in config/*/; do
        dir_name=$(basename "$dir")

        if [ -d "$dir" ]; then
            cp -r "$dir" ~/.config/
            printf "%b\n" "Cloned $dir_name to ~/.config/"
        else
            printf "%b\n" "Directory $dir_name does not exist, skipping"
        fi
    done
}

configure_backgrounds() {
    PIC_DIR="$HOME/Pictures"

    BG_DIR="$PIC_DIR/backgrounds"

    if [ ! -d "$PIC_DIR" ]; then
        printf "%b\n" "Pictures directory does not exist"
        mkdir ~/Pictures
        printf "%b\n" "Directory was created in Home folder"
    fi

    if [ ! -d "$BG_DIR" ]; then
        if ! git clone https://github.com/ChrisTitusTech/nord-background.git "$PIC_DIR/backgrounds"; then
            printf "%b\n" "Failed to clone the repository"
            return 1
        fi
        printf "%b\n" "Downloaded desktop backgrounds to $BG_DIR"
    else
        printf "%b\n" "Path $BG_DIR exists for desktop backgrounds, skipping download of backgrounds"
    fi
}

setupDisplayManager() {
    printf "%b\n" "Setting up Xorg..."
    sudo pacman -S --needed --noconfirm xorg-xinit xorg-server
    printf "Xorg installed successfully."
    printf "Setting up display manager ... "
    currentdm="none"
    for dm in gdm sddm lightdm; do
        if command -v "$dm" >/dev/null 2>&1 || isServiceActive "$dm"; then
            currentdm="$dm"
            break
        fi
    done
    printf "%b\n" "Current display manager: $currentdm"
    if [ "$currentdm" = "none" ]; then
        printf "%b\n" "No display manager found..."
        DM="sddm"
        sudo pacman -S --needed --noconfirm "$DM"
        if [ "$DM" = "lightdm" ]; then
            sudo pacman -S --needed --noconfirm lightdm-gtk-greeter
        elif [ "$DM" = "sddm" ]; then
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
        fi
        printf "%b\n" "Installed successfully"
        enableService "$DM"
    fi
}

setupDisplayManager
setupDWM
makeDWM
install_nerd_font
clone_config_folders
configure_backgrounds
