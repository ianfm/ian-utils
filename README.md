# Ian's Useful Utils

A collection of scripts and configurations I've found useful for development and system administration. It's mostly linux-focused but I do use Windows often so in some cases there are both bash and Powershell scripts for a given task.

Scripts and configs are organized by the tool they focus on, so e.g. scripts for simplifying `docker run` commands would be under `/docker` alongside things like Dockerfiles and compose.yaml files.

Most useful files for me:
- `/ssh/new_remote_host.sh` or `/ssh/new_remote_host.ps1` to set up ssh auth and optionally a docker context for a remote machine
- `/git/set_git_credentials.sh` for a quick interactive setup when git asks who you are
- `dotfiles/.nanorc` because NOBODY EVER ASKED FOR 8-SPACE TABS
- `/powershell/add_git_completion.ps1` to make git way more usable on windows

## Public vs private

This repo is public, so it holds only things that work on anyone's machine and
name no specific host, network or project. Anything that names my machines or a
client's project lives in a separate private repo, `ian-utils-private`. The two
are independent clones -- no submodules, nothing shared between them.

Roughly:

| here (public) | `ian-utils-private` |
| --- | --- |
| generic, reusable, no host or project names | names a specific host, network, or project |
| appimage tooling, Makefiles, code examples, openocd fragments | `.ssh/config`, per-project setup scripts, real image paths |

The openocd fragments use `PROJECT` as a placeholder where a real project name
used to be; substitute your own.

It's pretty messy right now and a few scripts use my name and email for things, so be aware. I'll strip that as I get to it now that I've made this repo public.

Still to sanitize:
- `/remote_development/windows_setup_ssh.ps1` (hostname + public key)
- `/ros_dev.dockerfile` (host-specific key filename)
- `/docker`, `/git`, `/PN` (name and email)
