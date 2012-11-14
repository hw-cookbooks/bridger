default[:bridger][:interface] = 'eth0'
default[:bridger][:name] = 'br0'
default[:bridger][:dhcp] = true
default[:bridger][:address] = nil
default[:bridger][:netmask] = '255.255.255.0'
default[:bridger][:gateway] = nil
default[:bridger][:enable_on_boot] = false
default[:bridger][:data_bag_config] = false
default[:bridger][:data_bag] = 'bridger'
default[:bridger][:data_bag_item] = 'bridges'

# Additional bridges are hashes using the same
# infomation structure as above
default[:bridger][:additionals] = []
