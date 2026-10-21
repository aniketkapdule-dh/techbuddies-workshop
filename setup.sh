#!/usr/bin/env bash
# ==============================================================================
# Setup script for Data Pipelines for AI Agents Workshop
# Works on macOS and Linux (Windows: use WSL) for VS Code, PyCharm, and Jupyter.
# Starts from a bare machine: installs uv, which in turn downloads Python.
# Only requirements: bash, and curl or wget.
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PYTHON_VERSION="3.12"
MODEL="gemma2:2b"

# Color formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

echo -e "${BOLD}${BLUE}====================================================================${NC}"
echo -e "${BOLD}${BLUE}  Data Pipelines for AI Agents Workshop - Environment Setup       ${NC}"
echo -e "${BOLD}${BLUE}====================================================================${NC}"
echo ""
echo "Heads up: the first run downloads several GB (PyTorch, embedding model)."
echo "Make sure you have an internet connection and about 5 GB of free disk space."
echo ""

# Ask a yes/no question. Defaults to "no" when not interactive, unless the
# environment variable named in $2 is set to "yes".
ask_yes_no() {
    local prompt="$1" env_var="$2" answer=""
    if [ "${!env_var:-}" = "yes" ]; then
        return 0
    fi
    if [ -t 0 ]; then
        read -r -p "$prompt [y/N] " answer || true
        case "$answer" in
            y|Y|yes|YES) return 0 ;;
        esac
    fi
    return 1
}

download() {
    # download <url>: print the body to stdout using curl or wget
    if command -v curl >/dev/null 2>&1; then
        curl -LsSf "$1"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$1"
    else
        echo -e "${YELLOW}❌ Neither curl nor wget found. Please install one of them and re-run.${NC}" >&2
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 1. Ensure uv is installed (uv manages Python itself, no system Python needed)
# ------------------------------------------------------------------------------
echo -e "${CYAN}[1/5] Checking uv (Python and package manager)...${NC}"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

if command -v uv >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Found $(uv --version)${NC}"
else
    echo "  uv not found. Installing it now (https://docs.astral.sh/uv/)..."
    download https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    if ! command -v uv >/dev/null 2>&1; then
        echo -e "${YELLOW}❌ uv installation did not succeed. Install it manually from https://docs.astral.sh/uv/ and re-run.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Installed $(uv --version)${NC}"
fi

# ------------------------------------------------------------------------------
# 2. Create virtual environment (uv downloads Python $PYTHON_VERSION if needed)
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}[2/5] Creating / verifying virtual environment (.venv, Python ${PYTHON_VERSION})...${NC}"

VENV_DIR="$SCRIPT_DIR/.venv"

if [ ! -x "$VENV_DIR/bin/python" ]; then
    uv venv --seed --python "$PYTHON_VERSION" "$VENV_DIR"
fi
VENV_PYTHON="$VENV_DIR/bin/python"

echo -e "${GREEN}✓ Virtual environment ready at $VENV_DIR ($("$VENV_PYTHON" --version))${NC}"

# ------------------------------------------------------------------------------
# 3. Install Required Dependencies (pinned via uv.lock)
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}[3/5] Installing workshop dependencies (this can take a few minutes)...${NC}"

if [ -f "$SCRIPT_DIR/uv.lock" ]; then
    UV_PROJECT_ENVIRONMENT="$VENV_DIR" uv sync --python "$VENV_PYTHON"
else
    uv pip install --python "$VENV_PYTHON" -r "$SCRIPT_DIR/requirements.txt"
fi

echo -e "${GREEN}✓ Dependencies installed (lancedb, sentence-transformers, polars, requests, ipykernel).${NC}"

# ------------------------------------------------------------------------------
# 4. Register Jupyter Kernel and Configure IDEs
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}[4/5] Registering Jupyter kernel & configuring IDE defaults...${NC}"

# Register kernel with display name for VS Code & PyCharm
"$VENV_PYTHON" -m ipykernel install --user --name techbuddies-workshop --display-name "Python (techbuddies-workshop)" >/dev/null 2>&1

# Ensure VS Code settings exist for automatic interpreter detection
mkdir -p "$SCRIPT_DIR/.vscode"
cat << 'EOF' > "$SCRIPT_DIR/.vscode/settings.json"
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "jupyter.interactiveWindow.textEditor.executeSelection": true
}
EOF

echo -e "${GREEN}✓ Jupyter kernel 'Python (techbuddies-workshop)' registered.${NC}"
echo -e "${GREEN}✓ VS Code configuration (.vscode/settings.json) updated.${NC}"

# ------------------------------------------------------------------------------
# 5. Ollama & LLM Model (Parts 4 & 5)
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}[5/5] Setting up Ollama (local LLM for Parts 4 & 5)...${NC}"

OLLAMA_MANUAL_HINT=""
OS="$(uname -s)"

if ! command -v ollama >/dev/null 2>&1; then
    echo -e "${YELLOW}ℹ️  Ollama is not installed.${NC}"
    if ask_yes_no "  Install Ollama now (about 1.6 GB model download follows)?" WORKSHOP_INSTALL_OLLAMA; then
        if [ "$OS" = "Darwin" ]; then
            if command -v brew >/dev/null 2>&1; then
                brew install ollama || true
            else
                OLLAMA_MANUAL_HINT="Homebrew not found. Download the Ollama app from https://ollama.com/download"
            fi
        else
            # Official installer (may ask for sudo)
            download https://ollama.com/install.sh | sh || true
        fi
    else
        OLLAMA_MANUAL_HINT="Skipped. Install later from https://ollama.com/download (macOS: brew install ollama)"
    fi
fi

if command -v ollama >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama CLI is installed.${NC}"

    if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo "  Starting Ollama server in the background..."
        nohup ollama serve >/dev/null 2>&1 &
        for _ in $(seq 1 20); do
            if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
                break
            fi
            sleep 1
        done
    fi

    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Ollama server is running.${NC}"
        if ollama list 2>/dev/null | grep -q "$MODEL"; then
            echo -e "${GREEN}✓ Model '$MODEL' is already pulled and ready.${NC}"
        else
            echo "  Pulling model '$MODEL' (about 1.6 GB)..."
            ollama pull "$MODEL"
            echo -e "${GREEN}✓ Model '$MODEL' downloaded successfully.${NC}"
        fi
    else
        echo -e "${YELLOW}ℹ️  Could not start the Ollama server automatically.${NC}"
        echo "   Before executing Parts 4 & 5, run in a separate terminal:"
        echo -e "     ${BOLD}ollama serve${NC}"
        echo "   And download the model with:"
        echo -e "     ${BOLD}ollama pull $MODEL${NC}"
    fi
else
    [ -n "$OLLAMA_MANUAL_HINT" ] && echo "   $OLLAMA_MANUAL_HINT"
    echo "   Then run: ollama serve  and  ollama pull $MODEL"
    echo "   (Note: without Ollama the notebook automatically falls back to template answers.)"
fi

# ------------------------------------------------------------------------------
# Done!
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${GREEN}====================================================================${NC}"
echo -e "${BOLD}${GREEN}  Setup Complete! You are ready for the workshop.                  ${NC}"
echo -e "${BOLD}${GREEN}====================================================================${NC}"
echo ""
echo -e "${BOLD}How to run in your editor:${NC}"
echo ""
echo -e "  ${BOLD}Visual Studio Code:${NC}"
echo "    1. Open this folder in VS Code:  code ."
echo "    2. Open 'dh_agent_pipeline_workshop.ipynb'."
echo "    3. Click the kernel selector at the top-right and choose:"
echo "       'Python (techbuddies-workshop)' or '.venv'."
echo "    4. Run cells top to bottom!"
echo ""
echo -e "  ${BOLD}PyCharm:${NC}"
echo "    1. Open this folder in PyCharm."
echo "    2. PyCharm will automatically detect the .venv."
echo "    3. Open 'dh_agent_pipeline_workshop.ipynb'."
echo "    4. If prompted for a Jupyter server/kernel, select 'Python (techbuddies-workshop)'."
echo "    5. Run cells top to bottom!"
echo ""
