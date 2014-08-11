#
# Cookbook Name:: metroextractor
# Recipe:: planet
#

# override tempfile location so the planet download
#   temp file goes somewhere with enough space
ENV['TMP'] = node[:metroextractor][:setup][:basedir]

# fail if someone tries to pull something other than
#   a pbf data file
fail if node[:metroextractor][:planet][:file] !~ /\.pbf$/

remote_file "#{node[:metroextractor][:setup][:basedir]}/#{node[:metroextractor][:planet][:file]}.md5" do
  action    :create
  backup    false
  source    "#{node[:metroextractor][:planet][:url]}.md5"
  mode      0644
  notifies  :create, "remote_file[#{node[:metroextractor][:setup][:basedir]}/#{node[:metroextractor][:planet][:file]}]", :immediately
  notifies  :run,    'ruby_block[verify md5]',                                                                          :immediately
end

remote_file "#{node[:metroextractor][:setup][:basedir]}/#{node[:metroextractor][:planet][:file]}" do
  action  :nothing
  backup  false
  source  node[:metroextractor][:planet][:url]
  mode    0644
end

ruby_block 'verify md5' do
  action :nothing

  block do
    require 'digest'

    planet_md5  = Digest::MD5.file("#{node[:metroextractor][:setup][:basedir]}/#{node[:metroextractor][:planet][:file]}").hexdigest
    md5         = File.read("#{node[:metroextractor][:setup][:basedir]}/#{node[:metroextractor][:planet][:file]}.md5").split(' ').first

    if planet_md5 != md5
      Chef::Log.info('Failure: the md5 of the planet we downloaded does not appear to be correct. Aborting.')
      abort
    end
  end
end
