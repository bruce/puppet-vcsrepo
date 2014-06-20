vcsrepo { "/tmp/vcstest-p4-create_client":
  ensure    => absent,
  provider  => p4, 
  p4client  => "puppet-test001"
}