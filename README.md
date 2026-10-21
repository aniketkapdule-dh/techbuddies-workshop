# Designing Data Pipelines for AI Agents

Hands-on workshop demonstrating how to build streaming and batch data pipelines for AI agents:
- Stream ingestion and idempotence
- PII sanitization before vector embedding
- Vector storage and retrieval with LanceDB
- Real-time freshness vs. stale batch comparisons
- Grounding and evaluation with local LLMs (Ollama `gemma2:2b`)

---

## Quickstart

Clone the repository and run the setup script:

```bash
git clone https://github.com/aniketkapdule-dh/techbuddies-workshop.git
cd techbuddies-workshop
./setup.sh
```

**Prerequisites:** `git`, a terminal with `bash` and `curl` (macOS or Linux; on Windows use [WSL](https://learn.microsoft.com/windows/wsl/install)), an internet connection, and about 5 GB of free disk space. Nothing else is needed. You do not need Python or uv installed.

`./setup.sh` will automatically:
1. Install `uv` if it is missing (uv also downloads Python 3.12 for you).
2. Create a local virtual environment (`.venv`).
3. Install all pinned dependencies from `uv.lock` (`lancedb`, `sentence-transformers`, `polars`, `requests`, `ipykernel`, `pip`).
4. Register the Jupyter kernel as **`Python (techbuddies-workshop)`**.
5. Set up editor defaults for VS Code and PyCharm.
6. Offer to install Ollama (asks first), start it, and download the `gemma2:2b` model. Set `WORKSHOP_INSTALL_OLLAMA=yes` to skip the prompt.

If `uv` was just installed, open a new terminal (or run `source ~/.zshrc`) afterwards so it is on your `PATH`.

---

## Running the Notebook

### In Visual Studio Code
1. Open the project folder:
   ```bash
   code .
   ```
2. Open `dh_agent_pipeline_workshop.ipynb`.
3. In the top-right corner of the notebook editor, click **Select Kernel**.
4. Choose **Python Environments...** -> **`.venv (Python 3.x)`** or **Jupyter Kernel...** -> **`Python (techbuddies-workshop)`**.
5. Run the cells from top to bottom (`Shift + Enter`).

### In PyCharm
1. Open the project folder in PyCharm (`File > Open...`).
2. PyCharm will automatically detect the `.venv` in the project root.
3. Open `dh_agent_pipeline_workshop.ipynb`.
4. When prompted or in the notebook toolbar, ensure the kernel is set to **`Python (techbuddies-workshop)`** (or `.venv`).
5. Run the cells top to bottom.

---

## Local LLM Setup (Parts 4 & 5)

Parts 4 and 5 query **`gemma2:2b`** running locally via Ollama:
1. Make sure Ollama is installed:
   - **macOS:** `brew install ollama` (or download from [ollama.com](https://ollama.com))
   - **Linux:** `curl -fsSL https://ollama.com/install.sh | sh`
2. Start the Ollama server (in a terminal or launch the Ollama app):
   ```bash
   ollama serve
   ```
3. Pull the model (if `./setup.sh` did not already pull it):
   ```bash
   ollama pull gemma2:2b
   ```

> **Note:** If Ollama is not running, the notebook automatically falls back to deterministic template answers so you can still complete every step of the pipeline.
