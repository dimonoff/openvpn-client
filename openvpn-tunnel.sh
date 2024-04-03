#!/usr/bin/env bash
# Start OpenVPN client which only routes traffics

set -xe

# Function to display usage information
usage() {
    echo "Usage: ./openvpn-tunnel.sh --auth-user-pass /path/to/user-pass /path/to/your/client.ovpn"
    exit  1
}

# Check if no arguments were passed
if [[ $# -eq  0 ]]; then
    usage
fi

# Parse command line arguments
while [[ "$#" -gt  0 ]]; do
    case $1 in
        --auth-user-pass)
            if [[ -n "$2" ]] && [[ -f "$2" ]]; then
                echo "Using credentials from file $2" 
                AUTH_USER_PASS="$2"
                shift
            else
                echo "Error: --auth-user-pass requires a value. File must exist"
                usage
            fi
            shift
            ;;
        --iptables-restore)
            if [[ -n "$2" ]] && [[ -f "$2" ]]; then
                echo "Restore iptables rules from $2" 
                IPTABLES_RULES="$2"
                shift
            else
                echo "Error: --iptables-restore requires a value. File must exist"
                usage
            fi
            shift
            ;;
        *)
            echo "$1"
            if [[ "$1" =~ \.ovpn$ ]] && [[ -f "$1" ]]; then
              echo "Using config from file $1" 
              CONFIG="$1"
            else
                echo "Please provide a valid OpenVPN client config file."
                echo "$1 is not a valid OpenVPN client config file."
                usage
            fi
            shift
            ;;
    esac
done

# Check if all mandatory arguments are provided
if [[ -z "$AUTH_USER_PASS" ]] || [[ -z "$CONFIG" ]]; then
    echo "Error: All arguments are mandatory"
    usage
fi

iptables-restore < "$IPTABLES_RULES"
openvpn --config "$CONFIG" --auth-user-pass "$AUTH_USER_PASS"
