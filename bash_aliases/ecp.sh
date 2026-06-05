ecp() {
    original_command=$(printf '%q ' "$@")
    current_dir=$(pwd)
    user=$(whoami)
    hostname=$(hostname)
    output=$(eval "$original_command")
    echo "$output"
    copy_text="${user}@${hostname}:${current_dir}$ $original_command
$output"
    if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy &>/dev/null; then
        echo -e "$copy_text" | wl-copy
    elif [ -n "$DISPLAY" ] && command -v xclip &>/dev/null; then
        echo -e "$copy_text" | xclip -selection clipboard
    elif [ -n "$DISPLAY" ] && command -v xsel &>/dev/null; then
        echo -e "$copy_text" | xsel --clipboard --input
    else
        echo -e "$copy_text" | xclip -selection clipboard
    fi
}
