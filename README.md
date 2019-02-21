# NETWORKING LAB SCRIPTS

This repository contains all the work I've done for the networking lab where I work over a period of approximately 1 year. This project was a pretty big undertaking for me as I basically knew nothing about Bash scripting prior to taking the job.

### CONTENTS

There are two main folders in this repository: 

* **``console-managers``** contains scripts for the 12 Opengear CM7132 console managers used in the lab environment, as well as the custom firmware I compiled for them.

* **``openstack``** contains scripts used in the lab's Openstack deployment.

### INFORMATION

During my work period, I mainly worked with Bash scripting. Almost all of my work for this setup utilizes Bash. It is important to specify that the CMs use a very, very old version of Bash (v2.05), so don't be alarmed if you notice really weird implementations of *for* loops in the scripts.

My main tasks for my work period were setting up, configuring, and customizing 12 Opengear CM7132 console managers. The default *pmshell* package used to access the device consoles was inadequate at best, and I was tasked with creating a custom login shell that students access during their lab sessions. I spent the most time over the summer setting up these devices. They even run custom firmware (which includes additional/modified PAM modules and modifications to *sshd_config*).

### AN ASIDE: CHANGES TO THE CM FIRMWARE

While this is mentioned in the *CHANGES.txt* file in the directory for the CM firmware, it might be important to note exactly what changes were made to the CMs' firmware to make them run as intended:

* Added the PAM module ``pam_exec.so`` to run scripts prior to SSH authentication (ergo, running a script while the user is in the process of logging in with their credentials).

* Customized Opengear's ``pam_adduser.so`` PAM module to do the following: 1) not remove a user from a group if they're logging in to another pod that the CM manages, and 2) changing the ``USER_PMSHELL_ONLY`` definition from ``/bin/pmshell`` to ``/etc/config/customscripts/loginshell_menu`` (which means that *loginshell_menu* now runs as an *actual* shell and not just a script being executed from ``/etc/profile``).

* Modifying ``/etc/default/sshd_config`` to permanently disable keyboard interactive authentication by setting the configuration ``ChallengeResponseAuthentication`` to "no". This was required as that form of authentication was causing issues with the scripts I wrote for the CMs, specifically the script that temporarily sets an IP route to the RADIUS server based on a variety of factors. This had to be done, as any modifications made to ``/etc/config/sshd_config`` will be overwritten with the skeleton file located at ``/etc/default/sshd_config`` when you make changes to the CM through the web GUI.

### BACK TO INFORMATION

My second major task was setting up Openstack with another student employee. This was a bit more complex in nature and much more difficult, at least in my opinion. 
