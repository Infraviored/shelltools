#!/bin/bash

rccopykeys() {
    local user="rc"
    local password="roboception"

    # List of IP suffixes; complete IPs are:
    # 10.0.1.121, 10.0.1.110, 10.0.1.111, 10.0.1.108, 10.0.2.34, 10.0.2.10
    local ips=(
        "10.0.1.121"
        "10.0.1.110"
        "10.0.1.111"
        "10.0.1.108"
        "10.0.2.34"
        "10.0.2.10"
    )

    # Allow custom identity file if provided as an option
    local identity_opt=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i)
                if [ -n "$2" ]; then
                    identity_opt="-i $2"
                    shift 2
                else
                    echo "Error: -i option requires an argument"
                    return 1
                fi
                ;;
            *)
                echo "Usage: rccopykeys [-i identity_file]"
                return 1
                ;;
        esac
    done

    # Check if sshpass is installed
    if ! command -v sshpass &> /dev/null; then
        echo "Error: 'sshpass' is not installed. Please install it first (e.g., sudo apt install sshpass)."
        return 1
    fi

    for ip in "${ips[@]}"; do
        if ! ping -c 1 -W 1 "$ip" &> /dev/null; then
            echo "=> ${ip} is offline (ping timed out), skipping"
            continue
        fi

        # Remove old host key to prevent "identification changed" warnings
        ssh-keygen -R "$ip" &> /dev/null

        echo "=> Copying SSH key to ${user}@${ip}"
        if [ -n "$identity_opt" ]; then
            sshpass -p "$password" ssh-copy-id -o StrictHostKeyChecking=no $identity_opt "${user}@${ip}"
        else
            sshpass -p "$password" ssh-copy-id -o StrictHostKeyChecking=no "${user}@${ip}"
        fi
        
        if [ $? -eq 0 ]; then
            echo "   OK: key copied to ${ip}"
        else
            echo "   FAIL: failed to copy key to ${ip}"
        fi
    done

    echo "Done."
}

# Add alias for alternative command formats
alias rc-copy-keys="rccopykeys"
alias rc-copy-id="rccopykeys"
