#!/bin/sh
#
# **NOTICE**
# Do NOT move this file anywhere else. Keep it here. The CM loads this file natively
# without me having to configure anything for the sheer fact that this file exists
# here. If you move it, it won't call this script every time a port is accessed.

PORT=$1
clear

echo -e "
  			 [ Port #$PORT ]
  [########################################################]
  |                                                        \e[0m|
  |             --[\e[1;38;5;27;48;5;45m CONNECTION SUCCESSFUL \e[0m]--              \e[0m|
  |							   |
  |   Before using BREAK COMMANDS, you must press \e[38;5;27mENTER:   \e[0m|
  |   > \e[1;37mRETURN TO MENU:\e[0m	[~] + [.]                 	   \e[0m|	
  |   > \e[1;37mPOWER MENU:\e[0m 	[~] + [P]  			   \e[0m|
  |                                                        \e[0m|
  |   For support, contact Josh at \e[38;5;27mjosh.lowe@uoit.ca\e[0m.      |
  |                                                        \e[0m|
  |   If the device does not respond to keypresses, use    |
  |   the POWER MENU and enter \"s\" to show power status.   |
  |							   |
  |             \e[1;38;5;27mPress any key to continue...               \e[0m|
  |                                                        \e[0m|
  [########################################################]"


read -n 1 -s -r -p " "
clear
