#!/bin/bash
# Maps for ports with key names
# serviceNames=("key1" "key2" "key3")
# ports=(8080 8081 8082)
serviceNames=("ftp" "CasaOS" "NextCloud" "Calibre-Web")
ports=(445 8080 8081 8082)

# Domains to connect to. This can speed things up with local networks.
# domainUser="user"
# fallbackDomains=("test.domain.tld" "192.168.1.2")
domainUser="corbin"
fallbackDomains=("test.domain.tld" "10.0.0.199")

# Define a list of required commands
required_commands=("gum" "nc")

# Loop through the list and check each command
for cmd in "${required_commands[@]}"; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: Required command '$cmd' not found. Please install it to continue."
        exit 1
    fi
done

checkTunnelStatus() {
    local process=$1
    local port=$2
    local expectedStatus=$3 # "open" for running, "closed" for stopped
    local retries=5
    local waitTime=1

    # Start a spinner in the background
    gum spin --spinner pulse --title="Verifying $process tunnel on port $port..." sleep 9999 &
    local spinnerPid=$!

    while [ $retries -gt 0 ]; do
        local currentState=$(nmap localhost -p $port | grep "$port" | grep -oE '(open|closed)')
        if [[ "$currentState" == "$expectedStatus" ]]; then
            #echo "Tunnel on port $port is now $expectedStatus."
            kill $spinnerPid > /dev/null 2>&1  # Stop the spinner
            wait $spinnerPid 2>/dev/null  # Wait for spinner process to terminate
            return 0
        fi
        sleep $waitTime
        ((retries--))
    done

    echo "Timeout waiting for tunnel on port $port to become $expectedStatus."
    kill $spinnerPid > /dev/null 2>&1  # Stop the spinner
    wait $spinnerPid 2>/dev/null  # Wait for spinner process to terminate
    return 1
}


# Define service names and corresponding ports
# Add an "Exit" option to the list of services for breaking out of the loop
serviceNames+=("Exit")

displayNames=()
# Initialize variable to keep track of the selected domain
selectedDomain=""

# Loop through each fallback domain until a successful port 22 connection
for domain in "${fallbackDomains[@]}"; do
    # Use gum spin with nc command to check port 22
    connectionResult=$(gum spin --spinner pulse --title="Checking port 22 on $domain..." -- bash -c "nc -zv -w 3 $domain 22" && echo success)
    if [[ $connectionResult == *"success"* ]]; then
        echo "Port 22 on $domain is accessible."
        selectedDomain=$domain
        break # Exit the loop on first successful connection
    else
        echo "Port 22 on $domain is not accessible."
    fi

done

# Check if a domain was successfully selected
if [[ -z $selectedDomain ]]; then
    echo "All fallback domains failed. Exiting..."
    exit 1
fi

while true; do
    displayNames=()
    # Check for running tunnels and update display names accordingly
    for i in "${!serviceNames[@]}"; do
        serviceName="${serviceNames[i]}"
        port="${ports[i]}"
        # Check if there's a listening socket on the service's port
        if nc -zv localhost $port &> /dev/null; then
            # If nc finds the port open, mark the service as running
            displayNames+=("$serviceName [RUNNING]")
        else
            displayNames+=("$serviceName")
        fi
    done

    # Present the options using gum choose and capture the selected service
    selectedService=$(gum choose --cursor="> " --header="Select a service to tunnel:" "${displayNames[@]}")

    # Extract the service name from the selected option
    # Remove potential "[RUNNING]" tag to find the actual service name for further logic
    selectedService=$(echo "$selectedService" | sed 's/ \[RUNNING\]//')

    # Check if user chose to exit
    if [[ "$selectedService" == "Exit" ]]; then
        echo "Exiting..."
        break
    fi

    # Check if no service was selected
    if [[ -z "$selectedService" ]]; then
        echo "No service selected. Exiting..."
        exit 1
    fi

    # Find the index of the selected service in the serviceNames array
    for i in "${!serviceNames[@]}"; do
        if [[ "${serviceNames[i]}" == "${selectedService}" ]]; then
            selectedIndex=$i
            break
        fi
    done

    # Use the index to find the corresponding port
    selectedPort=${ports[selectedIndex]}

    # Check if the tunnel is already running using nmap
    nmapOutput=$(nmap localhost -p $selectedPort)

    if echo "$nmapOutput" | grep -q "open"; then
        #echo "Tunnel for $selectedService on port $selectedPort is already running. Stopping it."
        # Find the SSH process responsible for the tunnel and kill it
        # This is a simplistic approach; refine it as needed for your setup
        tunnelPid=$(ps aux | grep "ssh" | grep "$selectedPort:localhost:$selectedPort" | awk '{print $2}' | head -n 1)
        if [[ ! -z "$tunnelPid" ]]; then
            kill $tunnelPid
            echo "${selectedService} Tunnel stopped."
        else
            echo "Could not find the tunnel process."
        fi
    else
        #echo "Starting tunnel for $selectedService on port $selectedPort."
        # Start the SSH tunnel in the background
        ssh ${domainUser}@${domain} -L ${selectedPort}:localhost:${selectedPort} -N &
        checkTunnelStatus ${selectedService} $selectedPort "open"
        echo "${selectedService} Tunnel started - http://localhost:${selectedPort}"
    fi
done
