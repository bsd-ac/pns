# pns

Run commands in a podman pod or container namespace.

## Synopsis

```
~$ pns name command [args]
```

## Description
The
**pns**
command is a utility to run a
*command*
inside a podman environment,
*name*.
It supports both pod names and container names.

## Requirements

- [podman](https://podman.io)
- [util-linux](https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/)
- [jq](https://stedolan.github.io/jq/)

## EXAMPLES

These examples showcase how to create a rootless pod
"**epsilonknot**"
by a user
"**epsilon**"
, add a	wireguard interface and manipulate its firewall.

Create the rootless container :

	@epsilon ~/$ podman pod create --name epsilonknot
	@epsilon ~/$ podman pod start epsilonknot

Bring up the wireguard interface
"www"
using
[wg-quick(8)](https://man7.org/linux/man-pages/man8/wg-quick.8.html):

	@epsilon ~/$ pns epsilonknot wg-quick up ~/wireguard/www.conf
	[#] ip link add www type wireguard
	[#] wg setconf www /dev/fd/63
	[#] ip -4 address add xx.xx.xx.xx/32 dev www
	[#] ip -6 address add xx:xx:xx:xx::xx/xx dev www
	[#] ip link set mtu 65440 up dev www
	[#] wg set www fwmark 51820
	[#] ip -6 route add ::/0 dev www table 51820
	[#] ip -6 rule add not fwmark 51820 table 51820
	[#] ip -6 rule add table main suppress_prefixlength 0
	[#] nft -f /dev/fd/63
	[#] ip -4 route add 0.0.0.0/0 dev www table 51820
	[#] ip -4 rule add not fwmark 51820 table 51820
	[#] ip -4 rule add table main suppress_prefixlength 0
	[#] sysctl -q net.ipv4.conf.all.src_valid_mark=1
	[#] nft -f /dev/fd/63

Show the default firewall rules created by
[wg-quick(8)](https://man7.org/linux/man-pages/man8/wg-quick.8.html):

	@epsilon ~/$ pns epsilonknot nft list ruleset
	table ip6 wg-quick-www {
	        chain preraw {
	                type filter hook prerouting priority raw; policy accept;
	                iifname != "www" ip6 daddr xx:xx:xx:xx::xx fib saddr type != local drop
	        }
	
	        chain premangle { # handle 2
	                type filter hook prerouting priority mangle; policy accept;
	                meta l4proto udp meta mark set ct mark
	        }
	
	        chain postmangle { # handle 3
	                type filter hook postrouting priority mangle; policy accept;
	                meta l4proto udp meta mark 0x0000ca6c ct mark set meta mark
	        }
	}
	table ip wg-quick-www { # handle 23
	        chain preraw { # handle 1
	                type filter hook prerouting priority raw; policy accept;
	                iifname != "www" ip daddr xx.xx.xx.xx fib saddr type != local drop
	        }
	
	        chain premangle { # handle 2
	                type filter hook prerouting priority mangle; policy accept;
	                meta l4proto udp meta mark set ct mark
	        }
	
	        chain postmangle { # handle 3
	                type filter hook postrouting priority mangle; policy accept;
	                meta l4proto udp meta mark 0x0000ca6c ct mark set meta mark
	        }
	}

Now add a new inet table with a chain and rules to disallow all ports
except 80 and 443 :

	@epsilon ~/$ pns epsilonknot nft add table inet wgq-www
	@epsilon ~/$ pns epsilonknot nft add chain inet wgq-www preraw '{ type filter hook prerouting priority raw; policy accept; }'
	@epsilon ~/$ pns epsilonknot nft add rule inet wgq-www preraw 'tcp dport != { 80, 443 } drop'
	@epsilon ~/$ pns epsilonknot nft list ruleset
	table ip6 wg-quick-www { # handle 22
	        chain preraw { # handle 1
	                type filter hook prerouting priority raw; policy accept;
	                iifname != "www" ip6 daddr xx:xx:xx:xx::xx fib saddr type != local drop
	        }
	
	        chain premangle { # handle 2
	                type filter hook prerouting priority mangle; policy accept;
	                meta l4proto udp meta mark set ct mark
	        }
	
	        chain postmangle { # handle 3
	                type filter hook postrouting priority mangle; policy accept;
	                meta l4proto udp meta mark 0x0000ca6c ct mark set meta mark
	        }
	}
	table ip wg-quick-www { # handle 23
	        chain preraw { # handle 1
	                type filter hook prerouting priority raw; policy accept;
	                iifname != "www" ip daddr xx.xx.xx.xx fib saddr type != local drop
	        }
	
	        chain premangle { # handle 2
	                type filter hook prerouting priority mangle; policy accept;
	                meta l4proto udp meta mark set ct mark
	        }
	
	        chain postmangle { # handle 3
	                type filter hook postrouting priority mangle; policy accept;
	                meta l4proto udp meta mark 0x0000ca6c ct mark set meta mark
	        }
	}
	table inet wgq-www { # handle 24
	        chain preraw { # handle 1
	                type filter hook prerouting priority raw; policy accept;
	                tcp dport != { 80, 443 } drop
	        }
	}

