# Function to copy full path to clipboard
cpp() {
    # Function to get the absolute path
    get_absolute_path() {
        local path="$1"
        # Expand tilde to home directory
        path="${path/#\~/$HOME}"
        # Get the absolute path
        echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    }

    # Check if a file name is provided
    if [ $# -eq 0 ]; then
        echo "Usage: cpp <filename>"
        return 1
    fi

    # Get the absolute path
    full_path=$(get_absolute_path "$1")

    # Copy the path to clipboard
    echo -n "$full_path" | xclip -selection clipboard

    # Print the path
    echo "Full path copied to clipboard:"
    echo "$full_path"
}
