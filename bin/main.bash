#!/bin/bash

# variables
source "$(dirname "$0")/colors.bash"
source "$(dirname "$0")/variables.bash"

# header 
print_header() {
    clear
    echo -e "${BOLD_YELLOW}"
    echo "      ___   ____    __    ____   _______.     ______   ______   .__   __. .___________..______        ______    __         .______      ___      .__   __.  _______  __      "
    echo "     /   \  \   \  /  \  /   /  /       |    /      | /  __  \  |  \ |  | |           ||   _  \      /  __  \  |  |        |   _  \    /   \     |  \ |  | |   ____||  |     "
    echo "    /  ^  \  \   \/    \/   /  |   (----\`   |  ,----'|  |  |  | |   \|  | \`---|  |----\`|  |_)  |    |  |  |  | |  |        |  |_)  |  /  ^  \    |   \|  | |  |__   |  |     "
    echo "   /  /_\  \  \            /    \   \       |  |     |  |  |  | |  . \`  |     |  |     |      /     |  |  |  | |  |        |   ___/  /  /_\  \   |  . \`  | |   __|  |  |     "
    echo "  /  _____  \  \    /\    / .----)   |      |  \`----.|  \`--'  | |  |\   |     |  |     |  |\  \----.|  \`--'  | |  \`----.   |  |     /  _____  \  |  |\   | |  |____ |  \`----."
    echo " /__/     \__\  \__/  \__/  |_______/        \______| \______/  |__| \__|     |__|     | _| \`._____| \______/  |_______|   | _|    /__/     \__\ |__| \__| |_______||_______|"
    echo -e "${NC}"
    
    echo -e "${WHITE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                       AWS-ControlPanel v1.0                  ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║ Author       : Marlon Burri (marlob03)                       ║"
    echo "║ Purpose      : Manage and automate AWS resources             ║"
    echo "║ Features     : EC2, VPC, Subnets, Security Groups            ║"
    echo "║ Environment  : Bash CLI interface with modular structure     ║"
    echo "║ Session Info : $USER@$HOSTNAME | $DATE             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}


# menu 
show_menu() {
    echo -e "${BOLD_BLUE}"
    echo "1. EC2-Menu"
    echo "2. VPC-Menu"
    echo "3. Subnet-Menu"
    echo "4. SecurityGroup-Menu"
    echo "5. Exit"
    echo -e "${NC}"
}

# input
read_input() {
    read -rp "Please select an option: " choice
    case "$choice" in
        1)
            echo -e "${BOLD_YELLOW}You selected EC2-Menu. Loading EC2 options...${NC}"
            bash "$(dirname "$0")/ec2_menu.bash"
            ;;
        2)
            echo -e "${BOLD_YELLOW}You selected VPC-Menu. Loading VPC options...${NC}"
            bash "$(dirname "$0")/vpc_menu.bash"
            ;;
        3)
            echo -e "${BOLD_YELLOW}You selected Subnet-Menu. Loading Subnet options...${NC}"
            bash "$(dirname "$0")/subnet_menu.bash"
            ;;
        4)
            echo -e "${BOLD_YELLOW}You selected SecurityGroup-Menu. Loading Security Group options...${NC}"
            bash "$(dirname "$0")/securitygroup_menu.bash"
            ;;
        5)
            echo -e "${BOLD_YELLOW}Exiting program. Goodbye!${NC}"
            source "$(dirname "$0")/ascii_logo.bash"
            print_ascii_logo
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
}


# pause
pause() {
    read -rp "Press [Enter] key to continue..."
}

# main loop
main() {
    while true; do
        print_header
        show_menu
        read_input
        pause
    done
}


# Only executes if it runs directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
