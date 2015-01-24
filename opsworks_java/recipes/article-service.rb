service 'article_server' do
  service_name node['opsworks_java']['service_name']
      provider Chef::Provider::Service::Upstart
      supports :status => true, :restart => true, :reload => true
    
  action :nothing
end