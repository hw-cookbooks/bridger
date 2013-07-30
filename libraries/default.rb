def bridges_interfaces
  brctl = Mixlib::ShellOut.new("brctl show")
  brctl.run_command
  bridges = brctl.stdout.split("\n") # split in lines
  bridges.delete_at(0) # suppress first line (with header)
  bridges.map! { |x| x.split("\t").to_a.keep_if {|m| m != ""}} # split lines with tabs

  brif = {}
  current_bridge = ""
  bridges.each do |bridge|
    if bridge.length > 1 #first line of bridge
      current_bridge = bridge[0]
      brif[current_bridge] = []
      brif[current_bridge] += [ bridge[3] ] if bridge.length == 4 # we are adding interface in hash
    elsif bridge.length == 1 # line with only an interface
      brif[current_bridge] += [ bridge[0] ]
    end
  end
  return brif
end
