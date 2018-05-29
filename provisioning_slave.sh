#!/bin/bash

sudo apt-get update
sudo apt-get install -y subversion git
sudo apt-get install -y build-essential ncurses-dev libz-dev
sudo apt-get install -y cmake

# Install ninja.
git clone git://github.com/martine/ninja.git ~/ninja
cd ~/ninja
./configure.py --bootstrap
sudo cp ./ninja /usr/bin/ninja

# Install buildbot slave.
sudo apt-get install -y python-dev python-setuptools
sudo easy_install buildbot-slave
buildslave create-slave slave buildbot-master.include-what-you-use.org:9989 <name> <password>


# Setup EBS.
sudo mkfs -t ext4 /dev/xvdf
sudo mkdir /mnt/buildbot_iwyu_trunk
sudo mount /dev/xvdf /mnt/buildbot_iwyu_trunk/
sudo mkdir /mnt/buildbot_iwyu_trunk/workspace
sudo chown ubuntu:ubuntu /mnt/buildbot_iwyu_trunk/workspace/
# Add to /etc/fstab record like
# UUID=224413c7-7291-4fcb-a247-7e2ce78ce1f4 /mnt/buildbot_iwyu_trunk auto defaults,errors=remount-ro 0 2

mkdir /mnt/buildbot_iwyu_trunk/workspace/sources
svn checkout http://llvm.org/svn/llvm-project/llvm/trunk /mnt/buildbot_iwyu_trunk/workspace/sources/llvm
svn checkout http://llvm.org/svn/llvm-project/cfe/trunk /mnt/buildbot_iwyu_trunk/workspace/sources/llvm/tools/clang

mkdir /mnt/buildbot_iwyu_trunk/workspace/build_llvm
cd /mnt/buildbot_iwyu_trunk/workspace/build_llvm
cmake -G Ninja -DCMAKE_INSTALL_PREFIX=/mnt/buildbot_iwyu_trunk/workspace/installed/ -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=YES /mnt/buildbot_iwyu_trunk/workspace/sources/llvm/
ninja install


cd /mnt/buildbot_iwyu_trunk/workspace/sources
#svn checkout https://include-what-you-use.googlecode.com/svn/trunk iwyu
git clone https://github.com/include-what-you-use/include-what-you-use.git iwyu
mkdir /mnt/buildbot_iwyu_trunk/workspace/build_iwyu
cd /mnt/buildbot_iwyu_trunk/workspace/build_iwyu
cmake -G Ninja -DCMAKE_PREFIX_PATH=/mnt/buildbot_iwyu_trunk/workspace/installed/ /mnt/buildbot_iwyu_trunk/workspace/sources/iwyu/


# Slave startup.
sudo crontab -e
  @reboot /usr/local/bin/buildslave start /home/ubuntu/slave/
