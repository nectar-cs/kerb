require_relative './../spec_helper'

RSpec.describe Kerbi::ValuesManager do

  subject { Kerbi::ValuesManager }

  describe '.safely_read_values_file' do
    context 'when the file exists' do
      it 'returns the right hash' do
        path = tmp_file("foo: bar\nbaz: <%= 1 %>")
        output = subject.safely_read_values_file(path)
        expect(output).to eq({foo: 'bar', baz: 1})
      end
    end
  end

  describe ".read_release_name" do
    context 'without the arg' do
      context 'when the main cmd is not template' do
        it 'returns nil' do
          argue("not-template foo")
          expect(subject.read_release_name).to be_nil
        end
      end
      context "when template is the main command" do
        # it 'returns the word following template' do
        #   argue("template foo -an-arg")
        #   expect(subject.read_release_name).to eq("foo")
        # end

        it 'still parses args correctly' do
          argue("template foo --set bar=baz")
          expect = {bar: "baz"}
          expect(Kerbi::ValuesManager.load).to eq(expect)
        end
      end
    end
  end

  describe '.read_values_file' do
    describe 'interpolation' do
      it 'interpolates erb with primitives' do
        path = tmp_file("foo: bar\nbaz: <%= 1 %>")
        output = subject.read_values_file(path)
        expect(output).to eq({foo: 'bar', baz: 1})
      end

      it 'interpolates erb accessing Kerbi::MixerHelper' do
        path = tmp_file("foo: bar\nbaz: <%= b64enc('foobar') %>")
        output = subject.read_values_file(path)
        expect(output).to eq({foo: 'bar', baz: "Zm9vYmFy"})
      end
    end

    context 'when the file exists' do
      context 'with yaml' do
        it 'correctly loads the file' do
          path = tmp_file("foo: bar\nbaz: bar2")
          output = subject.read_values_file(path)
          expect(output).to eq({foo: 'bar', baz: 'bar2'})
        end
      end
      context 'with json' do
        it 'correctly loads the file' do
          path = tmp_file(JSON.dump({foo: 'bar', baz: 'bar2'}))
          output = subject.read_values_file(path)
          expect(output).to eq({foo: 'bar', baz: 'bar2'})
        end
      end
    end
    context 'when the file does not exist' do
      it 'returns an empty hash' do
        output = subject.read_values_file('/bad-path')
        expect(output).to eq({})
      end
    end
  end

  describe '.load' do
    describe "merging" do
      it 'merges correctly with nesting' do
        result = n_yaml_files(
          hashes: [
            { a: 1, b: { b: 1 } },
            { b: { b: 2, c: 3 } },
            { x: 'y1' }
          ],
          more_args: %W[--set x=y2]
        )
        expect(result).to eq(a: 1, b: { b: 2, c: 3 }, x: 'y2')
      end

      it 'merges correctly with arrays' do
        result = two_yaml_files({a: [1, 2] }, {a: [3] })
        expect(result).to eq({a: [3] })
      end

      it 'merges correctly with empty hashes' do
        result = n_yaml_files(
          hashes: [
            {},
            { a: 1, b: { b: 1 } },
            {},
            { b: { b: 2, c: 3 } },
            {},
          ]
        )
        expect(result).to eq({a: 1, b: { b: 2, c: 3 }})
      end

      it 'merges correctly with a release name' do
        argue("template foo-rel --set foo=bar")
        expect(Kerbi::ValuesManager.read_release_name).to eq('foo-rel')
        expect(Kerbi::ValuesManager.load).to eq({foo: "bar"})
      end
    end
  end
end