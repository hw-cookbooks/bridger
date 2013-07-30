package 'bridge-utils'

([node[:bridger]] + node[:bridger][:additionals]).each do |bridge|
  # sanity checks
  if(bridge[:address] && bridge[:dhcp])
    raise "Bridge can only specify one of :address or :dhcp"
  elsif(bridge[:address].nil? && bridge[:dhcp].nil?)
    raise "Bridge must specify one of :address or :dhcp"
  end

  # Lets build a bridge!
  # TODO: flush here?

  bridger bridge[:name] do
    ipv4_address bridge[:address] if bridge[:address]
    ipv4_netmask bridge[:netmask] if bridge[:netmask]
  end

  bridger_interface bridge[:interface] do
    bidge_name bridge[:name]
    only_if bridge[:interface]
  end

  execute "bridger[configure the bridge (#{bridge[:name]} - dynamic)]" do
    command "dhclient #{bridge[:name]}"
    only_if bridge[:dhcp]
  end
  # YAY we built a bridge!
end
