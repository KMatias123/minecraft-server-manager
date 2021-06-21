#!/bin/sh
### BEGIN INIT INFO
# Provides:          Minecraft-Server
# Required-Start:    $all
# Required-Stop:     $remote_fs $syslog $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts minecraft server at boot time
# Description:       Starts minecraft server at boot time
### END INIT INFO

# dir which contains the server directory
basedir=/home/user/ # change this to your directory

# tmux session name (`basename \"$basedir\"` -> basedir's name)
session="`basename \"$basedir\"`"

if [[ basedir != */ ]]
then
   basedir+="/"
fi

start() {
    tmux new-session -d -s $session
    
    echo "Starting server"
    
    tmux send-keys -t $session:0 "cd $basedir" C-m
    tmux send-keys -t $session:0 "bash start.sh" C-m
    
    echo "Server started. To attach the session use the argument \"attach\""
    
    #sleep 0.5
    
    #tmux attach-session -t $session:0
}

stop() {
    tmux send-keys -t $session:0 "stop" C-m
    echo "Stopping server..."
    
    for i in {10..1..-1}
    do
        echo -ne "\rWaiting for shutdown... $i"
        sleep 1
    done
    echo "Server stopped. Killing tmux session."
    tmux kill-session -t $session
    echo "Done shutting down the server."
}

updateJar() {

    jarFileLocation="$basedir"
    jarFileLocation+="paperclip.jar"
    downloadinglatest=false
    echo "Getting the download link..."
    latestVersion=$(curl "https://papermc.io/api/v2/projects/paper" -H  "accept: application/json" | jq .versions[-1] | tr -d \")
    # echo $latestVersion
    version=$1

    if [[ $version == "" ]]
    then
        downloadinglatest=true
        version=$latestVersion
    fi

    #echo "Downloading papermc, version $version."

    latestBuild=$(curl -X GET "https://papermc.io/api/v2/projects/paper/versions/$latestVersion" -H  "accept: application/json" | jq .builds[-1])
    #echo "Latest build: $latestBuild"

    downloadLink="https://papermc.io/api/v2/projects/paper/versions/$latestVersion/builds/$latestBuild/downloads/"

    downloadLink+=$(curl -X GET "https://papermc.io/api/v2/projects/paper/versions/$latestVersion/builds/$latestBuild" -H "accept: application/json" | jq .downloads.application.name | tr -d \")

    echo "Downloading paper, version $version."
    echo $downloadLink
    curl -o $jarFileLocation -X GET $downloadLink -H  "accept: application/json"
    echo $downloadLink
}

case "$1" in
start)
    start
;;
stop)
    stop
;;
attach)
    tmux attach -t $session
;;
restart)
    stop
    sleep 0.8
    echo "Restarting server..."
    sleep 0.8
    start
;;
update)

    read -p "What version do you want to upgrade to? Default is the latest version: " version

    updateJar "$version"
;;
*)
echo "Usage: minecraftManager.sh (start|stop|restart|attach|update|help)"
;;
esac