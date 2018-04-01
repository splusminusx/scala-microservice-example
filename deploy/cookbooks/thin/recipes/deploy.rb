Chef::Recipe.send(:include, Thin)

services_names.each do |service_name|
  profiles = profile_names(service_name)
  profiles.each do |profile_name|

    profile = get_profile(service_name, profile_name)
    paths = host_paths(service_name, profile_name)

    current_user = get_user
    current_group = get_group

    [paths.conf, paths.log, paths.data].each do |path|
      directory path do
        owner current_user
        group current_group
        action :create
        recursive true
      end
    end

    profile.configs.each do |config|
      url = config_url(profile, config)
      path = config_path(profile, config)

      config_from_consul url do
        url url
        path path
      end
    end

    docker_image profile.image do
      image_version profile.version
      action :pull
    end

    volumes = %W(
        #{paths.conf}:#{profile.paths.conf}
        #{paths.log}:#{profile.paths.log}
        #{paths.data}:#{profile.paths.data}
    )

    env = %W(
        "HOST_IP_ADDRESS=#{get_private_ip}"
        "PROFILE=#{profile_name}"
    )

    docker_container "#{service_name}-#{profile_name}" do
      image profile.image
      image_version profile.version
      version profile.version
      detach true
      tty true
      command profile.command
      volumes volumes
      env env
      net 'host'
      action :update
      notifies :send, "report[version_#{service_name}-#{profile_name}]"
    end

    report "version_#{service_name}-#{profile_name}" do
      project service_name
      version profile.version
      profile profile_name
      only_if { node['report'] }
      action :nothing
    end
  end

end
