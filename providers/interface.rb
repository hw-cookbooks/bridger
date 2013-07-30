# support whyrun
def whyrun_supported?
  true
end

action :attach do
  if @current_resource.attached
    Chef::Log.info "#{ @new_resource } already attached - nothing to do."
  else
    execute "Attach interface #{@current_resource.interface_name} to bridge #{@current_resource.bridge_name}" do
      command "brctl addif #{@current_resource.bridge_name} #{@current_resource.interface_name}"
    end
  end
end

action :detach do
  unless @current_resource.attached
    Chef::Log.info "#{ @current_resource } doesn't attached - can't delete."
  else
    execute "Detach interface #{@current_resource.interface_name} from bridge #{@current_resource.bridge_name}" do
      command "brctl delif #{@current_resource.bridge_name} #{@current_resource.interface_name}"
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::BridgerInterface.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.interface_name(@new_resource.interface_name)
  @current_resource.bridge_name(@new_resource.bridge_name)
  @current_resource.attached = interface_attached?(@current_resource.interface_name, @current_resource.bridge_name)
end

private

def interface_attached?(interface, bridge)
  return true if bridges_interfaces[bridge].include?(interface)
  return false
end
