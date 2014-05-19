test_name 'C3473 - create bare repo specifying revision'

# Globals
repo_name = 'testrepo_bare.git'

hosts.each do |host|
  tmpdir = host.tmpdir('vcsrepo')
  step 'setup' do
    install_package(host, 'git')
  end

  teardown do
    on(host, "rm -fr #{tmpdir}")
  end

  step 'create bare repo specifying revision using puppet' do
    pp = <<-EOS
    vcsrepo { "#{tmpdir}/#{repo_name}":
      ensure => bare,
      revision => master,
      provider => git,
    }
    EOS

    apply_manifest_on(host, pp)
  end

  step 'verify repo does not contain .git directory' do
    on(host, "ls -al #{tmpdir}/#{repo_name}") do |res|
      fail_test "found .git for #{repo_name}" if res.stdout.include? ".git"
    end
  end

end
