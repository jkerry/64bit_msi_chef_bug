#
# Cookbook Name:: 64bitSvcInstallBug
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
include_recipe 'windows::default'

windows_feature "NetFx3" do
  action :install
end

cookbook_file "C:\\Installer.msi" do
  source "Installer.msi"
end

# msiexec required a qualified username so if this isn't a domain account
# then prepend the hostname.
domain_service_user = "#{node['hostname']}\\vagrant"

# assign logon as service rights. There's currently no chef resource to do this
# but there are ruby functions on the win api to do it
ruby_block 'Assign logon as service rights' do
  block do
    Chef::ReservedNames::Win32::Security.add_account_right(domain_service_user, 'SeServiceLogonRight')
  end
  not_if {(Chef::ReservedNames::Win32::Security.get_account_right(domain_service_user).include?('SeServiceLogonRight'))}
end

# install the Async service
package "C:\\Installer.msi" do
	action :install
	options "/l* c:\\msiinstall.log ACCOUNT=\"#{domain_service_user}\" PASSWORD=\"vagrant\"  INSTALLLOCATION=C:\\ServiceInstallDir /norestart"
	installer_type :msi
	source "C:\\Installer.msi"
end

remote_file "c:\\chef-client.msi" do
  source "https://packages.chef.io/stable/windows/2008r2/chef-client-12.10.24-1-x64.msi"
end
