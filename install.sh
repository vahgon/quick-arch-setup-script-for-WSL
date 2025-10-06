#!/bin/bash

if [[ "$1" != "user-setup" ]]; then

echo "setting up system..."
pacman -Syu sudo --noconfirm
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

clear

read -p "Enter a username: " username
if [[ -n $username ]]; then
    useradd -m "$username"
    
    usermod -aG wheel $username
    echo "$username ALL=(ALL) NOPASSWD: /usr/bin/pacman" >> /etc/sudoers
    
    echo "user created and has root access"
fi

passwd "$username"

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
pacman -S curl wget fzf gcc python-virtualenv python-pycurl git unzip libcurl-compat python python-pip vim python-pipx pyenv rustup nano vim make tmux zip direnv nmap jq python-dnspython ruby python-pipenv python-requests --noconfirm 

cp /root/install.sh /home/$username/
cp /root/bash_profile /home/$username/
chown $username:$username /home/$username/install.sh
chown $username:$username /home/$username/bash_profile
chmod +x /home/$username/install.sh

su - "$username" -c "/home/$username/install.sh user-setup $username"
clear 
else

# ---user setup------------------------------------------------
echo "setting up user"
username="$2"

cat bash_profile >> .bash_profile
rm bash_profile

cd ~

sudo -S pacman -S --needed git base-devel --noconfirm
echo "installing yay..."
git clone https://aur.archlinux.org/yay.git
cd ~/yay
makepkg -si
cd ~
rm -rf ~/yay

export PATH=$PATH:/snap/bin
export PATH=$HOME/.local/bin:$PATH
PIPENV_VENV_IN_PROJECT=1

mkdir -p ~/.local/bin

clear
echo "installing default stable toolchain via rustup..."
rustup default stable
clear
export PATH=$HOME/.cargo/bin:$PATH

if [[ -z "$GOPATH" ]]; then
echo "installing go..."
wget "https://dl.google.com/go/$(curl https://go.dev/VERSION?m=text | head -n1).linux-amd64.tar.gz"
sudo -S tar -xvf $(curl https://go.dev/VERSION?m=text | head -n1).linux-amd64.tar.gz
rm -f $(curl https://go.dev/VERSION?m=text | head -1).linux-amd64.tar.gz
sudo -S mv ~/go /usr/local
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
fi

if [[ -d /snap ]]; then
:
else
yay -S snapd
sudo -S ln -s /var/lib/snapd/snap /snap
export PATH=$PATH:/snap/bin
cd ~
fi

curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh | bash -s $HOME/.local/bin
cargo install rustscan

sudo -S systemctl enable --now snapd.socket 

GOPOS=("github.com/projectdiscovery/alterx/cmd/alterx@latest" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" "github.com/projectdiscovery/httpx/cmd/httpx@latest" "github.com/projectdiscovery/katana/cmd/katana@latest"
"github.com/tomnomnom/waybackurls@latest" "github.com/tomnomnom/anew@latest" "github.com/tomnomnom/meg@latest" "github.com/tomnomnom/unfurl@latest" "github.com/tomnomnom/gron@latest" "github.com/ffuf/ffuf/v2@latest"
"github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest" "github.com/incogbyte/shosubgo@latest" "github.com/sensepost/gowitness@latest" "github.com/lc/gau/v2/cmd/gau@latest" "github.com/OJ/gobuster/v3@latest"
"github.com/rverton/webanalyze/cmd/webanalyze@latest")

for gorepo in "${GOPOS[@]}"; do
    go install "$gorepo"
done 

go get -u github.com/tomnomnom/gf
go get -u github.com/tomnomnom/assetfinder

mkdir ~/tools

REPOS=("aboul3la/Sublist3r.git" "ticarpi/jwt_tool" "yassineaboukir/Asnlookup"
"maurosoria/dirsearch.git --depth 1" "m4ll0k/SecretFinder.git" "rbsec/dnscan.git"
"roys/cewler.git --depth 1")

cd ~/tools/
for repo in "${REPOS[@]}"; do
    
    repo_name=$(echo "$repo" | awk -F'/' '{print $2}' | awk '{print $1}' | sed 's/.git$//')
    git clone https://github.com/$repo $repo_name

    cd ~/tools/"$repo_name"

    pipenv install 
    echo "layout pipenv" >> ./.envrc
    direnv allow

    sed -i "1i #\!$(pwd)/.venv/bin/python" "$(find . -type f -name '*.py' | head -n 1)"
    cd ~/tools/
done

git clone --recurse-submodules https://github.com/r3nt0n/bopscrk
cd ./bopscrk

pipenv install
echo "layout pipenv" >> ./.envrc
direnv allow
cd ./bopscrk
sed -i "1i #\!/home/$username/tools/bopscrk/.venv/bin/python" bopscrk.py
ln ~/tools/bopscrk/bopscrk/bopscrk.py ~/.local/bin/bopscrk

cd ~/tools/
git clone https://github.com/blechschmidt/massdns.git
cd massdns
make
go install github.com/d3mondev/puredns/v2@latest

cd ~/tools/
git clone https://github.com/jobertabma/virtual-host-discovery.git


cd ~/tools/
git clone https://github.com/iamj0ker/bypass-403
cd bypass-403
chmod +x bypass-403.sh

pipx install arjun
pipx install git+https://github.com/xnl-h4ck3r/xnLinkFinder.git
pipx install bbot
pipx install git+https://github.com/xnl-h4ck3r/waymore.git

webanalyze -update

if [[ -d /usr/share/wordlists ]]; then
:
else
sudo -S mkdir /usr/share/wordlists
fi

sudo -S wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O /usr/share/wordlists/SecList.zip && sudo unzip /usr/share/wordlists/SecList.zip && sudo rm -f /usr/share/wordlists/SecList.zip
sudo -S git clone https://github.com/the-xentropy/samlists /usr/share/wordlists/samlists

clear

curshell=bashrc
if [[ "$(echo $SHELL)" == "/usr/bin/bash" ]]; then
read -p "switch to zsh? (y/n) " ans
if [[ "$ans" == "y" ]]; then
    curshell=zsh
    sudo -S pacman -S zsh --noconfirm
fi
fi

if [[ "$curshell" == "zsh" ]]; then
pntshl=zshrc
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"    
sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' ~/.zshrc
else
    pntshl=bashrc
    curshell=bash
fi

echo 'export GOROOT="/usr/local/go"' >> ~/.$pntshl
echo 'export GOPATH="$HOME/go"' >> ~/.$pntshl
echo 'export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"' >> ~/.$pntshl
echo 'export PATH="$PATH:/snap/bin"' >> ~/.$pntshl
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.$pntshl
echo 'export PATH="$HOME/.cargo/bin:$PATH"'
echo 'source ~/.bash_profile' >> ~/.$pntshl
echo 'PIPENV_VENV_IN_PROJECT=1' >> ~/.$pntshl
direnv hook $curshell >> ~/.$pntshl

sudo -S snap install amass

if [[ -f ~/.zshrc ]]; then
chsh -s $(which zsh)
echo "bindkey -v" >> ~/.zshrc
clear
fi
fi