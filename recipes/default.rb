package 'bridge-utils'

if(node[:bridger][:enable_on_boot])
  # setup startup bits
  directory '/etc/bridger'

  file '/etc/bridger/bridge.cnf' do
    action :create
    content(
      JSON.pretty_generate(
        [{:interface => node[:bridger][:interface], :name => node[:bridger][:name], 
        :dhcp => node[:bridger][:dhcp], :address => node[:bridger][:address],
        :netmask => node[:bridger][:netmask], :gateway => node[:bridger][:gateway]
        }] + node[:bridger][:additionals]
      )
    )
    mode 0600
  end

  template '/etc/init.d/bridger-setup' do
    mode 0755
  end

  template '/usr/local/bin/bridger-init' do
    source 'bridger.rb.erb'
    variables(
      :config_file => '/etc/bridger/bridge.cnf',
      :ruby_path => File.join(
        RbConfig::CONFIG['bindir'],
        RbConfig::CONFIG['ruby_install_name']
      )
    )
    mode 0755
  end

  if(node.platform == 'ubuntu')
    template '/etc/init/bridger.conf' do
      source 'bridger.upstart.erb'
      mode 0644
      variables(
        :bridger_exec => '/usr/local/bin/bridger-init'
      )
    end
  else
    template '/etc/init.d/bridger' do
      source 'bridger.init.erb'
      mode 0755
      variables(
        :bridger_exec => '/usr/local/bin/bridger-init'
      )
    end
  end
end

if(node[:bridger][:data_bag_config])
  bag = data_bag_item(node[:bridger][:data_bag], node[:bridger][:data_bag_item])
  if(bag['bridges'])
    bridges = bag['bridges'][node.name]
  end
else
  bridges = ([node[:bridger]] + node[:bridger][:additionals])
end

Chef::Log.warn 'No bridges found for this node!' if bridges.nil? || bridges.empty?

# now check current state
Array(bridges).each do |bridge|
  bridge = Mash.new(bridge)
  # sanity checks
  if(bridge[:address] && bridge[:dhcp])
    raise "Bridge can only specify one of :address or :dhcp"
  elsif(bridge[:address].nil? && bridge[:dhcp].nil?)
    raise "Bridge must specify one of :address or :dhcp"
  elsif(bridge[:gateway] && bridge[:network].nil?)
    raise "Bridge must specify network when providing gateway"
  end

  # Lets build a bridge!
  # TODO: flush here?
  execute "bridger[kill the interface (#{bridge[:interface]})]" do
    command "ifconfig #{bridge[:interface]} 0.0.0.0"
    not_if do
      system("ip addr show #{bridge[:name]} > /dev/null 2>&1")
    end
  end

  execute "bridger[create the bridge (#{bridge[:name]})]" do
    command "brctl addbr #{bridge[:name]}"
    action :nothing
    subscribes :run, resources(:execute => "bridger[kill the interface (#{bridge[:interface]})]"), :immediately
  end

  ruby_block "bridger[interface bind notifier for #{bridge[:name]}]" do
    block do
      true
    end
  end

  Array(bridge[:interface]).each do |interface|
    execute "bridger[bind the bridge (#{bridge[:name]} -> #{interface})]" do
      command "brctl addif #{bridge[:name]} #{interface}"
      not_if do
        %x{
          brctl show #{bridge[:name]} | grep #{bridge[:name]}
        }.strip.split("\n").detect do |line|
          line.split(/\s/).last == interface
        end
      end
    end
  end

  if(bridge[:dhcp])
    execute "bridger[configure the bridge (#{bridge[:name]} - dynamic)]" do
      command "dhclient #{bridge[:name]}"
      action :nothing
      subscribes :run, resources(:execute => "bridger[create the bridge (#{bridge[:name]})]"), :immediately
    end
  else
    execute "bridger[configure the bridge (#{bridge[:name]} - static)]" do
      command "ifconfig #{bridge[:name]} #{bridge[:address]} netmask #{bridge[:netmask]}"
      action :nothing
      subscribes :run, resources(:execute => "bridger[create the bridge (#{bridge[:name]})]"), :immediately
    end
    if(bridge[:gateway])
      execute "bridger[add gateway (#{bridge[:name]} -> #{bridge[:gateway]})]" do
        command "route add -net #{bridge[:network]} netmask #{bridge[:netmask]} gw #{bridge[:gateway]} dev #{bridge[:name]}"
        subscribes :run, resources(:execute => "bridger[configure the bridge (#{bridge[:name]} - static)]"), :immediately
        action :nothing
      end
  end
  # YAY we built a bridge!
end

unless(Array(bridges).empty?)
  execute "bridger[set default gateway (#{bridge[:name]} -> #{node[:bridger][:default_gateway]})]" do
    command "route add default gw #{node[:bridger][:default_gateway]}"
    not_if "route -n | grep #{node[:bridger][:default_gateway]} | grep UG"
  end
end
