#!/bin/bash

set -e

pacman_setup () {
    # Pacman keyring init
    pacman-key --init
    pacman-key --populate archlinuxarm
    
    # Update the package database
    echo "Updating the package database..."
    pacman -Syu --noconfirm
    
    # Install the base and base-devel packages
    echo "Installing the base and base-devel packages..."
    pacman -S --noconfirm base base-devel
    
    # Install the sudo package
    echo "Installing the sudo package..."
    pacman -S --noconfirm sudo
    
    # Install the git package and base-devel
    echo "Installing the git package and base-devel..."
    sudo pacman -S git base-devel --noconfirm
}

system_setup () {
    echo "Configuring SSH to allow root ssh..."
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

    echo "Restarting SSH service..."
    systemctl restart sshd
    
    # Set the hostname
    echo "Setting the hostname..."
    echo $HOSTNAME > /etc/hostname
    
    # Set the timezone
    echo "Setting the timezone..."
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    
    # Set the locale
    echo "Setting the locale..."
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    
    # Set the keyboard layout
    echo "Setting the keyboard layout..."
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
}

user_setup () {
    # # Find processes owned by the user alarm
    # USER_PIDS=$(ps -u alarm -o pid=)
    
    # # If processes are found, print and handle them
    # if [ -n "$PIDS" ]; then
    #     echo "Processes owned by alarm:"
    #     echo "$PIDS"
        
    #     # Optional: Kill the processes
    #     for PID in $PIDS; do
    #         echo "Killing process $PID"
    #         kill -9 $PID
    #     done
    # fi
    
    # Change the default username and password and the default root password
    echo "Changing the default username and password..."
    usermod -l $USER alarm
    
    # Change the password for the new user
    passwd $USER
    
    # Change the home directory name to match the new username
    echo "Changing the home directory name to match the new username..."
    usermod -d /home/$USER -m $USER
    
    # Change the group name to match the new username
    echo "Changing the group name to match the new username..."
    groupmod -n $NEW_USER $OLD_USER
    
    # Add the new user to sudo
    echo "Adding the new user to sudo..."
    echo "$USER ALL=(ALL) ALL" >> /etc/sudoers
}


pacman_setup
system_setup
user_setup