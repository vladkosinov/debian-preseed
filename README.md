# debian-preseed

Debian Buster preseed file and related configs for automatic installation over UEFI PXE from MacBook to NUC.

## Links:
- https://www.debian.org/releases/buster/amd64/index.en.html
- https://www.debian.org/releases/buster/example-preseed.txt

## Steps:
- [prepare TFTP directory](#prepare-tftp-directory)
- [set static IP for ethernet interface](#set-static-ip-for-ethernet-interface)
- configure dnsmasq (DHCP + TFTP)
- setup NAT for sharing internet
- run http-server to serve `preseed.txt` and `postinstall.sh`
- start installation

## prepare TFTP directory
#### download and extract netboot installer
```
http://ftp.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/netboot.tar.gz
```

#### copy `grubx64.efi` to the top of TFTP root
_for some reason installer will try to load `grubx64.efi` from the TFTP root and will fail if it's not there_

```bash
cp debian-installer/amd64/grubx64.efi ./
```

#### change `debian-installer/amd64/grub/grub.cfg`
  
```conf
menuentry 'INSTALL' {
    set background_color=black
    # URL TO PRESEED FILE:
    linux    /debian-installer/amd64/linux url=http://192.168.2.1/preseed.txt auto=true priority=critical vga=788 --- quiet
    initrd   /debian-installer/amd64/initrd.gz
}

# AUTO SELECT MENU OPTION:
default=INSTALL
timeout=0
```

## set static IP for ethernet interface
```
Configure IPv4: Manually
Ip Adderss 192.168.2.1
Subnet Mask 255.255.255.0
```

## configure dnsmasq (DHCP + TFTP)

#### install dnsmasq
```
brew install dnsmasq
```

#### change `/usr/local/etc/dnsmasq.conf`
```
log-queries 
log-dhcp

# log to stdout
log-facility=-

# change to your ethernet interface name
# which you can find in `ifconfig` output
interface=en8

dhcp-range=192.168.2.100,192.168.2.150,255.255.255.0,1h

dhcp-boot=/debian-installer/amd64/bootnetx64.efi
enable-tftp

# change to your absolute path to TFTP dir
tftp-root=/Users/pesto/netboot
```

#### start dnsmasq
```bash
sudo /usr/local/opt/dnsmasq/sbin/dnsmasq --keep-in-foreground -C /usr/local/etc/dnsmasq.conf
```

## setup NAT for sharing internet 

https://www.xarg.org/2017/07/set-up-internet-sharing-on-mac-osx-using-command-line-tools/

#### add to `/etc/pf.conf`:
```
# en0 iface name with internet access
nat on en0 from 192.168.2.0/24 to any -> (en0)
```

#### enable IP forwarding
```bash
# Enable IP forwarding: 
sudo sysctl -w net.inet.ip.forwarding=1
```

#### start `pfctl`
```bash
# Disable PF if it was enabled before
sudo pfctl -d

# Enable PF and load the config
sudo pfctl -e -f /etc/pf.conf
```

## create and serve `preseed.txt`

#### create `preseed.txt` 

Create your own `preseed.txt` based on [official preseed-example.txt](https://www.debian.org/releases/buster/example-preseed.txt)

- check documentation explanations for some options https://www.debian.org/releases/buster/amd64/apbs04.en.html
- [see the diff of my preseed.txt](https://github.com/vladkosinov/debian-preseed/compare/46507ab...9ce31a0) with the preseed-example.txt to get some ideas
- include `d-i partman-efi/non_efi_system boolean true` 
to bypass [Force UEFI installation](https://askubuntu.com/questions/827545/ubuntu-server-16-from-iso-in-uefi-preseed-file) screen

- include `d-i preseed/late_command string in-target wget --output-document=/tmp/postinstall.sh http://192.168.2.1/postinstall.sh; in-target /bin/sh /tmp/postinstall.sh` to download and run `postinstall.sh`


#### install and run `http-server`
`npm install -g http-server` or `brew install http-server`
  
```
sudo http-server -p 80 .
```


## Tested environment:
- target machinie `NUC 6CAYH`
- installation server `MacBook 16 (macOS 10.15.5)`

