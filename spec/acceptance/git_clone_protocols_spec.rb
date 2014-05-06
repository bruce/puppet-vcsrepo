require 'spec_helper_acceptance'

hosts.each do |host|

  describe 'clones a repo with git' do
    tmpdir =  host.tmpdir('vcsrepo')

    before(:all) do
      # {{{ setup
      on(host,apply_manifest("user{'testuser': ensure => present, }"))
      on(host,apply_manifest("user{'vagrant': ensure => present, }"))
      # install git
      install_package(host, 'git')
      install_package(host, 'git-daemon')
      # create ssh keys
      host.execute('mkdir -p /home/testuser/.ssh')
      host.execute('ssh-keygen -q -t rsa -f /home/testuser/.ssh/id_rsa -N ""')

      # copy public key to authorized_keys
      host.execute('cat /home/testuser/.ssh/id_rsa.pub > /home/testuser/.ssh/authorized_keys')
      host.execute('echo -e "Host localhost\n\tStrictHostKeyChecking no\n" > /home/testuser/.ssh/config')
      host.execute('chown -R testuser:testuser /home/testuser/.ssh')

      # create git repo
      my_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
      scp_to(host, "#{my_root}/acceptance/files/create_git_repo.sh", tmpdir)
      host.execute("cd #{tmpdir} && ./create_git_repo.sh")

      # copy ssl keys
      scp_to(host, "#{my_root}/acceptance/files/server.crt", tmpdir)
      scp_to(host, "#{my_root}/acceptance/files/server.key", tmpdir)

      host.execute("nohup git daemon  --detach --base-path=/#{tmpdir}")
      # }}}
    end

    after(:all) do
      # {{{ teardown
      on(host,apply_manifest("user{'testuser': ensure => absent,}"))
      # }}}
    end


    #---------------  TESTS ----------------------#

    context 'using local protocol (file URL)' do
      before(:all) do
        on(host,apply_manifest("file {'#{tmpdir}/testrepo': ensure => directory, purge => true, recurse => true, recurselimit => 1, force => true; }"))
      end

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

    context 'using git protocol' do
      before(:all) do
        on(host,apply_manifest("file {'#{tmpdir}/testrepo': ensure => directory, purge => true, recurse => true, recurselimit => 1, force => true; }"))
      end

      it 'should have HEAD pointing to master' do
        pp = <<-EOS
        vcsrepo { "#{tmpdir}/testrepo":
          ensure => present,
          provider => git,
          source => "git://#{host}/testrepo.git",
        }
        EOS

        # Run it twice and test for idempotency
        apply_manifest(pp, :catch_failures => true)
        apply_manifest(pp, :catch_changes => true)
      end
      describe file("#{tmpdir}/testrepo/.git/HEAD") do
        it { should contain 'ref: refs/heads/master' }
      end

    end

  end
end
