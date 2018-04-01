
def create_volume(volume_name)
  cmd = Mixlib::ShellOut.new("docker volume create #{volume_name}")
  cmd.run_command
  cmd.exitstatus != 0
end

def delete_volume(volume_name)
  cmd = Mixlib::ShellOut.new("docker volume rm #{volume_name}")
  cmd.run_command
  cmd.exitstatus != 0
end
