# Tmux Sessionizer

`Tmux Sessionizer` is a Bash script inspired by the Primeagen that automates the creation and management of Tmux sessions based on a user-defined configuration file. It allows you to quickly set up and switch between Tmux sessions, including specific directories, windows, and commands.

## Features

- Automatically create Tmux sessions based on a configuration file (`sessionizer.config.yaml`).
- Supports multiple search paths for project directories.
- Automatically finds project directories containing `.git` or `.session.config.yaml`.
- Configurable session windows and scripts.
- Supports FZF for quick selection of project directories.
- Automatically sets up Tmux session windows and runs setup scripts.

## Prerequisites

- **Tmux**: Make sure Tmux is installed and available in your `$PATH`.
- **yq**: This script relies on `yq` to parse YAML configuration files. Install it using:
  ```bash
  # Install yq (choose the appropriate installation method for your OS)
  # For example, using Homebrew on macOS:
  brew install yq
  ```
- **fzf**: The script uses `fzf` for fuzzy finding. Install it using:
  ```bash
  # Install fzf (choose the appropriate installation method for your OS)
  # For example, using Homebrew on macOS:
  brew install fzf
  ```

### Supported Shells
- `zsh`
- `bash`
***More coming soon!***


## Installation & Setup

### Installation
You can install the `tmux-sessionizer` with the following commands:
```bash
# For people on bash:
curl -sS https://raw.githubusercontent.com/BriHan-Tech/tmux-sessionizer/refs/heads/master/install.sh | bash

# For people on zsh:
curl -sS https://raw.githubusercontent.com/BriHan-Tech/tmux-sessionizer/refs/heads/master/install.sh | zsh
```

This will install the `sessionizer` script in the `~/.tmux/scripts/` directory. 
Then, it will bind the script to `Ctrl + f`

Note: If your user does not have permission, you will need:
```bash
curl -sS https://raw.githubusercontent.com/BriHan-Tech/tmux-sessionizer/main/install-sessionizer.sh | sudo <your-shell> 
```

### Setup
You can set up keyboard shorcuts to `tmux-sessionizer` by using the `sessionizer` alias.

For instance, I bound `Ctrl + f` to start the sessionizer:
```bash
bindkey -s ^f "sessionizer\n"
```


## Usage

### Basic Usage

The `sessionizer`  alias will launch `tmux-sessionizer`!

### Selecting a Project Directory

The script searches for project directories containing `.git` or `.session.config.yaml` files within the specified search paths defined in the `sessionizer.config.yaml` file. It uses `fzf` for fuzzy selection, allowing you to quickly choose the desired project directory.

### Configuration File

By default, the script looks for a configuration file at `~/.config/tmux/sessionizer.config.yaml`. You can override this location and file name by setting the `TMUX_SESSIONIZER` environment variable.

Example `sessionizer.config.yaml`:
```yaml
search_paths:
  paths:
    - "~/projects"
    - "~/work"
  mindepth: 1
  maxdepth: 3
```

### Session Configuration

Each project directory can contain a `.session.config.yaml` file to define session-specific configurations:

Example `.session.config.yaml`:
```yaml
name: my_project
directory: ~/projects/my_project
setup_script:
  - source venv/bin/activate
  - npm install
windows:
  - name: editor
    directory: ~/projects/my_project
    script:
      - vim
  - name: server
    directory: ~/projects/my_project
    script:
      - npm start
```

## How It Works

1. The script checks if `yq` is installed.
2. It loads the sessionizer configuration (`sessionizer.config.yaml`) to get search paths.
3. It searches for directories containing `.git` or `.session.config.yaml` files.
4. It prompts you to select a directory using `fzf` (if not provided as an argument).
5. It creates a new Tmux session with the name and directory specified in `.session.config.yaml` or defaults to the directory name.
6. It sets up the Tmux session windows, runs setup scripts, and attaches or switches to the session.

## Notes

- The script supports window scripts and session setup scripts defined in `.session.config.yaml`.
- If a session already exists with the same name, the script will switch to that session instead of creating a new one.

## Future Improvements

- Major Refactorings~
- Support for configuring Tmux panes within windows.

## License

This project is licensed under the MIT License.

