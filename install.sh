#!/bin/bash

# Shelltools Installation Script

# Determine the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Only run the installation if this script is being executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Create the installation message
    cat << EOF
=================================================
      Installing Shelltools to your system
=================================================

This script will:
1. Source all shell tools in your ~/.bash_aliases file
2. Make the scripts executable

EOF

    # Ask for confirmation
    read -p "Do you want to continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi

    # Make all scripts executable
    echo "Making scripts executable..."
    chmod +x "$SCRIPT_DIR/bash_aliases"/*.sh

    # Check if the tools are already sourced in .bashrc
    if grep -q "# Shelltools Integration" ~/.bashrc; then
        echo "Removing old Shelltools integration from ~/.bashrc..."
        # Remove the old integration
        sed -i '/# Shelltools Integration/,/done/d' ~/.bashrc
    fi

    # Check if the tools are already sourced in .bash_aliases
    if grep -q "# Shelltools Integration" ~/.bash_aliases; then
        echo "Removing old Shelltools integration from ~/.bash_aliases..."
        # Remove the old integration
        sed -i '/# Shelltools Integration/,/done/d' ~/.bash_aliases
    fi

    # Add the source commands to .bash_aliases
    echo "Adding Shelltools to ~/.bash_aliases..."
    
    cat << EOF >> ~/.bash_aliases

# Shelltools Integration
# Added on $(date)
for tool in "$SCRIPT_DIR/bash_aliases"/*.sh; do
    if [ -f "\$tool" ]; then
        source "\$tool"
    fi
done
EOF
    echo "Shelltools successfully added to ~/.bash_aliases"

    echo
    echo "Installation complete!"
    echo "Please restart your terminal or run 'source ~/.bash_aliases' to use the tools."
fi 