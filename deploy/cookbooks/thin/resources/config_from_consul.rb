require 'net/http'
require 'json'
require 'base64'
require 'fileutils'

resource_name :config_from_consul
actions :create

property :path, String, required: true
property :url, String, required: true

action :create do
  content = Net::HTTP.get(URI(url))
  if content.length > 0
    key_values = JSON.parse(content)
    if key_values.length > 0 && key_values[0].key?('Value')
      file_content = Base64.decode64(key_values[0]['Value'])
      ::File.open(path, 'w:UTF-8') {
          |file| file.write(file_content)
      }
    else
      fail("KeyValue length must be gt 0 url=#{url}")
    end
  else
    fail("Config not found url=#{url}")
  end
end
