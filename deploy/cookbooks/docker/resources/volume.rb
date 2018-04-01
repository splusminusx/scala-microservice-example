resource_name :docker_volume

property :volume_name, kind_of: String, name_property: true

action :create do
  create_volume(new_resource.volume_name)
end

action :delete do
  delete_volume(new_resource.volume_name)
end
