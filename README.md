# Shelltools

This repository contains a collection of powerful shell utilities designed to enhance your command-line productivity. Each tool is crafted to simplify specific tasks and streamline your workflow.

## Tools

### Copy Path (cpp.sh)

The `cpp` function quickly copies the full path of a file to your clipboard.

#### Usage:
```bash
cpp <filename>
```

#### Features:
- Expands tilde to home directory
- Gets the absolute path of the file
- Copies the path to the clipboard using `xclip`
- Prints the copied path to the console

### Execute Copy (ecp.sh)

The `ecp` function executes a command and copies both the command and its output to the clipboard, perfect for documentation or sharing command results.

#### Usage:
```bash
ecp <command>
```

#### Features:
- Executes the given command
- Captures the current directory, user, and hostname
- Copies the command, its output, and contextual information to the clipboard using `xclip`

### Git Tools (gittools.sh)

`gittools` is a comprehensive set of Git-related utilities that simplify repository management tasks.

#### Usage:
```bash
gittools <subcommand> [<args>]
```

#### Subcommands:
- `init_existing`: Initialize a local directory as a Git repository and push it to GitLab
- `remote_add`: Add a new remote and attempt to push
- `remote_delete`: Delete an existing remote

#### Features:
- Comprehensive error handling
- Interactive prompts for user input
- Supports both fetching and pushing configurations

### RC Discover and Wake (rcwake.sh)

`rcdiscover` is a powerful tool for managing and waking up network devices using Wake-on-LAN.

#### Usage:
```bash
rcdiscover [OPTION] [TARGET]
```

#### Options:
- `-l, --list`: List all available devices
- `-i, --input`: List devices and prompt for selection
- `-h, --help`: Display help message

#### Features:
- Maintains a database of devices with MAC and IP addresses
- Checks if a device is already awake before sending a wake-on-LAN packet
- Opens the device's IP address in a browser after waking

### Tree Files (treefiles.sh)

`treefiles` is an advanced file and directory visualization tool that displays a customizable tree-like structure of your filesystem.

#### Usage:
```bash
treefiles [-L level] [-P|--prune] [-I pattern]... [-S|--show] [directory]
```

#### Options:
- `-L level`: Set the maximum depth level (default: 2)
- `-P, --prune`: Prune empty directories
- `-I pattern`: Ignore files/directories matching the pattern
- `-S, --show`: Show mode: display numbered list and allow selection

#### Features:
- Customizable depth level
- Option to prune empty directories
- Ignore patterns for excluding files and directories
- Show mode for interactive file selection and content display

### Desktop Shortcut Cleaner (clean_shortcuts.sh)

`desktop-shortcut-cleaner` is a comprehensive utility for managing desktop shortcut files (.desktop files) in your system.

#### Usage:
```bash
desktop-shortcut-cleaner COMMAND [OPTIONS]
```

#### Commands:
- `search, s`: Search and delete desktop shortcuts by content
- `broken, b`: Find and delete broken desktop shortcuts
- `help, h`: Display help message

#### Aliases:
- `dsc`: Shorthand for desktop-shortcut-cleaner

#### Features:
- Search for desktop files by content or profile name
- Find broken shortcuts by checking if the executable exists
- Interactive interface to select which files to delete
- Detailed information about why each shortcut is considered broken
- Handles permission issues gracefully, suggesting sudo when needed
- Command-specific help with examples

Each tool in this collection is designed to address specific needs and improve your command-line experience. Explore the usage and features of each tool to boost your productivity and simplify your daily tasks.
