#!/bin/bash
# 
script_err=false

leave_exit() {
	printf "\n\n"
	if [ "$script_err" = true ]; then
		printf $"\nUsage: $0 {logs|load|all|clean|permissive|enforcing} host_file.txt\n"
	fi
	exit 0
}

if [ ! -L selinux_modules_tmp ]; then
	ln -s `mktemp -d` selinux_modules_tmp
fi

if [ -s "$TMP_DIR/load_hosts.txt" ]; then
	load_hosts=`cat $TMP_DIR/load_hosts.txt`
fi

TMP_DIR="./selinux_modules_tmp"

if [ "$1" = "logs" ]; then
	if [ -z "$2" ]; then
		printf "\n!!! Missing host file !!!"
		$script_err = true
		leave_exit
	else 
		host_list=`cat $2`
		cp "$2" ./selinux_modules_tmp/orig_hosts
	fi
fi

host_files() {
	printf "\nBuild new host list based on created pp files"
	find $TMP_DIR/ -name "*.pp" |sed 's|./selinux_modules_tmp/||' \
		|sed 's|.selinux.rule.pp||' \
		>"$TMP_DIR/load_hosts.txt" 2>&1
	printf "\nAll files were created in ./selinux_modules_tmp"
	states=( Disabled Permissive Enforcing )
	for state in ${states[@]} ;
	do printf "\nFind $state Hosts";
		find $TMP_DIR/ -name "*$state.log" |sed 's|./selinux_modules_tmp/||' \
			|sed "s|.selinux.status.$state.log||" \
			>"$TMP_DIR/$state.hosts" 2>&1;
	done
	leave_exit
}

read_logs() {
	AVC_CHECK="$TMP_DIR/avc_check.sh"
	cat <<EOME >$AVC_CHECK
	touch \$HOSTNAME.avc
	ausearch -i -m AVC --start today | audit2why > \$HOSTNAME.avc
	ausearch -i -m AVC --start today | audit2allow -M \$HOSTNAME.selinux.rule	
	touch \$HOSTNAME.selinux.status.\`getenforce\`.log
EOME
	chmod 755 $AVC_CHECK

	printf "\nCheck ausearch logs and build modules\n\n"
	for host in $host_list ; 
	do printf \n$host;
		scp $AVC_CHECK root@$host:;
		ssh -t root@$host "./avc_check.sh";
		scp root@$host:$host.* $TMP_DIR/;
		ssh root@$host "rm -f avc_check.sh; rm -f $host.*";
	done
	host_files
	leave_exit
}


load_modules() {
	printf "Load modules onto servers based on the auto generated $load_hosts"
	load_hosts=`cat $TMP_DIR/load_hosts.txt`
	for host in $load_hosts;
	do printf "$host\n";
		scp $TMP_DIR/$host.selinux.rule.pp root@$host:;
		ssh root@$host "semodule -i $host.selinux.rule.pp; \
				semanage fcontext -a -t krb5_keytab_t -fl /etc/krb5.keytab; \
				restorecon -R -v /etc; \
				rm -f $host.selinux.rule.pp; \
				reboot";
	done
	leave_exit
}

clean_up() {
	printf "Cleanup. Remove $TMP_DIR and link to $TMP_DIR"
	# if dir exists remove tmp dir
	rm -rf $TMP_DIR
	rm -rf ./selinux_modules_tmp
	leave_exit
}

set_permissive() {
	printf "Set hosts to permissive mode and reboot"
	orig_hosts=`cat $TMP_DIR/orig_hosts` 
	for host in $orig_hosts ;
	do printf "$host\n";
		ssh root@$host "sed -i 's|^SELINUX=.*|SELINUX=persmissive|g' \
				/etc/selinux/config; \
				reboot;";
	done
	leave_exit
}

set_enforcing() {
	printf "\nFinding hosts without modules..."
	find $TMP_DIR/ -name "*.avc" |sed 's|./selinux_modules_tmp/||' \
				|sed 's|.avc||' \
				>"$TMP_DIR/alive_hosts.txt" 2>&1
	ready_hosts=`comm -3 <(sort $TMP_DIR/alive_hosts.txt) <(sort $TMP_DIR/load_hosts.txt)`
	printf "Set working hosts to enforcing mode and reboot"
	for host in $ready_hosts ;
	do printf "$host\n";
		ssh root@$host "sed -i 's|^SELINUX=.*|SELINUX=enforcing|g' \
				/etc/selinux/config; \
				reboot;";
	done
	leave_exit
}



# Show start parameters and run appropriate section
case "$1" in
	logs)
		read_logs
		;;
	load)
		load_modules
		;;
	all)
		set_permissive
		read_logs
		load_modules
		read_logs
		;;
	clean)
		clean_up
		;;
	permissive)
		set_permissive
		;;
	enforcing)
		set_enforcing
		;;
	files)
		host_files
		;;
	*)
		printf $"\nUsage: $0 {logs|load|all|clean|permissive|enforcing} host_file.txt\n"
		leave_exit
esac
