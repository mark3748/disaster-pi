# Image Freeze
You can create a backup/export of you `disaster-pi` docker images. This can be useful if you need to recover the device, or even setup a new device, without internet access.

The freeze script is automatically installed at `/opt/disaster-pi/scripts/freeze-images.sh`.

To run it:
```Bash
sudo /opt/disaster-pi/scripts/freeze-images.sh
```

# Backup
There is an included restic backup script located at `/opt/disaster-pi/scripts/backup-daily.sh` that can be used to create backups of your `disaster-pi` data to an external drive. 

If you decide to change the backup location, make sure you update `USB_MOUNT="/mnt/usb_backup"` to the appropriate destination in the script!

## Why restic?
We want to be able to keep our data safe. Recipes, guides, personal files, all important to keep safe. Manual backups are a chore and restic allows for very quick incremental backups, so your large ZIMs only need to copy when they change!

The script also ensures the restic binary is copied to the backup device, so you can recover your data anywhere,

## Setup
You need to initialize this once.

### 1. Install Restic:
```bash
sudo apt-get install restic
```

### 2. Create a Password File: 
Don't rely on memory for passwords in a high-stress situation. Write it to a file readable only by root.
```Bash
mkdir -p /opt/disaster-pi/secrets
echo "your-secure-backup-password" > /opt/disaster-pi/secrets/restic_pw
chmod 600 /opt/disaster-pi/secrets/restic_pw
```

### 3. Initialize the USB Repo:
```Bash
restic -r /mnt/usb_backup/disaster-pi-repo init --password-file /opt/disaster-pi/secrets/restic_pw
```

## Usage
The script is now ready for use. You can manually execute at any time by running `/opt/disaster-pi/scripts/backup-daily.sh` 

### Scheduled Backups
You can run the backup script on a schedule by creating a `crontab` entry:
```bash
crontab -e
```

This example runs the backup at 04:00 every day:
```bash
0 4 * * * /opt/disaster-pi/scripts/backup-daily.sh >> /opt/disaster-pi/daily-backup.log 2>&1
```

You can choose the time, frequency, whatever you like. It is recommended to rename the files to match the schedule to prevent confusion!