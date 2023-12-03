#!/bin/bash

cd ~/ego_swarm_ws/src/ego_swarm_v2/

git stash

git fetch origin

git reset --hard origin/dev/semi-sim

git stash apply
