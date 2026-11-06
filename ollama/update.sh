#!/bin/bash
set -euo pipefail

curl -fsSL https://ollama.com/install.sh | doas sh
doas sv restart ollama

doas uv pip install -p /opt/open-webui/venv --torch-backend cpu -U open-webui
doas sv restart open-webui

until curl -fs http://127.0.0.1:11434 >/dev/null; do sleep 1; done
ollama pull qwen3.8
