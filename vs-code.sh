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

TARGET_PATHS=()
for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        while IFS= read -r found_file; do
            if [ -n "$found_file" ]; then TARGET_PATHS+=("$found_file"); fi
        done < <(find "$dir" -type f -name "workbench.html" 2>/dev/null)
    fi
done
 
if [ "$1" == "--install-hook" ]; then
    if [ ${#TARGET_PATHS[@]} -eq 0 ]; then
        echo "Error: VS Code installation paths not found. Setup aborted." >&2
        exit 1
    fi

    echo "Deploying system-level filesystem monitors..."
 
    sudo tee /etc/systemd/system/vscode-css-worker.service > /dev/null <<EOF
[Unit]
Description=Universal VS Code CSS Re-Injection Module
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH --quiet --system-hook
EOF

    counter=1
    for path in "${TARGET_PATHS[@]}"; do
        suffix="file${counter}"
        [[ "$path" == *"insiders"* ]] && suffix="insiders-${counter}"
        [[ "$path" == *"portable"* ]] && suffix="portable-${counter}"

        sudo tee /etc/systemd/system/vscode-watch-${suffix}.path > /dev/null <<EOF
[Unit]
Description=Kernel Path Watcher for VS Code Workbench Modifications

[Path]
PathChanged=$path
Unit=vscode-css-worker.service

[Install]
WantedBy=multi-user.target
EOF
        
        sudo systemctl enable --now "vscode-watch-${suffix}.path"
        ((counter++))
    done

    sudo systemctl daemon-reload
    
     sudo systemctl start vscode-css-worker.service

    echo "Success: background filesystem protection activated successfully."
    exit 0
fi
 
if [ ${#TARGET_PATHS[@]} -eq 0 ] || [ ! -f "$CSS_SOURCE" ]; then exit 0; fi

for TARGET_PATH in "${TARGET_PATHS[@]}"; do
    
    quiet_mode=false
    if [ "$1" == "--quiet" ] || [ "$2" == "--quiet" ]; then quiet_mode=true; fi

     if [ ! -w "$TARGET_PATH" ] && [ "$EUID" -ne 0 ]; then
        if [ "$quiet_mode" = false ]; then
            echo "🔒 Elevated access required to update core styling files. Authenticating..."
        fi
        sudo "$SCRIPT_PATH" "$TARGET_PATH" "--quiet"
        continue
    fi

     if [ -f "$1" ] && [[ "$1" == *"workbench.html" ]]; then
        ACTIVE_TARGET="$1"
    else
        ACTIVE_TARGET="$TARGET_PATH"
    fi


    python3 - <<EOF "$ACTIVE_TARGET" "$CSS_SOURCE" "$quiet_mode"
import sys, re

target_file = sys.argv[1]
css_file = sys.argv[2]
quiet_mode = sys.argv[3] == "True"

try:
    with open(target_file, 'r', encoding='utf-8') as f:
        content = f.read()

    if "<!-- CUSTOM CSS INJECTION START -->" in content and quiet_mode:
        sys.exit(0)

    with open(css_file, 'r', encoding='utf-8') as f:
        css_content = f.read()

    content = re.sub(r'<!-- CUSTOM CSS INJECTION START -->.*?<!-- CUSTOM CSS INJECTION END -->', '', content, flags=re.DOTALL)
    payload = f"\n<!-- CUSTOM CSS INJECTION START -->\n<style>\n{css_content}\n</style>\n<!-- CUSTOM CSS INJECTION END -->"

    if "</head>" in content:
        content = content.replace("</head>", f"{payload}\n</head>")
    else:
        content = content + payload

    with open(target_file, 'w', encoding='utf-8') as f:
        f.write(content)
except Exception as e:
    if not quiet_mode:
        print(f"Error patching target layout structure: {e}")
EOF

    if [ -f "$1" ] && [[ "$1" == *"workbench.html" ]]; then exit 0; fi

    if [ "$quiet_mode" = false ]; then
        echo "Injected theme assets into: $TARGET_PATH"
    fi
done
