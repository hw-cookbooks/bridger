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
end

# now check current state
([node[:bridger]] + node[:bridger][:additionals]).each do |bridge|
  # sanity checks
  if(bridge[:address] && bridge[:dhcp])
    raise "Bridge can only specify one of :address or :dhcp"
  elsif(bridge[:address].nil? && bridge[:dhcp].nil?)
    raise "Bridge must specify one of :address or :dhcp"
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
  end
  # YAY we built a bridge!
end
