actions :run, :stop, :update, :execute
default_action :run

property :name, name_property: true, kind_of: String, required: true

actions :execute
property :command, kind_of: String, required: true

actions :run, :update

property :image, kind_of: String, required: true
property :image_version, kind_of: String, required: true
property :restart_policy, equal_to: ['no', 'on-failure', 'always'], required: false, default: 'no'
property :command, kind_of: String, default: ''
property :tty, kind_of: [TrueClass, FalseClass], default: true
property :detach, kind_of: [TrueClass, FalseClass], default: true
property :net, kind_of: String, default: 'bridge'
property :volumes, kind_of: Array, default: []
property :env, kind_of: Array, default: []
property :version, kind_of: String, default: lazy { |r| r.image_version }
property :ports, kind_of: Array, default: []
property :hostname, kind_of: String, default: ''

attr_accessor :exists, :running
