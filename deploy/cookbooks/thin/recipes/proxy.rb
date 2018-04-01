Chef::Recipe.send(:include, Thin)

consul_proxy "service proxy" do
  nginx_conf_path get_nginx_path
  action :create
end
