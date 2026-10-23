#!/usr/bin/env bash
set -e

 SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CSS_SOURCE="$SCRIPT_DIR/vs-code/vs-code.css"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"

 SEARCH_DIRS=(
    "$HOME/.local/share/code-portable"
    "/usr/share/code"
    "/usr/share/code-insiders"
    "/usr/lib/code"
)
TARGET_PATH=""
FOR_INSIDERS=false

for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        FOUND=$(find "$dir" -type f -name "workbench.html" 2>/dev/null | head -n 1)
        if [ -n "$FOUND" ]; then 
            TARGET_PATH="$FOUND"
            [[ "$dir" == *"insiders"* ]] && FOR_INSIDERS=true
            break
        fi
    fi
done

 if [ "$FOR_INSIDERS" = true ]; then
    SETTINGS_JSON="$HOME/.config/Code - Insiders/User/settings.json"
else
    if [ -d "$HOME/.local/share/code-portable/data" ]; then
        SETTINGS_JSON="$HOME/.local/share/code-portable/data/user-data/User/settings.json"
    else
        SETTINGS_JSON="$HOME/.config/Code/User/settings.json"
    fi
fi
 
if [ "$1" == "--install-hook" ]; then
    if [ -z "$TARGET_PATH" ]; then
        echo "Error: Cannot set up automation. VS Code is not installed on this system." >&2
        exit 1
    fi

    USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
    mkdir -p "$USER_SYSTEMD_DIR"

    echo "Configuring Systemd Path monitor..."
    cat <<EOF > "$USER_SYSTEMD_DIR/vscode-css.path"
[Unit]
Description=Monitor VS Code Workbench for Updates

[Path]
PathChanged=$TARGET_PATH
Unit=vscode-css.service

[Install]
WantedBy=default.target
EOF

    echo "Configuring Systemd Service worker..."
    cat <<EOF > "$USER_SYSTEMD_DIR/vscode-css.service"
[Unit]
Description=Re-inject Custom CSS into VS Code

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH --quiet
EOF

    echo "Reloading and enabling background systemd monitor..."
    systemctl --user daemon-reload
    systemctl --user enable --now vscode-css.path

    echo "Success: Background systemd path unit is now guarding $TARGET_PATH."
    echo "Any modification or package update will instantly trigger a re-injection."
    exit 0
fi
 
if [ ! -f "$CSS_SOURCE" ] || [ -z "$TARGET_PATH" ]; then
    exit 1 
fi

 if [ ! -w "$TARGET_PATH" ] && [ "$EUID" -ne 0 ]; then
    sudo chown "$USER" "$TARGET_PATH"
fi

 python3 - <<EOF "$TARGET_PATH" "$CSS_SOURCE" "$SETTINGS_JSON" "$1"
import sys, re, json, os

target_file = sys.argv[1]
css_file = sys.argv[2]
settings_file = sys.argv[3]
quiet_mode = sys.argv[4] == "--quiet"

# 1. PROCESS HTML CSS INJECTION
with open(target_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Check if already accurately injected to prevent infinite update trigger loops
if "<!-- CUSTOM CSS INJECTION START -->" in content and quiet_mode:
    sys.exit(0)

with open(css_file, 'r', encoding='utf-8') as f:
    css_content = f.read()

content = re.sub(r'<!-- CUSTOM CSS INJECTION START -->.*?<!-- CUSTOM CSS INJECTION END -->', '', content, flags=re.DOTALL)
payload = f"\n<!-- CUSTOM CSS INJECTION START -->\n<style>\n{css_content}\n</style>\n<!-- CUSTOM CSS INJECTION END -->"

if "</html>" in content:
    content = content.replace("</html>", f"{payload}\n</html>")
elif "</html>".upper() in content:
    content = content.replace("</html>".upper(), f"{payload}\n</html>")
else:
    content = content + payload

with open(target_file, 'w', encoding='utf-8') as f:
    f.write(content)

# 2. PROCESS JSON SETTINGS INJECTION
os.makedirs(os.path.dirname(settings_file), exist_ok=True)
settings_data = {}
if os.path.exists(settings_file) and os.path.getsize(settings_file) > 0:
    try:
        with open(settings_file, 'r', encoding='utf-8') as f:
            clean_json = re.sub(r'//.*', '', f.read())
            settings_data = json.loads(clean_json)
    except Exception:
        settings_data = None

if isinstance(settings_data, dict):
    if settings_data.get("window.controlsStyle") != "custom":
        settings_data["window.controlsStyle"] = "custom"
        with open(settings_file, 'w', encoding='utf-8') as f:
            json.dump(settings_data, f, indent=4)

elif settings_data is None:
    with open(settings_file, 'r+', encoding='utf-8') as f:
        config_text = f.read()
        if '"window.controlsStyle"' not in config_text:
            modified_text = re.sub(r'\{\s*', '{\n    "window.controlsStyle": "custom",\n', config_text, count=1)
            f.seek(0); f.write(modified_text); f.truncate()
EOF

if [ "$1" != "--quiet" ]; then
    echo "Success: Custom CSS and settings updates applied successfully."
fi
