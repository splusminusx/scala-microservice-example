node['docker']['users'].each do |user|
  group 'docker' do
    action :modify
    members user
    append true
  end
end
