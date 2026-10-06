#!/usr/bin/env bash

# 1. Clear out old restoration folders
rm -rf ~/GnomeRestore
mkdir -p ~/GnomeRestore

# 2. Unpack the package
tar -xzf ./desktop/desktop.tar.gz -C ~/GnomeRestore

# 3. Create the direct user home asset directories
mkdir -p ~/.themes ~/.icons ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.local/share/gnome-shell/extensions

# 4. Restore assets straight to the home folder paths to bypass permission conflicts
[ -d ~/GnomeRestore/assets/themes ] && rsync -a ~/GnomeRestore/assets/themes/ ~/.themes/
[ -d ~/GnomeRestore/assets/icons ] && rsync -a ~/GnomeRestore/assets/icons/ ~/.icons/
[ -d ~/GnomeRestore/assets/extensions ] && rsync -a ~/GnomeRestore/assets/extensions/ ~/.local/share/gnome-shell/extensions/

# 5. FIX PERMISSIONS: Ensure the current user explicitly owns their restored themes/icons
chmod -R u+rwX ~/.themes ~/.icons ~/.local/share/gnome-shell/extensions

# 6. Restore the layout config baselines
dconf load /org/gnome/desktop/interface/ < ~/GnomeRestore/configs/interface.dconf
dconf load /org/gnome/desktop/wm/preferences/ < ~/GnomeRestore/configs/wm-preferences.dconf
dconf load /org/gnome/desktop/wm/keybindings/ < ~/GnomeRestore/configs/wm-keybindings.dconf
dconf load /org/gnome/mutter/ < ~/GnomeRestore/configs/mutter.dconf

# 7. Apply extension configurations and toggle the extension list
dconf load /org/gnome/shell/extensions/ < ~/GnomeRestore/configs/extensions-settings.dconf
if [ -f ~/GnomeRestore/configs/enabled-extensions.txt ]; then
    dconf write /org/gnome/shell/enabled-extensions "$(cat ~/GnomeRestore/configs/enabled-extensions.txt)"
fi

# 8. Restore GTK UI style engines
cp ~/GnomeRestore/configs/gtk-3.0/* ~/.config/gtk-3.0/ 2>/dev/null
cp ~/GnomeRestore/configs/gtk-4.0/* ~/.config/gtk-4.0/ 2>/dev/null

# 9. Clean up workspace environments
rm -rf ~/GnomeRestore

gsettings set org.gnome.mutter overlay-key ''

gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

#!/bin/bash

echo "Applying universal Flatpak theme and icon overrides..."

# 1. Unset the aggressive GTK_THEME variable that breaks Libadwaita layout engines
flatpak override --user --unset-env=GTK_THEME

# 2. Grant Read-Only access to all potential Icon directories
flatpak override --user --filesystem=xdg-data/icons:ro
flatpak override --user --filesystem=~/.icons:ro
flatpak override --user --filesystem=~/.local/share/icons:ro

# 3. Grant Read-Only access to GTK config directories and Asset themes
flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
flatpak override --user --filesystem=~/.themes:ro
flatpak override --user --filesystem=~/.local/share/themes:ro

# 4. Grant Read-Only access to dconf so apps can detect your active icon theme name
flatpak override --user --filesystem=~/.config/dconf:ro

echo "All overrides successfully applied! Please restart your Flatpak applications."


# 10. Reload GNOME Shell window components
killall -3 gnome-shell 2>/dev/null || echo "Please log out and log back in to finalize."
