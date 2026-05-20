# rcwake function for managing and waking up devices
rcwake() {
    local db_file=""
    if [ -n "${BASH_SOURCE[0]}" ]; then
        db_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/devices.conf"
    fi
    if [ ! -f "$db_file" ]; then
        db_file="$HOME/.config/rcwake/devices.conf"
    fi

    if [ ! -f "$db_file" ]; then
        echo "Error: Devices database file not found at $db_file"
        return 1
    fi

    declare -a device_names
    declare -A device_database

    while read -r name mac ip || [ -n "$name" ]; do
        [[ -z "$name" || "$name" =~ ^# ]] && continue
        device_names+=("$name")
        device_database["$name"]="$mac $ip"
    done < "$db_file"

    make_link() {
        local url="$1"
        local text="$2"
        printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$url" "$text"
    }

    list_entries() {
        printf "Checking device status..."
        
        local results
        results=$(
            set +m
            declare -A ping_pids
            for name in "${device_names[@]}"; do
                read mac ip <<< "${device_database[$name]}"
                ping -c 1 -W 1 "$ip" &>/dev/null &
                ping_pids["$name"]=$!
            done

            for name in "${device_names[@]}"; do
                local pid=${ping_pids["$name"]}
                if wait "$pid" 2>/dev/null; then
                    echo "$name|✓"
                else
                    echo "$name|✗"
                fi
            done
        )

        declare -A device_status
        while IFS="|" read -r name status_char || [ -n "$name" ]; do
            [[ -z "$name" || "$name" =~ ^# ]] && continue
            if [ "$status_char" = "✓" ]; then
                device_status["$name"]="   ✓   "
            else
                device_status["$name"]="   ✗   "
            fi
        done <<< "$results"

        printf "\r\033[K"
        printf "%-5s | %-15s | %-7s | %-20s | %-15s\n" "Index" "Name" "Status" "MAC Address" "IP Address"
        printf "%-5s-+-%-15s-+-%-7s-+-%-20s-+-%-15s\n" "-----" "---------------" "-------" "--------------------" "---------------"
        local index=0
        for name in "${device_names[@]}"; do
            read mac ip <<< "${device_database[$name]}"
            ip_link=$(make_link "http://$ip" "$ip")
            status=${device_status["$name"]}
            printf "%-5s | %-15s | %-7s | %-20s | %-15s\n" "$index" "$name" "$status" "$mac" "$ip_link"
            ((index++))
        done
    }

    wake_device() {
        local target="$1"
        local mac=""
        local ip=""
        local name=""
        
        if [[ "$target" =~ ^[0-9]+$ ]]; then
            if [ "$target" -ge 0 ] && [ "$target" -lt "${#device_names[@]}" ]; then
                name="${device_names[$target]}"
                read mac ip <<< "${device_database[$name]}"
            fi
        else
            read mac ip <<< "${device_database[$target]}"
            name="$target"
        fi
        
        if [ -n "$mac" ]; then
            printf "Waking %s (%s)... Checking status" "$name" "$ip"
            if ping -c 1 -W 1 "$ip" &> /dev/null; then
                printf "\r\033[KWaking %s (%s)... Already awake. Opening browser...\n" "$name" "$ip"
            else
                printf "\r\033[KWaking %s (%s)... Sending WoL" "$name" "$ip"
                wakeonlan -i 10.0.3.255 "$mac" &>/dev/null
                
                local elapsed=0
                until ping -c 1 -W 1 "$ip" &> /dev/null; do
                    ((elapsed++))
                    printf "\r\033[KWaking %s (%s)... Waiting (%ds)" "$name" "$ip" "$elapsed"
                    sleep 1
                done
                printf "\r\033[KWaking %s (%s)... Awake after %ds! Opening browser...\n" "$name" "$ip" "$elapsed"
            fi
            
            xdg-open "http://${ip}" &> /dev/null &
        else
            echo "Error: Device not found in the database."
            return 1
        fi
    }

    show_help() {
        echo "Usage: rcwake [OPTION] [TARGET]"
        echo
        echo "Wake-on-LAN tool for managing and waking up devices."
        echo
        echo "Options:"
        echo "  -l, --list     List all available devices"
        echo "  -i, --input    List devices and prompt for selection"
        echo "  -h, --help     Display this help message"
        echo
        echo "If no option is provided, the list of devices will be displayed."
        echo
        echo "To wake up a device, provide either its index number or name as the TARGET."
        echo "The script will first ping the device to check if it's already awake."
        echo "If the device doesn't respond to the ping, a wake-on-LAN packet will be sent."
        echo "The device's IP address will then be opened in a browser."
        echo
        echo "Examples:"
        echo "  rcwake 0           Check, wake up if needed, and open the first device in the list"
        echo "  rcwake heiko_cube  Check, wake up if needed, and open the device named 'heiko_cube'"
        echo "  rcwake -i          List devices, prompt for selection, then wake and open the selected device"
    }

    local target=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--list)
                list_entries
                return 0
                ;;
            -i|--input)
                list_entries
                echo
                printf "Select device to wake and open: "
                read -r target
                if [ -n "$target" ]; then
                    wake_device "$target"
                fi
                return 0
                ;;
            -h|--help)
                show_help
                return 0
                ;;
            *)
                if [ -z "$target" ]; then
                    target="$1"
                else
                    echo "Error: Too many arguments"
                    show_help
                    return 1
                fi
                shift
                ;;
        esac
    done

    if [ -z "$target" ]; then
        list_entries
        echo
        printf "Select device to wake and open: "
        read -r target
        if [ -n "$target" ]; then
            wake_device "$target"
        fi
    else
        wake_device "$target"
    fi
}
