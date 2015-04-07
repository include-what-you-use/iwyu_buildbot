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
buildslave create-slave slave buildbot-master.include-what-you-use.com:9989 <name> <password>


# Setup EBS.
sudo mkfs -t ext4 /dev/xvdf
sudo mkdir /mnt/buildbot_iwyu_trunk
sudo mount /dev/xvdf /mnt/buildbot_iwyu_trunk/
sudo mkdir /mnt/buildbot_iwyu_trunk/workspace
sudo chown ubuntu:ubuntu /mnt/buildbot_iwyu_trunk/workspace/

mkdir /mnt/buildbot_iwyu_trunk/workspace/sources
svn checkout http://llvm.org/svn/llvm-project/llvm/trunk /mnt/buildbot_iwyu_trunk/workspace/sources/llvm
svn checkout http://llvm.org/svn/llvm-project/cfe/trunk /mnt/buildbot_iwyu_trunk/workspace/sources/llvm/tools/clang

mkdir /mnt/buildbot_iwyu_trunk/workspace/build_llvm
cd /mnt/buildbot_iwyu_trunk/workspace/build_llvm
cmake -G Ninja -DCMAKE_INSTALL_PREFIX=/mnt/buildbot_iwyu_trunk/workspace/installed/ -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=YES /mnt/buildbot_iwyu_trunk/workspace/sources/llvm/
ninja install


svn checkout https://include-what-you-use.googlecode.com/svn/trunk iwyu
cmake -G Ninja -DLLVM_PATH=/mnt/buildbot_iwyu_trunk/workspace/installed/ /mnt/buildbot_iwyu_trunk/workspace/sources/iwyu/
