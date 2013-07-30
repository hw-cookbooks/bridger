# support whyrun
def whyrun_supported?
  true
end

action :create do
  if @current_resource.exists
    Chef::Log.info "#{ @new_resource } already exists - nothing to do."
  else
    execute "create bridge #{@current_resource.bridge_name}" do
      command "brctl addbr #{@current_resource.bridge_name}"
    end

    ifconfig "Add ipv4 address to (#{@current_resource.bridge_name})" do
      target @current_resource.ipv4_address
      mask @current_resource.ipv4_netmask if @current_resource.ipv4_netmask
      device @current_resource.bridge_name
      only_if @current_resource.ipv4_address
    end
  end
end

action :delete do
  unless @current_resource.exists
    Chef::Log.info "#{ @current_resource } doesn't exist - can't delete."
  else
    execute "Delete bridge #{@current_resource.bridge_name}" do
      command "brctl delbr #{@current_resource.bridge_name}"
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::Bridger.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.bridge_name(@new_resource.bridge_name)
  @current_resource.ipv4_address(@new_resource.ipv4_address)
  @current_resource.ipv4_netmask(@new_resource.ipv4_netmask)
  @current_resource.exists = bridge_exists?(@current_resource.bridge_name)
end

private

def bridge_exist?(name)
  return true if bridges_interfaces[name]
  return false
end
