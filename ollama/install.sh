#!/bin/bash
set -euo pipefail

doas cp -r sv/ollama sv/open-webui /etc/sv/

curl -fsSL https://ollama.com/install.sh | doas sh

id ollama &>/dev/null || doas useradd -r -U -m -d /var/lib/ollama -s /bin/false ollama
id open-webui &>/dev/null || doas useradd -r -U -m -d /var/lib/open-webui -s /bin/false open-webui

doas env UV_PYTHON_INSTALL_DIR=/opt/open-webui/python uv venv --managed-python --allow-existing -p 3.11 /opt/open-webui/venv
doas uv pip install -p /opt/open-webui/venv --torch-backend cpu open-webui

doas ln -sf /etc/sv/ollama /etc/sv/open-webui /var/service/

until curl -fs http://127.0.0.1:11434 >/dev/null; do sleep 1; done
ollama pull qwen3.8

echo "Open WebUI: http://localhost:8080"
