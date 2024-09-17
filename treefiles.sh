#!/bin/bash

treefiles() {
    shopt -s nullglob
    local dir_count=0
    local file_count=0

    local max_depth=2
    local prune=false
    local show_mode=false

    local -a ignore_patterns
    local -a file_paths

    usage() {
        echo "Usage: treefiles [-L level] [-P|--prune] [-I pattern]... [-S|--show] [directory]"
        echo
        echo "Options:"
        echo "  -L level     Set the maximum depth level (default: 2)"
        echo "  -P, --prune  Prune empty directories"
        echo "  -I pattern   Ignore files/directories matching the pattern"
        echo "  -S, --show   Show mode: display numbered list and allow selection"
        echo "  directory    The directory to display (default: current directory)"
    }

    # Default ignore patterns
    local -a default_ignore_patterns=(
        "**pycache**"
        "node_modules"
        ".git"
        ".vscode"
        ".idea"
        "__pycache__"
        "*.pyc"
        "*.pyo"
        "*.pyd"
        ".DS_Store"
        "Thumbs.db"
    )

    # Parse command line arguments
    local root="."
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -L) max_depth="$2"; shift ;;
            -P|--prune) prune=true ;;
            -I) ignore_patterns+=("$2"); shift ;;
            -S|--show) 
                show_mode=true
                max_depth=4
                prune=true
                ignore_patterns=("${default_ignore_patterns[@]}")
                ;;
            -h|--help) usage; return 0 ;;
            *) root="$1" ;;
        esac
        shift
    done

    # If no ignore patterns were specified and -S wasn't used, use empty array
    if [ ${#ignore_patterns[@]} -eq 0 ] && [ "$show_mode" = false ]; then
        ignore_patterns=()
    fi

    should_ignore() {
        local path="$1"
        for pattern in "${ignore_patterns[@]}"; do
            case "$pattern" in
                **)
                    if [[ "$path" == *"${pattern%\*\*}"* ]]; then
                        return 0
                    fi
                    ;;
                *)
                    if [[ "$(basename "$path")" == $pattern ]]; then
                        return 0
                    fi
                    ;;
            esac
        done
        return 1
    }

    traverse() {
        local directory=$1
        local prefix=$2
        local depth=$3

        [[ $max_depth -ne 0 && $depth -gt $max_depth ]] && return

        local children=("$directory"/*)
        local child_count=${#children[@]}

        for idx in "${!children[@]}"; do 
            local child=${children[$idx]}
            local child_name=${child##*/}

            if should_ignore "$child"; then
                continue
            fi

            local child_prefix="│   "
            local pointer="├── "

            if [ $idx -eq $((child_count - 1)) ]; then
                pointer="└── "
                child_prefix="    "
            fi

            local row_index=$(printf "%3d" ${#file_paths[@]})
            if $show_mode; then
                echo -n "$row_index "
            fi
            echo "${prefix}${pointer}${child_name}"
            
            file_paths+=("${child#./}")

            if [[ -d "$child" ]]; then
                dir_count=$((dir_count + 1))
                local next_depth=$((depth + 1))
                if ! $prune || [[ $(find "$child" -maxdepth 1 -mindepth 1 | wc -l) -gt 0 ]]; then
                    traverse "$child" "${prefix}$child_prefix" $next_depth
                fi
            else
                file_count=$((file_count + 1))
            fi
        done
    }

    print_tree() {
        file_paths=()
        dir_count=0
        file_count=0
        
        echo "Tree for $root with depth $max_depth, $(if $prune; then echo "pruned"; else echo "not pruned"; fi)"
        echo

        traverse "$root" "" 1

        echo
        echo "$dir_count directories, $file_count files"
    }

    print_file_content() {
        local file_path=$1
        echo "Content of $file_path:"
        echo "--------------------------------------------------------------------------------"
        cat "$file_path"
        echo
        echo "--------------------------------------------------------------------------------"
        echo
    }

    if $show_mode; then
        # First run: print tree with indices
        print_tree

        echo
        echo "Enter the row numbers you want to display (space-separated):"
        read -a selected_rows

        # Store selected paths
        local -a selected_paths
        for row in "${selected_rows[@]}"; do
            if [[ $row -ge 0 && $row -lt ${#file_paths[@]} ]]; then
                selected_paths+=("${file_paths[$row]}")
            else
                echo "Invalid row number: $row" >&2
            fi
        done

        # Second run: print tree without indices
        show_mode=false
        echo 
        echo
        print_tree

        echo
        echo "Important File contents"
        echo
        for path in "${selected_paths[@]}"; do
            if [[ -f "$path" ]]; then
                print_file_content "$path"
            else
                echo "Directory: $path"
                echo
            fi
        done
    else
        print_tree
    fi

    shopt -u nullglob
}
