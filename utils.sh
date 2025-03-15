# shellcheck shell=bash

# Format helpers for color_print
green="\033[0;32m"
blue="\033[0;34m"
cyan="\033[0;36m"
yellow="\033[0;33m"
red="\033[0;31m"
default="\033[0m"

function color_print() {
	local color=$1
	local message=$2

	echo -e "${color}${message}${default}\n"
}
