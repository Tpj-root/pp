#!/bin/bash
##########################################################
#/*
# * Copyright (C) 2025 [Tpj-root]
# * https://github.com/Tpj-root
# *
# * This program is free software; you can redistribute it and/or modify
# * it under the terms of the GNU General Public License version 2
# * as published by the Free Software Foundation.
# *
# * This program is distributed in the hope that it will be useful,
# * but WITHOUT ANY WARRANTY; without even the implied warranty of
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# * GNU General Public License for more details.
# *
# * You should have received a copy of the GNU General Public License
# * along with this program; if not, see <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.
# */
#
#  - 2025/02/02 (1.0) - First version released
#
#  Usage: ./pp.sh <category> [--list]
#
#
### Description:
#
#   Package Pilot is a user-friendly command-line tool 
#   designed to simplify software installation on Linux systems.
#   It uses a JSON configuration file to categorize and manage software packages, 
#   allowing you to install or list software with ease. 
#   With features like enable/disable flags and colorful output, 
#   Package Pilot makes managing dependencies and software setups a breeze.
#
##########################################################
# Function to check and install jq if not already installed

#
#  color list
#
function get_colors() {
    export RESET='\033[0m'
    export BLACK='\033[30m'
    export RED='\033[31m'
    export GREEN='\033[32m'
    export YELLOW='\033[33m'
    export BLUE='\033[34m'
    export MAGENTA='\033[35m'
    export CYAN='\033[36m'
    export WHITE='\033[37m'
    export BOLD='\033[1m'
    export UNDERLINE='\033[4m'
    export BRIGHT_BLACK='\033[90m'
    export BRIGHT_RED='\033[91m'
    export BRIGHT_GREEN='\033[92m'
    export BRIGHT_YELLOW='\033[93m'
    export BRIGHT_BLUE='\033[94m'
    export BRIGHT_MAGENTA='\033[95m'
    export BRIGHT_CYAN='\033[96m'
    export BRIGHT_WHITE='\033[97m'
    
    # Return the color codes as a dictionary-like structure
    # echo -e "RESET: $RESET"
    # echo -e "BLACK: $BLACK"
    # echo -e "RED: $RED"
    # echo -e "GREEN: $GREEN"
    # echo -e "YELLOW: $YELLOW"
    # echo -e "BLUE: $BLUE"
    # echo -e "MAGENTA: $MAGENTA"
    # echo -e "CYAN: $CYAN"
    # echo -e "WHITE: $WHITE"
    # echo -e "BOLD: $BOLD"
    # echo -e "UNDERLINE: $UNDERLINE"
    # echo -e "BRIGHT_BLACK: $BRIGHT_BLACK"
    # echo -e "BRIGHT_RED: $BRIGHT_RED"
    # echo -e "BRIGHT_GREEN: $BRIGHT_GREEN"
    # echo -e "BRIGHT_YELLOW: $BRIGHT_YELLOW"
    # echo -e "BRIGHT_BLUE: $BRIGHT_BLUE"
    # echo -e "BRIGHT_MAGENTA: $BRIGHT_MAGENTA"
    # echo -e "BRIGHT_CYAN: $BRIGHT_CYAN"
    # echo -e "BRIGHT_WHITE: $BRIGHT_WHITE"
}

# test
# get_colors()


# Checking if jq and figlet are installed
# If not, it will install them automatically
ensure_jq_and_figlet_installed() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        sudo apt update
        sudo apt install -y jq
        if ! command -v jq &> /dev/null; then
            echo "Failed to install jq. Please install it manually and try again."
            exit 1
        fi
    fi

    # Check if figlet is installed
    if ! command -v figlet &> /dev/null; then
        echo "figlet is not installed. Installing figlet..."
        sudo apt install -y figlet
        if ! command -v figlet &> /dev/null; then
            echo "Failed to install figlet. Please install it manually and try again."
            exit 1
        fi
    fi
}



# Function to print colored text
print_colored() {
    local color="$1"
    local text="$2"
    case "$color" in
        green) echo -e "\033[0;32m$text\033[0m" ;;
        red) echo -e "\033[0;31m$text\033[0m" ;;
        yellow) echo -e "\033[1;33m$text\033[0m" ;;
        skyblue) echo -e "\033[1;36m$text\033[0m" ;;
        *) echo "$text" ;;
    esac
}

# Function to install software
# --install-recommends flag
install_software() {
    local software=$1

    # Check if the software is already installed
    if dpkg -l | grep -q "^ii  $software"; then
        # Print the software name in green
        echo -e "\033[0;32m$software\033[0m is already installed."
    else
        echo "Installing $software and its recommended packages..."
        sudo apt-get update
        sudo apt-get install -y --install-recommends "$software"
    fi
}


function disabled_software_list() {
    get_colors
    
    echo -e "${YELLOW}Skipping ${RED}$software${RESET}${YELLOW} (disabled in the list).${RESET}"
}


function disabled_echo() {
    get_colors
    
    echo -e "${YELLOW}  (Disabled: Will not be installed)${RESET}"
}



# Function to read software list from JSON and list/install based on category
install_software_from_file() {

    local software_list_file="$1"
    local category="$2"
    local list_only="$3"

    if [[ -f "$software_list_file" ]]; then
        echo "Reading software list from $software_list_file..."

        # Extract the software list for the given category
        software_list=$(jq -r ".$category | to_entries[] | [.key, .value.description, .value.enable] | @tsv" "$software_list_file")

        if [[ -z "$software_list" ]]; then
            echo "Category '$category' not found in $software_list_file!"
            return 1
        fi

        # List or install software
        while IFS=$'\t' read -r software description enable; do
            if [[ "$list_only" == "--list" ]]; then
                # Print software name in green if enabled, red if disabled
                if [[ "$enable" == "1" ]]; then
                    print_colored green "$software"
                else
                    print_colored red "$software"
                fi
                # Print description in sky blue
                print_colored skyblue "  $description"
                if [[ "$enable" == "0" ]]; then
                    disabled_echo
                fi
            else
                if [[ "$enable" == "1" ]]; then
                    install_software "$software"
                else
                    # software list
                    disabled_software_list
                fi
            fi
        done <<< "$software_list"
    else
        echo "${RED}Software list file $software_list_file not found!"
    fi
}

####
# counts for categories and software list
#
####
count_categories_and_software() {
    JSON_FILE="software_list.json"

    if [[ ! -f "$JSON_FILE" ]]; then
        echo -e "\e[31mError: $JSON_FILE not found!\e[0m"
        exit 1
    fi

    # Count categories
    CATEGORY_COUNT=$(jq -r 'keys | length' "$JSON_FILE")

    # Count total enabled software
    SOFTWARE_COUNT=$(jq -r 'to_entries | map(.value | to_entries | map(select(.value.enable == 1))) | add | length' "$JSON_FILE")

    # Count total disabled software
    DISABLED_SOFTWARE_COUNT=$(jq -r 'to_entries | map(.value | to_entries | map(select(.value.enable == 0))) | add | length' "$JSON_FILE")

    # Output the counts
    echo -e "Categories count: ${CATEGORY_COUNT}"
    echo -e "Total enabled software count: ${SOFTWARE_COUNT}"
    echo -e "Total disabled software count: ${DISABLED_SOFTWARE_COUNT}"
}

# Call the function
# count_categories_and_software



#  
#
#
Copyright_Header() {

    figlet pp
    echo -e "${RED}                                 " 
    echo -e "${RED}Package Pilot is a user-friendly command-line tool" 
    echo -e "${RED}Copyright (C) 2025 [Tpj-root]" 
    echo -e "${RED}https://github.com/Tpj-root"
    echo -e "${RED}GNU General Public License version 2"
    echo -e ""
    echo -e ""
    echo -e ""

}


# Function to display basic usage with colored output
usage() {
    JSON_FILE="software_list.json"

    if [[ ! -f "$JSON_FILE" ]]; then
        echo -e "\e[31mError: $JSON_FILE not found!\e[0m"
        exit 1
    fi

    CATEGORIES=$(jq -r 'keys[]' "$JSON_FILE")


#
#    # enable random color codes
#    #
#    # Define color codes
#    RED='\e[31m'
#    YELLOW='\e[33m'
#    GREEN='\e[32m'
#    BLUE='\e[34m'
#    MAGENTA='\e[35m'
#    CYAN='\e[36m'
#    RESET='\e[0m'
#
#    # Function to print text in a random color
#    print_random_color() {
#        COLORS=("$RED" "$YELLOW" "$GREEN" "$BLUE" "$MAGENTA" "$CYAN")
#        RANDOM_COLOR=${COLORS[$RANDOM % ${#COLORS[@]}]}
#        echo -e "${RANDOM_COLOR}$1${RESET}"
#    }
#

    #color codes
    get_colors
    #RED='\e[31m'
    #GREEN='\e[32m'
    #RESET='\e[0m'

    # Function to print text in a random color
    print_random_color() {
        COLORS=("$GREEN")
        RANDOM_COLOR=${COLORS[$RANDOM % ${#COLORS[@]}]}
        echo -e "${RANDOM_COLOR}$1${RESET}"
    }

    Copyright_Header
    # Print usage information with colors
    echo -e "${RED}Usage: $0 <category> [--list]${RESET}"
    echo -e ""
    echo -e "Available categories:"
    for category in $CATEGORIES; do
        print_random_color "$category"
    done | column
    echo -e ""
    echo -e "${YELLOW}Options:${RESET}"
    echo -e "${YELLOW}  --list  List software in the category without installing${RESET}"
    # counts for categories and software list
    echo -e ""
    count_categories_and_software
    exit 1
}

# Ensure jq is installed before proceeding
ensure_jq_and_figlet_installed

# Path to the JSON file (assumed to be in the same directory as the script)
software_list_file="$(dirname "$0")/software_list.json"

# Check if no arguments are provided
if [[ -z "$1" ]]; then
    usage
fi

# Check if the first argument is a valid category
category="$1"
shift

# Check if the --list flag is provided
list_only=""
if [[ "$1" == "--list" ]]; then
    list_only="--list"
fi

# Install or list software for the given category
install_software_from_file "$software_list_file" "$category" "$list_only"
echo ""
echo "Script execution completed!"
