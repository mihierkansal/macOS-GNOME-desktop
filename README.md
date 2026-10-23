# MacOS Theme for GNOME

This describes how to make your GNOME desktop look like macOS, with some resources included.

# What it looks like

## Desktop

<img src="screenshot/desktop.png" style="border-radius: 6px"/>

## Spotlight

<img src="screenshot/spotlight.png" style="border-radius: 6px"/>

## Terminal

<img src="screenshot/terminal.png" style="border-radius: 6px"/>

## Vivaldi

<img src="screenshot/vivaldi.png" style="border-radius: 6px"/>

## Firefox

<img src="screenshot/firefox.png" style="border-radius: 6px"/>

## VS Code

<img src="screenshot/vscode.png" style="border-radius: 6px"/>

# Main Install (GNOME Shell, GTK)

Run ./install-desktop.sh in your terminal. Warning, it will log you out of GNOME. If it doesn't apply to some apps, copy the contents of ~/.themes/MacTahoe-Dark-Solid/gtk-4.0 (entire directory contents) into ~/.config/gtk-4.0.

It might ask you for sudo password.

If you open VS Code and it says it's corrupt, just click the Gear and "don't show again".

# Wallpapers

You can get them from ./wallpaper.

# Applications

Copy everything from ./applaunchers to ~/.local/share/applications.

# Spotlight search

By default, Spotlight opens when you press Ctrl + Super + Space, to avoid conflicting with other shortcuts.

But, if you want Super + Space (since, on macOS, Command is equivalent to Super, and Spotlight opens on Command + Space), you can run `./spotlight-key.sh`.

# Firefox

Enable CSS customizations, then use ./firefox/theme.css as your userChrome.css. Note, unlike some themes, this does not make Firefox look like Safari; rather, it makes it look like the macOS Firefox (mainly styles the window buttons).
Trying to make it look like Safari would be impossible to do correctly, and it's anyway not the macOS experience; on real macOS, Firefox still looks like Firefox.

# Email Clients

This doesn't include a Thunderbird theme; theming that is harder than Firefox. If you want native macOS look, use a GTK-based email client: **Convey**, **Hylki**, or **Postcard** for example. (note: I am not affiliated with those projects; they're just ones I happened to find that follow the set GTK theme)

# Vivaldi

Copy ./vivaldi to somewhere in your home directory and point Vivaldi Custom CSS to there. Note, this does not make Vivaldi look like Safari; it makes it look like the macOS Vivaldi.

# Chrome, other Chromium-based browsers

Unfortunately, Vivaldi is the only Chromium-based browser that supports this kind of theming.

# VS Code CSS

**The installer should automatically theme VS Code.**

If it doesn't:
First make sure you've not installed it using Snap or Flatpak.

If you haven't installed it using Snap or Flatpak, and it's still looking un-themed, make sure you have this in your user config:

```json
"window.menuStyle": "custom",
"window.controlsStyle": "custom",
"window.titleBarStyle": "custom",

"vscode_custom_css.imports": ["(Path to the vs-code.css file)"],
"window.menuBarVisibility": "toggle",
```

If it still doesn't work, get an extension for custom CSS and give it the vs-code.css (found under vs-code/).

# MEGA Cloud Sync

MEGA sync will not work by default if you have system tray disabled; either enable the system tray in Extension Manager or use mega-cmd instead of MEGASync Desktop.

# Updating/Contributing

Make your changes in your home theme folder (~/.themes), then run ./pack.sh.

Or, unpack desktop.tar.gz, make your edits, re-pack natively, and copy.
