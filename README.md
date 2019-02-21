# Networking Lab Login Shell
A *pmshell* replacement for the Opengear CM7132 console manager (now fully implemented as a login shell!).

<p align="center">
  <img src="../images/logo.png"/>
</p>

## Introduction
This collection of scripts was developed over a period of approximately 6 months, currently deployed on 12 Opengear CM7132 console managers in a university networking lab. These scripts are what run the student-accessible portion of the lab environment. Students will SSH into the console managers and access one of two "pods" that they manage, which contain a varying number of racked networking devices that students will configure and work with during lab sessions.

There are 8 devices located in the lab itself, referred to as "Lab" CMs. The remaining 4 are located in the data centre, and are referred to as "DC" CMs.

There is a specific reason why there are two groups of CMs in this setup -- the first group, "Lab", is for students in second year or above. These devices are physically accessible from the lab and are intended to be physically cabled by the students during lab sessions. The second group, "DC", includes devices that are racked in a data centre down the hall from the lab. These devices are used by first year students, who are not yet allowed to physically interact with expensive networking equipment. 

The main differences between the CMs specifically are as follows:

- Lab CMs manage 2 student pods each (a total of 16 racks with 2 pods in each rack). The DC CMs manage 4 student pods each (a total of 4 racks with 4 pods in each rack).
- Lab CMs manage 8 devices (4 routers, 4 switches), DC CMs manage 6 devices (3 routers, 3 switches).
- The DC CMs require a menu to access the Openstack VM server; the Lab CMs do not need to provide access to this.
- DC CMs cannot directly interact with their PDUs by use of *powerman* -- they must use SNMP to get and set power states. Additionally, the power states can only be viewed in the custom *power_menu* script. 
- Each group of CMs are on separate networks; the Lab CMs operate in the 172.16.0.0/23 subnet ("Lab_Access"), and the DC CMs operate in the 172.16.2.0/23 subnet ("DC_Access")

As such, there exists two separate folders for each group of CMs. **lab-cm** contains the scripts required for the Lab CMs, and **dc-cm** contains the scripts required for the DC CMs.

The sets of scripts are essentially the same, with some minor differences that reflect the differences in the two groups of CMs explained above. 

## Purpose

Long story short, the default "console menu" login shell that Opengear provides, called "pmshell", is quite unappealing and did not allow for any form of customization. 

Overall, the purpose of these scripts are:
1. Having a nicer-looking menu that users interact with
2. Allowing the CM to effectively operate as *two* devices by use of IP routes
3. Allowing additional menu items that aren't just for accessing console devices (ie. power menu, VM menu)



This login shell is called by a modified *pam_adduser*, which is a proprietary Opengear PAM module that dynamically generates */etc/passwd* and */etc/group*. Initially, the login shell was called by use of a script that would run in */etc/profile*, but this introduced some security concerns that, while they could be addressed, were quite "invasive" in terms of how the system operated (in example, this required an EXIT trap that would trap any invocation of CTRL+D by killing the user's current Bash process; this felt invasive to me, but it was the only thing that could be done to prevent users from exiting the login shell script).

**WIP**

## Todo
- [ ] Finish updating firmware on all Lab CMs
- [ ] Standardize filesystem on Lab CMs
- [ ] Add new "shell" firmware to DC CMs
