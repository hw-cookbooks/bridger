default[:bridger][:interface] = 'eth0'
default[:bridger][:name] = 'br0'
default[:bridger][:dhcp] = true
default[:bridger][:address] = nil
default[:bridger][:netmask] = '255.255.255.0'
default[:bridger][:gateway] = nil
default[:bridger][:enable_on_boot] = false

# Additional bridges are hashes using the same
# infomation structure as above
default[:bridger][:additionals] = []
