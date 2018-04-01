#
# Cookbook Name:: docker
# Recipe:: install_docker_ce
#
# Copyright:: 2017, Livetex, All Rights Reserved.

packages = %w(
  apt-transport-https
  ca-certificates
  curl
  gnupg2
  software-properties-common
)
packages.each { |p| package p }

apt_repository 'docker-ce' do
  uri           'https://download.docker.com/linux/debian'
  arch          'amd64'
  distribution  node['lsb']['codename']
  components    ['stable']
  key           'https://download.docker.com/linux/debian/gpg'
  notifies      :run, 'execute[apt-get update]', :immediately
end

execute 'apt-get update' do
  command 'apt-get update'
  action  :nothing
end

package 'docker-ce'
