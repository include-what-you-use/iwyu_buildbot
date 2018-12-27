#!/usr/bin/env python

import os
import time

try:
    import boto
    import boto.ec2
except ImportError:
    boto = None

from twisted.internet import threads
from twisted.python import log

from buildbot import config
from buildbot.worker import AbstractLatentWorker

RUNNING = "running"
STOPPED = "stopped"

class EC2LatentWorker(AbstractLatentWorker):
    """Slave which starts existing EC2 instance, executes build, stops instance.

    Difference between default EC2LatentWorker is it doesn't create a new
    instance, but starts existing.
    """

    _poll_resolution = 5

    def __init__(self, name, password,
                 aws_id_file_path, region, instance_name):
        if not boto:
            config.error("The python module 'boto' is needed to use EC2 build slaves")
        AbstractLatentWorker.__init__(self, name, password,
            max_builds=None, notify_on_missing=[], missing_timeout=60 * 20,
            build_wait_timeout=0, properties={}, locks=None)
        if not os.path.exists(aws_id_file_path):
            raise ValueError(
                "Please supply your AWS credentials in "
                "the {} file (on two lines).".format(aws_id_file_path))
        with open(aws_id_file_path, "r") as aws_credentials_file:
            access_key_id = aws_credentials_file.readline().strip()
            secret_key = aws_credentials_file.readline().strip()
        self.ec2_conn = boto.ec2.connect_to_region(region,
            aws_access_key_id=access_key_id, aws_secret_access_key=secret_key)
        self.instance = self.ec2_conn.get_only_instances(filters={"tag:Name": instance_name})[0]

    def start_instance(self, build):
        return threads.deferToThread(self._start_instance)

    def _start_instance(self):
        if self.instance.state != RUNNING:
            self.instance.start()
        while self.instance.state != RUNNING:
            time.sleep(self._poll_resolution)
            self.instance.update()
        log.msg("Started instance")
        return True

    def stop_instance(self, fast=False):
        return threads.deferToThread(self._stop_instance)

    def _stop_instance(self):
        if self.instance.state != STOPPED:
            self.instance.stop()
        while self.instance.state != STOPPED:
            time.sleep(self._poll_resolution)
            self.instance.update()
        log.msg("Stopped instance")
