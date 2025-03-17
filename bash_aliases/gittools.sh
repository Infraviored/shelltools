#!/bin/bash

gittools() {
    local subcommand="$1"
    shift

    case "$subcommand" in
        init_existing)
            gittools_init_existing "$@"
            ;;
        remote_add)
            gittools_remote_add
            ;;
        remote_delete)
            gittools_remote_delete
            ;;
        *)
            echo "Unknown subcommand: $subcommand"
            gittools_help
            return 1
            ;;
    esac
}

gittools_help() {
    echo "Usage: gittools <subcommand> [<args>]"
    echo
    echo "Subcommands:"
    echo "  init_existing  Initialize a local directory as a Git repository"
    echo "  remote_add     Add a new remote and attempt to push"
    echo "  remote_delete  Delete an existing remote"
    echo
    echo "For more information on a subcommand, run:"
    echo "  gittools <subcommand> --help"
}

gittools_init_existing() {
    # Help function
    gittools_init_existing_help() {
        echo "Usage: gittools init_existing <local_path> <remote_url>"
        echo
        echo "Initialize a local directory as a Git repository and push it to GitLab."
        echo
        echo "Arguments:"
        echo "  <local_path>  Path to the local directory (use '.' for current directory)"
        echo "  <remote_url>  URL of the GitLab repository (e.g., git@gitlab.com:username/repo.git)"
        echo
        echo "Example:"
        echo "  gittools init_existing . git@gitlab.com:username/repo.git"
    }

    # Check if help is requested
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        gittools_init_existing_help
        return 0
    fi

    # Check if both arguments are provided
    if [ $# -ne 2 ]; then
        echo "Error: Incorrect number of arguments."
        gittools_init_existing_help
        return 1
    fi

    local_path="$1"
    remote_url="$2"

    # Change to the specified directory
    cd "$local_path" || { echo "Error: Unable to change to directory $local_path"; return 1; }

    # Function to handle errors
    handle_error() {
        echo "Error: $1"
        return 1
    }

    # Initialize the repository
    git init || handle_error "Failed to initialize git repository"

    # Add the remote
    git remote add origin "$remote_url" || handle_error "Failed to add remote"

    # Fetch from the remote repository
    git fetch origin || handle_error "Failed to fetch from remote"

    # Check if the remote has a 'main' branch
    if git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
        remote_branch="main"
    else
        remote_branch="master"
    fi

    # If local repository is empty, reset to the remote branch
    if [ -z "$(git rev-parse --verify HEAD 2>/dev/null)" ]; then
        git reset --hard "origin/${remote_branch}" || handle_error "Failed to reset to remote branch"
    else
        # If not empty, merge the remote branch
        git merge --allow-unrelated-histories "origin/${remote_branch}" || handle_error "Failed to merge remote branch"
    fi

    # Ensure the local branch name matches the remote
    git branch -m "${remote_branch}" || handle_error "Failed to rename branch"

    # Add all files in the current directory
    git add . || handle_error "Failed to add files"

    # Commit changes
    git commit -m "Initial commit" || handle_error "Failed to commit changes"

    # Push to the remote repository
    git push -u origin "${remote_branch}" || handle_error "Failed to push to remote"

    echo "Repository initialized, files added, and pushed to remote successfully."
}

gittools_remote_add() {
    echo "Current remotes:"
    git remote -v
    echo
    read -p "Enter the URL for the new remote: " remote_url

    # Add the new URL as a second push URL for origin
    if git remote set-url --add --push origin "$remote_url"; then
        echo "Added $remote_url as a second pushing remote for origin."
        
        read -p "Should it be set as a second fetching remote as well? (Y/N): " add_fetch
        if [[ $add_fetch =~ ^[Yy]$ ]]; then
            if git remote set-url --add origin "$remote_url"; then
                echo "Added $remote_url as a second fetching remote for origin."
            else
                echo "Failed to add the URL as a fetching remote."
            fi
        fi

        echo "Updated remotes:"
        git remote -v

        # Attempt to push to all remotes
        if git push --all; then
            echo "Successfully pushed to all remotes."
        else
            echo "Push failed. One or more remotes may not be empty."
            read -p "Do you want to try force push? (y/N): " force_push
            if [[ $force_push =~ ^[Yy]$ ]]; then
                if git push --all -f; then
                    echo "Successfully force pushed to all remotes."
                else
                    echo "Force push failed."
                    read -p "Do you want to remove the newly added remote URL? (y/N): " remove_url
                    if [[ $remove_url =~ ^[Yy]$ ]]; then
                        git remote set-url --delete --push origin "$remote_url"
                        if [[ $add_fetch =~ ^[Yy]$ ]]; then
                            git remote set-url --delete origin "$remote_url"
                        fi
                        echo "Removed the new remote URL."
                        git remote -v
                    fi
                fi
            fi
        fi
    else
        echo "Failed to add the new remote URL."
    fi
}

gittools_remote_delete() {
    echo "Current remotes:"
    git remote -v
    echo

    # Get all unique URLs
    urls=($(git remote -v | awk '{print $2}' | sort -u))

    # If there are no URLs, exit
    if [ ${#urls[@]} -eq 0 ]; then
        echo "No remotes found."
        return
    fi

    # Print enumerated list of URLs
    for i in "${!urls[@]}"; do
        echo "$((i+1)). ${urls[$i]}"
    done

    # Ask user to select a URL
    read -p "Enter the number of the URL to delete: " selection

    # Validate input
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#urls[@]}" ]; then
        echo "Invalid selection."
        return
    fi

    # Get the selected URL
    selected_url=${urls[$((selection-1))]}

    # Try to remove the URL from both fetch and push configurations
    fetch_removed=false
    push_removed=false

    if git remote get-url origin | grep -q "$selected_url"; then
        if git remote set-url --delete origin "$selected_url"; then
            echo "Removed $selected_url from fetch URLs."
            fetch_removed=true
        else
            echo "Failed to remove $selected_url from fetch URLs."
        fi
    fi

    if git remote get-url --push origin | grep -q "$selected_url"; then
        if git remote set-url --delete --push origin "$selected_url"; then
            echo "Removed $selected_url from push URLs."
            push_removed=true
        else
            echo "Failed to remove $selected_url from push URLs."
        fi
    fi

    if $fetch_removed || $push_removed; then
        echo "Updated remotes:"
        git remote -v
    else
        echo "The specified URL was not found in the remote configuration."
    fi
}

# If this script is sourced, don't execute anything
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    return 0
fi

# If the script is executed directly, run the gittools function
gittools "$@"
