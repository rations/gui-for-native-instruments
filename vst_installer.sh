#!/bin/bash

# Mount point
MOUNT_POINT="/mnt/cdrom0"

(
    echo "10"; echo "# Checking mount point..."

    # Create mount point if it doesn't exist
    if [ ! -d "/mnt/cdrom0" ]; then
        sudo mkdir /mnt/cdrom0
    fi

    # Check if mount point is already mounted
    if mount | grep -q "$MOUNT_POINT"; then
        echo "# Unmounting existing mount..."
        sudo umount "$MOUNT_POINT"
        sleep 1
    fi

    echo "20"; echo "# Waiting for user to select ISO file..."
) |
zenity --progress --title="VST Plugin Installer" --text="Preparing..." --percentage=0 --auto-close

# Ask user to select ISO file (default to Downloads)
ISO_FILE=$(zenity --file-selection --title="Select VST Plugin ISO" --filename="$HOME/Downloads/" --file-filter="*.iso")

if [ -z "$ISO_FILE" ]; then
    zenity --error --text="No ISO file selected. Exiting."
    exit 1
fi

(
    echo "30"; echo "# Mounting ISO..."
    if ! sudo mount -t udf "$ISO_FILE" -o unhide "$MOUNT_POINT"; then
        echo "100"; echo "# Failed to mount ISO."
        sleep 1
        exit 1
    fi

    sleep 1
    echo "50"; echo "# Searching for Windows installer (.exe)..."
) |
zenity --progress --title="VST Plugin Installer" --text="Mounting ISO..." --percentage=0 --auto-close

# Find .exe file in mounted directory
EXE_FILE=$(find "$MOUNT_POINT" -type f -iname "*.exe" | head -n 1)

if [ -z "$EXE_FILE" ]; then
    zenity --error --text="No .exe installer found inside ISO."
    sudo umount "$MOUNT_POINT"
    exit 1
fi

# Ask confirmation before running Wine
zenity --question --text="Found installer:\n$EXE_FILE\n\nRun with Wine now?" || {
    sudo umount "$MOUNT_POINT"
    exit 0
}

(
    echo "60"; echo "# Running installer with Wine..."
    wine "$EXE_FILE"
    echo "80"; echo "# Unmounting ISO..."
    sudo umount "$MOUNT_POINT"
    sleep 1

    echo "90"; echo "# Syncing yabridge..."
    if [ -d "$HOME/.local/share/yabridge" ]; then
        cd "$HOME/.local/share/yabridge" || exit 1
        ./yabridgectl sync
    else
        zenity --warning --text="yabridge directory not found at ~/.local/share/yabridge. Skipping sync."
    fi

    echo "100"; echo "# Done!"
    sleep 1
) |
zenity --progress --title="Installing Plugin..." --percentage=0 --auto-close

# Final message
zenity --info --text="✅ Installation complete!\n\nOpen your DAW and scan for new plugins."
