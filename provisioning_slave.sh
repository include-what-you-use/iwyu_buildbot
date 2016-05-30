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
cmake -G Ninja -DLLVM_PATH=/mnt/buildbot_iwyu_trunk/workspace/installed/ /mnt/buildbot_iwyu_trunk/workspace/sources/iwyu/


# Slave startup.
sudo crontab -e
  @reboot /home/ubuntu/attach_ebs.sh
  @reboot /usr/local/bin/buildslave start /home/ubuntu/slave/


# attach_ebs.sh 764 ubuntu:ubuntu
#!/bin/bash

set -euo pipefail

sudo mkdir /mnt/buildbot_iwyu_trunk
sudo mount /dev/xvdf /mnt/buildbot_iwyu_trunk
