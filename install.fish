#!/usr/bin/fish

# Shelltools Installation Script (Fish Version)

# Determine the directory where the script is located
set -l SCRIPT_DIR (realpath (dirname (status filename)))

# Create the installation message
echo "================================================="
echo "      Installing Shelltools to Fish"
echo "================================================="
echo
echo "This script will:"
echo "1. Add a loop to ~/.config/fish/config.fish to source your Fish aliases"
echo "2. Ensure the shelltools integration is clean"
echo

# Ask for confirmation
read -P "Do you want to continue? (y/n): " confirm
if not string match -ri 'y' "$confirm"
    echo "Installation cancelled."
    exit 1
end

# Check if config.fish exists, create if not
if not test -f ~/.config/fish/config.fish
    mkdir -p ~/.config/fish
    touch ~/.config/fish/config.fish
end

# Remove old integration if it exists
if grep -q "# Shelltools Integration (Fish)" ~/.config/fish/config.fish
    echo "Removing old Shelltools integration from ~/.config/fish/config.fish..."
    # This is a bit tricky with sed in Fish/Linux to handle multi-line blocks correctly
    # We'll use a temporary file to filter it out
    set -l tmpfile (mktemp)
    sed '/# Shelltools Integration (Fish)/,/end # End Shelltools Integration/d' ~/.config/fish/config.fish > $tmpfile
    mv $tmpfile ~/.config/fish/config.fish
end

# Add the source commands to config.fish
echo "Adding Shelltools to ~/.config/fish/config.fish..."
set -l timestamp (date)

echo "
# Shelltools Integration (Fish)
# Added on $timestamp
if test -d $SCRIPT_DIR/fish_aliases
    for f in $SCRIPT_DIR/fish_aliases/*.fish
        source \$f
    end
end # End Shelltools Integration" >> ~/.config/fish/config.fish

echo "Shelltools successfully added to ~/.config/fish/config.fish"
echo
echo "Installation complete!"
echo "Please restart your terminal or run 'source ~/.config/fish/config.fish' to use the tools."
