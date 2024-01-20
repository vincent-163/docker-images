#!/bin/bash

update() {
    curl -L "https://github.com/vincent-163/docker-images/raw/main/functions.sh" -o ~/functions.sh
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