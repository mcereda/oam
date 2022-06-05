# Upgrade a PS4's HDD

1. [Back up the current system data and saves][back up the existing data on an external usb storage device] to an external drive;
1. shut down the PS4 completely;
1. [upgrade the HDD];
1. [install the system software][reinstall the system software] on the new drive;
1. [restore the system data and saves][restore backed up data from an external usb storage device to the playstation 4] from the external drive.

## Back up the existing data on an external USB storage device

To back up data you need an FAT32 or exFAT-formatted USB drive with at least the storage space of the PS4 backup file. If you don't have enough space to back up everything on your device, you can choose not to back up application data.

> It's important to sync your Trophies first, as they are not included in the backup data: go to _Trophies_, press the _OPTIONS_ button, and select _Sync Trophies With PSN_.

1. Insert the USB drive into your PS4 console;
1. go to _Settings_ > _System_ > _Back Up and Restore_;
1. select _Back Up_;
1. confirm which data you'd like to back up.

   > It is important to back up saved data to avoid losing any game progress.

1. Customize the backup file name and select _Back Up_; this will restart the console and start the backup process;
1. remove the USB drive once the console has been started up normally again.


## Upgrade the HDD

> This procedure has been tested on a PS4 Pro. Other models have different procedures.

1. Place the console upside-down on a flat surface and remove the HDD bay cover; remove from the **right side** first.

   > You may see a sticker covering the HDD bay cover. It's safe to remove this, and it will **not** affect the warranty.

   ![remove the hdd bay cover](remove%20the%20hdd%20bay%20cover.png)

1. Remove the screw holding the tray in place and and pull the HDD mounting bracket to remove it;

   ![remove the mounting bracket](remove%20the%20mounting%20bracket.png)

1. Remove the HDD from the mounting bracket and insert its replacement;

   ![remove the screws from the mounting bracket](remove%20the%20screws%20from%20the%20mounting%20bracket.png)

1. screw the screws back in, being careful not to over-tighten them;
1. reinsert the HDD mounting bracket and put the crew back in to hold it in place;

   ![insert the mounting bracket](insert%20the%20mounting%20bracket.png)

1. re-attach the HDD cover.

## Reinstall the system software

> This will delete all of the data on your PS4 console. This process is often referred to as a "factory" reset, or "hard" reset.

1. Using another device:

   1. create a folder named _PS4_ on a USB drive formatted as FAT32;
   1. inside that folder, create another folder named _UPDATE_;
   1. download the **full** installation file from the [system software download page];

      > the system software installation file must be for a version that is **>=** to the firmware currently installed on the console.

   1. copy the installation file in the _UPDATE_ folder created before; the file **must** be named _PS4UPDATE.PUP_.

2. Plug the USB drive containing the file into the PS4;
3. start the console in _Safe Mode_ pressing and hold the power button, and releasing it after the second beep;
4. select Safe Mode's option 7: _Initialize PS4 (Reinstall System Software)_;
5. confirm at the prompts.

If the PS4 does not recognize the file, check that the folder names and file name are correct. Enter the folder names and file name using uppercase letters.

## Restore backed up data from an external USB storage device to the PlayStation 4

When restoring data, your PS4 will erase all the data currently saved on your console. This can't be undone, even if you cancel the restore operation. Make sure you don't erase any important data by mistake. Erased data can't be restored.

1. Go to _Settings_ > _System_ > _Back Up and Restore_;
1. insert the USB drive that contains the backup into your PS4;
1. select _Restore PS4_;
1. select the backup file you'd like to restore;
1. confirm to restore.

Please note, users who have never signed in to PlayStation™Network (PSN) can restore saved data to only the original PS4 console that was backed up. To restore saved data to another PS4 console, you must sign in to PSN before backing up data.

## Sources

- [PS4: upgrade HDD]
- [PS4: External hard drive support]

<!-- internal references -->
[back up the existing data on an external usb storage device]: #back-up-the-existing-data-on-an-external-usb-storage-device
[reinstall the system software]: #reinstall-the-system-software
[restore backed up data from an external usb storage device to the playstation 4]: #restore-backed-up-data-from-an-external-usb-storage-device-to-the-playstation-4
[upgrade the hdd]: #upgrade-the-hdd

[ps4: external hard drive support]: https://www.playstation.com/en-us/support/hardware/ps4-external-hdd-support/
[ps4: upgrade hdd]: https://www.playstation.com/en-us/support/hardware/ps4-upgrade-hdd/#7000
[system software download page]: https://www.playstation.com/en-us/support/hardware/ps4/system-software/
