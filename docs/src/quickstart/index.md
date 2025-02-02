# {#quickstart} Quickstart

This quickstart guide outlines the step-by-step instructions for getting started with programming in Reach.
You can install on the following operating systems:

* [Windows](##qs-win)
* [Linux](##qs-linux)
* [MacOS](##qs-mac)

If you have any issues running `reach`, please check the [Troubleshooting](##trouble) page for solutions.

# {#qs-win} Windows

Reach requires [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/install) and [Docker Desktop](https://www.docker.com/get-started) to be installed.

## {#qs-win-prereqs} Prerequisites

* Windows 10 installed with version 2004 or higher,

or

* Windows 11

* Virtualization Technology (VT-x) enabled on the BIOS 

## {#qs-win-install} Installation

Click the Windows icon, type `Powershell`, and then click `Run as Administrator`.
There are a number of commands that need to be run to get Windows ready for Reach.

We want to download a tool from Microsoft's GitHub called `winget`.
`winget` is the official Windows package manager:

To install Winget run:
``` cmd
cd c:\; mkdir winget_download; cd winget_download; 
wget -uri https://github.com/microsoft/winget-cli/releases/download/v1.3.431/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -outfile .\winget.msixbundle; .\winget.msixbundle;
.\winget.msixbundle
```
A window should popup, click on Update.

To install WSL on Windows, run:

:::note
Some Windows 10 users need to run `dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart` to install WSL.
:::

``` cmd
$ wsl --install -d Ubuntu
```

In the Command Prompt window, run the following command to set the WSL version to 2:

``` cmd
$ wsl --set-version ubuntu 2
``` 

Next we are going to install Docker using winget:

``` cmd
winget install docker.dockerdesktop
```

After installing docker you should reboot:
``` cmd
shutdown -d -t 0
```

::: note
After rebooting a WSL2 terminal will open up informing it is finishing the installation.
When the installation is finished it will request you to setup a user and password, make sure you don't skip this step
:::

## {#qs-win-conf-docker} Configuring docker:

Open Docker and wait until it is fully started
Click the `Settings` (gear) icon along the top of the Docker app.

![Settings icon in Docker`](/quickstart/settings-icon.png)

Verify that `WSL 2.0` is checked, as well as `Use Docker Compose V2`.

![WSL 2 settings in Docker`](/quickstart/wsl-2.png)
![Docker Compose in Docker`](/quickstart/docker-compose.png)

Click `Resources` in the left-hand menu, and make sure that that `Enable integration with additional distros` is checked, and that `Ubuntu` is selected.

![WSL integration in Docker`](/quickstart/wsl-integrate.png)

Click the Ubuntu icon in the Windows Start-up menu to open the Ubuntu terminal.
You will need to provide a `username` and `password` for Ubuntu.

In the terminal, run the following to install `make` and `curl`:

```cmd
$ sudo apt install make curl
```

Create and navigate to the `reach` directory with the following command:

``` cmd
$ mkdir -p ~/reach && cd ~/reach
```

Download Reach with the following command:

``` cmd
$ curl https://docs.reach.sh/reach -o reach ; chmod +x reach
```

Reach is successfully downloaded if the following command returns a version number:

```
$ ./reach version
```

You are now ready to start programming in Reach.
Check out our [tutorials](##tuts) to get started.

# {#qs-linux} Linux

Reach requires [make](https://en.wikipedia.org/wiki/Make_(software)), [Docker Engine](https://docs.docker.com/get-docker/), and [Docker Compose](https://docs.docker.com/compose/install/).

## {#qs-linux-prereqs} Prerequisites

* A version of Linux compatible with Docker.

Our instructions are written assuming you're using the most recent version of Ubuntu.
Check the [Docker Engine](https://docs.docker.com/engine/install/) page for supported distros. 

## {#qs-linux-install} Installation for Ubuntu

Follow the [Docker Engine](https://docs.docker.com/engine/install/) instructions for installing on your version of Linux.
Check the commands required for completing the tasks below for your distro.
The following instructions, from
[Docker](https://docs.docker.com/engine/install/ubuntu/) assume that Ubuntu is the installed distro.

In the terminal, run the following to install `make`:

```cmd
$ sudo apt install make curl
```

Next, run the following to allow `apt` to use repositories containing HTTPS:

```cmd
$ sudo apt install ca-certificates gnupg lsb-release
```

Docker will be installed by adding a package repository from Docker; this requires updating your `apt` configuration:

```cmd
$ sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

And then, run:

```cmd
$ sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \ $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

After this, run:

```cmd
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io
```

You may want to run the [post-installation steps for Linux](https://docs.docker.com/engine/install/linux-postinstall/) that Docker recommends.

Create and navigate to the `reach` directory with the following command:

``` cmd
$ mkdir -p ~/reach && cd ~/reach
```

Download Reach with the following command:

``` cmd
$ curl https://docs.reach.sh/reach -o reach ; chmod +x reach
```

Reach is successfully downloaded if the following command returns a version number:

```
$ ./reach version
```

You are now ready to start programming in Reach.
Check out our [tutorials](##tuts) to get started.

# {#qs-mac} MacOS

Reach is compatible with M1 chips and Intel chips running macOS 10.15 or newer.
Installation instructions should not differ regardless of the MacOS architecture.
Reach requires installing [Docker](https://www.docker.com/get-started).

## {#qs-mac-install} Installation

`make` should be preinstalled.
Test this by opening `terminal` and running the following command:

``` cmd
$ make --version
```

Download [Docker Desktop](https://www.docker.com/get-started) and follow the prompts to complete application setup.

According to the [Docker Docs](https://docs.docker.com/compose/install/), "Docker Desktop for Mac includes Compose along with other Docker apps, so Mac users do not need to install Compose separately."

To verify that Docker Compose is operating on your Mac, execute the command:

``` cmd
$ docker-compose --version
```

When it returns a version number, Reach is ready to be installed. 

Create and navigate to the `reach` directory with the following command:

``` cmd
$ mkdir -p ~/reach && cd ~/reach
```

Download Reach with the following command:

``` cmd
$ curl https://docs.reach.sh/reach -o reach ; chmod +x reach
```

Reach is successfully downloaded if the following command returns a version number:

```
$ ./reach version
```

You are now ready to start programming in Reach.
Check out our [tutorials](##tuts) to get started.

