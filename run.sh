#!/bin/bash

# Load environment variables from the .env file
# set -a: Mark variables for export to the environment of subsequent commands
set -a
source .env
# set +a: Turn off the export attribute for variables
set +a

# Convert the availability_zones string into a list format for Terraform
# This assumes the original format is a comma-separated string enclosed in quotes
# The sed command removes the first and last characters (assumed to be quotes)
# and wraps the result in square brackets
export TF_VAR_availability_zones=$(echo $TF_VAR_availability_zones | sed 's/^.\(.*\).$/[\1]/')

# Execute the Terraform command passed as an argument to this script
# The "$@" syntax passes all arguments to the script directly to the exec command
exec "$@"