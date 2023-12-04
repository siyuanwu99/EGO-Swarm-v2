#!/usr/bin/env python3
# Software License Agreement (BSD License)
#
# Copyright (c) 2008, Willow Garage, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials provided
#    with the distribution.
#  * Neither the name of Willow Garage, Inc. nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Revision $Id$

# Simple talker demo that published std_msgs/Strings messages
# to the 'chatter' topic

import numpy as np
import rospy
from std_msgs.msg import String

avg_latency = 0
max_latency = 0
min_latency = 100000
n = 0


def talker():
    rospy.init_node("latency_talker", anonymous=True)
    pub = rospy.Publisher("chatter", String, queue_size=10)
    rospy.Subscriber("chatter_feedback", String, callback)
    rospy.Timer(rospy.Duration(1), timer_callback)
    rate = rospy.Rate(100)  # 100hz
    while not rospy.is_shutdown():
        hello_str = "%s" % rospy.get_time()
        pub.publish(hello_str)
        rate.sleep()


def timer_callback(event):
    global avg_latency
    global max_latency
    global min_latency
    global n
    rospy.loginfo(
        "Avg: %.2f ms, Max: %.2f ms, Min: %.2f ms",
        avg_latency * 1000,
        max_latency * 1000,
        min_latency * 1000,
    )
    n = 0
    avg_latency = 0
    max_latency = 0
    min_latency = 100000


def callback(msg):
    # rospy.loginfo('Feedback "%s" received at %s', msg.data, rospy.get_time())
    send_time = float(msg.data.split(" ")[0])
    feedback_time = float(msg.data.split(" ")[-1])
    # rospy.loginfo("Latency 2: %s", rospy.get_time() - send_time)
    # rospy.loginfo("Latency 1: %s", feedback_time - send_time)
    latency2 = (rospy.get_time() - send_time) / 2

    global avg_latency
    global max_latency
    global min_latency
    global n
    n += 1
    avg_latency = avg_latency + latency2 / n
    max_latency = max(max_latency, latency2)
    min_latency = min(min_latency, latency2)


if __name__ == "__main__":
    try:
        talker()
    except rospy.ROSInterruptException:
        pass
