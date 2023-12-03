#!/bin/bash

# Path to the YAML file
YAML_FILE="robots.yaml"
TEMP_FILE="working_robots.txt"

# Read robot names and IPs from the YAML file
# Assuming the YAML structure is like:
# robots:
#   - name: "robot1"
#     ip: "192.168.1.10"
#   - name: "robot2"
#     ip: "192.168.1.11"
# ...

# Readd YAML file from input
if [ $# -eq 1 ]; then
	YAML_FILE=$1
fi

# Initialize arrays
declare -a robot_names
declare -a robot_ips
declare -a robot_groups
declare -a working_ips
declare -a working_names
declare -a working_groups

# Extracting robot names, IPs, and groups
ping_robots() {
	robot_names=()
	robot_ips=()
	robot_groups=()
	if [ ! -f $YAML_FILE ]; then
		echo "File $YAML_FILE not found!"
		exit 1
	else
		echo "Reading $YAML_FILE..."
		while IFS= read -r line; do
			if [[ $line =~ ^[[:space:]]*\-[[:space:]]name: ]]; then
				robot_names+=("$(echo $line | sed 's/.*name: //')")
			elif [[ $line =~ ^[[:space:]]*ip: ]]; then
				robot_ips+=("$(echo $line | sed 's/.*ip: //')")
			elif [[ $line =~ ^[[:space:]]*sensor: ]]; then
				robot_groups+=("$(echo $line | sed 's/.*sensor: //')")
			fi
		done <"$YAML_FILE"
	fi

	# Length of the array
	length=${#robot_ips[@]}
	echo "Found $length IPs in $YAML_FILE"

	# Exit if no IP is found
	if [ $length -eq 0 ]; then
		echo "No IP found in $YAML_FILE"
		exit 1
	fi

	# Remove the temporary file if it exists
	if [ -f $TEMP_FILE ]; then
		rm $TEMP_FILE
	fi

	# Ping each robot and save working ones
	for ((i = 0; i < length; i++)); do
		name=${robot_names[$i]}
		ip=${robot_ips[$i]}
		group=${robot_groups[$i]}

		echo "Pinging $name with IP $ip..."

		if ping -c 1 $ip &>/dev/null; then
			echo ">> | $name is reachable."
			working_ips+=("$ip")
			working_names+=("$name")
			working_groups+=("$group")
			# Save to a temporary file
			echo "$name,$ip,$group" >>$TEMP_FILE
		else
			echo "$name with IP $ip is not reachable."
		fi
	done

}

load_robots() {
	working_ips=()
	working_names=()
	working_groups=()
	if [ -f $TEMP_FILE ]; then
		echo "Loading robots from $TEMP_FILE..."
		while IFS=, read -r name ip sensor; do
			working_ips+=("$ip")
			working_names+=("$name")
			working_groups+=("$sensor")
		done <"$TEMP_FILE"
	else
		echo "File $TEMP_FILE not found! Please run read_robots first."
	fi

	# Generate report

	length=${#working_ips[@]}
	echo "----- $length Working robots -----"
	echo "name               ip            sensor"
	echo "------------------------------------"
	for ((i = 0; i < length; i++)); do
		name=${working_names[$i]}
		ip=${working_ips[$i]}
		group=${working_groups[$i]}
		echo "$name            $ip            $group"
	done
}

run_half_sim() {
	# SSH to each working robot
	length=${#working_ips[@]}
	for ((i = 0; i < length; i++)); do
		name=${working_names[$i]}
		ip=${working_ips[$i]}
		group=${working_groups[$i]}

		echo "Connecting to $name with sensor $group..."

		# Commands to run depending on the group
		if [ "$group" == "realsense" ]; then
			cmd="cam"
		elif [ "$group" == "lidar" ]; then
			cmd="lio"
		else
			cmd="echo Unknown group"
		fi

		# SSH and tmux session configuration
		ssh -t "nvidia@$ip" "
				tmux list-sessions &> /dev/null && tmux kill-session -a
        tmux new-session -d -s $name
				tmux split-window -h -p 50
				tmux select-pane -t 1
				tmux split-window -v -p 75
				tmux select-pane -t 3
				tmux split-window -v -p 80

				for pane in {1..4}; do
    				tmux send-keys -t $name:1.\$pane 'cd ~/ego_swarm_ws && source setup.bash' C-m
				done

				tmux send-keys -t $name:1.1 'roslaunch swarm_ros_bridge onboard_bridge.launch config:=semi_sim_swarm_drone.yaml' C-m
				tmux send-keys -t $name:1.2 'roslaunch ego_planner semi_sim_run_onboard.launch' C-m

				echo '[$name] Initialized.'

        exit;
    	"
		echo "Started tmux session for $name"
	done
}

kill_vins() {
	# SSH to each working robot
	length=${#working_ips[@]}
	for ((i = 0; i < length; i++)); do
		name=${working_names[$i]}
		ip=${working_ips[$i]}
		sensor=${working_groups[$i]}

		if [ "$sensor" == "realsense" ]; then
			cmd="C-c"
		elif [ "$sensor" == "lidar" ]; then
			cmd=""
		fi

		# SSH and tmux session configuration
		ssh -t "nvidia@$ip" "
					tmux send-keys -t $name:1.1 C-c C-m
					tmux send-keys -t $name:1.2 C-c C-m
					echo '[$name] Program Killed]'
        	exit;
    	"
	done
}

kill_sessions() {
	# SSH to each working robot
	length=${#working_ips[@]}
	for ((i = 0; i < length; i++)); do
		name=${working_names[$i]}
		ip=${working_ips[$i]}
		group=${working_groups[$i]}

		# SSH and tmux session configuration
		ssh -t "nvidia@$ip" "
				tmux kill-session -t $name
				echo '[$name] Killed all sessions.'
        exit;
    	"
	done

}

shutdown_all() {
	# SSH to each working robot
	length=${#working_ips[@]}
	for ((i = 0; i < length; i++)); do
		name=${working_names[$i]}
		ip=${working_ips[$i]}
		group=${working_groups[$i]}

		# SSH and tmux session configuration
		ssh -t "nvidia@$ip" "
				echo '[$name] Shutting down...'
				echo 'nvidia' | sudo -S shutdown now 
        exit;
    	"
	done
}
