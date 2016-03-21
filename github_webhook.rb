require 'sinatra'
require 'json'
require 'open3'
require 'concurrent'

class ShellRunner
  include Concurrent::Async

  def mvn_build
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
      p ""
      p ""
    end
  end
end


configure do
  set :bind, '0.0.0.0'
  set :port, 9292
  File.open('sinatra.pid', 'w') {|f| f.write Process.pid }
end

get '/' do
  'wlen'
end

post '/payload' do
  request.body.rewind
  payload = JSON.parse request.body.read
  if request.env['HTTP_X_GITHUB_EVENT'] == 'push'
    ShellRunner.new.async.mvn_build if payload['ref'] == 'refs/heads/master'
  end
end
