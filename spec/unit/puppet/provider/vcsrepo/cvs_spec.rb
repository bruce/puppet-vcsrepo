require 'spec_helper'

describe Puppet::Type.type(:vcsrepo).provider(:cvs) do

  let(:resource) { Puppet::Type.type(:vcsrepo).new({
    :name     => 'test',
    :ensure   => :present,
    :provider => :cvs,
    :revision => '2634',
    :source   => ':pserver:anonymous@cvs.sv.gnu.org:/sources/cvs/',
    :path     => '/tmp/test',
  })}

  let(:provider) { resource.provider }

  before :each do
    Puppet::Util.stubs(:which).with('cvs').returns('/usr/bin/cvs')
  end

  describe 'creating' do
    context "with a source" do
      it "should execute 'cvs checkout'" do
        resource[:source] = ':ext:source@example.com:/foo/bar'
        resource[:revision] = 'an-unimportant-value'
        expects_chdir('/tmp')
        Puppet::Util::Execution.expects(:execute).with([:cvs, '-d', resource.value(:source), 'checkout', '-r', 'an-unimportant-value', '-d', 'test', '.'], :custom_environment => {}, :combine => true, :failonfail => true)
        provider.create
      end

      it "should execute 'cvs checkout' as user 'muppet'" do
        resource[:source] = ':ext:source@example.com:/foo/bar'
        resource[:revision] = 'an-unimportant-value'
        resource[:user] = 'muppet'
        expects_chdir('/tmp')
        Puppet::Util::Execution.expects(:execute).with([:cvs, '-d', resource.value(:source), 'checkout', '-r', 'an-unimportant-value', '-d', 'test', '.'], :uid => 'muppet', :custom_environment => {}, :combine => true, :failonfail => true)
        provider.create
      end

      it "should just execute 'cvs checkout' without a revision" do
        resource[:source] = ':ext:source@example.com:/foo/bar'
        resource.delete(:revision)
        Puppet::Util::Execution.expects(:execute).with([:cvs, '-d', resource.value(:source), 'checkout', '-d', File.basename(resource.value(:path)), '.'], :custom_environment => {}, :combine => true, :failonfail => true)
        provider.create
      end

      context "with a compression" do
        it "should just execute 'cvs checkout' without a revision" do
          resource[:source] = ':ext:source@example.com:/foo/bar'
          resource[:compression] = '3'
          resource.delete(:revision)
          Puppet::Util::Execution.expects(:execute).with([:cvs, '-d', resource.value(:source), '-z', '3', 'checkout', '-d', File.basename(resource.value(:path)), '.'], :custom_environment => {}, :combine => true, :failonfail => true)
          provider.create
        end
      end
    end

    context "when a source is not given" do
      it "should execute 'cvs init'" do
        resource.delete(:source)
        Puppet::Util::Execution.expects(:execute).with([:cvs, '-d', resource.value(:path), 'init'], :custom_environment => {}, :combine => true, :failonfail => true)
        provider.create
      end
    end
  end

  describe 'destroying' do
    it "it should remove the directory" do
      provider.destroy
    end
  end

  describe "checking existence" do
    context "with a source value" do
      it "should run 'cvs status'" do
        resource[:source] = ':ext:source@example.com:/foo/bar'
        File.expects(:directory?).with(File.join(resource.value(:path), 'CVS')).returns(true)
        expects_chdir
        Puppet::Util::Execution.expects(:execute).with([:cvs, '-nqd', resource.value(:path), 'status', '-l'], :custom_environment => {}, :combine => true, :failonfail => true)
        provider.exists?
      end
    end

    context "without a source value" do
      it "should check for the CVSROOT directory and config file" do
        resource.delete(:source)
        File.expects(:directory?).with(File.join(resource.value(:path), 'CVSROOT')).returns(true)
        File.expects(:exists?).with(File.join(resource.value(:path), 'CVSROOT', 'config,v')).returns(true)
        provider.exists?
      end
    end
  end

  describe "checking the revision property" do
    before do
      @tag_file = File.join(resource.value(:path), 'CVS', 'Tag')
    end

    context "when CVS/Tag exists" do
      before do
        @tag = 'TAG'
        File.expects(:exist?).with(@tag_file).returns(true)
      end
      it "should read CVS/Tag" do
        File.expects(:read).with(@tag_file).returns("T#{@tag}")
        expect(provider.revision).to eq(@tag)
      end
    end

    context "when CVS/Tag does not exist" do
      before do
        File.expects(:exist?).with(@tag_file).returns(false)
      end
      it "assumes HEAD" do
        expect(provider.revision).to eq('HEAD')
      end
    end
  end

  describe "when setting the revision property" do
    before do
      @tag = 'SOMETAG'
    end

    it "should use 'cvs update -dr'" do
      expects_chdir
      Puppet::Util::Execution.expects(:execute).with([:cvs, 'update', '-dr', @tag, '.'], :custom_environment => {}, :combine => true, :failonfail => true)
      provider.revision = @tag
    end
  end

  describe "checking the source property" do
    it "should read the contents of file 'CVS/Root'" do
      File.expects(:read).with(File.join(resource.value(:path), 'CVS', 'Root')).
        returns(':pserver:anonymous@cvs.sv.gnu.org:/sources/cvs')
      expect(provider.source).to eq(resource.value(:source))
    end
  end
  describe "setting the source property" do
    it "should call 'create'" do
      provider.expects(:create)
      provider.source = resource.value(:source)
    end
  end

  describe "checking the module property" do
    before do
      resource[:module] = 'ccvs'
    end
    it "should read the contents of file 'CVS/Repository'" do
      File.expects(:read).with(File.join(resource.value(:path), 'CVS', 'Repository')).
        returns('ccvs')
      expect(provider.module).to eq(resource.value(:module))
    end
  end
  describe "setting the module property" do
    it "should call 'create'" do
      provider.expects(:create)
      provider.module = resource.value(:module)
    end
  end

end
