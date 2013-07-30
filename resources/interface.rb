require 'resolv'

actions :attach, :detach
default_action :attach

attribute :interface_name, :kind_of => String, :name_attribute => true, :required => true
attribute :bridge_name, :kind_of => String, :required => true

attr_accessor :attached
