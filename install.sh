#!/bin/bash

SCRIPT_PATH=$(realpath "$0")
if [[ "$1" != "user-setup" ]]; then

echo "setting up system..."
pacman -Syu sudo --noconfirm
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

clear

read -p "Enter a username: " username
if [[ -n $username ]]; then
    useradd -m "$username"
    
    usermod -aG wheel $username
    echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo "user created and has root access"
fi

passwd "$username"
clear

# Make sure this is WSL
if [[ -f /etc/wsl.conf ]]; then
localectl set-locale LANG=en_US.UTF-8
    while true; do
        read -p "make '$username' the default user?: ('y'\'n'): " choice
        if [[ "$choice" == "y" ]]; then
            echo "[user]" >> /etc/wsl.conf
            echo "default=$username" >> /etc/wsl.conf
            break
        elif [[ "$choice" == "n" ]]; then
            break
        else
            echo "invalid choice, defaulting to no..."
        fi
    done
fi

clear

echo "installing packages..." 
pacman -S git base-devel curl wget fzf gcc python-virtualenv python-pycurl git unzip libcurl-compat python python-pip python-pipx pyenv rustup nano vim make tmux zip direnv nmap ruby python-pipenv python-requests --noconfirm 

cp /root/install.sh /home/$username/
cp /root/bash_profile /home/$username/
chown $username:$username /home/$username/install.sh
chown $username:$username /home/$username/bash_profile
chmod +x /home/$username/install.sh

su - "$username" -c "/home/$username/install.sh user-setup $username"
clear 
else

# ---user setup------------------------------------------------
usrPath=('export GOROOT="/usr/local/go"' 'export GOPATH="$HOME/go"' 'export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"' 'export PATH="$PATH:/snap/bin"' 
'export PATH="$HOME/.local/bin:$PATH"' 'export PATH="$HOME/.cargo/bin:$PATH"' 'PIPENV_VENV_IN_PROJECT=1')
username="$2"

for dir in "${usrPath[@]}"; do
echo ${dir} >> ~/.bashrc
done

echo "setting up user"
cat bash_profile >> .bash_profile
rm bash_profile

cd ~

echo "installing yay..."
git clone https://aur.archlinux.org/yay.git
cd ~/yay
makepkg -si
cd ~

mkdir -p ~/.local/bin

clear
echo "installing stable toolchain via rustup..."
rustup default stable
clear

if [[ -z "$GOPATH" ]]; then
echo "installing go..."
wget "https://dl.google.com/go/$(curl https://go.dev/VERSION?m=text | head -n1).linux-amd64.tar.gz"
sudo tar -xvf $(curl https://go.dev/VERSION?m=text | head -n1).linux-amd64.tar.gz
rm -f $(curl https://go.dev/VERSION?m=text | head -1).linux-amd64.tar.gz
sudo mv ~/go /usr/local
fi

if [[ -d /snap ]]; then
:
else
yay -S snapd
sudo ln -s /var/lib/snapd/snap /snap
cd ~
fi

source ~/.bashrc
sudo systemctl enable --now snapd.socket 

clear

direnv hook $curshell >> ~/.bashrc
echo 'export EDITOR=vim' >> ~/.bashrc

echo 'if [[ -z "$TMUX_PANE" ]]; then
    tmux new-session -A -s "${USER}"
fi' >> ~/.bashrc

rm ./install.sh

fi
