function fritzbox-tunnel
    pkill -f "8443:192.168.178.1:443"
    ssh -fN -J ssh.infraviored.com -L 8443:192.168.178.1:443 root@192.168.178.100
    sleep 2
    firefox https://fritz.box:8443 &
end
