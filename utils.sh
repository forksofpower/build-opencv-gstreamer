# colors
BLUE="\e[34m"
RED="\e[31m"
RESET="\e[0m"

# Helpers
print_msg() {
    echo -e "${BLUE}$1${RESET}"
}
print_error() {
    echo -e "${RED}$1${RESET}"
}

# Run a command and print start/complete messages
# error message on failure
#
# example:
#   run_command "Testing: ls -la" ls -la
#   run_command "Testing: false command" false_command
#   run_command "Testing: sleep 2" sleep 2
run_command() {
    local msg="[$1]"
    shift 1
    print_msg "$msg: Start"
    # Run the command
    "$@"
    if [ $? -eq 0 ]; then
        print_msg "$msg: Complete"
    else
        print_error "$msg: Command failed - $*"
        exit 1
    fi
}