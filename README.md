# Service Tunnel Management Script

https://github.com/CorbinIvon/SSH-Tunnel-Tool/assets/20233488/b59fd802-7a35-4a77-b374-9c79d6ed4409

This Bash script manages SSH tunnels for specified services, allowing remote access to services running on different ports. It checks for required commands, verifies tunnel statuses, and attempts to establish connections through fallback domains.

## Features

- Checks for required commands (`gum`, `nc`) before execution.
- Manages SSH tunnels for a configurable list of services and ports.
- Verifies tunnel status with retries, using a visual spinner for feedback.
- Automatically selects a fallback domain for tunneling based on port 22 accessibility.
- Allows users to manually start or stop tunnels for specific services.

## Requirements

- Bash shell
- `gum`: A modern tool for fancy input and output in the terminal. [Source](https://github.com/charmbracelet/gum)
- `nc` (netcat): A networking utility for reading from and writing to network connections.
- `nmap`: Network exploration tool and security / port scanner.
- SSH access to the target domain(s) with port forwarding capabilities.

## Installation

1. Ensure you have `gum`, `nc`, and `nmap` installed on your system. You can usually install these tools through your package manager. For example, on Ubuntu:

```bash
sudo apt-get update
sudo apt-get install netcat nmap
# Install gum from its official repository or documentation
```

Place the script in a desired directory and make it executable:
```bash
chmod +x tunnel_management.sh
```

## Usage

Configure the serviceNames and ports arrays at the top of the script to match the services you want to manage and their respective local ports.
Optionally, set the domainUser and fallbackDomains to reflect your remote access configuration.
Run the script:
```bash
./tunnel_management.sh
```
Follow the on-screen prompts to start or stop tunnels for the configured services.

## Customization

You can customize the script by modifying the `serviceNames`, `ports`, `domainUser`, and `fallbackDomains` variables to match your infrastructure and preferences. References Provided.

## Troubleshooting

If you encounter an error about missing commands, ensure that gum, nc, and nmap are correctly installed and accessible in your PATH.
If no tunnels can be established, verify that SSH access is correctly set up for the domainUser on the fallbackDomains and that port 22 is open.

## Contributing

Feel free to fork this script and submit pull requests with improvements or additional features.

## License

Please refer to the license in this repository.
