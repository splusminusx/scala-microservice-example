module Thin

  Paths = Struct.new(:conf, :log, :data)

  Profile = Struct.new(:name, :service, :image, :version, :command, :configs, :paths)

  def get_private_ip
    networks = [IPAddr.new('192.168.0.0/16'), IPAddr.new('10.0.0.0/8')]
    if node['private_network']
      networks = [IPAddr.new(node['private_network'])]
    end

    (node.key?('network') && node['network'].key?('interfaces')) ||
      fail('node must contain interfaces key')

    interfaces = node['network']['interfaces']

    addresses = interfaces.values.map {
        |iface| (iface['addresses'] || {}).select {
          |_, addr| addr.family == 'inet'
      }.keys
    }.flatten.map { |address| IPAddr.new(address) }

    compatible_addresses = addresses.flatten.select {
        |address| networks.map {
          |network| network.include?(address)
      }.any?
    }

    if compatible_addresses.empty?
      fail("Can't find any private ip address for consul!")
    else
      compatible_addresses.first.to_s
    end
  end

  def get_nginx_path
    node['deploy'] || fail("deploy configuration not set. Check node['deploy'].")
    node['deploy']['nginx_path'] || fail("deploy_path not set. Check node['deploy']['nginx_path'].")
  end

  def services_names
    node['thin'] || fail("services not defined. Check node['thin'].")
    node['thin'].keys
  end

  def profile_names(service_name)
    node['thin'] || fail("services not defined. Check node['thin'].")
    node['thin'][service_name] || fail("service #{service_name} not defined. Check node['thin'][service_name].")

    node['thin'][service_name].keys
  end

  def get_profile(service_name, profile_name)
    node['thin'] || fail("services not defined. Check node['thin'].")
    node['thin'][service_name] || fail("service #{service_name} not defined. Check node['thin']['#{service_name}'].")
    node['thin'][service_name][profile_name] ||
        fail("profile #{profile_name} not defined. Check node['thin']['#{service_name}']['#{profile_name}'].")

    profile = node['thin'][service_name][profile_name]

    valid = %w(version command configs conf_path log_path data_path).all? {
        |key| profile.key?(key)
    }
    if valid
      Profile.new(
          profile_name,
          service_name,
          profile['image'] ||
              "dh.livetex.ru/service/#{service_name}",
          profile['version'],
          profile['command'],
          profile['configs'],
          Paths.new(
              profile['conf_path'],
              profile['log_path'],
              profile['data_path']
          )
      )
    else
      fail("Invalid profile service_name=#{service_name} profile_name=#{profile_name}")
    end
  end

  def host_paths(service_name, profile_name)
    node['deploy'] || fail("deploy configuration not set. Check node['deploy'].")

    # WARNING: приоритет разрешения атрибутов менять опасно.
    # Приведет к несовместимости. Необходимо для совместимости с util
    # и ply.
    conf_path = File.join(node['deploy']['path'], 'conf') || node['deploy']['conf_path'] ||
        fail("conf_path not set. Check node['deploy']['path'] or node['deploy']['conf_path']")
    log_path = File.join(node['deploy']['path'], 'log') || node['deploy']['log_path'] ||
        fail("log_path not set. Check node['deploy']['path'] or node['deploy']['log_path']")
    data_path = File.join(node['deploy']['path'], 'data') || node['deploy']['data_path'] ||
        fail("data_path not set. Check node['deploy']['path'] or node['deploy']['data_path']")

    Paths.new(
        File.join(conf_path, service_name, profile_name),
        File.join(log_path, service_name, profile_name),
        File.join(data_path, service_name, profile_name)
    )
  end

  def config_url(profile, config_name)
    node['deploy'] || fail("deploy configuration not set. Check node['deploy'].")
    node['deploy']['consul_url'] || fail("consul_url not set. Check node['deploy']['consul_url'].")
    "#{node['deploy']['consul_url']}/#{profile.service}/#{profile.name}/#{config_name}"
  end

  def config_path(profile, config_name)
    File.join(host_paths(profile.service, profile.name).conf, config_name)
  end

  def get_user
    node['deploy'] || fail("deploy configuration not set. Check node['deploy'].")
    # WARNING: приоритет разрешения атрибутов менять опасно.
    # Приведет к несовместимости. Необходимо для совместимости с util
    # и ply.
    node['deploy']['user'] || node['deploy']['deploy_user'] ||
        fail("deploy user not set. Check node['deploy']['user'] or node['deploy']['deploy_user']")
  end

  def get_group
    node['deploy'] || fail("deploy configuration not set. Check node['deploy'].")
    # WARNING: приоритет разрешения атрибутов менять опасно.
    # Приведет к несовместимости. Необходимо для совместимости с util
    # и ply.
    node['deploy']['group'] || node['deploy']['deploy_group'] ||
        fail("deploy group not set. Check node['deploy']['group'] or node['deploy']['deploy_group']")
  end

end