#!/usr/bin/env sh

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
      echo "Please enter your password to continue."
      sudo -v
      echo ""

      clt_placeholder="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
      sudo touch $clt_placeholder
      trap 'rm -f ${clt_placeholder}' EXIT
      
      echo "Querying software update for available versions ..."
      clt_label=$(softwareupdate --list | \
        grep "\* Label" | \
        grep "Command Line Tools" | \
        cut -d ' ' -f 3- | \
        sort -V | \
        tail -n1)

      if [ -n "${clt_label}" ]; then
        echo "Intalling '${clt_label}' via software update ..."
        echo ""
        sudo softwareupdate --verbose --install "${clt_label}"
        sudo xcode-select --switch "/Library/Developer/CommandLineTools"
        echo ""
      fi
      rm -f "${clt_placeholder}"

      xcode-select --print-path  > /dev/null 2>&1
      rc=$?

      if [ $rc -ne 0 ]; then
        echo "Please continue the installation from the desktop window."
        echo ""

        echo "Starting installer ..."
        xcode-select --install  > /dev/null 2>&1
        
        while ! pgrep "Install Command Line Developer Tools" > /dev/null 2>&1; do
          sleep 1
        done

        echo "Waiting for installer to complete ..."
        while pgrep "Install Command Line Developer Tools" > /dev/null 2>&1; do
          sleep 1
        done
      fi

      # Test again to make sure install was successful
      xcode-select --print-path > /dev/null 2>&1 
      rc=$?
      
      if [ $rc -ne 0 ]; then
        echo "Xcode command line developer tools install did not complete. Aborting."
        echo ""
        exit 1
      fi
      
      echo "Xcode command line developer tools install completed."
      echo ""
    fi
    ;;
   Linux*)
    required="git curl bash"
    missing=""

    for r in $required; do
      [ "$(command -v "$r")" ] || missing="${missing} ${r}"
    done
    
    if [ -n "$missing" ]; then
      echo "Pre-requisites not found: ${missing}"
      echo ""

      install_command=""
      [ -f /etc/debian_version ] && install_command="sudo apt-get update && sudo apt-get install -y"
      [ -f /etc/alpine-release ] && install_command="sudo apk update && sudo apk add --force"
      [ -f /etc/centos-release ] && install_command="sudo yum update && sudo yum install"
      [ -f /etc/fedora-release ] && install_command="sudo dnf -y makecache && dnf -y install"

      if [ -z "${install_command}" ]; then
        echo "ERROR: Could not install pre-requisites. Unknown distribution."
        exit 1
      fi

      echo "Installing missing pre-requisites ..."
      echo ""
      sh -c "${install_command} ${missing}"
      rc=$?

      if [ $rc -ne 0 ]; then
        echo "ERROR: Could not install pre-requisites. '$install_command' failed."
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
  echo "Fetching temporary chezmoi binary ..."
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