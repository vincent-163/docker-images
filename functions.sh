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
    chown -R user.user /home/user/
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
command_not_found_handle() {
    case "$1" in
        sudo)
            apt-get install -y sudo || sudo pacman -Sy sudo
        ;;
        vim)
            sudo apt-get install -y vim || sudo pacman -Sy vim
        ;;
        tmux)
            sudo apt-get install -y tmux || sudo pacman -Sy tmux
        ;;
        curl)
            sudo apt-get install -y curl || sudo pacman -Sy curl
        ;;
        rsync)
            sudo apt-get install -y rsync || sudo pacman -Sy rsync
        ;;
        rclone)
            sudo pacman -Sy rclone || curl https://rclone.org/install.sh | sudo bash
        ;;
        docker)
            curl -L https://get.docker.io | bash
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