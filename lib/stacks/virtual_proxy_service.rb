require 'stacks/namespace'
require 'stacks/machine_def_container'
require 'stacks/app_server'
require 'stacks/nat'
require 'stacks/proxy_vhost'
require 'uri'

module Stacks::XProxyService
  def self.extended(object)
    object.configure()
  end

  attr_reader :proxy_vhosts
  attr_reader :proxy_vhosts_lookup

  def configure()
    @downstream_services = []
    @proxy_vhosts_lookup = {}
    @proxy_vhosts = []
    @ports = [80, 443]
  end


  def vhost(service, options={}, &config_block)
     key = "#{self.name}.vhost.#{service}.server_name"
    _vhost(key, vip_front_fqdn, vip_fqdn, service, 'default', options, &config_block)
  end

  def sso_vip_front_fqdn
    "#{environment.name}-#{name}-sso-vip.front.#{@domain}"
  end

  def sso_vip_fqdn
    "#{environment.name}-#{name}-sso-vip.#{@domain}"
  end

  def sso_vhost(service, options={}, &config_block)
     key = "#{self.name}.vhost.#{service}-sso.server_name"
     _vhost(key, sso_vip_front_fqdn, sso_vip_fqdn, service, 'sso', options, &config_block)
  end

  def _vhost(key, default_vhost_fqdn, alias_fqdn, service, type, options={}, &config_block)
   if (environment.options.has_key?(key))
      proxy_vhost = Stacks::ProxyVHost.new(environment.options[key], service, type, &config_block)
      proxy_vhost.with_alias(default_vhost_fqdn)
    else
      proxy_vhost = Stacks::ProxyVHost.new(default_vhost_fqdn, service, type, &config_block)
    end
    proxy_vhost.with_alias(alias_fqdn)
    @proxy_vhosts << @proxy_vhosts_lookup[key] = proxy_vhost
  end

  def find_virtual_service(service)
    environment.accept do |machine_def|
      if machine_def.kind_of? Stacks::AbstractVirtualService and service.eql? machine_def.name
        return machine_def
      end
    end

    raise "Cannot find the service called #{service}"
  end

  def downstream_services
    vhost_map = @proxy_vhosts_lookup.values.group_by do |proxy_vhost|
      proxy_vhost.vhost_fqdn
    end

    duplicates = Hash[vhost_map.select do |key, values|
      values.size>1
    end]

    raise "duplicate keys found #{duplicates.keys.inspect}" unless duplicates.size==0

    return Hash[@proxy_vhosts_lookup.values.map do |vhost|
      primary_app = find_virtual_service(vhost.service)

      proxy_pass_rules = Hash[vhost.proxy_pass_rules.map do |path, service|
        [path, "http://#{find_virtual_service(service).vip_fqdn}:8000"]
      end]

      proxy_pass_rules['/'] = "http://#{primary_app.vip_fqdn}:8000"

      [vhost.vhost_fqdn, {
        'aliases' => vhost.aliases,
        'redirects' => vhost.redirects,
        'application' => primary_app.application,
        'proxy_pass_rules' => proxy_pass_rules,
        'type'  => vhost.type
      }]
    end]

  end

  def to_loadbalancer_config
    grouped_realservers = self.realservers.group_by do |realserver|
      'blue'
    end

    realservers = Hash[grouped_realservers.map do |group, realservers|
      realserver_fqdns = realservers.map do |realserver|
        realserver.prod_fqdn
      end.sort
      [group, realserver_fqdns]
    end]

    [self.vip_fqdn, {
      'type' => 'proxy',
      'ports' => @ports,
      'realservers' => realservers
    }]
  end
end
