# Pi4snap

This repository shows how to setup a Snapcast server on a Raspberry Pi 4B running Ubuntu Server 20.04 and makes use of the great [snapcast](https://github.com/badaix/snapcast) and [snapweb](https://github.com/badaix/snapweb) projects. The image it uses is built from source, and there is a LOT of room for optimization. If you're interested in doing this, I recently came across [a project by @Saiyato](https://github.com/Saiyato/snapserver_docker) that seems promising and more optimized!

## Installation instructions for Rasberry Pi 4B running Ubuntu Server 20.04

```bash
sudo apt-get update && sudo apt-get upgrade
sudo apt-get -y install alsa-utils build-essential libffi-dev libssl-dev python3-dev git

git clone https://github.com/badaix/snapweb.git

# note that though this installation method is recommended on the docker docs
# it's a security risk to pipe anything straight to your shell
# you may choose to separate these into two steps so you may examine
# the script before running
curl -sSL https://get.docker.com | sh

# similar warning with the get-pip.py file used here
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && sudo python3 get-pip.py && rm get-pip.py
sudo pip3 install docker-compose

sudo docker-compose up -d
```
