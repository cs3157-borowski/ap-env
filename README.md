# Advanced Programming – Standard Docker Environment

This repository provides the **standard development environment** for Advanced Programming. Follow these instructions once to get set up; after that, starting your environment takes a single command.

## Table of Contents

- [1. Set Up SSH Keys for GitHub](#1-set-up-ssh-keys-for-github)
- [2. Clone This Repository](#2-clone-this-repository)
- [3. Install Docker](#3-install-docker)
  - [macOS](#macos)
  - [Windows (WSL)](#windows-wsl)
  - [Linux](#linux)
- [4. Make the Scripts Executable](#4-make-the-scripts-executable)
- [5. First-Time Setup: Run the Setup Script](#5-first-time-setup-run-the-setup-script)
- [6. Every Time After That: Starting the Container](#6-every-time-after-that-starting-the-container)
- [7. What You Do Inside the Container](#7-what-you-do-inside-the-container)
- [8. Troubleshooting](#8-troubleshooting)
- [9. Fairness and Grading Policy](#9-fairness-and-grading-policy)

---

## 1. Set Up SSH Keys for GitHub

To clone this repository, your computer needs to be authorized to communicate with GitHub. The standard way to do this is with an SSH key — a pair of files that act like a password, but you never have to type it.

**If you have never set up GitHub SSH keys before**, follow GitHub's official guide:

> [Generating a new SSH key and adding it to the SSH agent](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

That page walks you through creating a key and registering it with your GitHub account. Once done, you will be able to `git clone` and `git pull` without entering a password every time.

You won't need to push to this repository — but we may update the scripts over time, so you may occasionally need to run `git pull` to get the latest version.

---

## 2. Clone This Repository

Pick a **permanent folder** on your computer where you will keep your course work. This folder will also be your working directory inside the container, so choose somewhere stable (not your Downloads folder, not a temp directory).

For example:

```bash
# macOS / Linux / WSL (Ubuntu terminal)
mkdir -p ~/cs3157
cd ~/cs3157
git clone git@github.com:CUAdvProg/ap-env.git
cd ap-env
```

> Not sure how to use `git clone`? See GitHub's guide: [Cloning a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)

After cloning, your folder will contain (among others) `setup_docker.sh` and `run_docker.sh`. **Do not move or rename this folder** — your container will always look for it in the same place.

---

## 3. Install Docker

Docker is the software that runs the course environment. Installation differs by OS.

### macOS

1. Download and install **Docker Desktop for Mac** from:
   > [https://docs.docker.com/desktop/install/mac-install/](https://docs.docker.com/desktop/install/mac-install/)

   Choose the installer that matches your chip (Apple Silicon or Intel — check via  → About This Mac).

2. Open the downloaded `.dmg` file and drag Docker to your Applications folder.

3. Open Docker from Applications. You will see a whale icon in your menu bar. **Wait until it stops animating and shows "Docker is running."**

4. **You do not need to create a Docker account.** If it prompts you to sign in, you can skip or dismiss it.

5. You do not need to use the Docker Desktop GUI after this — it just needs to be running in the background when you use the container.

---

### Windows (WSL)

Docker on Windows requires WSL (Windows Subsystem for Linux), which gives you a full Linux terminal on your Windows machine.

**Step A — Install WSL with Ubuntu (only once)**

1. Open PowerShell as Administrator:
   - Press Start, type `PowerShell`, right-click → "Run as administrator".
2. Run:
   ```powershell
   wsl --install
   ```
3. Restart your computer when prompted.
4. After reboot, an Ubuntu terminal window will open automatically. If it doesn't, open "Ubuntu" from the Start Menu.
5. Create a Linux username and password when prompted (this is local to WSL, not your Windows login).

You now have a Linux terminal on Windows. **All course work is done inside this Ubuntu terminal**, not PowerShell or CMD.

**Step B — Install Docker Desktop for Windows**

1. Download and install from:
   > [https://docs.docker.com/desktop/install/windows-install/](https://docs.docker.com/desktop/install/windows-install/)

2. During installation, make sure "Use WSL 2 instead of Hyper-V" is checked (it usually is by default).

3. **You do not need to create a Docker account.** Skip or dismiss any sign-in prompt.

4. Open Docker Desktop. Wait until the whale icon in the system tray says "Docker is running."

5. In Docker Desktop, go to **Settings → Resources → WSL Integration** and enable your Ubuntu distro.

6. You can minimize Docker Desktop — it just needs to be running in the background.

**Step C — Clone the repo inside WSL**

Open your Ubuntu terminal and follow the same steps from [Section 2](#2-clone-this-repository):

```bash
mkdir -p ~/cs3157
cd ~/cs3157
git clone git@github.com:CUAdvProg/ap-env.git
cd ap-env
```

> **Important:** Always work inside the WSL filesystem (paths like `/home/yourname/...`), not in `/mnt/c/...`. The `/mnt/c` path is your Windows C: drive — it's slower and causes permission issues.

---

### Linux

1. Install Docker Engine using the official instructions for your distro:
   > [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)

2. After installation, add your user to the `docker` group so you don't need `sudo` every time:
   ```bash
   sudo usermod -aG docker $USER
   ```
   Then log out and log back in for the change to take effect.

3. Clone the repo as in [Section 2](#2-clone-this-repository).

---

## 4. Make the Scripts Executable

Before running anything, mark both scripts as executable. Run this once from inside the cloned folder:

```bash
chmod +x setup_docker.sh run_docker.sh
```

This is required — without it, the shell will refuse to run the scripts.

---

## 5. First-Time Setup: Run the Setup Script

From inside the `ap-env` folder you cloned, run:

```bash
./setup_docker.sh
```

This script will:

1. Check that Docker is installed and running.
2. Pull the course Docker image from the internet (this may take a few minutes the first time).
3. Launch the container and drop you into a shell at `/ap`.

If Docker isn't running yet when you run this, the script will try to start it automatically and wait. If it can't, it will tell you what to do (usually: open Docker Desktop and try again).

---

## 6. Every Time After That: Starting the Container

Once the setup is done, you don't need to run `setup_docker.sh` again. To start your environment in future sessions, run:

```bash
./run_docker.sh
```

**You must run this from the same `ap-env` folder you cloned** — that folder is what gets shared with the container at `/ap`. If you run it from a different directory, the mount won't point to your work.

If the container already exists from a previous session, the script resumes it. If not, it creates a fresh one.

---

## 7. What You Do Inside the Container

Once you're in the container, your prompt will look like:

```
(ap-env) student@<id>:/ap$
```

You are now inside a Linux environment with all course tools installed (`gcc`, `clang`, `make`, `gdb`, `valgrind`, `git`, and more).

Your `/ap` directory inside the container is the same as the `ap-env` folder on your host machine — files you create or edit on either side are immediately visible on the other side.

Typical workflow:

```bash
cd /ap
ls              # see your files
make            # compile
./my_program    # run
valgrind ./my_program   # check for memory errors
```

You can also edit files using your regular editor on your host (VS Code, etc.) while the container is running — changes appear instantly inside the container.

To exit the container:

```bash
exit
```

The container stops, but your files remain on your host machine.

---

## 8. Troubleshooting

### "Permission denied" when running a script

Make sure you ran the `chmod` command from [Section 4](#4-make-the-scripts-executable):

```bash
chmod +x setup_docker.sh run_docker.sh
```

### "Docker command not found"

Docker is not installed or not in your PATH. Go back to [Section 3](#3-install-docker) and follow the steps for your OS.

### "Cannot connect to Docker daemon"

Docker is installed but not running. Open Docker Desktop (macOS or Windows) and wait until it says "Docker is running", then try again.

### "Permission denied" using Docker on Linux/WSL

Your user is not in the `docker` group yet. Run:

```bash
sudo usermod -aG docker $USER
```

Then log out and log back in. On WSL, close and reopen the Ubuntu terminal.

### Files don't appear inside the container

Make sure you ran `run_docker.sh` from inside the `ap-env` folder you cloned, not from a different directory.

### Something else

Copy the full error message and bring it to office hours or post it on the course forum.

---

## 9. Fairness and Grading Policy

All students are required to compile and test their code inside this Docker environment. We grade using:

- The same Docker image (`ghcr.io/cuadvprog/ap-env:latest`)
- The same resource limits:
  - 4 CPUs
  - 4 GB RAM

If your program works outside the container but fails inside it, we grade based on its behavior inside. There are no exceptions — this ensures a level playing field for everyone.
