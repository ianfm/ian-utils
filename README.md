# Ian's Useful Utils

A collection of scripts and configurations I've found useful for development and system administration. It's mostly linux-focused but I do use Windows often so in some cases there are both bash and Powershell scripts for a given task.

Scripts and configs are organized by the tool they focus on, so e.g. scripts for simplifying `docker run` commands would be under `/docker` alongside things like Dockerfiles and compose.yaml files.

Most useful files for me:
- `/ssh/new_remote_host.sh` or `/ssh/new_remote_host.ps1` to set up ssh auth and optionally a docker context for a remote machine
- `/git/set_git_credentials.sh` for a quick interactive setup when git asks who you are
- `dotfiles/.nanorc` because NOBODY EVER ASKED FOR 8-SPACE TABS
- `/powershell/add_git_completion.ps1` to make git way more usable on windows

It's pretty messy right now and a few scripts use my name and email for things, so be aware. I'll strip that as I get to it now that I've made this repo public.

To remove/sanitize:
- `/dotfiles`
- `/git`
- `/PN`
