#!/bin/bash

desktop_shortcut_cleaner() {
    local subcommand="$1"
    shift

    case "$subcommand" in
        search|s)
            desktop_shortcut_cleaner_search "$@"
            ;;
        broken|b)
            desktop_shortcut_cleaner_broken "$@"
            ;;
        help|h|"")
            desktop_shortcut_cleaner_help
            ;;
        *)
            echo "Error: Unknown subcommand: $subcommand"
            echo
            desktop_shortcut_cleaner_help
            return 1
            ;;
    esac
}

desktop_shortcut_cleaner_help() {
    echo "Usage: desktop-shortcut-cleaner COMMAND [OPTIONS]"
    echo
    echo "A tool for managing desktop shortcut files (.desktop files)"
    echo
    echo "Commands:"
    echo "  search, s    Search and delete desktop shortcuts by content"
    echo "  broken, b    Find and delete broken desktop shortcuts"
    echo "  help, h      Display this help message"
    echo
    echo "Run 'desktop-shortcut-cleaner COMMAND --help' for more information on a command."
}

desktop_shortcut_cleaner_search_help() {
    echo "Usage: desktop-shortcut-cleaner search [OPTIONS]"
    echo
    echo "Search for and delete desktop shortcuts by content or profile"
    echo
    echo "Options:"
    echo "  --help       Display this help message"
    echo "  ALL <profile> Delete all shortcuts for a specific profile"
    echo
    echo "Examples:"
    echo "  desktop-shortcut-cleaner search"
    echo "    Interactive search for desktop shortcuts"
    echo
    echo "  desktop-shortcut-cleaner search ALL Default"
    echo "    Find all shortcuts for the 'Default' profile"
}

desktop_shortcut_cleaner_broken_help() {
    echo "Usage: desktop-shortcut-cleaner broken [OPTIONS]"
    echo
    echo "Find and delete broken desktop shortcuts"
    echo
    echo "Options:"
    echo "  --help       Display this help message"
    echo
    echo "Examples:"
    echo "  desktop-shortcut-cleaner broken"
    echo "    Scan for broken desktop shortcuts and provide interactive deletion"
}

desktop_shortcut_cleaner_search() {
    if [[ "$1" == "--help" ]]; then
        desktop_shortcut_cleaner_search_help
        return 0
    fi

    local search_dir="$HOME/.local/share/applications"
    
    echo "Current desktop shortcut files in $search_dir:"
    ls -1 "$search_dir"/*.desktop 2>/dev/null
    echo ""
    
    # Check if ALL profile was specified directly on the command line
    if [[ "$1" == "ALL" && -n "$2" ]]; then
        local profile="$2"
        echo "Searching for all desktop shortcuts for profile '$profile'..."
        local matches=( "$search_dir"/*-"$profile".desktop )
        if [ ${#matches[@]} -eq 0 ] || [ ! -e "${matches[0]}" ]; then
            echo "No desktop shortcut files found for profile '$profile'."
            return 0
        fi
        
        echo "Found the following files for profile '$profile':"
        local index=1
        declare -A file_map
        for file in "${matches[@]}"; do
            if [ -f "$file" ]; then
                echo ""
                echo "[$index] ----------------------------------------"
                echo "Filename: $file"
                echo "----------------------------------------"
                cat "$file"
                echo "----------------------------------------"
                file_map[$index]="$file"
                ((index++))
            fi
        done
        
        echo ""
        echo "Select files to delete:"
        echo "  - Enter numbers separated by spaces (e.g., 1 3 4)"
        echo "  - Enter 'A' for all files"
        echo "  - Enter 'N' to cancel"
        read -p "Your choice: " choice
        
        if [[ "${choice,,}" == "n" ]]; then
            echo "Deletion aborted."
            return 0
        fi
        
        local files_to_delete=()
        if [[ "${choice,,}" == "a" ]]; then
            for file in "${matches[@]}"; do
                if [ -f "$file" ]; then
                    files_to_delete+=("$file")
                fi
            done
        else
            for num in $choice; do
                if [[ -n "${file_map[$num]}" ]]; then
                    files_to_delete+=("${file_map[$num]}")
                else
                    echo "Warning: Invalid selection '$num' ignored"
                fi
            done
        fi
        
        if [ ${#files_to_delete[@]} -gt 0 ]; then
            echo "Deleting selected files..."
            for file in "${files_to_delete[@]}"; do
                rm -v "$file"
            done
            echo "Deletion complete."
        else
            echo "No valid files selected for deletion."
        fi
        
        echo ""
        echo "Remaining desktop shortcut files in $search_dir:"
        ls -1 "$search_dir"/*.desktop 2>/dev/null
        return 0
    fi
    
    # Interactive mode
    echo "Usage:"
    echo "  To search by content, enter one or more search queries separated by spaces."
    echo "    (Files must contain ALL queries, case-insensitive.)"
    echo "  To delete all shortcuts for a profile, type: ALL <profile>"
    echo "    (For example: ALL Default or ALL Profile_1)"
    echo ""
    
    read -p "Enter search query (or 'ALL <profile>'): " -a inputs
    if [ ${#inputs[@]} -eq 0 ]; then
        echo "No input provided. Exiting."
        return 1
    fi

    if [[ "${inputs[0],,}" == "all" ]]; then
        if [ ${#inputs[@]} -lt 2 ]; then
            echo "Error: Please provide a profile name after ALL (e.g., Default or Profile_1)."
            return 1
        fi
        local profile="${inputs[1]}"
        echo "Searching for all desktop shortcuts for profile '$profile'..."
        local matches=( "$search_dir"/*-"$profile".desktop )
        if [ ${#matches[@]} -eq 0 ] || [ ! -e "${matches[0]}" ]; then
            echo "No desktop shortcut files found for profile '$profile'."
            return 0
        fi
        
        echo "Found the following files for profile '$profile':"
        local index=1
        declare -A file_map
        for file in "${matches[@]}"; do
            if [ -f "$file" ]; then
                echo ""
                echo "[$index] ----------------------------------------"
                echo "Filename: $file"
                echo "----------------------------------------"
                cat "$file"
                echo "----------------------------------------"
                file_map[$index]="$file"
                ((index++))
            fi
        done
        
        echo ""
        echo "Select files to delete:"
        echo "  - Enter numbers separated by spaces (e.g., 1 3 4)"
        echo "  - Enter 'A' for all files"
        echo "  - Enter 'N' to cancel"
        read -p "Your choice: " choice
        
        if [[ "${choice,,}" == "n" ]]; then
            echo "Deletion aborted."
            return 0
        fi
        
        local files_to_delete=()
        if [[ "${choice,,}" == "a" ]]; then
            for file in "${matches[@]}"; do
                if [ -f "$file" ]; then
                    files_to_delete+=("$file")
                fi
            done
        else
            for num in $choice; do
                if [[ -n "${file_map[$num]}" ]]; then
                    files_to_delete+=("${file_map[$num]}")
                else
                    echo "Warning: Invalid selection '$num' ignored"
                fi
            done
        fi
        
        if [ ${#files_to_delete[@]} -gt 0 ]; then
            echo "Deleting selected files..."
            for file in "${files_to_delete[@]}"; do
                rm -v "$file"
            done
            echo "Deletion complete."
        else
            echo "No valid files selected for deletion."
        fi
    else
        local queries=("${inputs[@]}")
        echo "Searching for desktop shortcuts containing all queries: ${queries[*]}"
        local files=( "$search_dir"/*.desktop )
        local matched_files=()
        
        for file in "${files[@]}"; do
            if [ -f "$file" ]; then
                local all_match=true
                for query in "${queries[@]}"; do
                    if ! grep -qi "$query" "$file"; then
                        all_match=false
                        break
                    fi
                done
                if $all_match; then
                    matched_files+=("$file")
                fi
            fi
        done
        
        if [ ${#matched_files[@]} -eq 0 ]; then
            echo "No desktop shortcut files found containing: ${queries[*]}"
            return 0
        fi
        
        echo "Found the following desktop shortcut files matching all queries:"
        local index=1
        declare -A file_map
        for file in "${matched_files[@]}"; do
            echo ""
            echo "[$index] ----------------------------------------"
            echo "Filename: $file"
            echo "----------------------------------------"
            cat "$file"
            echo "----------------------------------------"
            file_map[$index]="$file"
            ((index++))
        done
        
        echo ""
        echo "Select files to delete:"
        echo "  - Enter numbers separated by spaces (e.g., 1 3 4)"
        echo "  - Enter 'A' for all files"
        echo "  - Enter 'N' to cancel"
        read -p "Your choice: " choice
        
        if [[ "${choice,,}" == "n" ]]; then
            echo "Deletion aborted."
            return 0
        fi
        
        local files_to_delete=()
        if [[ "${choice,,}" == "a" ]]; then
            files_to_delete=("${matched_files[@]}")
        else
            for num in $choice; do
                if [[ -n "${file_map[$num]}" ]]; then
                    files_to_delete+=("${file_map[$num]}")
                else
                    echo "Warning: Invalid selection '$num' ignored"
                fi
            done
        fi
        
        if [ ${#files_to_delete[@]} -gt 0 ]; then
            echo "Deleting selected files..."
            for file in "${files_to_delete[@]}"; do
                rm -v "$file"
            done
            echo "Deletion complete."
        else
            echo "No valid files selected for deletion."
        fi
    fi
    
    echo ""
    echo "Remaining desktop shortcut files in $search_dir:"
    ls -1 "$search_dir"/*.desktop 2>/dev/null
}

# Function to check if a desktop file is broken
check_desktop_file() {
    local file="$1"
    local name=$(basename "$file" .desktop)
    
    # Extract the Exec line, handling quotes and parameters properly
    local exec_line=$(grep "^Exec=" "$file" | head -1 | sed 's/^Exec=//')
    
    # Remove desktop entry parameters (%f, %u, etc.)
    local clean_exec=$(echo "$exec_line" | sed 's/%[a-zA-Z]//g' | sed 's/%[%]/%/g')
    
    # Extract just the command (first part before any arguments)
    local cmd=$(echo "$clean_exec" | awk '{print $1}' | sed 's/"//g' | sed "s/'//g")
    
    # If it's empty, that's definitely a problem
    if [ -z "$cmd" ]; then
        echo "$file|empty command"
        return 0
    fi
    
    # Check if it's an absolute path
    if [[ "$cmd" == /* ]]; then
        if [ -x "$cmd" ]; then
            # Executable exists
            return 1
        elif [ -e "$cmd" ]; then
            echo "$file|file exists but not executable: $cmd"
            return 0
        else
            # Try to find it in common locations
            local basename_cmd=$(basename "$cmd")
            if command -v "$basename_cmd" &>/dev/null; then
                # Command exists by name
                return 1
            fi
            echo "$file|file not found: $cmd"
            return 0
        fi
    else
        # It's a command name, check if it exists in PATH
        if command -v "$cmd" &>/dev/null; then
            # Command exists in PATH
            return 1
        fi
        
        # Check common application directories
        for dir in ~/Programs ~/.local/bin ~/bin /opt /usr/local/bin; do
            if [ -x "$dir/$cmd" ]; then
                # Found in a common location
                return 1
            fi
        done
        
        # Try to launch it anyway as a final test
        if gtk-launch "$name" &>/dev/null; then
            return 1
        fi
        
        echo "$file|command not found: $cmd"
        return 0
    fi
}

desktop_shortcut_cleaner_broken() {
    if [[ "$1" == "--help" ]]; then
        desktop_shortcut_cleaner_broken_help
        return 0
    fi

    # Find all broken desktop files
    local broken_files=()
    local broken_reasons=()

    echo "Scanning for broken .desktop files..."
    for file in ~/.local/share/applications/*.desktop /usr/share/applications/*.desktop; do
        if [ -f "$file" ]; then
            result=$(check_desktop_file "$file")
            if [ $? -eq 0 ]; then
                IFS='|' read -r path reason <<< "$result"
                broken_files+=("$path")
                broken_reasons+=("$reason")
            fi
        fi
    done

    # Exit if no broken files found
    if [ ${#broken_files[@]} -eq 0 ]; then
        echo "No broken .desktop files found."
        return 0
    fi

    # Initialize array to track which files to delete
    local to_delete=()
    for ((i=0; i<${#broken_files[@]}; i++)); do
        to_delete[i]=0
    done

    # Function to display the list
    display_list() {
        clear
        echo "Found ${#broken_files[@]} broken .desktop files:"
        echo "----------------------------------------"
        for ((i=0; i<${#broken_files[@]}; i++)); do
            num=$((i+1))
            if [ ${to_delete[i]} -eq 1 ]; then
                mark="[X]"
            else
                mark="[ ]"
            fi
            echo "$num. $mark ${broken_files[i]}"
            echo "   Reason: ${broken_reasons[i]}"
        done
        echo "----------------------------------------"
        echo "Enter a number to toggle deletion, 'a' to select all, 'n' to select none,"
        echo "'d' to delete selected files, or 'q' to quit without deleting:"
    }

    # Main loop
    while true; do
        display_list
        read -r choice
        
        # Check if input is a number
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            index=$((choice-1))
            if [ "$index" -ge 0 ] && [ "$index" -lt ${#broken_files[@]} ]; then
                # Toggle the selection
                if [ ${to_delete[index]} -eq 0 ]; then
                    to_delete[index]=1
                else
                    to_delete[index]=0
                fi
            fi
        elif [ "$choice" == "a" ]; then
            # Select all
            for ((i=0; i<${#broken_files[@]}; i++)); do
                to_delete[i]=1
            done
        elif [ "$choice" == "n" ]; then
            # Select none
            for ((i=0; i<${#broken_files[@]}; i++)); do
                to_delete[i]=0
            done
        elif [ "$choice" == "d" ]; then
            # Delete selected files
            count=0
            for ((i=0; i<${#broken_files[@]}; i++)); do
                if [ ${to_delete[i]} -eq 1 ]; then
                    file="${broken_files[i]}"
                    if [ -w "$file" ]; then
                        rm "$file"
                        echo "Deleted: $file"
                        count=$((count+1))
                    else
                        echo "Cannot delete (permission denied): $file"
                        echo "Try running with sudo for system-wide .desktop files"
                    fi
                fi
            done
            echo "Deleted $count files."
            echo "Press Enter to continue..."
            read
            break
        elif [ "$choice" == "q" ]; then
            echo "Exiting without deleting any files."
            break
        fi
    done
}

# Create aliases for quick access
alias desktop-shortcut-cleaner="desktop_shortcut_cleaner"
alias dsc="desktop_shortcut_cleaner"

# Export the functions (if needed in subshells)
export -f desktop_shortcut_cleaner
export -f desktop_shortcut_cleaner_search
export -f desktop_shortcut_cleaner_broken
export -f desktop_shortcut_cleaner_help
export -f desktop_shortcut_cleaner_search_help
export -f desktop_shortcut_cleaner_broken_help
export -f check_desktop_file

# If the script is being run directly, call the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    desktop_shortcut_cleaner "$@"
fi
