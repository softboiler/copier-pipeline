# ? Initialize Linux or MacOS machines

BREW="brew"

# ? Initialize MacOS machine
if [[ $OSTYPE == "darwin"* ]]; then
    # ? Install brew if missing
    if ! command -v $BREW &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ -x "/usr/local/bin/brew" ]; then
            BREW="/usr/local/bin/brew"
        elif [ -x "/opt/homebrew/bin/brew" ]; then
            BREW="/opt/homebrew/bin/brew"
        fi
    fi
    $BREW update
    # ? Install Git
    $BREW install git
    # ? Install PowerShell
    $BREW install powershell/tap/powershell
    # ? Install GitHub API
    $BREW install gh
    return
fi

# ? Initialize Linux machines

sudo -v
SNAP="snap"

# ? Handle WSL-specific systemd issue
if grep -i microsoft /proc/version > /dev/null && [ ! -f /etc/wsl.conf ]; then
    sudo tee -a /etc/wsl.conf > /dev/null << EOF
[boot]
systemd=true
EOF
    echo "Enabled systemd in WSL. Run `wsl --shutdown` in host, restart WSL, then re-run this script."
    return
fi

# ? Install snap as needed on Ubuntu or Fedora
if [ "$(command -v apt)" ]; then
    PKG="apt"
    sudo apt update
    # ? Install snap if missing
    if ! command -v $SNAP &> /dev/null; then
        sudo $PKG install -y snapd
        SNAP="/usr/bin/snap"
    fi
elif [ "$(command -v dnf)" ]; then
    PKG="dnf"
    sudo dnf makecache
    # ? Install snap if missing
    if ! command -v $SNAP &> /dev/null; then
        sudo $PKG install -y snapd
        SNAP="/usr/bin/snap"
        # ? Perform Fedora-specific snap setup
        sudo systemctl enable --now snapd.socket
        sudo ln -s /var/lib/snapd/snap /snap
    fi
else return
fi

# ? Install Git, PowerShell, VSCode, and GitHub API on Linux
sudo $PKG install -y git gh
sudo $SNAP install powershell --classic
sudo $SNAP install code --classic

# ? Install `uv`
curl --proto '=https' --tlsv1.2 -LsSf 'https://astral.sh/uv/install.sh' | sh

# ? Finish machine setup
pwsh -Command '. ./dev.ps1 && Initialize-Machine'
