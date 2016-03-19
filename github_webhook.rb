require 'sinatra'
require 'json'
require 'pry'
require 'open3'

configure do
  set :bind, '0.0.0.0'
  set :port, 9292
end

get '/' do
  'wlen'
end

post '/payload' do
  request.body.rewind
  payload = JSON.parse request.body.read
  if request.env['HTTP_X_GITHUB_EVENT'] == 'push'
    binding.pry
    mvn_build if payload['ref'] == 'refs/heads/master'
  end
end

def mvn_build
  # project = "docker-controller"
  project = "palinuridae"
  path = "/opt/deploy/#{project}"
  # git pull
  cmds = %Q{
    git remote update -p
    git checkout -f origin/master
    git submodule update --init
    mvn clean install
  }
  cmds.lines.map(&:strip).delete_if(&:empty?).each do |cmd|
    p "RUN: >>#{cmd}<<"
    oe, ts = Open3.capture2e cmd,chdir: path
    p "STATUS: #{ts.exitstatus}"
    p "===============stdout_and_stderr============"
    print oe
    p
    p
  end
end
