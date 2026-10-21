#!/usr/bin/env bash
# ==============================================================================
# Setup script for Data Pipelines for AI Agents Workshop
# Works seamlessly on macOS and Linux for VS Code, PyCharm, and Jupyter
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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

# ------------------------------------------------------------------------------
# 1. Check Python installation (Python >= 3.10 required)
# ------------------------------------------------------------------------------
echo -e "${CYAN}[1/5] Checking Python installation...${NC}"

PYTHON_BIN=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
fi

if [ -z "$PYTHON_BIN" ]; then
    echo -e "${YELLOW}❌ Python 3 was not found on your system.${NC}"
    echo "Please install Python 3.10 or newer (via python.org, Homebrew, or your OS package manager)."
    exit 1
fi

PY_VERSION=$("$PYTHON_BIN" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PY_MAJOR=$("$PYTHON_BIN" -c "import sys; print(sys.version_info.major)")
PY_MINOR=$("$PYTHON_BIN" -c "import sys; print(sys.version_info.minor)")

if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ]; }; then
    echo -e "${YELLOW}❌ Detected Python $PY_VERSION. Python 3.10+ is required.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Found Python $PY_VERSION ($PYTHON_BIN)${NC}"

# ------------------------------------------------------------------------------
# 2. Setup Virtual Environment
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}[2/5] Creating / Verifying virtual environment (.venv)...${NC}"

VENV_DIR="$SCRIPT_DIR/.venv"

if command -v uv >/dev/null 2>&1; then
    echo -e "  Using ${BOLD}uv${NC} for ultrafast virtualenv and package management."
    if [ ! -d "$VENV_DIR" ]; then
        uv venv --seed "$VENV_DIR"
    fi
    # Ensure pip is installed in the virtualenv for Jupyter %pip compatibility
    uv pip install --quiet pip
    VENV_PYTHON="$VENV_DIR/bin/python"
else
    echo "  uv not detected; using standard python venv module."
    if [ ! -d "$VENV_DIR" ]; then
        "$PYTHON_BIN" -m venv "$VENV_DIR"
    fi
    VENV_PYTHON="$VENV_DIR/bin/python"
    "$VENV_PYTHON" -m pip install --quiet --upgrade pip
fi

echo -e "${GREEN}✓ Virtual environment configured at $VENV_DIR${NC}"

# ------------------------------------------------------------------------------
# 3. Install Required Dependencies
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}[3/5] Installing workshop dependencies...${NC}"

if command -v uv >/dev/null 2>&1; then
    uv pip install -r "$SCRIPT_DIR/requirements.txt"
else
    "$VENV_PYTHON" -m pip install -r "$SCRIPT_DIR/requirements.txt"
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
# 5. Check Ollama & LLM Model (Parts 4 & 5)
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}[5/5] Checking Ollama (local LLM for Parts 4 & 5)...${NC}"

MODEL="gemma2:2b"
if command -v ollama >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama CLI is installed.${NC}"
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Ollama server is currently running.${NC}"
        if ollama list 2>/dev/null | grep -q "$MODEL"; then
            echo -e "${GREEN}✓ Model '$MODEL' is already pulled and ready.${NC}"
        else
            echo "  Pulling model '$MODEL' (about 1.6 GB)..."
            ollama pull "$MODEL"
            echo -e "${GREEN}✓ Model '$MODEL' downloaded successfully.${NC}"
        fi
    else
        echo -e "${YELLOW}ℹ️  Ollama server is not running right now.${NC}"
        echo "   Before executing Parts 4 & 5, start it in a separate terminal with:"
        echo -e "     ${BOLD}ollama serve${NC}"
        echo "   And download the model with:"
        echo -e "     ${BOLD}ollama pull $MODEL${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  Ollama is not installed.${NC}"
    OS="$(uname -s)"
    if [ "$OS" = "Darwin" ]; then
        echo "   To enable local LLM answers on macOS:"
        echo -e "     1. Install Ollama: ${BOLD}brew install ollama${NC} (or from https://ollama.com)"
        echo -e "     2. Start the server: ${BOLD}ollama serve${NC}"
        echo -e "     3. Pull the model:   ${BOLD}ollama pull $MODEL${NC}"
    else
        echo "   To enable local LLM answers on Linux:"
        echo -e "     1. Install Ollama: ${BOLD}curl -fsSL https://ollama.com/install.sh | sh${NC}"
        echo -e "     2. Start the server: ${BOLD}ollama serve${NC}"
        echo -e "     3. Pull the model:   ${BOLD}ollama pull $MODEL${NC}"
    fi
    echo "   (Note: If Ollama is not running, the notebook automatically falls back to template answers.)"
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
