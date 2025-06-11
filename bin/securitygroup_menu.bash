#!/bin/bash

# variables
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

# menu
show_menu() {
    echo -e "${BOLD_BLUE}"
    echo "1. Add New Security Group"
    echo "2. List Security Groups"
    echo "3. Delete Security Group"
    echo "4. Back to Main Menu"
    echo "5. Exit Program"
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
            echo "Create Security Group..."
            bash $SCRIPTDIR/securitygroup_create.bash
            ;;
        2)
            echo "Listing Security Groups..."
            bash $SCRIPTDIR/securitygroup_list.bash
            ;;
        3)
            echo "Delete Security Group..."
            bash $SCRIPTDIR/securitygroup_delete.bash
            ;;
        4)
            echo "Returning to Main Menu..."
            source "$(dirname "$0")/main.bash"
            exit 0
            ;;
        5)
            echo -e "${BOLD_YELLOW}Exiting program. Goodbye!${NC}"
            source $LIBDIR/ascii_logo.bash
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
