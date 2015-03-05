#!/bin/bash

pause(){
  read -p "Press [Enter] key to continue..." key
}
 
configure_networking(){
  #echo "configure networking called"
  python /opt/fractalio/scripts/python/configure_networking.py
}

set_as_primary(){
  #echo "set as primary called"
  ping -c 1 fractalio-pri.fractalio.lan > /dev/null 2> /dev/null
  ret=$?
  if [ $ret != 0 ]
  then
    python /opt/fractalio/scripts/python/set_node_type.py primary
    pause
  else
    echo 'A primary GRIDCell (with hostname fractalio-pri) seems to already exist in the LAN! A grid cannot have more than one primary.'
    pause
  fi
}

first_time_setup(){
  hn=`hostname`
  if [ $hn == "fractalio-pri" ]
  then
    /opt/fractalio/scripts/python/first_time_setup.py
    pause
  else
    echo 'This functionality can only initiated from the primary GRIDCell.'
  fi
}

view_node_status(){
  python /opt/fractalio/scripts/python/display_node_status.py
  pause
}
view_node_config(){
  python /opt/fractalio/scripts/python/display_node_config.py
  pause
}

set_as_secondary(){
  #echo "set as secondary called"
  ping -c 1 fractalio-sec.fractalio.lan > /dev/null 2> /dev/null
  ret=$?
  if [ $ret != 0 ]
  then
    python /opt/fractalio/scripts/python/set_node_type.py secondary
    pause
  else
    echo 'A secondary GRIDCell (with hostname fractalio-sec) seems to already exist in the LAN! A grid cannot have more than one secondary.'
    pause
  fi
}

view_minion_status(){
  hn=`hostname`
  echo $hn
  if [ $hn == "fractalio-pri" ]
  then
    /opt/fractalio/scripts/shell/view_minions.sh
    pause
  else
    echo 'This functionality can only done on a primary GRIDCell'
    pause
  fi
}

reset_minion(){
  /opt/fractalio/scripts/shell/reset_salt_minion.sh
  pause
}

remove_minions(){
  hn=`hostname`
  if [ $hn == "fractalio-pri" ]
  then
    python /opt/fractalio/scripts/python/clear_minions.py
    pause
  else
    echo 'This functionality can only done on a primary GRIDCell'
    pause
  fi
}

 

goto_shell() {
  su -l fractalio
  pause
}

do_reboot() {
  reboot now
  pause
}


do_shutdown() {
  shutdown -h now
  pause
}

show_menu() {
  primary=$1
  secondary=$2
  clear
  echo "-------------------------------"	
  echo " Fractalio IntegralStore - Menu"
  echo "-------------------------------"
  echo "1. Configure Network Configuration"
  echo "2. Reboot"
  echo "3. Shutdown"
  echo "4. View GRIDCell configuration"
  echo "5. View GRIDCell process status"
  if [ $primary == 0 -a $secondary == 0 ]
  then
    #Normal node
    echo "6. Convert this GRIDCell to a primary"
    echo "7. Convert this GRIDCell to a secondary"
  fi
  if [ $primary == 1 ]
  then
    if [ ! -f '/opt/fractalio/first_time_setup_completed' ]
    then
      echo "6. View minion status"
      echo "7. Initiate the first time grid setup"
    else
      echo "6. View minion status"
    fi
  fi
}

read_input(){
  primary=$1
  secondary=$2
  local input 
  if [ $primary == 0 -a $secondary == 0 ]
  then
    # Normal node
    read -p "Enter choice [1 - 7] " input 
    case $input in
  		1) configure_networking ;;
    		2) do_reboot;;
    		3) do_shutdown;;
    		4) view_node_config;;
    		5) view_node_status;;
   		6) set_as_primary;;
   		7) set_as_secondary;;
    		*)  echo "Not a Valid INPUT" && sleep 2
    esac
  fi
  if [ $primary == 1  ]
  then
    #Primary node
    if [ ! -f '/opt/fractalio/first_time_setup_completed' ]
    then
        #Primary node with first time setup complete
        read -p "Enter choice [1 - 7] " input 
        case $input in
  		1) configure_networking ;;
    		2) do_reboot;;
    		3) do_shutdown;;
    		4) view_node_config;;
    		5) view_node_status;;
    		6) view_minion_status ;;
    		7) first_time_setup;;
    		*)  echo "Not a Valid INPUT" && sleep 2
    	esac
    else
        read -p "Enter choice [1 - 6] " input 
        case $input in
  		1) configure_networking ;;
    		2) do_reboot;;
    		3) do_shutdown;;
    		4) view_node_config;;
    		5) view_node_status;;
    		6) view_minion_status ;;
    		*)  echo "Not a Valid INPUT" && sleep 2
    	esac
    fi
  fi
}
 
trap '' SIGINT SIGQUIT SIGTSTP
 
while true
do
  echo "fractal menu is started" > /tmp/out
  primary=0
  secondary=0
  hn=`hostname`
  if [ $hn == "fractalio-pri" ]
  then
    primary=1
  fi
  if [ $hn == "fractalio-sec" ]
  then
    secondary=1
  fi
  show_menu $primary $secondary
  read_input $primary $secondary
  echo "fractal menu is stoped" >> /tmp/out
done