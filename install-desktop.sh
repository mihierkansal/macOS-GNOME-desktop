#!/usr/bin/env bash

 rm -rf ~/GnomeRestore
mkdir -p ~/GnomeRestore

 tar -xzf ./desktop/desktop.tar.gz -C ~/GnomeRestore

 mkdir -p ~/.themes ~/.icons ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.local/share/gnome-shell/extensions

 [ -d ~/GnomeRestore/assets/themes ] && rsync -a ~/GnomeRestore/assets/themes/ ~/.themes/
[ -d ~/GnomeRestore/assets/icons ] && rsync -a ~/GnomeRestore/assets/icons/ ~/.icons/
[ -d ~/GnomeRestore/assets/extensions ] && rsync -a ~/GnomeRestore/assets/extensions/ ~/.local/share/gnome-shell/extensions/

 chmod -R u+rwX ~/.themes ~/.local/share/gnome-shell/extensions

 dconf load /org/gnome/desktop/interface/ < ~/GnomeRestore/configs/interface.dconf
dconf load /org/gnome/desktop/wm/preferences/ < ~/GnomeRestore/configs/wm-preferences.dconf
dconf load /org/gnome/desktop/wm/keybindings/ < ~/GnomeRestore/configs/wm-keybindings.dconf
dconf load /org/gnome/mutter/ < ~/GnomeRestore/configs/mutter.dconf

 dconf load /org/gnome/shell/extensions/ < ~/GnomeRestore/configs/extensions-settings.dconf
if [ -f ~/GnomeRestore/configs/enabled-extensions.txt ]; then
    dconf write /org/gnome/shell/enabled-extensions "$(cat ~/GnomeRestore/configs/enabled-extensions.txt)"
fi

 cp ~/GnomeRestore/configs/gtk-3.0/* ~/.config/gtk-3.0/ 2>/dev/null
cp ~/GnomeRestore/configs/gtk-4.0/* ~/.config/gtk-4.0/ 2>/dev/null

 rm -rf ~/GnomeRestore

gsettings set org.gnome.mutter overlay-key ''

gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

#!/bin/bash

echo "Applying universal Flatpak theme and icon overrides..."

 flatpak override --user --unset-env=GTK_THEME

 flatpak override --user --filesystem=xdg-data/icons:ro
flatpak override --user --filesystem=~/.icons:ro
flatpak override --user --filesystem=~/.local/share/icons:ro

 flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
flatpak override --user --filesystem=~/.themes:ro
flatpak override --user --filesystem=~/.local/share/themes:ro

 flatpak override --user --filesystem=~/.config/dconf:ro

echo "All overrides successfully applied! Please restart your Flatpak applications."

# Exits gracefully if there is no VS Code
./vs-code.sh --install-hook

 killall -3 gnome-shell 2>/dev/null || echo "Please log out and log back in to finalize."
