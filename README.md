# bwsh

Shell wrapper for [Bitwarden Secrets Manager](https://bitwarden.com/products/secrets-manager/) CLI (`bws`).

Simplifies local development by letting you manage secrets by name (not UUID), run commands with secrets injected, and migrate to/from `.env` files.

## Prerequisites

- [bws](https://bitwarden.com/help/secrets-manager-cli/) - Bitwarden Secrets Manager CLI
- [jq](https://jqlang.github.io/jq/) - JSON processor
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
2. Your default project ID (stored in `~/.config/bwsh/project`)

Alternatively, set environment variables:
```bash
export BWS_ACCESS_TOKEN="your-token"
export BWS_DEFAULT_PROJECT_ID="your-project-id"
```

## Usage

### Run Commands with Secrets

Run any command with all secrets injected as environment variables:

```bash
bwsh run npm start
bwsh run python app.py
bwsh run docker-compose up
```

No `.env` file needed - secrets are injected directly into the subprocess.

### Export/Import .env Files

```bash
# Export secrets to .env format
bwsh env export > .env.local

# Import secrets from .env file
bwsh env import .env

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
```

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

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BWS_ACCESS_TOKEN` | Bitwarden Secrets Manager access token | (from config file) |
| `BWS_DEFAULT_PROJECT_ID` | Default project ID for creating secrets | (from config file) |
| `BWSH_TOKEN_FILE` | Path to token file | `~/.config/bwsh/token` |
| `BWSH_PROJECT_FILE` | Path to project ID file | `~/.config/bwsh/project` |

## Files

```
~/.local/bin/bwsh              # Main script
~/.config/bwsh/token           # Access token (chmod 600)
~/.config/bwsh/project         # Default project ID
~/.bash_completion.d/bwsh.bash # Bash completions
~/.zsh/completions/_bwsh       # Zsh completions
```

## License

MIT
