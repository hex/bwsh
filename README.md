# bwsh

Shell wrapper for [Bitwarden Secrets Manager](https://bitwarden.com/products/secrets-manager/) CLI (`bws`).

Simplifies local development by letting you manage secrets by name (not UUID), run commands with secrets injected, and migrate to/from `.env` files.

## Prerequisites

- [bws](https://bitwarden.com/help/secrets-manager-cli/) - Bitwarden Secrets Manager CLI
- [jq](https://jqlang.github.io/jq/) - JSON processor
- [age](https://github.com/FiloSottile/age) - Modern encryption tool (optional, for local caching)
- A Bitwarden Secrets Manager account with an access token

## Installation

### From source

```bash
git clone https://github.com/hex/bwsh.git
cd bwsh
./install.sh
```

### Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/hex/bwsh/main/install.sh | bash
```

> :warning: Always review scripts ([install.sh](install.sh)) before running them from the internet.

The installer:
- Adds `bwsh` to `~/.local/bin/`
- Installs shell completions for bash and zsh
- Optionally runs credential setup

## Setup

After installation, run the setup command to configure your credentials:

```bash
bwsh setup
```

This will prompt you for:
1. Your BWS access token (stored securely in `~/.config/bwsh/token`)
2. Your default project ID (optional - stored in `~/.config/bwsh/project`)

If you skip setting a default project, you'll be prompted to select one interactively when needed, or you can specify one with the `--project` flag.

Alternatively, set environment variables:
```bash
export BWS_ACCESS_TOKEN="your-token"
export BWS_DEFAULT_PROJECT_ID="your-project-id"  # optional
```

## Usage

### Run Commands with Secrets

Run any command with all secrets injected as environment variables:

```bash
bwsh run npm start
bwsh run python app.py
bwsh run docker-compose up

# Use a specific project
bwsh run -p <project_id> npm start
```

No `.env` file needed - secrets are injected directly into the subprocess.

### Export/Import .env Files

```bash
# Export secrets to .env format
bwsh env export > .env.local

# Import secrets from .env file
bwsh env import .env

# Import to a specific project
bwsh env import .env -p <project_id>

# Preview what would be imported
bwsh env import .env --dry-run
```

### Manage Secrets by Name

```bash
# Store a secret (prompts for value if omitted)
bwsh set API_KEY
bwsh set API_KEY sk-abc123

# Retrieve a secret
bwsh get API_KEY

# Use a specific project (overrides default)
bwsh set DB_PASS secret --project abc123
bwsh get DB_PASS -p abc123

# List all secrets
bwsh list

# Delete a secret
bwsh delete API_KEY
```

### Function Mode

Source the script to get shell functions:

```bash
# Add to ~/.bashrc or ~/.zshrc
source ~/.local/bin/bwsh
```

Then use the functions directly:

```bash
bwkey API_KEY sk-abc123    # Store
bwgetkey API_KEY           # Retrieve
bwkeys                     # List
bwdelkey API_KEY           # Delete
bwrun npm start            # Run with secrets
bwenv export               # Export .env
bwsh_load                  # Load all secrets from cache
```

### Encrypted Caching

For faster shell startup, bwsh can cache secrets locally with age encryption. Instead of making 14+ API calls at startup, it fetches once and caches.

**First, install age:**
```bash
brew install age
```

**Replace individual exports in your shell rc:**
```bash
# Before (slow - 14 API calls):
export ANTHROPIC_API_KEY=$(bwgetkey ANTHROPIC_API_KEY)
export OPENAI_API_KEY=$(bwgetkey OPENAI_API_KEY)
# ... more keys

# After (fast - 0-1 API calls):
source ~/.local/bin/bwsh
bwsh_load
```

**How it works:**
1. First load: fetches all secrets from bws, encrypts with age, stores locally
2. Subsequent loads: decrypts from local cache (instant)
3. Cache auto-refreshes when TTL expires (default: 1 hour)

**Cache management:**
```bash
bwsh cache status    # Check cache state
bwsh cache refresh   # Force refresh now
bwsh cache clear     # Delete local cache
```

**Configuration:**
```bash
export BWSH_CACHE_TTL=7200  # 2 hour TTL (default: 3600)
```

**Security:**
- Cache is encrypted with age (ChaCha20-Poly1305)
- Age key stored at `~/.config/bwsh/age.key` (chmod 600)
- Cache stored at `~/.cache/bwsh/secrets.age`
- If bws is unavailable, stale cache is used with a warning

### Tab Completion

After installation, enable completions in your shell:

**Bash** - Add to `~/.bashrc`:
```bash
[[ -f ~/.bash_completion.d/bwsh.bash ]] && source ~/.bash_completion.d/bwsh.bash
```

**Zsh** - Add to `~/.zshrc` (before compinit):
```bash
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```

### Project Resolution

Commands that create secrets (`set`, `run`, `env import`) need a project. Projects are resolved in this order:

1. **Explicit flag** (`--project` or `-p`) - highest priority
2. **Default project** from config (`BWS_DEFAULT_PROJECT_ID`)
3. **Interactive selection** - if no default is set, you'll be prompted to choose

If you have only one project, it will be auto-selected without prompting.

### Uninstall

```bash
bwsh uninstall          # Remove bwsh, keep config and cache
bwsh uninstall --force  # Remove everything including credentials
```

After uninstalling, remove these lines from your shell rc file:
```bash
source ~/.local/bin/bwsh
bwsh_load
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BWS_ACCESS_TOKEN` | Bitwarden Secrets Manager access token | (from config file) |
| `BWS_DEFAULT_PROJECT_ID` | Default project ID for creating secrets | (from config file) |
| `BWSH_TOKEN_FILE` | Path to token file | `~/.config/bwsh/token` |
| `BWSH_PROJECT_FILE` | Path to project ID file | `~/.config/bwsh/project` |
| `BWSH_CACHE_DIR` | Cache directory | `~/.cache/bwsh` |
| `BWSH_CACHE_TTL` | Cache TTL in seconds | `3600` |

## Files

```
~/.local/bin/bwsh              # Main script
~/.config/bwsh/token           # Access token (chmod 600)
~/.config/bwsh/project         # Default project ID
~/.config/bwsh/age.key         # Age encryption key (chmod 600)
~/.cache/bwsh/secrets.age      # Encrypted secrets cache
~/.bash_completion.d/bwsh.bash # Bash completions
~/.zsh/completions/_bwsh       # Zsh completions
```

## License

MIT
