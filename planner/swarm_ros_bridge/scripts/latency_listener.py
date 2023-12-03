#!/usr/bin/env python3

import rospy
from std_msgs.msg import String


def callback(data):
    # rospy.loginfo(rospy.get_caller_id() + "I heard %s", data.data)

    rospy.loginfo("I heard %s", data.data)
    # feedback_str = data.data + " feedback at:" + str(rospy.get_time())
    feedback_str = data.data + " " + str(rospy.get_time())
    # print(feedback_str)
    pub.publish(feedback_str)


if __name__ == "__main__":

    # In ROS, nodes are uniquely named. If two nodes with the same
    # name are launched, the previous one is kicked off. The
    # anonymous=True flag means that rospy will choose a unique
    # name for our 'listener' node so that multiple listeners can
    # run simultaneously.
    rospy.init_node("latency_listener", anonymous=True)

    pub = rospy.Publisher("chatter_feedback", String, queue_size=10)

    rospy.Subscriber("chatter", String, callback)
    # spin() simply keeps python from exiting until this node is stopped
    rospy.spin()
