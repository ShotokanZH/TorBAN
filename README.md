# TorBAN
A (cronnable) script to automatically ban tor exit nodes from accessing your server

# Usage:
`chmod +x torban.sh`

`./torban.sh`

..Or in crontab:

`*/15 * * * * ~/torban.sh >/dev/null`

# How does it work:
The script works by creating an iptables table (default: tor-ban), and fills it with the tor IP addresses that can reach the host ( https://check.torproject.org/cgi-bin/TorBulkExitList.py ) all with `-j REJECT --reject-with icmp-port-unreachable`.

It's that simple. But it works.
