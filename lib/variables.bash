#!/bin/bash

# header informations 
DATE=$(date +"%Y-%m-%d %H:%M")   
USER=$(whoami)                   
HOST=$(hostname)


print_header() {
    clear

    local script_name
    script_name=$(basename "${BASH_SOURCE[1]}")

    local menu_name
    menu_name=$(echo "$script_name" | sed 's/_menu\.bash//' | tr '[:lower:]' '[:upper:]')

    echo -e "${BOLD_WHITE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo -ne "║"
    echo -ne "${BOLD_YELLOW}"
    printf "%*sMENU%*s" $(((62 - ${#menu_name}) / 2)) "$menu_name " $(((61 - ${#menu_name}) / 2)) ""
    echo -e "${BOLD_WHITE}║"
    echo "║                                                              ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    printf "║ Session Info : %-45s ║\n" "$USER@$HOSTNAME | $DATE"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# logging Configuration 
LOGFILE="$LOGDIR/aws-control.log"  
LOGLEVEL="INFO"                     

# logging function 
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    
    if [[ "$level" == "ERROR" || "$level" == "$LOGLEVEL" || "$LOGLEVEL" == "DEBUG" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOGFILE"
        echo -e "[$timestamp] [$level] $message"
    fi
}

# ensure necessary directories exist 
mkdir -p "$LOGDIR" "$VARDIR" "$TMPDIR"

# cleanup function for temp files on exit 
cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

# requirements check
check_aws_requirements() {
    # checks if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log "ERROR" "AWS CLI is not installed."
        echo "AWS CLI is not installed. Please install it first."
        exit 1
    fi

    # checks if valid AWS credentials are present
    if ! aws sts get-caller-identity &> /dev/null; then
        log "ERROR" "AWS credentials are missing or invalid."
        echo "No valid AWS credentials found. Please configure your AWS credentials."
        exit 1
    fi
}
