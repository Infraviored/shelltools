ecp() {
    original_command="$*"
    current_dir=$(pwd)
    user=$(whoami)
    hostname=$(hostname)
    output=$(eval "$original_command")
    echo "$output"
    copy_text="${user}@${hostname}:${current_dir}$ $original_command
$output"
    echo -e "$copy_text" | xclip -selection clipboard
}


