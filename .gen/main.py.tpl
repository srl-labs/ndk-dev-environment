#!/usr/bin/env python
# coding=utf-8

import grpc

from datetime import datetime

from ndk import sdk_service_pb2
from ndk import sdk_service_pb2_grpc

import logging
from logging.handlers import RotatingFileHandler

agent_name = "{{ getenv "APPNAME" }}"


if __name__ == "__main__":

    log_filename = f"/var/log/srlinux/stdout/{agent_name}.log"
    logging.basicConfig(
        handlers=[RotatingFileHandler(log_filename, maxBytes=3000000, backupCount=5)],
        format="%(asctime)s,%(msecs)03d %(name)s %(levelname)s %(message)s",
        datefmt="%H:%M:%S",
        level=logging.INFO,
    )
    logging.info("START TIME :: {}".format(datetime.now()))

    channel = grpc.insecure_channel("127.0.0.1:50053")
    metadata = [("agent_name", agent_name)]
    sdk_mgr_client = sdk_service_pb2_grpc.SdkMgrServiceStub(channel)

    response = sdk_mgr_client.AgentRegister(
        request=sdk_service_pb2.AgentRegistrationRequest(), metadata=metadata
    )
    logging.info(f"Agent succesfully registered! App ID: {response.app_id}")
