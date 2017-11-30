# SELinux Add Modules

## Goal
This script helps build and load SELinux modules based on 
ausearch output to audit2allow -M.  With the newly created pp 
files the script will attempt to load the customized modules 
on each machine.
	
## Details
This script searches hosts audit logs denied entries using ausearch, 
creating a module for each host loading he module and cleaning 
up work and rebooting hosts 
Input should be hosts file with one host per line
Options to allow switching selinux config to permissive 
and then to enforcing after testing

## AUTHOR
Jeff Derbyshire <jeffderb@fnal.gov>

## NOTE
Use as your own risk.  
Whether it's a good idea to do this is unclear, but it seems 
like a better than option than completely disabling SELinux.

## How to Use
```Shell
selinux.add.modules.sh {logs|load|all|clean|permissive|enforcing} {host_list.txt}
```
host_list.txt only required on first run and before clean

### logs
Use list and ausearct to build modules

### load
Load modules on hosts that need them

### all
Set permissive mode, reboot, run logs, then load modules
Then run logs again.  Does not set enforcing mode.

### clean
remove tmp dir and sym link

### permissive
Put SELinux in permssive and reboot hosts

### enforcing
Put SELinux in enforcing mode and reboot hosts
