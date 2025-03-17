#!/bin/bash

multilinefile() {
    # Help function
    multilinefile_help() {
        echo "Usage: multilinefile <filename>"
        echo
        echo "Create or overwrite a file with multi-line content."
        echo "Type your content and end with 'END' on a new line."
        echo
        echo "Example:"
        echo "  multilinefile myfile.txt"
        echo "  [type content]"
        echo "  END"
    }

    # Check if help is requested
    if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
        multilinefile_help
        return 0
    fi

    local filename="$1"
    
    echo "Enter your multi-line content. Type 'END' on a new line to finish."
    echo "Content will be saved to: $filename"
    echo "---Begin typing below this line---"

    # Use a temporary file to store content while typing
    local tempfile=$(mktemp)
    
    while IFS= read -r line; do
        [[ $line == "END" ]] && break
        echo "$line" >> "$tempfile"
    done

    # Move temp file to final destination
    mv "$tempfile" "$filename"
}

# If this script is sourced, don't execute anything
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    return 0
fi

# If the script is executed directly, run the multilinefile function
multilinefile "$@"
