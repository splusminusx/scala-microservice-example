default['deploy'] = {
  'user' => 'livetex',
  'group' => 'livetex',
  'deploy_user' => 'livetex',
  'deploy_group' => 'livetex',
  'conf_path' => '/home/livetex/chef/conf',
  'log_path' => '/home/livetex/chef/log',
  'data_path' => '/home/livetex/chef/data',
  'path' => '/home/livetex/chef',
  'consul_url' => 'http://consul.service.consul:3004/v1/kv/configs/master',
  'nginx_path' => '/etc/nginx'
}
default['report'] = false
