require 'spec_helper'

describe Puppet::Type.type(:vcsrepo).provider(:bzr) do

  let(:resource) { Puppet::Type.type(:vcsrepo).new({
    :name     => 'test',
    :ensure   => :present,
    :provider => :bzr,
    :revision => '2634',
    :source   => 'lp:do',
    :path     => '/tmp/test',
  })}

  let(:provider) { resource.provider }

  before :each do
    Puppet::Util.stubs(:which).with('bzr').returns('/usr/bin/bzr')
  end

  describe 'creating' do
    context 'with defaults' do
      it "should execute 'bzr clone -r' with the revision" do
        provider.expects(:bzr).with('branch', '-r', resource.value(:revision), resource.value(:source), resource.value(:path))
        provider.create
      end
    end

    context 'without revision' do
      it "should just execute 'bzr clone' without a revision" do
        resource.delete(:revision)
        provider.expects(:bzr).with('branch', resource.value(:source), resource.value(:path))
        provider.create
      end
    end

    context 'without source' do
      it "should execute 'bzr init'" do
        resource.delete(:source)
        provider.expects(:bzr).with('init', resource.value(:path))
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
    it "should execute bzr status on the path" do
      File.expects(:directory?).with(resource.value(:path)).returns(true)
      provider.expects(:bzr).with('status', resource[:path])
      provider.exists?
    end
  end

  describe "checking the revision property" do
    before do
      expects_chdir
      provider.expects(:bzr).with('version-info').returns(File.read(fixtures('bzr_version_info.txt')))
      @current_revid = 'menesis@pov.lt-20100309191856-4wmfqzc803fj300x'
    end

    context "when given a non-revid as the resource revision" do
      context "when its revid is not different than the current revid" do
        it "should return the ref" do
          resource[:revision] = '2634'
          provider.expects(:bzr).with('revision-info', '2634').returns("2634 menesis@pov.lt-20100309191856-4wmfqzc803fj300x\n")
          expect(provider.revision).to eq(resource.value(:revision))
        end
      end
      context "when its revid is different than the current revid" do
        it "should return the current revid" do
          resource[:revision] = '2636'
          provider.expects(:bzr).with('revision-info', resource.value(:revision)).returns("2635 foo\n")
          expect(provider.revision).to eq(@current_revid)
        end
      end
    end

    context "when given a revid as the resource revision" do
      context "when it is the same as the current revid" do
        it "should return it" do
          resource[:revision] = 'menesis@pov.lt-20100309191856-4wmfqzc803fj300x'
          provider.expects(:bzr).with('revision-info', resource.value(:revision)).returns("1234 #{resource.value(:revision)}\n")
          expect(provider.revision).to eq(resource.value(:revision))
        end
      end
      context "when it is not the same as the current revid" do
        it "should return the current revid" do
          resource[:revision] = 'menesis@pov.lt-20100309191856-4wmfqzc803fj300y'
          provider.expects(:bzr).with('revision-info', resource.value(:revision)).returns("2636 foo\n")
          expect(provider.revision).to eq(@current_revid)
        end
      end

    end
  end

  describe "setting the revision property" do
    it "should use 'bzr update -r' with the revision" do
      Dir.expects(:chdir).with('/tmp/test').at_least_once.yields
      provider.expects(:bzr).with('update', '-r', 'somerev')
      provider.revision = 'somerev'
    end
  end

  describe "checking the source property" do
    it "should use 'bzr info'" do
      expects_chdir
      resource[:source] = 'http://bazaar.launchpad.net/~bzr-pqm/bzr/bzr.dev/'
      provider.expects(:bzr).with('info').returns(' parent branch: http://bazaar.launchpad.net/~bzr-pqm/bzr/bzr.dev/')
      expect(provider.source).to eq(resource.value(:source))
    end
  end
  describe "setting the source property" do
    it "should call 'create'" do
      resource[:source] = 'http://bazaar.launchpad.net/~bzr-pqm/bzr/bzr.dev/'
      provider.expects(:create)
      provider.source = resource.value(:source)
    end
  end
end
