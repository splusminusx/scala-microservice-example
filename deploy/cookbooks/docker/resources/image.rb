actions :pull
default_action :pull

attribute :name, name_attribute: true, kind_of: String, required: true
attribute :image_version, kind_of: String, default: 'latest'
