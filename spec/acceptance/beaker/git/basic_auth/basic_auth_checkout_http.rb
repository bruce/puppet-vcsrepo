test_name 'C3492 - checkout with basic auth (http protocol)'

# Globals
repo_name = 'testrepo_checkout'
user      = 'foo'
password  = 'bar'
http_server_script = 'basic_auth_http_daemon.rb'

hosts.each do |host|
  tmpdir = host.tmpdir('vcsrepo')
  step 'setup - create repo' do
    install_package(host, 'git')
    my_root = File.expand_path(File.join(File.dirname(__FILE__), '../../../..'))
    scp_to(host, "#{my_root}/acceptance/files/create_git_repo.sh", tmpdir)
    on(host, "cd #{tmpdir} && ./create_git_repo.sh")
  end

  step 'setup - start http server' do
    script =<<-EOF
    require 'webrick'

    authenticate = Proc.new do |req, res|
      WEBrick::HTTPAuth.basic_auth(req, res, '') do |user, password|
        user == '#{user}' && password == '#{password}'
      end
    end

    server = WEBrick::HTTPServer.new(
    :Port               => 8000,
    :DocumentRoot       => "#{tmpdir}",
    :DocumentRootOptions=> {:HandlerCallback => authenticate},
    )
    WEBrick::Daemon.start
    server.start
    EOF
    create_remote_file(host, "#{tmpdir}/#{http_server_script}", script)
    on(host, "ruby #{tmpdir}/#{http_server_script}")
  end

  teardown do
    on(host, "rm -fr #{tmpdir}")
    on(host, "ps ax | grep 'ruby #{tmpdir}/#{http_server_script}' | grep -v grep | awk '{print \"kill -9 \" $1}' | sh")
  end

  step 'checkout with puppet using basic auth' do
    pp = <<-EOS
    vcsrepo { "#{tmpdir}/#{repo_name}":
      ensure => present,
      source => "http://#{host}:8000/testrepo.git",
      provider => git,
      basic_auth_username => '#{user}',
      basic_auth_password => '#{password}',
    }
    EOS

    apply_manifest_on(host, pp)
    apply_manifest_on(host, pp)
  end

  step "verify checkout" do
    on(host, "ls #{tmpdir}/#{repo_name}/.git/") do |res|
      fail_test('checkout not found') unless res.stdout.include? "HEAD"
    end
  end

end
