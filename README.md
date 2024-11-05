# WordPress Docker Deployment Project

## Overview

This project automates the deployment of a WordPress environment with Docker, including MariaDB and Nginx for SSL termination. 
The deployment is designed for ease of use, secure handling of environment variables, automatic SSL certificate renewal, backup scheduling, and log generation.

## Project Structure

```plaintext
.
├── dist
│   ├── certs                    # Directory for SSL certificates (fullchain.pem, privkey.pem)
│   ├── docker-compose-wp.yml    # Docker Compose configuration file
│   ├── nginx.conf               # Nginx configuration file
│   ├── scripts                  # Directory for shell scripts
│   │   ├── install.sh           # Script for initial setup and server configuration
│   │   ├── admin.sh             # Script for service management (start, stop, restart)
│   │   ├── backup.sh            # Script for backup of volumes and database
│   │   ├── updateSSL.sh         # Script for SSL certificate renewal
│   │   ├── logs.sh              # Script for log generation
│   │   └── cron-jobs            # Directory for cron job scripts
│       │   ├── cron_daily.sh    # Daily script for Docker logs generation
│       │   ├── cron_weekly.sh   # Weekly script for backup and log rotation
│       │   └── cron_monthly.sh  # Monthly script for SSL renewal
├── lenv
│   ├── dist.env.example         # Example environment file for server configuration
│   └── local.env.example        # Example environment file for Python script
├── requirements.txt             # Python dependencies (paramiko, dotenv, etc.)
├── server.py                    # Main Python script for deployment and management
├── venv.sh                      # Script to create and activate a virtual Python environment

```
## Prerequisites

### Local Machine
1. **Python 3.10 or above**: Required for running the deployment script.
2. **Virtual Environment Setup**:
   - Run `venv.sh` to create and activate a virtual environment and install the required dependencies from `requirements.txt`.
   ```bash
   source venv.sh
    ```
3. **SSH Access**: Ensure you can connect to the remote server via SSH.

### Remote Machine
1. **Ubuntu Server with Sudo-enabled User**: Ensure your server is running Ubuntu and that you have a user with sudo privileges.
2. **Docker, Docker Compose, and Certbot**: These will be installed automatically on the server if they are not already present.

## Environment Variables

Configuration is managed through two `.env` files, not included in the repository for security reasons:

- **`dist.env.example`**: Server-specific variables, including Docker configurations, database credentials, and SSL information.
- **`local.env.example`**: Local settings for SSH connections, used in the Python deployment script.

To prepare these files:
1. **Copy the example files**:
   ```bash
   cp lenv/dist.env.example xenv/dist.env
   cp lenv/local.env.example xenv/local.env
   ```

2. **Edit dist.env and local.env with the necessary values.**

Example of `dist.env`

   ```dotenv 
    MYSQL_DATABASE=wordpress_db
    MYSQL_USER=wp_user
    MYSQL_PASSWORD=wp_password
    CERTBOT_EMAIL=admin@example.com
    CERTBOT_DOMAIN=example.com
   ```

Example of `local.env`

   ```dotenv 
   HOST=your.server.ip.address
   ADMIN_USER=your_admin_user
   PROJECT_DIRECTORY=WPDOCK
   ```
## Distant Scripts Overview

### Scripts and Functions

Each script is designed to handle a specific task on the remote server. The following table provides an overview:

| Script                    | Description                                                                                                                |
|---------------------------|----------------------------------------------------------------------------------------------------------------------------|
| `admin.sh`                | Manages Docker services (`docker start`, `docker stop`, ` docker restart`) and Cronjobs (`cron status` `enable` `disable`) |
| `backup.sh`               | Performs a backup of WordPress files and database                                                                          |
| `updateSSL.sh`            | Renews SSL certificates with Certbot and reloads Nginx if required                                                         |
| `logs.sh`                 | Collects Docker container logs and stores them in a timestamped log directory                                              |
| `cron-jobs/cron_daily.sh` | Configured for daily maintenance tasks such as log generation                                                              |
| `cron-jobs/cron_weekly.sh`| Scheduled weekly for database and file backups                                                                             |
| `cron-jobs/cron_monthly.sh`| Scheduled monthly to renew SSL certificates if necessary                                                                   |


## Python Deployment Script Overview

The `server.py` script is designed to manage the deployment process from a local machine, with the following features:

1. **Environment Setup**: Loads necessary environment variables from `xenv/local.env` to establish SSH connection details and project configurations.
   
2. **File Packaging**: Compresses all required files into a zip file, including necessary scripts, configuration files, and encrypted environment variables (`dist.env` encrypted to `dist.env.enc`).

3. **File Transfer and Extraction**: Connects to the remote server via SSH, transfers the zip file, extracts the contents in the specified directory, and deletes the zip file post-extraction.

4. **Permissions and Execution**: Sets executable permissions for all scripts on the remote server and initiates the deployment process.


## Deployment Steps

### Local Part

1. **Set Environment Variables**:
   - Edit `xenv/local.env` to specify your local configuration, including:
     - `HOST`: Remote server IP or hostname
     - `ADMIN_USER`: Admin user with SSH access on the remote server
     - `PROJECT_DIRECTORY`: Directory name where the project will be set up on the remote server

2. **Activate the Python Environment**:
   - Run the `venv.sh` script to create a Python virtual environment and install dependencies:
     ```bash
     source venv.sh
     ```

3. **Run the Deployment Script**:
   - Execute the Python deployment script to package and upload necessary files to the remote server:
     ```bash
     python server.py
     ```
   - During the process, you will be prompted to enter:
     - The SSH password for the remote admin user.
     - A password to encrypt the `dist.env` file, which will store environment variables securely.

### Remote Part

1. **Execute `install.sh`**:
   - On the remote server, run `install.sh` to set up the environment:
     ```bash
     ./scripts/install.sh
     ```
   - This script performs the following actions:
     - Frees port 80 if it’s in use.
     - Installs Docker, Docker Compose, and Certbot if they’re not already installed.
     - Generates SSL certificates using Certbot.
     - Activate the cronjobs
     - Decrypts the `dist.env` file by asking the password you set during the local deployment.
   
2. **Start Docker Services**:
   - Use `admin.sh` to start Docker services:
     ```bash
     ./scripts/admin.sh docker start
     ```
   - This script initializes Docker containers for WordPress, MariaDB, and Nginx with SSL enabled.
