# dotfiles
My cross-platform bootstrap configuration and dotfiles

## Tools Used
- [Chezmoi](https://www.chezmoi.io/)
- [Homebrew](https://brew.sh/)

## Bootstrap a new system
To bootstrap the system, run one of the following commands:

If *curl* is installed:
```sh
bash -c "$(curl -fsLS https://github.com/ebrusseau/dotfiles/raw/main/bootstrap.sh)"
```
If *wget* is installed:
```sh
bash -c "$(wget -qO- https://github.com/ebrusseau/dotfiles/raw/main/bootstrap.sh)"
```