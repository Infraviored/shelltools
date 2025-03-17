#!/bin/bash
add_program() {
  local program_path="$1"
  if [ -z "$program_path" ]; then
    echo "Usage: add_program <path_to_program>"
    return 1
  fi
  if [ ! -f "$program_path" ]; then
    echo "Error: File does not exist: $program_path"
    return 1
  fi

  # Get absolute path
  program_path=$(readlink -f "$program_path")

  # Get program name
  echo -n "How should the program be called? "
  read program_name
  if [ -z "$program_name" ]; then
    echo "Error: Program name cannot be empty"
    return 1
  fi

  # Make program executable
  chmod +x "$program_path"

  # Create symbolic link in /usr/local/bin
  sudo ln -sf "$program_path" "/usr/local/bin/$program_name"

  # Ask about desktop entry
  echo -n "Should a desktop link be created? (Y/N) "
  read create_desktop
  if [[ "$create_desktop" =~ ^[Yy]$ ]]; then
    # Ask for icon path
    echo -n "Specify Icon Path (blank to use default): "
    read icon_path

    # If icon path is empty, try to use the default icon from the program
    if [ -z "$icon_path" ]; then
      icon_path="$program_path"
    fi

    # Create desktop entry directory if it doesn't exist
    mkdir -p "$HOME/.local/share/applications"

    # Create .desktop file using the symbolic link name instead of direct path
    cat >"$HOME/.local/share/applications/${program_name}.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$program_name
Exec=$program_name
Icon=$icon_path
Categories=Utility;
Terminal=false
EOF

    # Make desktop file executable
    chmod +x "$HOME/.local/share/applications/${program_name}.desktop"
    echo "Desktop entry created successfully"
  fi

  echo "Program '$program_name' has been installed successfully"
  echo "You can now run it by typing '$program_name' in the terminal"
}
