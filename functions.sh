#!/bin/bash

inituser() {
    type sudo || (echo "sudo not installed, please install"; exit 1)
    useradd -ms /bin/bash user
    groupadd sudo
    usermod -aG sudo user
    echo '%sudo ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/50-sudo-nopasswd
    cp -r ~/.ssh/ /home/user/
    chown -R user.user /home/user/
}