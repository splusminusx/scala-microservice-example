#package apt-transport-https ca-certificates


template "/etc/apt/sources.list.d/docker.list" do
    source "docker.list.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :run, 'execute[add-key]', :immediately
end

execute "add-key" do
    command "apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D"
    action :nothing
    notifies :run, 'execute[apt-get update]', :immediately
end 

execute "apt-get update" do
    command "apt-get update"
    action :nothing
end

package "docker-engine"

