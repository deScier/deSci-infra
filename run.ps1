# Load environment variables from the .env file
# Get-Content reads the file and ForEach-Object processes each line
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $key = $Matches[1].Trim()
        $value = $Matches[2].Trim()
        # Remove surrounding quotes (both single and double) if present
        $value = $value -replace '^\s*[''"]|[''"]$'
        # For array values (like availability_zones and subnet_cidrs), ensure proper formatting
        if ($value -match '^\[.*\]$') {
            # Convert single quotes to double quotes for Terraform compatibility
            $value = $value -replace "'", '"'
        }
        [Environment]::SetEnvironmentVariable($key, $value, 'Process')
    }
}

# Convert the availability_zones string into a list format for Terraform
# In this case, as it's already in the correct format, no conversion is needed
# We keep this line to maintain equivalence with the bash script
$zones = [Environment]::GetEnvironmentVariable('TF_VAR_availability_zones')
[Environment]::SetEnvironmentVariable('TF_VAR_availability_zones', $zones, 'Process')

# Execute the Terraform command passed as an argument to this script
# $args in PowerShell is equivalent to $@ in bash
& terraform $args