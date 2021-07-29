require_relative './../spec_helper'

RSpec.describe Kerbi::Utils::Utils do

  subject { Kerbi::Utils::Utils }

  describe ".str_assign_to_h" do
    it "returns the right hash" do
      result = subject.str_assign_to_h("foo.bar=baz")
      expect(result).to eq({foo: {bar: 'baz'}})
    end
  end

  describe ".flatten_hash" do
    context 'with an already flat hash' do
      it 'returns the same hash' do
        actual = subject.flatten_hash({foo: 'bar'})
        expect(actual).to eq({foo: 'bar'})
      end
    end

    context 'with a deep hash' do
      it 'returns a flat hash with deep keys' do
        actual = subject.flatten_hash({foo: { bar: 'baz' }})
        expect(actual).to eq({'foo.bar': 'baz'})
      end
    end
  end
end