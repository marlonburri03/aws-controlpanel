#!/bin/bash

# variables
source "$(dirname "$0")/colors.bash"
source "$(dirname "$0")/variables.bash"

# header
print_header() {
    clear
    echo -e "${BOLD_YELLOW}"
    echo "VPC MENU"
    echo -e "${NC}"
    echo -e "${WHITE}Session Info : $USER@$HOSTNAME | $DATE${NC}"
}

# menu
show_menu() {
    echo -e "${BOLD_BLUE}"
    echo "1. Create VPC"
    echo "2. List VPC's"
    echo "3. Delete VPC"
    echo "4. Back to Main Menu"
    #echo "6. Exit Program"
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
            echo "VPC creation coming soon..."
            ;;
        2)
            echo "Listing VPC's..."
            ;;
        3)
            echo "Delete VPC..."
            ;;
        4)
            echo "Returning to Main Menu..."
            source "$(dirname "$0")/main.bash"
            exit 0
            ;;
        #6)
            #echo -e "${BOLD_YELLOW}Exiting program. Goodbye!${NC}"
            #source "$(dirname "$0")/ascii_logo.bash"
            #print_ascii_logo
            #exit 0
            #;;
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
