#! /usr/bin/env ruby
require 'spec_helper'

describe Puppet::Type.type(:vcsrepo) do

  before :each do
    Puppet::Type.type(:vcsrepo).stubs(:defaultprovider).returns(providerclass)
  end

  let(:providerclass) do
    described_class.provide(:fake_vcsrepo_provider) do
      attr_accessor :property_hash
      def create; end
      def destroy; end
      def exists?
        get(:ensure) != :absent
      end
      mk_resource_methods
    end
  end

  let(:provider) do
    providerclass.new(:name => 'fake-vcs')
  end

  let(:resource) do
    described_class.new(:name => '/repo',
                        :ensure => :present,
                        :provider => provider)
  end

  let(:ensureprop) do
    resource.property(:ensure)
  end

  properties = [ :ensure, :source ]

  properties.each do |property|
    it "should have a #{property} property" do
      expect(described_class.attrclass(property).ancestors).to be_include(Puppet::Property)
    end
  end

  parameters = [ :ensure ]

  parameters.each do |parameter|
    it "should have a #{parameter} parameter" do
      expect(described_class.attrclass(parameter).ancestors).to be_include(Puppet::Parameter)
    end
  end

  describe "munging of 'source' property" do
    it "should remove trailing /" do
      resource[:source] = ':pserver:anonymous@cvs.sv.gnu.org:/sources/cvs/'
      expect(resource[:source]).to eq(':pserver:anonymous@cvs.sv.gnu.org:/sources/cvs')
    end
  end

  describe 'default resource with required params' do
    it 'should have a valid name parameter' do
      expect(resource[:name]).to eq('/repo')
    end

    it 'should have ensure set to present' do
      expect(resource[:ensure]).to eq(:present)
    end

    it 'should have path set to /repo' do
      expect(resource[:path]).to eq('/repo')
    end

    defaults = {
      :owner => nil,
      :group => nil,
      :user => nil,
      :revision => nil,
    }

    defaults.each_pair do |param, value|
      it "should have #{param} parameter set to #{value}" do
        expect(resource[param]).to eq(value)
      end
    end
  end

  describe 'when changing the ensure' do
    it 'should be in sync if it is :absent and should be :absent' do
      ensureprop.should = :absent
      expect(ensureprop.safe_insync?(:absent)).to eq(true)
    end

    it 'should be in sync if it is :present and should be :present' do
      ensureprop.should = :present
      expect(ensureprop.safe_insync?(:present)).to eq(true)
    end

    it 'should be out of sync if it is :absent and should be :present' do
      ensureprop.should = :present
      expect(ensureprop.safe_insync?(:absent)).not_to eq(true)
    end

    it 'should be out of sync if it is :present and should be :absent' do
      ensureprop.should = :absent
      expect(ensureprop.safe_insync?(:present)).not_to eq(true)
    end
  end

  describe 'when running the type it should autorequire packages' do
    before :each do
      @catalog = Puppet::Resource::Catalog.new
      ['git', 'git-core', 'mercurial'].each do |pkg|
        @catalog.add_resource(Puppet::Type.type(:package).new(:name => pkg))
      end
    end

    it 'should require package packages' do
      @resource = described_class.new(:name => '/foo', :provider => provider)
      @catalog.add_resource(@resource)
      req = @resource.autorequire
      expect(req.size).to eq(3)
    end
  end
end
