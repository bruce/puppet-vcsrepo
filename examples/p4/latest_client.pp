vcsrepo { "/tmp/vcstest-p4-create_client":
  ensure    => latest,
  provider  => p4, 
  p4client  => "puppet-test001",
  source    => "//depot/..."
}