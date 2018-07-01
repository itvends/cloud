#!/bin/sh

mkdir /srv
touch /srv/bootstrap

cat << EOF | tee /usr/local/etc/rc.d/itvends
#!/bin/sh
#

# PROVIDE: itvends

. /etc/rc.subr

name="itvends-bootstrap"
desc="Custom It Vends components"
rcvar="itvends_enable"
start_cmd="itvends_start"
stop_cmd="itvends_stop"

itvends_start()
{
	/usr/local/bin/git clone git://github.com/itvends/cloud.git /srv/cloud
}

itvends_stop()
{
	echo "Stopped"
}

load_rc_config \$name
run_rc_command "\$1"
EOF

chmod +x /etc/rc.d/itvends

