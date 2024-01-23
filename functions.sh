#!/bin/bash

update() {
    curl -L "https://github.com/vincent-163/docker-images/raw/main/functions.sh?_=$(date +%s)" -o ~/functions.sh
    (echo 'source ~/functions.sh'; grep -v 'source ~/functions.sh' ~/.bashrc) > ~/.bashrc.tmp
    
    mv ~/.bashrc.tmp ~/.bashrc
    source ~/functions.sh
}

inituser() {
    type sudo || (echo "sudo not installed, please install"; exit 1)
    useradd -ms /bin/bash user
    groupadd sudo
    usermod -aG sudo user
    echo '%sudo ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/50-sudo-nopasswd
    cp -r ~/.ssh/ /home/user/
    chmod 700 /home/user/.ssh
    chmod 600 /home/user/.ssh/
    cp ~/functions.sh /home/user/
    (echo 'source ~/functions.sh'; grep -v 'source ~/functions.sh' /home/user/.profile) > /home/user/.profile.tmp
    mv /home/user/.profile.tmp /home/user/.profile
    chown -R user.user /home/user/
    loginctl enable-linger user
}
beep() {
    echo -en '\007'
}
waitfor() {
    tail --pid="$1" -f /dev/null
}
waitforp() {
    list=$(pgrep "$@")
    echo "Waiting for $@: $list"
    while read i; do
        waitfor "$i"
    done <<< "$list" 
}
initnspawn() {
    mkdir -p /etc/systemd/nspawn/
    echo '[Network]
VirtualEthernet=off
[Exec]
PrivateUsers=off' > /etc/systemd/nspawn/"$1".nspawn
}

# Handle netplan cloud-init bugs
dmit-init() {
    killall udevadm
    mv /run/systemd/network/* /etc/systemd/network/ && \
    rm /etc/netplan/50-cloud-init.yaml
    sleep 1
    pacman -R --noconfirm netplan cloud-init
    echo "Reboot recommended after fix"
}

# Run command as systemd service
sysuser() {
    name="$1"
    if [ ! "$PWD" == "$HOME" ]; then
        echo "Working directory has to be $HOME"
    fi
    mkdir -p .config/systemd/user
    echo "[Unit]
Description=$name service

[Service]
ExecStart=$@
WorkingDirectory=$HOME

[Install]
WantedBy=default.target" > .config/systemd/user/"$name".service
    systemctl --user enable "$name"
    systemctl --user start "$name"
    sleep 0.5
    systemctl --user status "$name"
}

# Handle not found command
orig_command_not_found_handle ()
{
    if [ -x /usr/lib/command-not-found ]; then
        /usr/lib/command-not-found -- "$1";
        return $?;
    else
        if [ -x /usr/share/command-not-found/command-not-found ]; then
            /usr/share/command-not-found/command-not-found -- "$1";
            return $?;
        else
            printf "%s: command not found\n" "$1" 1>&2;
            return 127;
        fi;
    fi
}
# ~/.local/go/bin for go and gofmt
# ~/go/bin for packages installed via go
export PATH=$HOME/.local/go/bin:$HOME/go/bin:$PATH
command_not_found_handle() {
    case "$1" in
        sudo)
            apt-get install -y sudo || pacman -Sy --noconfirm sudo
        ;;
        vim|git|tmux|curl|rsync|git|which|ufw|bmon|man|jq)
            sudo apt-get install -y "$1" || sudo pacman -Sy --noconfirm "$1"
        ;;
        rclone)
            sudo pacman -Sy --noconfirm rclone || curl https://rclone.org/install.sh | sudo bash
        ;;
        python)
            sudo pacman -Sy --noconfirm python || sudo apt-get install -y python-is-python3
        ;;
        pip)
            sudo pacman -Sy --noconfirm python-pip || sudo apt-get install -y pip
        ;;
        hysteria)
            bash <(curl -fsSL https://get.hy2.sh/)
            # Uninstall: bash <(curl -fsSL https://get.hy2.sh/) --remove
            # Location: /usr/local/bin/hysteria
            sudo setcap cap_net_bind_service=+ep $(which hysteria)
        ;;
        go)
            sudo pacman -Sy --noconfirm go || (
                # https://go.dev/doc/install
                # This installation guide installs with root but suggests adding PATH to user profile
                # bad taste
                # we add path in this functions.sh directly
                mkdir -p ~/.local
                rm -rf ~/.local/go && curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | tar -C ~/.local/ -xzf -
                # (grep -v '$HOME/.local/go/bin' ~/.profile; echo 'export PATH=$PATH:$HOME/.local/go/bin') > ~/.profile.new
                # mv ~/.profile.new ~/.profile
            )
        ;;
        docker|docker-compose)
            (sudo pacman -Sy --noconfirm docker docker-compose && sudo systemctl enable docker --now) || curl -L https://get.docker.io | bash
        ;;
        # brew)
            # NONINTERACTIVE required to prevent it from calling sudo -s which asks for password
            # NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> ~/.bashrc
            # eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        # ;;
        hcloud)
            # sudo pacman -Sy chloud || brew install hcloud
            go install github.com/hetznercloud/cli/cmd/hcloud@latest
        ;;
        tailscale)
            curl -fsSL https://tailscale.com/install.sh | sh
        ;;
        systemd-nspawn)
            sudo apt-get install -y systemd-container || sudo pacman -Sy systemd-container
        ;;
    esac
    if type "$1"; then
        "$@"
    else
        orig_command_not_found_handle "$@"
    fi
}