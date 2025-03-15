#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")"
source ./utils.sh

# Check if Touch ID for sudo is already configured
if grep -q '^auth.*pam_tid\.so' /etc/pam.d/sudo_local; then
	color_print "$blue" 'Touch ID for sudo commands is already configured.' # Changed to blue
else
	# use touch id to allow sudo commands
	sed -e 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null
	color_print "$green" 'Configured Touch ID to allow sudo commands'
fi

./set_defaults.sh
color_print "$green" 'Defaults from "set_defaults.sh" where set'

# TODO: copy config files, dirs, etc. Maybe prompt for which to install and which not?
color_print "$yellow" 'Config files must be copied manually'
