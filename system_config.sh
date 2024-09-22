#!/bin/bash

# Check if a valid argument is provided
if [ "$1" != "backup" ] && [ "$1" != "restore" ]; then
    echo "Usage: $0 {backup|restore}"
    exit 1
fi

# Directory to store or retrieve backups
BACKUP_DIR="config_backup"

# Backup Function
backup() {
    echo "Starting system backup..."

    # Create backup directory if it doesn't exist
    mkdir -p $BACKUP_DIR

    # 1. Backup installed packages
    echo "Backing up installed packages..."
    sudo dnf list installed > $BACKUP_DIR/installed_packages.txt

    # 2. Backup enabled services
    echo "Backing up enabled services..."
    systemctl list-unit-files --state=enabled > $BACKUP_DIR/enabled_services.txt

    # 3. Backup firewall rules
    echo "Backing up firewall rules..."
    firewall-cmd --list-all > $BACKUP_DIR/firewall_rules.txt

    # 4. Backup configuration files (add any necessary config files here)
    echo "Backing up essential configuration files..."
    cp /etc/hosts $BACKUP_DIR/
    cp /etc/fstab $BACKUP_DIR/

    # 5. Backup network configurations
    echo "Backing up network configurations..."
    nmcli con show > $BACKUP_DIR/network_config.txt

    echo "Backup complete! Files saved in the $BACKUP_DIR directory."
}

# Restore Function
restore() {
    echo "Starting system restoration..."

    # Check if backup directory exists
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Error: Backup directory $BACKUP_DIR not found."
        exit 1
    fi

    # 1. Restore installed packages
    echo "Restoring installed packages..."
    sudo dnf install -y $(awk '{print $1}' $BACKUP_DIR/installed_packages.txt)

    # 2. Re-enable services
    echo "Restoring enabled services..."
    while read -r service; do
        systemctl enable --now $service
    done < $BACKUP_DIR/enabled_services.txt

    # 3. Restore firewall rules
    echo "Restoring firewall rules..."
    firewall-cmd --reload

    # 4. Restore configuration files
    echo "Restoring configuration files..."
    cp $BACKUP_DIR/hosts /etc/hosts
    cp $BACKUP_DIR/fstab /etc/fstab

    # 5. Restore network configurations
    echo "Restoring network configurations..."
    nmcli con load $BACKUP_DIR/network_config.txt

    echo "System restoration complete!"
}

# Run the appropriate function based on the argument
if [ "$1" == "backup" ]; then
    backup
elif [ "$1" == "restore" ]; then
    restore
fi

