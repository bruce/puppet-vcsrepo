require File.join(File.dirname(__FILE__), '..', 'vcsrepo')

Puppet::Type.type(:vcsrepo).provide(:darcs, :parent => Puppet::Provider::Vcsrepo) do
  desc "Supports Darcs repositories"

  commands   :darcs => 'darcs'
  defaultfor :darcs => :exists

  def create
    if !@resource.value(:source)
      initialize_repository(@resource.value(:path))
    else
      get_repository(@resource.value(:revision))
    end
  end

  def exists?
    File.directory?(File.join(@resource.value(:path), '_darcs'))
  end

  def destroy
    FileUtils.rm_rf(@resource.value(:path))
  end
  
  # def revision
  #   at_path do
  #     current = darcs('parents')[/^changeset:\s+(?:-?\d+):(\S+)/m, 1]
  #     desired = @resource.value(:revision)
  #     if current == desired
  #       current
  #     else
  #       mapped = darcs('tags')[/^#{Regexp.quote(desired)}\s+\d+:(\S+)/m, 1]
  #       if mapped
  #         # A tag, return that tag if it maps to the current nodeid
  #         if current == mapped
  #           desired
  #         else
  #           current
  #         end
  #       else
  #         # Use the current nodeid
  #         current
  #       end
  #     end
  #   end
  # end

  def revision=(desired)
    darcs('pull', '--repodir', @resource.value(:path), '--all', '--tags', desired)
  end

  private

  def initialize_repository(path)
    darcs('initialize', '--repodir', path)
  end

  def get_repository(revision)
    args = ['get', '--lazy']
    if revision
      args.push('--tag', revision)
    end
    args.push(@resource.value(:source),
              @resource.value(:path))
    darcs(*args)
  end

end
