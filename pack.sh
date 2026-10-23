#!/usr/bin/env bash

# 1. Create clean staging directory structure
mkdir -p ~/GnomeBackup/configs/gtk-3.0 ~/GnomeBackup/configs/gtk-4.0
mkdir -p ~/GnomeBackup/assets/themes
mkdir -p ~/GnomeBackup/assets/icons
mkdir -p ~/GnomeBackup/assets/extensions

echo "-> Gathering GNOME Dconf settings..."
# 2. Extract strictly visual layout configuration keys (No user history or pinned states)
dconf dump /org/gnome/desktop/interface/ > ~/GnomeBackup/configs/interface.dconf
dconf dump /org/gnome/desktop/wm/preferences/ > ~/GnomeBackup/configs/wm-preferences.dconf
dconf dump /org/gnome/desktop/wm/keybindings/ > ~/GnomeBackup/configs/wm-keybindings.dconf
dconf dump /org/gnome/mutter/ > ~/GnomeBackup/configs/mutter.dconf

# 3. Surgically dump shell extension activation states
dconf read /org/gnome/shell/enabled-extensions > ~/GnomeBackup/configs/enabled-extensions.txt
dconf dump /org/gnome/shell/extensions/ > ~/GnomeBackup/configs/extensions-settings.dconf

# 4. Copy current manual GTK user override stylesheets if they exist
[ -f ~/.config/gtk-3.0/gtk.css ] && cp ~/.config/gtk-3.0/gtk.css ~/GnomeBackup/configs/gtk-3.0/ 2>/dev/null
[ -f ~/.config/gtk-4.0/gtk.css ] && cp ~/.config/gtk-4.0/gtk.css ~/GnomeBackup/configs/gtk-4.0/ 2>/dev/null

echo "-> Moving physical assets into backup staging area..."
# 5. Use rsync to pool themes, structural icons, and extensions without breaking symlinks
[ -d ~/.themes ] && rsync -a ~/.themes/ ~/GnomeBackup/assets/themes/
[ -d ~/.local/share/themes ] && rsync -a ~/.local/share/themes/ ~/GnomeBackup/assets/themes/
[ -d ~/.icons ] && rsync -a ~/.icons/ ~/GnomeBackup/assets/icons/
[ -d ~/.local/share/icons ] && rsync -a ~/.local/share/icons/ ~/GnomeBackup/assets/icons/
[ -d ~/.local/share/gnome-shell/extensions ] && rsync -a ~/.local/share/gnome-shell/extensions/ ~/GnomeBackup/assets/extensions/

echo "-> Packaging archive into final tarball..."
# 6. Archive the workspace cleanly
tar -czf ./desktop/desktop.tar.gz -C ~/GnomeBackup .
rm -rf ~/GnomeBackup

echo "=========================================================================="
echo "SUCCESS: Standalone archive generated at: ./desktop/desktop.tar.gz"
