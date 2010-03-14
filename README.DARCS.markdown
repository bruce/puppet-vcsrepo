Using vcsrepo with Darcs
========================

To create a blank repository
----------------------------

Define a `vcsrepo` without a `source`, `tag`, or `patch`:

    vcsrepo { "/path/to/repo":
      ensure   => present,
      provider => darcs
    }

To get a repository
-------------------

Provide a `source`:

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => darcs,
        source   => "http://darcs.example.com/myrepo"
    }

To get patch files only as needed, set `lazy`:

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => darcs,
        source   => "http://darcs.example.com/myrepo",
        lazy     => true
    }

To set the local repository to a specific tag, use `revision`:

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => darcs,
        source   => "http://darcs.example.com/myrepo",
        lazy     => true,
        revision => '1.1.2'
    }

Note that `revision` cannot be a patch pattern (as used with
`--to-match` and `--to-patch`), it must be a valid tag.
