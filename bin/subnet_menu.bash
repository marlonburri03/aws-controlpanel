#!/bin/bash

# variables
source "$(dirname "$0")/colors.bash"
source "$(dirname "$0")/variables.bash"

# header
print_header() {
    clear
    echo -e "${BOLD_YELLOW}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                       Subnet MENU                            ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║ Session Info : $USER@$HOSTNAME | $DATE             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
}

# menu
show_menu() {
    echo -e "${BOLD_BLUE}"
    echo "1. Add New Subnet to existing VPC"
    echo "2. List Subnets"
    echo "3. Delete Subnet"
    echo "4. Create new Subnet and VPC"
    echo "5. Back to Main Menu"
    echo "6. Exit Program"
    echo -e "${NC}"
}

# pause
pause() {
    read -rp "Press [Enter] to continue..."
}

# handle input
handle_input() {
    read -rp "Select an option: " choice
    case "$choice" in
        1)
            echo "Subnet creation coming soon..."
            ;;
        2)
            echo "Listing Subnets..."
            ;;
        3)
            echo "Delete Subnet..."
            ;;
        4)
            echo "Creating new Subnet and VPC..."
            ;;
        5)
            echo "Returning to Main Menu..."
            source "$(dirname "$0")/main.bash"
            exit 0
            ;;
        6)
            echo -e "${BOLD_YELLOW}Exiting program. Goodbye!${NC}"
            source "$(dirname "$0")/ascii_logo.bash"
            print_ascii_logo
            kill $PPID
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
}



# main loop
main_ec2_menu() {
    while true; do
        print_header
        show_menu
        handle_input
        pause
    done
}

# Only executes if it runs directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_ec2_menu
fi
