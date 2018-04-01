def whyrun_supported?
  true
end

action :pull do
  if update_needed
    cmd = "docker pull #{@current_resource.name}:" +
          @current_resource.image_version
    execute cmd do
      Chef::Log.info "#{@current_resource} was pulled."
    end
    new_resource.updated_by_last_action(true)
  end
end

def load_current_resource
  @current_resource = Chef::Resource::DockerContainer.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.image_version(@new_resource.image_version)
end

def update_needed
  cmd = Mixlib::ShellOut.new(
      "docker images | grep #{@new_resource.name} | awk '{ print $2 }' | "\
      "grep #{@new_resource.image_version}")
  cmd.run_command
  cmd.exitstatus != 0
end
