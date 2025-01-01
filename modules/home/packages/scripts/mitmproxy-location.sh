#!/usr/bin/env bash

# Default values
INTERFACE="Wi-Fi"
HOST="127.0.0.1"
PORT="8080"
LOCATION_NAME="mitm-proxy"
CERT_DIR="$HOME/.mitmproxy"
INSTALL_CERT=true
REMOVE_CERT=false

# Help message
show_help() {
    echo "Usage: $0 [options] [-- mitmproxy_options]"
    echo
    echo "Options:"
    echo "  -i, --interface <interface>  Network interface (default: Wi-Fi)"
    echo "  -h, --host <host>           Proxy host (default: 127.0.0.1)"
    echo "  -p, --port <port>           Proxy port (default: 8080)"
    echo "  -l, --location <name>       Network location name (default: mitm-proxy)"
    echo "  -c, --cert-dir <dir>        Certificate directory (default: ~/.mitmproxy)"
    echo "  --no-cert                   Skip certificate installation"
    echo "  --remove-cert               Remove certificates on exit (default: false)"
    echo "  --help                      Show this help message"
    echo
    echo "Everything after -- is passed directly to mitmproxy"
    echo
    echo "Examples:"
    echo "  $0 -i 'Wi-Fi' -p 8081 -- --mode regular --showhost"
    echo "  $0 -- --mode transparent --scripts ./script.py"
    echo "  $0 --remove-cert -- --mode regular"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interface)
            INTERFACE="$2"
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
        -l|--location)
            # Convert location name to lowercase and replace spaces/dots with hyphens
            LOCATION_NAME=$(echo "$2" | tr '[:upper:]' '[:lower:]' | tr ' .' '-')
            shift 2
            ;;
        -c|--cert-dir)
            CERT_DIR="$2"
            shift 2
            ;;
        --no-cert)
            INSTALL_CERT=false
            shift
            ;;
        --remove-cert)
            REMOVE_CERT=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        --)
            shift
            MITMPROXY_ARGS="$*"
            break
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Function to install certificates
install_certificates() {
    # Check if certificates already exist and are installed
    if [ -f "$CERT_DIR/mitmproxy-ca-cert.cer" ] && security find-certificate -c "mitmproxy" /Library/Keychains/System.keychain >/dev/null 2>&1; then
        echo "Certificates already installed, skipping..."
        return
    fi

    echo "Installing mitmproxy certificates..."
    
    # Ensure mitmproxy certificate directory exists
    mkdir -p "$CERT_DIR"
    
    # Generate certificates if they don't exist
    if [ ! -f "$CERT_DIR/mitmproxy-ca-cert.pem" ]; then
        echo "Generating new certificates..."
        mitmdump --set confdir="$CERT_DIR" &
        MITM_PID=$!
        # sleep 2
        kill $MITM_PID
        # sleep 1  # Wait for process to fully terminate
    fi

    # Convert PEM to CER format for macOS
    openssl x509 -outform der -in "$CERT_DIR/mitmproxy-ca-cert.pem" -out "$CERT_DIR/mitmproxy-ca-cert.cer"

    # Install certificate to System Keychain and trust it
    echo "Adding certificate to System Keychain..."
    sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" "$CERT_DIR/mitmproxy-ca-cert.cer"
    # sleep 1  # Wait for keychain to update
}

# Function to remove certificates
remove_certificates() {
    if [ "$REMOVE_CERT" = true ] && [ -f "$CERT_DIR/mitmproxy-ca-cert.cer" ]; then
        echo "Removing mitmproxy certificates..."
        if security find-certificate -c "mitmproxy" /Library/Keychains/System.keychain >/dev/null 2>&1; then
            sudo security remove-trusted-cert -d "$CERT_DIR/mitmproxy-ca-cert.cer"
            # sleep 1  # Wait for keychain to update
        fi
    fi
}

# Function to create network location
create_proxy_location() {
    # Save current location
    local current_location
    current_location=$(networksetup -getcurrentlocation)
    echo "Current location: $current_location"

    # Remove existing location if it exists
    echo "Removing existing location if present..."
    networksetup -deletelocation "$LOCATION_NAME" 2>/dev/null || true
    # sleep 1  # Wait for location to be removed

    # Create new location
    echo "Creating new location: $LOCATION_NAME"
    if ! networksetup -createlocation "$LOCATION_NAME" populate; then
        echo "Error: Failed to create network location '$LOCATION_NAME'"
        exit 1
    fi
    # sleep 2  # Wait for location to be created and populated

    # Activate the new location
    echo "Activating new location..."
    if ! networksetup -switchtolocation "$LOCATION_NAME"; then
        echo "Error: Failed to switch to network location '$LOCATION_NAME'"
        networksetup -switchtolocation "$current_location"
        exit 1
    fi
    # sleep 1  # Wait for location switch to complete

    # Configure proxy settings for the active network service
    echo "Setting up proxy configuration..."
    # Get all network services
    local services
    mapfile -t services < <(networksetup -listallnetworkservices | grep -v "asterisk" | tail -n +2)
    
    # Find our target interface
    local target_service=""
    for service in "${services[@]}"; do
        if echo "$service" | grep -qi "$INTERFACE"; then
            target_service="$service"
            break
        fi
    done

    if [ -z "$target_service" ]; then
        echo "Error: Network interface '$INTERFACE' not found"
        echo "Available interfaces:"
        printf '%s\n' "${services[@]}"
        networksetup -switchtolocation "$current_location"
        exit 1
    fi

    # Configure proxy settings
    echo "Configuring proxy for $target_service..."
    networksetup -setwebproxy "$target_service" "$HOST" "$PORT"
    networksetup -setsecurewebproxy "$target_service" "$HOST" "$PORT"
    # sleep 1  # Wait for proxy settings to apply
    
    echo "Network location '$LOCATION_NAME' configured successfully"
}

# Function to clean up network location and certificates
cleanup() {
    # Only run cleanup once
    [ "${CLEANUP_DONE:-0}" -eq 1 ] && return
    CLEANUP_DONE=1

    echo "Cleaning up..."
    # Get the current location before cleanup
    local current_location
    current_location=$(networksetup -getcurrentlocation)
    
    # Only switch back to Automatic if we're in our proxy location
    if [ "$current_location" = "$LOCATION_NAME" ]; then
        echo "Switching back to Automatic location..."
        networksetup -switchtolocation "Automatic"
        # sleep 1  # Wait for location switch
    fi
    
    # Delete our proxy location
    echo "Removing proxy location..."
    networksetup -deletelocation "$LOCATION_NAME" 2>/dev/null || true
    # sleep 1  # Wait for location removal
    
    # Remove certificates
    remove_certificates
    
    trap - EXIT INT TERM  # Remove the trap
    exit 0
}

# Set up trap for cleanup on script termination
trap cleanup EXIT INT TERM

# Install certificates if needed
if [ "$INSTALL_CERT" = true ]; then
    install_certificates
fi

# Create and switch to proxy location
create_proxy_location

# Start mitmproxy with arguments
if [ -n "$MITMPROXY_ARGS" ]; then
    # shellcheck disable=SC2086
    mitmproxy ${MITMPROXY_ARGS}
else
    mitmproxy --mode regular --showhost
fi 