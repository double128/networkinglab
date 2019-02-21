#!/bin/bash
#
# LOGIN SHELL POWER MENU
# This is called by the login shell (loginshell_menu.sh). 
# Users will be able to access power options for every device in the rack, 
# all in one convenient space (rather than manually turning off each device
# one at a time... it gets annoying).
# 

COLUMNS=1

### TRAPS #######################
trap "" SIGINT SIGQUIT SIGTSTP  #         
trap "kill -9 $PPID" EXIT       #	
#################################`

# Need this to check the IP address of the current user
SSH_IP="$(echo $SSH_CONNECTION | awk '{print $3}')"

########################### IMPORTANT ####
# Change these variables for each rack	##
					##
POD1="1"				##
POD1IP="172.16.2.1"			##
					##
POD2="2"				##
POD2IP="172.16.2.2"			##
					##
POD3="3"				##
POD3IP="172.16.2.3"			##
					##
POD4="4"				##
POD4IP="172.16.2.4"			##
					##
##########################################

if [[ "$SSH_IP" == "$POD1IP" ]]; then
	POD="$POD1"
elif [[ "$SSH_IP" == "$POD2IP" ]]; then
	POD="$POD2"
elif [[ "$SSH_IP" == "$POD3IP" ]]; then
	POD="$POD3"
elif [[ "$SSH_IP" == "$POD4IP" ]]; then
	POD="$POD4"
fi

# Function for querying powerman information. Accounts for Pod1 and Pod2's existence.
# This menu displays when the power menu is first accessed. It displays the current
# state of each port in the pod.
# This function MUST be called every time an update is made to a device's power state.
powerQuery() {
	
	# Ignore any input to prevent the loading bar from being messed with
	stty igncr
	
	# -----------------------------------------------------------------------------------+ POD 1
	if [[ "$POD" == "$POD1" ]]; then							
        	clear
        	echo -n " > Querying power status"
        	
        	# Pod1 R1 (Port 1)
        	if [[ $(powerman -Q port32_0 | grep 'off:     port') ]]; then
        	        r1_output=$(echo -e "R1 STATUS:	\e[31mOFF\e[0m")
        	elif [[ $(powerman -Q port32_0 | grep 'on:      port') ]]; then
        	        r1_output=$(echo -e "R1 STATUS:	\e[32mON\e[0m")
        	fi
		
		echo -n "."
		
	        # Pod1 R2 (Port 2)
	        if [[ $(powerman -Q port32_1 | grep 'off:     port') ]]; then
	                r2_output=$(echo -e "R2 STATUS:	\e[31mOFF\e[0m")
	        elif [[ $(powerman -Q port32_1 | grep 'on:      port') ]]; then
	                r2_output=$(echo -e "R2 STATUS:	\e[32mON\e[0m")
	        fi
	        
	        echo -n "."

	        # Pod1 R3 (Port 3)
	        if [[ $(powerman -Q port32_2 | grep 'off:     port') ]]; then
	                r3_output=$(echo -e "R3 STATUS:	\e[31mOFF\e[0m")
	        elif [[ $(powerman -Q port32_2 | grep 'on:      port') ]]; then
	                r3_output=$(echo -e "R3 STATUS:	\e[32mON\e[0m")
	        fi
		
		echo -n "."
		
		# Pod1 SW1 (Port 4)        
		if [[ $(powerman -Q port32_3 | grep 'off:     port') ]]; then
	                sw1_output=$(echo -e "SW1 STATUS:	\e[31mOFF\e[0m")
	        elif [[ $(powerman -Q port32_3 | grep 'on:      port') ]]; then
	                sw1_output=$(echo -e "SW1 STATUS:	\e[32mON\e[0m")
	        fi
		
		echo -n "."
		
	        # Pod1 SW2 (Port 5)
	        if [[ $(powerman -Q port32_4 | grep 'off:     port') ]]; then
	                sw2_output=$(echo -e "SW2 STATUS:	\e[31mOFF\e[0m")
	        elif [[ $(powerman -Q port32_4 | grep 'on:      port') ]]; then
	                sw2_output=$(echo -e "SW2 STATUS:	\e[32mON\e[0m")
	        fi
		
		echo -n "."
		
	        # Pod1 SW3 (Port 6)
	        if [[ $(powerman -Q port32_5 | grep 'off:     port') ]]; then
	                sw3_output=$(echo -e "SW3 STATUS:	\e[31mOFF\e[0m")
	        elif [[ $(powerman -Q port32_5 | grep 'on:      port') ]]; then
        	        sw3_output=$(echo -e "SW3 STATUS:	\e[32mON\e[0m")
	        fi
		
		echo -n "."
		echo
	
	# -----------------------------------------------------------------------------------+ POD 2		
	elif [[ "$POD" == "$POD2" ]]; then 
		clear
		echo -n " > Querying power status"
				
		# Pod2 R1 (Port 7)                                              
		if [[ $(powerman -Q port32_6 | grep 'off:     port') ]]; then   
      			r1_output=$(echo -e "R1 STATUS: \e[31mOFF\e[0m")        
		elif [[ $(powerman -Q port32_6 | grep 'on:      port') ]]; then 
        		r1_output=$(echo -e "R1 STATUS: \e[32mON\e[0m")         
		fi  
		
		echo -n "."	
		
		# Pod2 R2 (Port 8)
		if [[ $(powerman -Q port32_7 | grep 'off:     port') ]]; then
			r2_output=$(echo -e "R2 STATUS: \e[31mOFF\e[0m")
		elif [[ $(powerman -Q port32_7 | grep 'on:      port') ]]; then
			r2_output=$(echo -e "R2 STATUS: \e[32mON\e[0m")
		fi

		echo -n "."
		
		# Pod2 R3 (Port 9)
		if [[ $(powerman -Q port32_8 | grep 'off:     port') ]]; then
                        r3_output=$(echo -e "R3 STATUS: \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_8 | grep 'on:      port') ]]; then
                        r3_output=$(echo -e "R3 STATUS: \e[32mON\e[0m")
                fi

		echo -n "."		
		
		# Pod2 SW1 (Port 10)
		if [[ $(powerman -Q port32_9 | grep 'off:     port') ]]; then
                        sw1_output=$(echo -e "SW1 STATUS: \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_9 | grep 'on:      port') ]]; then
                        sw1_output=$(echo -e "SW1 STATUS: \e[32mON\e[0m")
                fi

		echo -n "."		

		# Pod2 SW2 (Port 11)
		if [[ $(powerman -Q port32_10 | grep 'off:     port') ]]; then
                        sw2_output=$(echo -e "SW2 STATUS: \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_10 | grep 'on:      port') ]]; then
                        sw2_output=$(echo -e "SW2 STATUS: \e[32mON\e[0m")
                fi

		echo -n "."
		
		# Pod2 SW3 (Port 12)
		if [[ $(powerman -Q port32_11 | grep 'off:     port') ]]; then
                        sw3_output=$(echo -e "SW3 STATUS: \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_11 | grep 'on:      port') ]]; then
                        sw3_output=$(echo -e "SW3 STATUS: \e[32mON\e[0m")
                fi 
                
                echo -n "."
                echo     
	
	# -----------------------------------------------------------------------------------+ POD 3
	elif [[ "$POD" == "$POD3" ]]; then
                clear
                echo -n " > Querying power status"

                # Pod3 R1 (Port 13)
                if [[ $(powerman -Q port32_12 | grep 'off:     port') ]]; then
                        r1_output=$(echo -e "R1 STATUS: \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_12 | grep 'on:      port') ]]; then
                        r1_output=$(echo -e "R1 STATUS: \e[32mON\e[0m")
                fi

                echo -n "."

                # Pod3 R2 (Port 14)
                if [[ $(powerman -Q port32_13 | grep 'off:     port') ]]; then
                        r2_output=$(echo -e "R2 STATUS: \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_13 | grep 'on:      port') ]]; then
                        r2_output=$(echo -e "R2 STATUS: \e[32mON\e[0m")
                fi

                echo -n "."

                # Pod3 R3 (Port 15)
                if [[ $(powerman -Q port32_14 | grep 'off:     port') ]]; then
                        r3_output=$(echo -e "R3 STATUS: \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_14 | grep 'on:      port') ]]; then
                        r3_output=$(echo -e "R3 STATUS: \e[32mON\e[0m")
                fi

                echo -n "."

                # Pod3 SW1 (Port 16)
                if [[ $(powerman -Q port32_15 | grep 'off:     port') ]]; then
                        sw1_output=$(echo -e "SW1 STATUS:       \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_15 | grep 'on:      port') ]]; then
                        sw1_output=$(echo -e "SW1 STATUS:       \e[32mON\e[0m")
                fi

                echo -n "."

                # Pod1 SW2 (Port 17)
                if [[ $(powerman -Q port32_16 | grep 'off:     port') ]]; then
                        sw2_output=$(echo -e "SW2 STATUS:       \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_16 | grep 'on:      port') ]]; then
                        sw2_output=$(echo -e "SW2 STATUS:       \e[32mON\e[0m")
                fi

                echo -n "."

                # Pod1 SW3 (Port 18)
                if [[ $(powerman -Q port32_17 | grep 'off:     port') ]]; then
                        sw3_output=$(echo -e "SW3 STATUS:       \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_17 | grep 'on:      port') ]]; then
                        sw3_output=$(echo -e "SW3 STATUS:       \e[32mON\e[0m")
                fi

                echo -n "."
                echo
	
	# -----------------------------------------------------------------------------------+ POD 4
	elif [[ "$POD" == "$POD4" ]]; then
                clear
                	echo -n " > Querying power status"

                # Pod4 R1 (Port 19)
                if [[ $(powerman -Q port32_18 | grep 'off:     port') ]]; then
                        r1_output=$(echo -e "R1 STATUS: \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_18 | grep 'on:      port') ]]; then
                        r1_output=$(echo -e "R1 STATUS: \e[32mON\e[0m")
                fi

                echo -n "."

                # Pod4 R2 (Port 20)
                if [[ $(powerman -Q port32_19 | grep 'off:     port') ]]; then
                        r2_output=$(echo -e "R2 STATUS: \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_19 | grep 'on:      port') ]]; then
                        r2_output=$(echo -e "R2 STATUS: \e[32mON\e[0m")
                fi

                echo -n "."

                # Pod4 R3 (Port 21)
                if [[ $(powerman -Q port32_20 | grep 'off:     port') ]]; then
                        r3_output=$(echo -e "R3 STATUS: \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_20 | grep 'on:      port') ]]; then
                        r3_output=$(echo -e "R3 STATUS: \e[32mON\e[0m")
                fi

                echo -n "."

                # Pod4 SW1 (Port 22)
                if [[ $(powerman -Q port32_21 | grep 'off:     port') ]]; then
                        sw1_output=$(echo -e "SW1 STATUS:       \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_21 | grep 'on:      port') ]]; then
                        sw1_output=$(echo -e "SW1 STATUS:       \e[32mON\e[0m")
                fi

                echo -n "."

                # Pod4 SW2 (Port 23)
                if [[ $(powerman -Q port32_22 | grep 'off:     port') ]]; then
                        sw2_output=$(echo -e "SW2 STATUS:       \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_22 | grep 'on:      port') ]]; then
                        sw2_output=$(echo -e "SW2 STATUS:       \e[32mON\e[0m")
                fi

                echo -n "."

                # Pod1 SW3 (Port 6)
                if [[ $(powerman -Q port32_23 | grep 'off:     port') ]]; then
                        sw3_output=$(echo -e "SW3 STATUS:       \e[31mOFF\e[0m")
                elif [[ $(powerman -Q port32_23 | grep 'on:      port') ]]; then
                        sw3_output=$(echo -e "SW3 STATUS:       \e[32mON\e[0m")
                fi

                echo -n "."
                echo            
                                         
        else
        	echo "ERROR: User not in any groups. How did you get here?"
	fi
	stty -igncr
}

# Function for displaying current power states. Pulls the variables from
# powerQuery() and outputs them all at once. Without this function, the 
# powerman queries display one at a time rather than all at once.
powerStatusDisplay() {
	powerQuery
	podNo=$(echo "POD $POD POWER STATUS")
	
	echo -e "
  [#####################################]
  |					|
  |      --[\e[1;38;5;27;48;5;45m$podNo\e[0m]--  	|  	
  |					|
  | 	    $r1_output		|
  | 	    $r2_output		| 
  | 	    $r3_output		|
  |	    $sw1_output		|
  | 	    $sw2_output		|
  | 	    $sw3_output		|
  |      	                        |
  [#####################################]
  
  NOTE: Changes made to a single device's 
  power state via option 1) will be shown
  when the user returns to the power menu.
"      
}

# Changes an individual device's power state, either to OFF or ON, depending on the
# current state of the device.
DevicePowerStateChange() {
	export PS3="[DEVICE]:  "
	echo ""
	echo "Select a device to toggle on/off:  "
	select choice in "R1" "R2" "R3" "R4" "SW1" "SW2" "SW3" "SW4" "Return to main menu"; do
	if [[ "$POD" == "$POD1" ]]; then	
		case $REPLY in
		1)	if [[ $(powerman -Q port32_0 | grep 'on:      port') ]]; then
				powerman -0 port32_0
				echo -e "R1 is now \e[31mOFF\e[0m."
			elif [[ $(powerman -Q port32_0 | grep 'off:     port') ]]; then
				powerman -1 port32_0
				echo -e "R1 is now \e[32mON\e[0m."
			fi;;
	
		2)	if [[ $(powerman -Q port32_1 | grep 'on:      port') ]]; then
				 powerman -0 port32_1
				 echo -e "R2 is now \e[31mOFF\e[0m."
                	elif [[ $(powerman -Q port32_1 | grep 'off:     port') ]]; then
                        	powerman -1 port32_1
                        	echo -e "R2 is now \e[32mON\e[0m."
                	fi;;
	
                3)	if [[ $(powerman -Q port32_2 | grep 'on:      port') ]]; then
                        	powerman -0 port32_2
                        	echo -e "R3 is now \e[31mOFF\e[0m."
               		elif [[ $(powerman -Q port32_2 | grep 'off:     port') ]]; then
                        	powerman -1 port32_2
                        	echo -e "R3 is now \e[32mON\e[0m."
                	fi;;

                4)	if [[ $(powerman -Q port32_3 | grep 'on:      port') ]]; then
                        	powerman -0 port32_3
                        	echo -e "R4 is now \e[31mOFF\e[0m."
                	elif [[ $(powerman -Q port32_3 | grep 'off:     port') ]]; then
                        	powerman -1 port32_3
                        	echo -e "R4 is now \e[32mON\e[0m."
        		fi;;
	
                5)	if [[ $(powerman -Q port32_4 | grep 'on:      port') ]]; then
                        	powerman -0 port32_4
                        	echo -e "SW1 is now \e[31mOFF\e[0m."
                	elif [[ $(powerman -Q port32_4 | grep 'off:     port') ]]; then
                        	powerman -1 port32_4
                        	echo -e "SW1 is now \e[32mON\e[0m."
                	fi;;

                6)	if [[ $(powerman -Q port32_5 | grep 'on:      port') ]]; then
                        	powerman -0 port32_5
                        	echo -e "SW2 is now \e[31mOFF\e[0m."
                	elif [[ $(powerman -Q port32_5 | grep 'off:     port') ]]; then
                        	powerman -1 port32_5
                        	echo -e "SW2 is now \e[32mON\e[0m."
			fi;;
			
                7)	if [[ $(powerman -Q port32_6 | grep 'on:      port') ]]; then
                        	powerman -0 port32_6
                        	echo -e "SW3 is now \e[31mOFF\e[0m."
                	elif [[ $(powerman -Q port32_6 | grep 'off:     port') ]]; then
                        	powerman -1 port32_6
                        	echo -e "SW3 is now \e[32mON\e[0m."
	                fi;;

                8)	if [[ $(powerman -Q port32_7 | grep 'on:      port') ]]; then
                        	powerman -0 port32_7
                        	echo -e "SW4 is now \e[31mOFF\e[0m."
                	elif [[ $(powerman -Q port32_7 | grep 'off:     port') ]]; then
                        	powerman -1 port32_7
                        	echo -e "SW4 is now \e[32mON\e[0m."
                	fi;;
		
		9) clear
		powerStatusDisplay
		break;;

		*) echo "Incorrect input, try again.";;

		esac

	elif [[ "$POD" == "$POD2" ]]; then
                case $REPLY in
                1)      if [[ $(powerman -Q port32_8 | grep 'on:      port') ]]; then
                                powerman -0 port32_8
                                echo -e "R1 is now \e[31mOFF\e[0m."
                        elif [[ $(powerman -Q port32_8 | grep 'off:     port') ]]; then
                                powerman -1 port32_8
                                echo -e "R1 is now \e[32mON\e[0m."
                        fi;;

                2)      if [[ $(powerman -Q port32_9 | grep 'on:      port') ]]; then
                                 powerman -0 port32_9
                                 echo -e "R2 is now \e[31mOFF\e[0m."
                        elif [[ $(powerman -Q port32_9 | grep 'off:     port') ]]; then
                                powerman -1 port32_9
                                echo -e "R2 is now \e[32mON\e[0m."
                        fi;;

                3)      if [[ $(powerman -Q port32_10 | grep 'on:      port') ]]; then
                                powerman -0 port32_10
                                echo -e "R3 is now \e[31mOFF\e[0m."
                        elif [[ $(powerman -Q port32_10 | grep 'off:     port') ]]; then
                                powerman -1 port32_10
                                echo -e "R3 is now \e[32mON\e[0m."
                        fi;;

                4)      if [[ $(powerman -Q port32_11 | grep 'on:      port') ]]; then
                                powerman -0 port32_11
                                echo -e "R4 is now \e[31mOFF\e[0m."
                        elif [[ $(powerman -Q port32_11 | grep 'off:     port') ]]; then
                                powerman -1 port32_11
                                echo -e "R4 is now \e[32mON\e[0m."
                        fi;;

                5)      if [[ $(powerman -Q port32_12 | grep 'on:      port') ]]; then
                                powerman -0 port32_12
                                echo -e "SW1 is now \e[31mOFF\e[0m."
                        elif [[ $(powerman -Q port32_12 | grep 'off:     port') ]]; then
                                powerman -1 port32_12
                                echo -e "SW1 is now \e[32mON\e[0m."
                        fi;;

                6)      if [[ $(powerman -Q port32_13 | grep 'on:      port') ]]; then
                                powerman -0 port32_13
                                echo -e "SW2 is now \e[31mOFF\e[0m."
                        elif [[ $(powerman -Q port32_13 | grep 'off:     port') ]]; then
                                powerman -1 port32_13
                                echo -e "SW2 is now \e[32mON\e[0m."
                        fi;;

                7)      if [[ $(powerman -Q port32_14 | grep 'on:      port') ]]; then
                                powerman -0 port32_14
                                echo -e "SW3 is now \e[31mOFF\e[0m."
                        elif [[ $(powerman -Q port32_14 | grep 'off:     port') ]]; then
                                powerman -1 port32_14
                                echo -e "SW3 is now \e[32mON\e[0m."
                        fi;;

                8)      if [[ $(powerman -Q port32_15 | grep 'on:      port') ]]; then
                                powerman -0 port32_15
                                echo -e "SW4 is now \e[31mOFF\e[0m."
                        elif [[ $(powerman -Q port32_15 | grep 'off:     port') ]]; then
                                powerman -1 port32_15
                                echo -e "SW4 is now \e[32mON\e[0m."
                        fi;;

                9) clear
		powerStatusDisplay
                break;;

                *) echo "Incorrect input, try again.";;

                esac
	fi
	done
	export PS3="> "
}

allDevicesOff() {
	read -p "Shut down all devices? (Y/N): " -n 1 -r choice
	if [[ "$POD" == "$POD1" ]]; then
		case "$choice" in
			y|Y ) echo
			powerman -0 port32_[0-7]
			sleep 1
			powerStatusDisplay;;
			
			n|N ) echo "";;
			
			* ) echo; echo "ERROR: Enter Y or N."
				continue;;
		esac
	elif [[ "$POD" == "$POD2" ]]; then
		case "$choice" in
                        y|Y ) echo
                        powerman -0 port32_[8-15]
                        sleep 1
                        powerStatusDisplay;;

                        n|N ) echo "";;

                        * ) echo; echo "ERROR: Enter Y or N."
                                continue;;
                esac
	fi
}

allDevicesOn() {
	read -p "Power on all devices? (Y/N): " -n 1 -r choice
        if [[ "$POD" == "$POD1" ]]; then	
        	case "$choice" in
                	y|Y ) echo
                       	powerman -1 port32_[0-7]
                       	sleep 1
                       	powerStatusDisplay;;

                        n|N ) echo "";;

                        * ) echo; echo "ERROR: Enter Y or N."
                                continue;;
                esac
	elif [[ "$POD" == "$POD2" ]]; then
		case "$choice" in
                        y|Y ) echo
                        powerman -1 port32_[8-15]
                        sleep 1
                        powerStatusDisplay;;

                        n|N ) echo "";;

                        * ) echo; echo "ERROR: Enter Y or N."
                                continue;;
                esac
	fi
}

powerStatusDisplay
	
PS3="> "
echo "Power menu options: "
select choice in "Change device power state" "Power on all devices" "Power off all devices" "Exit"; do
case $REPLY in
	1) DevicePowerStateChange;;
	2) allDevicesOn;;
	3) allDevicesOff;;
	4) clear; exec /etc/config/customscripts/loginshell_menu.sh;;
esac
done
