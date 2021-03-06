#!/usr/bin/env rspec

require 'spec_helper'

describe Puppet::Type.type(:rpmkey).provider(:rpm) do

  before :each do
    Puppet::Type.type(:rpmkey).stubs(:defaultprovider).returns described_class
  end

  describe ".instances" do
    it "should have an instances method" do
      described_class.should respond_to :instances
    end

    it "should get installed rpm keys by running rpm -q" do
      described_class.expects(:rpm).with('-q', 'gpg-pubkey').returns File.read(my_fixture('rpm_q'))
      described_class.instances.map(&:name).should == [
        'DB42A60E',
        '4F2A6FD2',
        '23A254D4'
      ]
    end

    it "should return an empty list if no key is installed" do
      described_class.expects(:rpm).with('-q', 'gpg-pubkey').raises Puppet::ExecutionFailure, 'package gpg-pubkey is not installed'
      described_class.instances.should be_empty
    end
  end

  describe "#exists?" do
    it "should return true if the resource is present" do
      provider = described_class.new(:name => 'DB42A60E', :ensure => :present)
      provider.should be_exists
    end

    it "should return false if the resource is absent" do
      provider = described_class.new(:name => 'DB42A60E', :ensure => :absent)
      provider.should_not be_exists
    end
  end

  describe "#create" do
    it "should import the key" do
      provider = described_class.new(Puppet::Type.type(:rpmkey).new(
        :name   => 'DB42A60E',
        :source => 'http://example.com/foo',
        :ensure => :present
      ))
      provider.expects(:rpm).with('--import', 'http://example.com/foo')
      provider.create
    end

    it "should raise an error if no source is specified" do
      provider = described_class.new(Puppet::Type.type(:rpmkey).new(
        :name   => 'DB42A60E',
        :ensure => :present
      ))
      expect { provider.create }.to raise_error(Puppet::Error, /Cannot add key without a source/)
    end
  end

  describe "#destroy" do
    it "should remove the key" do
      provider = described_class.new(Puppet::Type.type(:rpmkey).new(
        :name   => 'DB42A60E',
        :source => 'http://example.com/foo',
        :ensure => :absent
      ))
      provider.expects(:rpm).with('-e', '--allmatches', 'gpg-pubkey-db42a60e')
      provider.destroy
    end

    it "should not complain about a missing source" do
      provider = described_class.new(Puppet::Type.type(:rpmkey).new(
        :name   => 'DB42A60E',
        :ensure => :absent
      ))
      provider.expects(:rpm).with('-e', '--allmatches', 'gpg-pubkey-db42a60e')
      expect { provider.destroy }.to_not raise_error
    end
  end
end
