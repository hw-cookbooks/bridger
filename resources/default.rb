require 'resolv'

actions :create, :delete
default_action :create

attribute :bridge_name, :kind_of => String, :name_attribute => true
attribute :ipv4_address, :kind_of => String, :regex => Resolv::IPv4::Regex
attribute :ipv4_netmask, :kind_of => String, :regex => Resolv::IPv4::Regex

attr_accessor :exists
