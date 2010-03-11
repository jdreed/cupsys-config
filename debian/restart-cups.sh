restart_cups()
{
	# Handle Debian package name change from cupsys to cups.
	[ -e /etc/init.d/cups ] && rcname=cups || rcname=cupsys
	# Restart cupsd if it is running
	if /etc/init.d/$rcname status; then
	    if hash invoke-rc.d; then
		invoke="invoke-rc.d $rcname"
	    else
		invoke="/etc/init.d/$rcname"
	    fi
	    # Flush remote.cache to deal with things like changing the
	    # server we BrowsePoll against. But don't do so if
	    # policy-rc.d is going to prevent us from restarting cupsd
	    # (for instance, if reactivate is installed and running;
	    # in that case, the next logout will flush remote.cache and restart
	    # cupsd anyway).
	    if $invoke stop; then
		rm -f /var/cache/cups/remote.cache
		$invoke start
	    fi

	    # Wait up to two minutes to pick up all the BrowsePoll server's queues.
	    browse_host="$(sed -ne '/^BrowsePoll/ { s/^BrowsePoll //p; q }' /etc/cups/cupsd.conf)"
	    if [ -n "$browse_host" ]; then
		queue_count=$(lpstat -h "$browse_host" -a | wc -l)
		timeout=0
		while [ $(lpstat -a | wc -l) -lt $queue_count ] && [ $timeout -le 120 ]; do
		    sleep 1
		    timeout=$((timeout+1))
		done
	    fi
	fi
}
