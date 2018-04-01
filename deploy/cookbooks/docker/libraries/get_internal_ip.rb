
def docker_get_internal_ip(name, version)
  full_name = docker_get_full_name(name, version)
  ip = docker_get_internal_ip_by_name(full_name)
  return ip
end

def docker_get_internal_ip_by_name(full_name)
  ip = `docker inspect --format '{{ .NetworkSettings.IPAddress }}' #{full_name} | tr -d "\n"`
  return ip
end

