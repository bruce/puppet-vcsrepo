Using vcsrepo with Perforce
===========================

To create an empty Workspace
----------------------------

Define a `vcsrepo` without a `source` or `revision`:

    vcsrepo { "/path/to/repo":
      ensure   => present,
      provider => p4
    }

If no `p4client` name is provided a workspace generated name is calculated based on the 
Digest of path.  For example:

    puppet-91bc00640c4e5a17787286acbe2c021c

Providing a `p4client` name will create/update the client workspace in Perforce.
 
    vcsrepo { "/path/to/repo":
      ensure   => present,
      provider => p4
      p4client   => "my_client_ws"
    }

To create/update and sync a Perforce workspace
----------------------------------------------

To sync a depot path to head (latest):

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => p4,
        source   => '//depot/branch/...'
    }

For a specific changelist, use `revision`:

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => p4,
        source   => '//depot/branch/...',
        revision => '2341'
    }

You can also set `revision` to a label:

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => p4,
        source   => '//depot/branch/...',
        revision => 'my_label'
    }

Check out as a user by setting `p4user`:

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => p4,
        source   => '//depot/branch/...',
        p4user   => 'user'
    }

You can set `p4port` to specify a Perforce server:

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => p4,
        source   => '//depot/branch/...',
        p4port   => 'ssl:perforce.com:1666'
    }

You can set `p4passwd` for authentication :

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => p4,
        source   => '//depot/branch/...',
        p4port   => 'ssl:perforce.com:1666'
    }

If `p4port`, `p4user`, `p4charset`, `p4passwd` or `p4client` are specified they will 
override the environment variabels P4PORT, P4USER, etc... If a P4CONFIG file is 
defined, the config file settings will take precedence.


More Examples
-------------

For examples you can run, see `examples/p4/`
