require 'spec_helper_acceptance'

hosts.each do |host|

describe 'clones a repo with git' do
  tmpdir = host.tmpdir('vcsrepo')
  before(:all) do
    pp = <<-EOS
    user { 'testuser':
      ensure => absent,
      managehome => true,
    }
    EOS
    on(host,apply_manifest(pp, :catch_failures => true))
    on(host,apply_manifest("file {'#{tmpdir}': ensure => absent}", :catch_failures => true))
    # {{{ setup
    # install git
    install_package(host, 'git')

    # create git repo
    my_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    #shell("mkdir -p #{tmpdir}") # win test
    scp_to(host, "#{my_root}/acceptance/files/create_git_repo.sh", tmpdir)
    host.execute("cd #{tmpdir} && ./create_git_repo.sh")

    # copy ssl keys
    scp_to(host, "#{my_root}/acceptance/files/server.crt", tmpdir)
    scp_to(host, "#{my_root}/acceptance/files/server.key", tmpdir)

    # hack for non-vagrant deploys (deleteme)
    on(host,apply_manifest("user{'vagrant': ensure => present, }"))

    # create user
    pp = <<-EOS
    user { 'testuser':
      ensure => present,
      managehome => true,
    }
    EOS
    on(host,apply_manifest(pp, :catch_failures => true))

    # create ssh keys
    host.execute('mkdir -p /home/testuser/.ssh')
    host.execute('ssh-keygen -q -t rsa -f /home/testuser/.ssh/id_rsa -N ""')

    # copy public key to authorized_keys
    host.execute('cat /home/testuser/.ssh/id_rsa.pub > /home/testuser/.ssh/authorized_keys')
    host.execute('echo -e "Host localhost\n\tStrictHostKeyChecking no\n" > /home/testuser/.ssh/config')
    host.execute('chown -R testuser:testuser /home/testuser/.ssh')
    # }}}
  end

  after(:all) do
    # {{{ teardown
    pp = <<-EOS
    user { 'testuser':
      ensure => absent,
      managehome => true,
    }
    EOS
    on(host,apply_manifest(pp, :catch_failures => true))
    on(host,apply_manifest("file {'#{tmpdir}': ensure => absent}", :catch_failures => true))
    # }}}
  end

  after(:each) do
    on(host,apply_manifest("file {'#{tmpdir}/testrepo': ensure => absent}", :catch_failures => true))
  end

  #---------------  TESTS ----------------------#

  context 'using local protocol (file URL)' do
    it 'should have HEAD pointing to master' do
      pp = <<-EOS
      vcsrepo { "#{tmpdir}/testrepo":
        ensure => present,
        provider => git,
        source => "file://#{tmpdir}/testrepo.git",
      }
      EOS

      # Run it twice and test for idempotency
      on(host,apply_manifest(pp, :catch_failures => true))
      on(host,apply_manifest(pp, :catch_changes => true))
    end

    describe file("#{tmpdir}/testrepo/.git/HEAD") do
      it { should contain 'ref: refs/heads/master' }
    end

  end

end
end
