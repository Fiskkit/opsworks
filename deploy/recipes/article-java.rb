include_recipe 'deploy'

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'java'
    Chef::Log.debug("Skipping deploy::java application #{application} as it is not a Java app")
    next
  end

  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  opsworks_deploy do
    deploy_data deploy
    app application
  end

  current_dir = ::File.join(deploy[:deploy_to], 'current')
  app_dir = ::File.join(node['opsworks_java']['app_dir'], 'java')

  # opsworks_deploy creates some stub dirs, which are not needed for typical webapps
  ruby_block "remove unnecessary directory entries in #{current_dir}" do
    block do
      node['opsworks_java'][node['opsworks_java']['java_app_server']]['webapps_dir_entries_to_delete'].each do |dir_entry|
        ::FileUtils.rm_rf(::File.join(current_dir, dir_entry), :secure => true)
      end
    end
  end

  link app_dir do
    to current_dir
    action :create
  end

  include_recipe "opsworks_java::article_service"

  execute "trigger article service restart" do
    command '/bin/true'
    notifies :restart, "service[#{node['opsworks_java']['service_name']}]"
  end
end
