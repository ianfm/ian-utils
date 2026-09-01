# Linux Application Shortcuts

This directory contains Linux desktop/application shortcuts configured for **Bambu Studio** and **Cangaroo CAN Bus Analyzer**. Desktop shortcuts simplify launching applications and generally increase quality of life for linux users. Shortcuts of the the form appname.desktop can be used to launch any executable as far as I know and can be assigned an icon and command arguments to get the deisired launch behavior. They can not only be placed on the desktop, but can be used to register the associated program with the system app launcher!

## Purpose

Provide a template to easily create a shortcut, particularly for AppImages, since they are prevalent and provide no integration with the Ubuntu app launcher.

## Folder Organization

The shortcuts assume the following folder structure, which (I think) adheres to Linux conventions:

- **Application binaries**: Located in `/usr/bin/`
- **Application resources**: Located in `/usr/share/<appname>/`

### Example Structure

For an application named `example_app` with CLI arg --no-sandbox

```ini
[Desktop Entry]
Name=My App Name
Comment=This app does something
Exec=/usr/bin/example_app --no-sandbox
Icon=/usr/share/bambu/example_app.png 
Terminal=false
Type=Application
Categories=Utility;Application;
```

## How to Use

1. Copy an example shortcut file from this directory
2. Edit the file to replace the application name, description, executable path, and icon path. Add any arguments specific to your app as needed
3. To simply have a desktop shortcut, place the file in `/home/$USER/Desktop`
4. To register the shortcut with the system app launcher, copy the file to `~/.local/share/applications/` for user-specific shortcuts or `/usr/share/applications/` for system-wide shortcuts


### Quick Setup Commands

```bash
sudo mv /home/$USER/Downloads/example_app /home/usr/bin/
sudo mkdir /home/usr/share/example_app
sudo mv /home/$USER/Downloads/example_app.png /home/usr/share/example_app/
nano /home/$USER/Desktop/example_app.desktop
# Paste desktop shortcut configuration
sudo cp /home/$USER/Desktop/example_app.desktop /home/usr/share/applications/
```
