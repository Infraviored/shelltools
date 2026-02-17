function gittools -d "Git tools helper"
    set -l subcommand $argv[1]
    set -e argv[1]

    switch "$subcommand"
        case init-existing
            gittools_init_existing $argv
        case remote-add
            gittools_remote_add
        case remote-delete
            gittools_remote_delete
        case local-prune
            gittools_local_prune
        case '*'
            echo "Unknown subcommand: $subcommand"
            gittools_help
            return 1
    end
end

function gittools_help
    echo "Usage: gittools <subcommand> [<args>]"
    echo
    echo "Subcommands:"
    echo "  init-existing  Initialize a local directory as a Git repository"
    echo "  remote-add     Add a new remote and attempt to push"
    echo "  remote-delete  Delete an existing remote"
    echo "  local-prune    Remove local branches that are gone on remote"
    echo
    echo "For more information on a subcommand, run:"
    echo "  gittools <subcommand> --help"
end

function gittools_init_existing
    function __gittools_init_existing_help
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
    end

    if contains -- -h $argv; or contains -- --help $argv
        __gittools_init_existing_help
        return 0
    end

    if test (count $argv) -ne 2
        echo "Error: Incorrect number of arguments."
        __gittools_init_existing_help
        return 1
    end

    set -l local_path $argv[1]
    set -l remote_url $argv[2]

    cd $local_path; or begin; echo "Error: Unable to change to directory $local_path"; return 1; end

    git init; or begin; echo "Error: Failed to initialize git repository"; return 1; end
    git remote add origin $remote_url; or begin; echo "Error: Failed to add remote"; return 1; end
    git fetch origin; or begin; echo "Error: Failed to fetch from remote"; return 1; end

    set -l remote_branch master
    if git ls-remote --exit-code --heads origin main >/dev/null 2>&1
        set remote_branch main
    end

    if test -z (git rev-parse --verify HEAD 2>/dev/null)
        git reset --hard "origin/$remote_branch"; or begin; echo "Error: Failed to reset to remote branch"; return 1; end
    else
        git merge --allow-unrelated-histories "origin/$remote_branch"; or begin; echo "Error: Failed to merge remote branch"; return 1; end
    end

    git branch -m $remote_branch; or begin; echo "Error: Failed to rename branch"; return 1; end
    git add .; or begin; echo "Error: Failed to add files"; return 1; end
    git commit -m "Initial commit"; or begin; echo "Error: Failed to commit changes"; return 1; end
    git push -u origin $remote_branch; or begin; echo "Error: Failed to push to remote"; return 1; end

    echo "Repository initialized, files added, and pushed to remote successfully."
end

function gittools_remote_add
    echo "Current remotes:"
    git remote -v
    echo
    read -P "Enter the URL for the new remote: " remote_url

    if git remote set-url --add --push origin "$remote_url"
        echo "Added $remote_url as a second pushing remote for origin."
        
        read -P "Should it be set as a second fetching remote as well? (Y/N): " add_fetch
        if string match -ri 'y' "$add_fetch"
            if git remote set-url --add origin "$remote_url"
                echo "Added $remote_url as a second fetching remote for origin."
            else
                echo "Failed to add the URL as a fetching remote."
            end
        end

        echo "Updated remotes:"
        git remote -v

        if git push --all
            echo "Successfully pushed to all remotes."
        else
            echo "Push failed. One or more remotes may not be empty."
            read -P "Do you want to try force push? (y/N): " force_push
            if string match -ri 'y' "$force_push"
                if git push --all -f
                    echo "Successfully force pushed to all remotes."
                else
                    echo "Force push failed."
                    read -P "Do you want to remove the newly added remote URL? (y/N): " remove_url
                    if string match -ri 'y' "$remove_url"
                        git remote set-url --delete --push origin "$remote_url"
                        if string match -ri 'y' "$add_fetch"
                            git remote set-url --delete origin "$remote_url"
                        end
                        echo "Removed the new remote URL."
                        git remote -v
                    end
                end
            end
        end
    else
        echo "Failed to add the new remote URL."
    end
end

function gittools_remote_delete
    echo "Current remotes:"
    git remote -v
    echo

    set -l urls (git remote -v | awk '{print $2}' | sort -u)

    if test (count $urls) -eq 0
        echo "No remotes found."
        return
    end

    for i in (seq (count $urls))
        echo "$i. $urls[$i]"
    end

    read -P "Enter the number of the URL to delete: " selection

    if not string match -qr '^[0-9]+$' "$selection"; or test "$selection" -lt 1; or test "$selection" -gt (count $urls)
        echo "Invalid selection."
        return
    end

    set -l selected_url $urls[$selection]

    set -l fetch_removed false
    set -l push_removed false

    if git remote get-url origin | grep -q "$selected_url"
        if git remote set-url --delete origin "$selected_url"
            echo "Removed $selected_url from fetch URLs."
            set fetch_removed true
        else
            echo "Failed to remove $selected_url from fetch URLs."
        end
    end

    if git remote get-url --push origin | grep -q "$selected_url"
        if git remote set-url --delete --push origin "$selected_url"
            echo "Removed $selected_url from push URLs."
            set push_removed true
        else
            echo "Failed to remove $selected_url from push URLs."
        end
    end

    if $fetch_removed; or $push_removed
        echo "Updated remotes:"
        git remote -v
    else
        echo "The specified URL was not found in the remote configuration."
    end
end

function gittools_local_prune
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Error: Not a git repository."
        return 1
    end

    echo "Fetching and pruning remote-tracking branches..."
    git fetch --prune

    # Identify local branches that are 'gone' on the remote
    # We look for "[gone]" in git branch -vv output
    set -l gone_branches (git branch -vv | grep ": gone]" | awk '{print $1}' | string replace -r '^\*' '')

    if test (count $gone_branches) -eq 0
        echo "No local branches found that are gone on the remote."
        return 0
    end

    echo "The following local branches are gone on the remote:"
    for branch in $gone_branches
        echo "  - $branch"
    end

    read -P "Should we remove these local branches? (y/N): " confirm
    if string match -ri 'y' "$confirm"
        for branch in $gone_branches
            git branch -D $branch
        end
        echo "Selected local branches removed."
    else
        echo "Operation cancelled."
    end
end
