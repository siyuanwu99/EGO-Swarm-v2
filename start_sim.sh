#!/bin/bash
#
timeout 3 | rostopic pub /traj_start_trigger geometry_msgs/PoseStamped '{header: {stamp: now, frame_id: "world"}, pose: {position: {x: 0.0, y: 0.0, z: 0.0}, orientation: {x: 0.0, y: 0.0, z: 0.0, w: 1.0}}}'
