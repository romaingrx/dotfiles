#!/usr/bin/env bash

# Default values
INTERFACES=("Wi-Fi" "USB 10/100/1000 LAN")
HOST="127.0.0.1"
PORT="8080"

# Help message
show_help() {
    echo "Usage: $0 [options] [on|off]"
    echo
    echo "Options:"
    echo "  -i, --interface <interface>  Network interface (default: Wi-Fi and USB 10/100/1000 LAN)"
    echo "  -h, --host <host>           Proxy host (default: 127.0.0.1)"
    echo "  -p, --port <port>           Proxy port (default: 8080)"
    echo "  --help                      Show this help message"
    echo
    echo "Commands:"
    echo "  on                          Enable proxy"
    echo "  off                         Disable proxy"
    echo "  status                      Show proxy status"
    echo
    echo "Examples:"
    echo "  $0 on                       Enable proxy on default interfaces"
    echo "  $0 off                      Disable proxy on default interfaces"
    echo "  $0 -i 'Wi-Fi' on            Enable proxy on Wi-Fi only"
    echo "  $0 status                   Show proxy status"
}

# Parse arguments
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interface)
            INTERFACES=("$2")
            shift 2
            ;;
        -h|--host)
            HOST="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        on|off|status)
            COMMAND="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if command is provided
if [ -z "$COMMAND" ]; then
    echo "Error: No command provided"
    show_help
    exit 1
fi

# Function to check if interface exists
interface_exists() {
    networksetup -getinfo "$1" &>/dev/null
    return $?
}

# Function to enable proxy
enable_proxy() {
    for interface in "${INTERFACES[@]}"; do
        if interface_exists "$interface"; then
            echo "Enabling proxy on $interface..."
            networksetup -setwebproxy "$interface" "$HOST" "$PORT"
            networksetup -setsecurewebproxy "$interface" "$HOST" "$PORT"
            networksetup -setwebproxystate "$interface" on
            networksetup -setsecurewebproxystate "$interface" on
        else
            echo "Warning: Interface $interface does not exist, skipping..."
        fi
    done
    echo "Proxy enabled"
}

# Function to disable proxy
disable_proxy() {
    for interface in "${INTERFACES[@]}"; do
        if interface_exists "$interface"; then
            echo "Disabling proxy on $interface..."
            networksetup -setwebproxystate "$interface" off
            networksetup -setsecurewebproxystate "$interface" off
        else
            echo "Warning: Interface $interface does not exist, skipping..."
        fi
    done
    echo "Proxy disabled"
}

# Function to show proxy status
show_status() {
    for interface in "${INTERFACES[@]}"; do
        echo "Status for $interface:"
        if interface_exists "$interface"; then
            echo "HTTP Proxy:"
            networksetup -getwebproxy "$interface"
            echo "HTTPS Proxy:"
            networksetup -getsecurewebproxy "$interface"
        else
            echo "Interface does not exist"
        fi
        echo
    done
}

# Execute command
case $COMMAND in
    on)
        enable_proxy
        ;;
    off)
        disable_proxy
        ;;
    status)
        show_status
        ;;
esac 