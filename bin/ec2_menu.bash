#!/bin/bash

# variables
#source "$(dirname "$0")/init_env.bash"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"


# menu
show_menu() {
    echo -e "${BOLD_BLUE}"
    echo "1. Create EC2 Instance"
    echo "2. List EC2 Instances"
    echo "3. Delete EC2 Instance"
    echo "4. Create new full EC2 Environment"
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
            echo -e "${BOLD_YELLOW}Loading EC2 creation process...${NC}"
            bash $SCRIPTDIR/ec2_create.bash
            ;;
        2)
            echo "Listing EC2 instances..."
            bash $SCRIPTDIR/ec2_list.bash
            ;;
        3)
            echo -e "${BOLD_YELLOW}Loading EC2 deletion process...${NC}"
            bash $SCRIPTDIR/ec2_delete.bash
            ;;
        4)
            echo "Creating new full EC2 environment..."
            bash $SCRIPTDIR/ec2_fullenviroment.bash
            ;;
        5)
            echo "Returning to Main Menu..."
            exit 0
            ;;
        6)
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
