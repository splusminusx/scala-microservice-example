include Thin
require 'net/http'
require 'json'
require 'base64'
require 'fileutils'

resource_name :consul_proxy
actions :create

property :nginx_conf_path, String, required: true

action :create do
  url = "http://#{get_private_ip}:3004/v1/agent/services"
  content = Net::HTTP.get(URI("http://#{get_private_ip}:3004/v1/agent/services"))
  fields = %w(Tags Service Address Port ID)

  if content.length > 0
    services = JSON.parse(content)
    services.is_a?(Hash) || fail("#{url} response must be marshaled to Hash.")
    services.values.each do |service|
      (service.is_a?(Hash) &&
          fields.all? {|field| service.key?(field)}) ||
          fail("required field not present in service #{service}")

      id = service['ID']
      tags = service['Tags']
      domain = "#{service['Service']}.service.consul"

      host = service['Address']
      if host == ''
        host = '127.0.0.1'
      end

      port = service['Port']
      if port == ''
        port = '80'
      end
      
      domains = tags.select { |tag|
        tag.start_with?('circuit=')
      }.map { |tag|
        circuit = tag.sub('circuit=', '').sub('.', '_')
        "#{circuit}.#{domain}"
      }

      unless domains.empty?
        #create symlink BEFORE create file to correct notify
        link "#{nginx_conf_path}/sites-enabled/#{id}" do
          to "#{nginx_conf_path}/sites-available/#{id}"
        end

        template "#{nginx_conf_path}/sites-available/#{id}" do
          source "service.conf"
          mode "0644"
          cookbook "thin"
          variables ({
              :domains => domains,
              :main_name => id,
              :url => "http://#{host}:#{port}"
          })
          notifies :run, 'execute[test nginx config]', :immediately
        end
      end
    end
    
    #test config
    #nginx -t
    execute "test nginx config" do
      command "nginx -t"
      action :nothing
      notifies :run, 'execute[reload nginx config]', :immediately
    end
    
    #apply config
    #nginx -s reload
    execute "reload nginx config" do
      command "nginx -s reload"
      action :nothing
    end
  end
end
