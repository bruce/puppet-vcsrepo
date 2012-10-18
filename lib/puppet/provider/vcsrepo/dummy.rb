require File.join(File.dirname(__FILE__), '..', 'vcsrepo')

Puppet::Type.type(:vcsrepo).provide(:dummy, :parent => Puppet::Provider::Vcsrepo) do
  desc "Dummy default provider"

  defaultfor :vcsrepo => :dummy
end
