def whyrun_supported?
  true
end

action :run do
  if running
    Chef::Log.info "#{@new_resource} already running."
  else
    remove_container if exists
    start_container
    new_resource.updated_by_last_action(true)
  end
end

action :update do
  if running
    if version == @new_resource.version
      Chef::Log.info "#{@new_resource} version \
      #{@new_resource.version} already running."
    else
      Chef::Log.info "#{@new_resource} already running."
      stop_container
      remove_container
      start_container
      new_resource.updated_by_last_action(true)
    end
  else
    if exists
      Chef::Log.info "#{@new_resource} already exists."
      remove_container
    end
    start_container
    new_resource.updated_by_last_action(true)
  end
end

action :stop do
  if running
    Chef::Log.info "#{@new_resource} already running."
    stop_container
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{@current_resource.name} not running."
  end
end

action :execute do
  if running
    execute_in_container
    new_resource.updated_by_last_action(true)
  end
end

def load_current_resource
  @current_resource = Chef::Resource::DockerContainer.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @container_regex = "'[\\ ]#{@current_resource.name}-[0-9]\\+\\.[0-9]\\+[a-zA-Z0-9\\.\\_\\-]\\+.*$'"
  @current_resource.version(version)
end

def running
  cmd = Mixlib::ShellOut.new('docker ps | grep -oh ' + @container_regex)
  cmd.run_command
  cmd.exitstatus == 0
end

def exists
  cmd = Mixlib::ShellOut.new('docker ps -a | grep -oh ' + @container_regex)
  cmd.run_command
  cmd.exitstatus == 0
end

def version
  cmd = Mixlib::ShellOut.new(
    'docker ps -a | grep -oh ' + @container_regex + " | sed 's/[\\ ]*#{@current_resource.name}-//g'")
  cmd.run_command
  cmd.stdout.strip
end

def configure_tty
  (@new_resource.detach ? ' -d' : '') +
    (@new_resource.tty ? ' -t' : '')
end

def configure_volumes
  @new_resource.volumes.map { |v| ' -v ' + v }.join('')
end

def confugure_network
  " --net=#{@new_resource.net}" +
    @new_resource.ports.map { |p| ' -p ' + p }.join('')
end

def confugure_restart
  " --restart=#{@new_resource.restart_policy}" 
end

def configure_env
  @new_resource.env.map { |e| ' -e ' + e }.join('')
end

def configure_hostname
  (@new_resource.hostname != '') ? " -h #{@new_resource.hostname}" : ''
end

def start_container
  cmd = 'docker run' + configure_tty + configure_volumes +
        confugure_network + configure_env + confugure_restart +
        " --name=#{@new_resource.name}-#{@new_resource.version} " +
        "#{@new_resource.image}:#{@new_resource.image_version} " +
        @new_resource.command
  execute cmd do
    Chef::Log.info "new #{@new_resource} was run."
  end
end

def remove_container
  cmd = "docker rm -f #{@current_resource.name}-#{@current_resource.version}"
  execute cmd do
    Chef::Log.info "#{@current_resource} was removed."
  end
end

def stop_container
  cmd = "docker stop #{@current_resource.name}-#{@current_resource.version}"
  execute cmd do
    Chef::Log.info "#{@current_resource} was stopped."
  end
end

def execute_in_container
  cmd = "docker exec -i #{@current_resource.name}-#{@current_resource.version} /bin/sh -c '#{@new_resource.command}'"
  execute cmd
end
