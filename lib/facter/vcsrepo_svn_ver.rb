Facter.add(:vcsrepo_svn_ver) do
  setcode do
    begin
      unless Facter.value(:operatingsystem) == 'Darwin' and not File.directory?(Facter::Core::Execution.execute('xcode-select -p'))
        version = Facter::Core::Execution.execute('svn --version --quiet')
        if Gem::Version.new(version) > Gem::Version.new('0.0.1')
          version
        else
          ''
        end
      else
        ''
      end
    rescue StandardError
      ''
    end
  end
end
