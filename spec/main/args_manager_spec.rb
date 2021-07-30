require_relative './../spec_helper'

RSpec.describe Kerbi::ArgsManager do

  subject { Kerbi::ArgsManager.new }

  describe "#get_kmd_arg_str" do
    it "returns the right expression" do
      ARGV.replace(%w[--context foo])
      result = subject.get_kmd_arg_str
      puts "result #{result}"
      expect(result).to eq("--context foo")
    end
  end

  describe '#get_run_env' do
    context 'without CLI args or env' do
      it "returns 'development'" do
        expect(subject.get_run_env).to eq('development')
      end
    end

    context 'with only a CLI arg' do
      it 'returns the CLI value' do
        ARGV.replace %w[-e foo]
        expect(subject.get_run_env).to eq('foo')
      end
    end

    context 'with an env only' do
      it 'returns the env value' do
        ENV['KERBI_ENV'] = 'foo'
        expect(subject.get_run_env).to eq('foo')
      end
    end

    context 'with env and CLI args' do
      it 'gives precedence to the cli arg' do
        ENV['KERBI_ENV'] = 'foo'
        ARGV.replace %w[-e bar]
        expect(subject.get_run_env).to eq('bar')
      end
    end
  end


end