require 'rspec'
require 'krypt-core'
require 'openssl'
require_relative './resources'

describe Krypt::ASN1::Null do 
  include Krypt::ASN1::Resources

  let(:mod) { Krypt::ASN1 }
  let(:klass) { mod::Null }
  let(:decoder) { mod }

  # For test against OpenSSL
  #
  #let(:mod) { OpenSSL::ASN1 }
  #
  # OpenSSL stub for signature mismatch
  class OpenSSL::ASN1::Null
    class << self
      alias old_new new
      def new(*args)
        if args.size == 1
          # nothing to do
        elsif args.size > 0
          args = [args[0], args[1], :IMPLICIT, args[2]]
        else
          args = [nil]
        end
        old_new(*args)
      end
    end
  end

  describe '#new' do
    context 'constructs without value' do
      subject { klass.new }

      its(:tag) { should == Krypt::ASN1::NULL }
      its(:tag_class) { should == :UNIVERSAL }
      its(:value) { should == nil }
      its(:infinite_length) { should == false }
    end

    context 'gets value for construct' do
      subject { klass.new(nil) }

      its(:tag) { should == Krypt::ASN1::NULL }
      its(:tag_class) { should == :UNIVERSAL }
      its(:value) { should == nil }
      its(:infinite_length) { should == false }
    end

    it "only accepts nil as the value argument" do
      -> { klass.new(1) }.should raise_error(ArgumentError)
    end

    context 'gets explicit tag number as the 2nd argument' do
      subject { klass.new(nil, tag, :PRIVATE) }

      context 'accepts default tag' do
        let(:tag) { Krypt::ASN1::NULL }
        its(:tag) { should == tag }
      end

      context 'accepts custom tag' do
        let(:tag) { 14 }
        its(:tag) { should == tag }
      end
    end

    context 'gets tag class symbol as the 3rd argument' do
      subject { klass.new(nil, Krypt::ASN1::NULL, tag_class) }

      context 'accepts :UNIVERSAL' do
        let(:tag_class) { :UNIVERSAL }
        its(:tag_class) { should == tag_class }
      end

      context 'accepts :APPLICATION' do
        let(:tag_class) { :APPLICATION }
        its(:tag_class) { should == tag_class }
      end

      context 'accepts :CONTEXT_SPECIFIC' do
        let(:tag_class) { :CONTEXT_SPECIFIC }
        its(:tag_class) { should == tag_class }
      end

      context 'accepts :PRIVATE' do
        let(:tag_class) { :PRIVATE }
        its(:tag_class) { should == tag_class }
      end
    end

    context 'when the 2nd argument is given but 3rd argument is omitted' do
      subject { klass.new(nil, Krypt::ASN1::NULL) }
      its(:tag_class) { should == :CONTEXT_SPECIFIC }
    end
  end

  describe 'accessors' do
    describe '#value' do
      subject { o = klass.new(nil); o.value = value; o }

      context 'accepts nil' do
        let(:value) { nil }
        its(:value) { should == nil }
      end

      it "only accepts nil as the value argument" do
        -> { klass.new.value = 1 }.should raise_error(ArgumentError)
      end
    end

    describe '#tag' do
      subject { o = klass.new(nil); o.tag = tag; o }

      context 'accepts default tag' do
        let(:tag) { Krypt::ASN1::NULL }
        its(:tag) { should == tag }
      end

      context 'accepts custom tag' do
        let(:tag) { 14 }
        its(:tag) { should == tag }
      end
    end

    describe '#tag_class' do
      subject { o = klass.new(nil); o.tag_class = tag_class; o }

      context 'accepts :UNIVERSAL' do
        let(:tag_class) { :UNIVERSAL }
        its(:tag_class) { should == tag_class }
      end

      context 'accepts :APPLICATION' do
        let(:tag_class) { :APPLICATION }
        its(:tag_class) { should == tag_class }
      end

      context 'accepts :CONTEXT_SPECIFIC' do
        let(:tag_class) { :CONTEXT_SPECIFIC }
        its(:tag_class) { should == tag_class }
      end

      context 'accepts :PRIVATE' do
        let(:tag_class) { :PRIVATE }
        its(:tag_class) { should == tag_class }
      end
    end
  end

  describe '#to_der' do
    context 'encodes a given value' do
      subject { klass.new.to_der }
      it { should == "\x05\x00" }
    end

    context 'encodes tag number' do
      subject { klass.new(nil, tag, :PRIVATE).to_der }

      context 'default tag' do
        let(:tag) { Krypt::ASN1::NULL }
        it { should == "\xC5\x00" }
      end

      context 'custom tag' do
        let(:tag) { 14 }
        it { should == "\xCE\x00" }
      end

      context 'nil' do
        let(:tag) { nil }
        it { -> { subject }.should raise_error ArgumentError }
      end
    end

    context 'encodes tag class' do
      subject { klass.new(nil, Krypt::ASN1::NULL, tag_class).to_der }

      context 'UNIVERSAL' do
        let(:tag_class) { :UNIVERSAL }
        it { should == "\x05\x00" }
      end

      context 'APPLICATION' do
        let(:tag_class) { :APPLICATION }
        it { should == "\x45\x00" }
      end

      context 'CONTEXT_SPECIFIC' do
        let(:tag_class) { :CONTEXT_SPECIFIC }
        it { should == "\x85\x00" }
      end

      context 'PRIVATE' do
        let(:tag_class) { :PRIVATE }
        it { should == "\xC5\x00" }
      end

      context nil do
        let(:tag_class) { nil }
        it { -> { subject }.should raise_error ArgumentError } # TODO: ossl does not check nil
      end

      context :no_such_class do
        let(:tag_class) { :no_such_class }
        it { -> { subject }.should raise_error ArgumentError }
      end
    end

    context 'encodes values set via accessors' do
      subject {
        o = klass.new(nil)
        o.tag = tag if defined? tag
        o.value = value if defined? value
        o.tag_class = tag_class if defined? tag_class
        o.to_der
      }

      context 'value: 72' do
        let(:value) { nil }
        it { should == "\x05\x00" }
      end

      context 'custom tag' do
        let(:value) { "" }
        let(:tag) { 14 } # TODO: setting the tag to 14 will change the codec to default internally
        let(:tag_class) { :PRIVATE }
        it { should == "\xCE\x00" }
      end

      context 'tag_class' do
        let(:value) { nil }
        let(:tag_class) { :APPLICATION }
        it { should == "\x45\x00" }
      end
    end
  end

  describe '#encode_to' do
    context 'encodes to an IO' do
      subject { klass.new(value).encode_to(io); io }

      context "StringIO" do
        let(:value) { nil }
        let(:io) { string_io_object }
        its(:written_bytes) { should == "\x05\x00" }
      end

      context "Object responds to :write" do
        let(:value) { nil }
        let(:io) { writable_object }
        its(:written_bytes) { should == "\x05\x00" }
      end

      context "raise IO error transparently" do
        let(:value) { nil }
        let(:io) { io_error_object }
        it { -> { subject }.should raise_error EOFError }
      end
    end

    it 'returns self' do
      obj = klass.new(nil)
      obj.encode_to(string_io_object).should == obj
    end
  end

  describe 'extracted from ASN1.decode' do
    subject { decoder.decode(der) }

    context 'extracted value' do
      let(:der) { "\x05\x00" }
      its(:class) { should == klass }
      its(:tag) { should == Krypt::ASN1::NULL }
      its(:value) { should == nil }
    end

    context 'extracted tag class' do
      context 'UNIVERSAL' do
        let(:der) { "\x05\x00" }
        its(:tag_class) { should == :UNIVERSAL }
      end

      context 'APPLICATION' do
        let(:der) { "\x45\x00" }
        its(:tag_class) { should == :APPLICATION }
      end

      context 'CONTEXT_SPECIFIC' do
        let(:der) { "\x85\x00" }
        its(:tag_class) { should == :CONTEXT_SPECIFIC }
      end

      context 'PRIVATE' do
        let(:der) { "\xC5\x00" }
        its(:tag_class) { should == :PRIVATE }
      end
    end
  end
end
