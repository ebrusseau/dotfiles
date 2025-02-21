#!/usr/bin/env bash

repo=${1:-ebrusseau}
branch=${2:-main}
chezmoi_bin=chezmoi
purge_bin=0
os="$(uname -s)"

echo "Bootstrapping $os ..."
echo ""
case "$os" in
  Darwin*)
    xcode-select --print-path  > /dev/null 2>&1
    rc=$?
    
    if [ $rc -ne 0 ]; then
      echo "Xcode command line developer tools will now be installed."
      echo "Please continue the installation from the desktop window."
      echo ""

      echo "Starting installer ..."
      xcode-select --install  > /dev/null 2>&1
      
      while ! pgrep "Install Command Line Developer Tools" > /dev/null; do
        sleep 1
      done

      echo "Waiting for installer to complete ..."
      x=0
      y=2
      while pgrep "Install Command Line Developer Tools" > /dev/null; do
        sleep 1
      done

      # Test again to make sure install was successful
      xcode-select --print-path > /dev/null 2>&1 
      rc=$?
      
      if [ $rc -ne 0 ]; then
        echo "Install did not complete. Aborting."
        echo ""
        exit 1
      fi
      
      echo "Install completed."
      echo ""
    fi
    ;;
   Linux*)
    if [ ! "$(command -v git)" ]; then
      echo "Git binary not found."
      echo ""

      declare -A osInfo;
      osInfo[/etc/debian_version]="sudo apt-get update && sudo apt-get install -y git curl"
      osInfo[/etc/alpine-release]="apk"
      osInfo[/etc/centos-release]="yum"
      osInfo[/etc/fedora-release]="dnf"

      install_command=""

      for f in "${!osInfo[@]}"; do
        if [[ -f $f ]];then
          install_command="${osInfo[$f]}"
          break
        fi
      done

      if [ -z "${install_command}" ]; then
        echo "ERROR: Could not install git. Unknown distribution."
        exit 1
      fi

      echo "Installing git ..."
      echo ""
      sh -c "$install_command"
      rc=$?

      if [ $rc -ne 0 ]; then
        echo "ERROR: Could not install git. '$install_command' failed."
        exit 1
      fi
    fi
    ;;
  *)
    echo "ERROR: Unknown operating system."
    exit 1
    ;;
esac

if [ ! "$(command -v chezmoi)" ]; then
  bin_dir="$HOME/.local/bin"
  chezmoi_bin="$bin_dir/chezmoi"
  purge_bin=1

  echo ""
  echo "Installing chezmoi ..."
  mkdir -p "$bin_dir"
  if [ "$(command -v curl)" ]; then
    sh -c "$(curl -fsSL https://git.io/chezmoi)" -- -b "$bin_dir"
  elif [ "$(command -v wget)" ]; then
    sh -c "$(wget -qO- https://git.io/chezmoi)" -- -b "$bin_dir"
  else
    echo "ERROR: Cannot continue; curl or wget not installed." >&2
    exit 1
  fi
fi

echo ""
echo "Initializing chezmoi ..."
set -e
if [ $purge_bin -eq 1 ]; then
    # remove temporary binary when complete
    exec "$chezmoi_bin" init --apply "$repo" --branch "$branch" --force --purge-binary
else
    exec "$chezmoi_bin" init --apply "$repo" --branch "$branch"
fi

if [ $? -ne 0 ]; then
  echo "Bootstrapping failed!"
else
  echo "Bootstrapping complete!"
fi
echo ""