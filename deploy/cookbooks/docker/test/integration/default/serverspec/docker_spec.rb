require 'spec_helper'

describe package('lxc-docker') do
  it { should be_installed }
end

describe user('vagrant') do
  it { should belong_to_group 'docker' }
end
