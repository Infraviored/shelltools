# rcdiscover function for managing and waking up devices
rcdiscover() {
    # Database of devices with MAC addresses and IP addresses
    declare -A device_database=(
        ["new_lab"]="78:d0:04:31:a0:94 10.0.2.81"
        ["blue_lab"]="78:d0:04:2d:5d:e3 10.0.1.108"
        ["ci_ng"]="48:b0:2d:e9:da:4d 10.0.1.122"
        ["ki4mrk"]="00:14:2d:68:b9:84 10.0.2.93"
        ["fpga_test"]="00:14:2d:2c:df:21 10.0.2.90"
        ["alex"]="00:14:2d:2c:de:bf 10.0.1.126"
        ["heiko_test"]="00:14:2d:2c:d5:35 10.0.2.45"
        ["felix160m"]="00:14:2d:2c:d4:ce 10.0.2.61"
        ["copperfield"]="00:14:2d:2c:6f:d7 10.0.1.128"
        ["ci_visard"]="00:14:2d:2c:6e:bb 10.0.1.120"
        ["jammy_cube"]="00:01:2e:aa:bc:dd 10.0.2.10"
        ["sales_cube"]="00:01:2e:a4:4e:90 10.0.2.62"
        ["heiko_cube"]="00:01:2e:96:ef:81 10.0.1.129"
        ["ci_cube"]="00:01:2e:96:1a:da 10.0.1.121"
    )

    # Function to create a clickable link
    make_link() {
        local url="$1"
        local text="$2"
        printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$url" "$text"
    }

    # Function to list all entries
    list_entries() {
        printf "%-5s | %-15s | %-7s | %-20s | %-15s\n" "Index" "Name" "Status" "MAC Address" "IP Address"
        printf "%-5s-+-%-15s-+-%-7s-+-%-20s-+-%-15s\n" "-----" "---------------" "-------" "--------------------" "---------------"
        local index=0
        for name in "${!device_database[@]}"; do
            read mac ip <<< "${device_database[$name]}"
            ip_link=$(make_link "http://$ip" "$ip")
            
            # Ping the device once
            if ping -c 1 -W 1 "$ip" &> /dev/null; then
                status="   ✓   "
            else
                status="   ✗   "
            fi
            
            printf "%-5s | %-15s | %-7s | %-20s | %-15s\n" "$index" "$name" "$status" "$mac" "$ip_link"
            ((index++))
        done
    }

    # Function to wake up a device
    wake_device() {
        local target="$1"
        local mac=""
        local ip=""
        local name=""
        
        # Check if the input is a number (index)
        if [[ "$target" =~ ^[0-9]+$ ]]; then
            local index=0
            for n in "${!device_database[@]}"; do
                if [ "$index" -eq "$target" ]; then
                    read mac ip <<< "${device_database[$n]}"
                    name="$n"
                    break
                fi
                ((index++))
            done
        else
            # Input is a name
            read mac ip <<< "${device_database[$target]}"
            name="$target"
        fi
        
        if [ -n "$mac" ]; then
            echo "Checking if $name ($ip) is already awake..."
            if ping -c 1 -W 1 "$ip" &> /dev/null; then
                echo "$name is already awake. No need to send wake-on-LAN packet."
            else
                echo "$name is not responding. Sending wake-on-LAN packet..."
                wakeonlan -i 10.0.3.255 "$mac"
                echo "Sent wake-on-LAN packet to $name ($mac)"
            fi
            
            echo "Opening http://${ip} in browser..."
            xdg-open "http://${ip}" &> /dev/null &
        else
            echo "Error: Device not found in the database."
            return 1
        fi
    }

    # Function to display help
    show_help() {
        echo "Usage: rcdiscover [OPTION] [TARGET]"
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
        echo "  rcdiscover 0           Check, wake up if needed, and open the first device in the list"
        echo "  rcdiscover heiko_cube  Check, wake up if needed, and open the device named 'heiko_cube'"
        echo "  rcdiscover -i          List devices, prompt for selection, then wake and open the selected device"
    }

    # Main function logic
    local target=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--list)
                list_entries
                return 0
                ;;
            -i|--input)
                list_entries
                echo
                echo "Select device to wake and open:"
                read -r target
                wake_device "$target"
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
    else
        wake_device "$target"
    fi
}
