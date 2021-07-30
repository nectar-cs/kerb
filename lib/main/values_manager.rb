require_relative './mixer_helper'
require_relative './../utils/utils'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/object/blank'
require 'yaml'
require 'json'
require 'erb'

module Kerbi
  class ValuesManager
    class << self
      def values_paths(fname)
        [
          fname,
          "values/#{fname}",
          "values/#{fname}.yaml.erb",
          "values/#{fname}.yaml",
          "values/#{fname}.json",
          "#{fname}.yaml.erb",
          "#{fname}.yaml",
          "#{fname}.json",
        ]
      end

      def all_values_paths
        [
          *values_paths('values'),
          *values_paths(args_manager.get_run_env),
          *args_manager.get_fnames
        ].compact
      end

      def safely_read_values_file(name)
        candidate_fnames = values_paths(name)
        decider = -> (fname) { File.exists?(fname) }
        if (fname = candidate_fnames.find(&decider))
          read_values_file(fname)
        end
      end

      #noinspection RubyResolve
      def read_values_file(fname)
        file_cont = File.read(fname) rescue nil
        return {} unless file_cont
        load_json(file_cont) || load_yaml(file_cont) || {}
      end

      def load_yaml(file_cont)
        interpolated = Wrapper.new.interpolate(file_cont)
        YAML.load(interpolated).deep_symbolize_keys# rescue nil
      end

      def load_json(file_cont)
        JSON.parse(file_cont.deep_symbolize_keys) rescue nil
      end

      def read_inline_assignments
        args_manager.get_inlines.inject({}) do |whole, str_assignment|
          hash_assignment = Utils::Utils.str_assign_to_h(str_assignment)
          whole.deep_merge(hash_assignment)
        end
      end

      def read_release_name
        if ARGV[0] == 'template'
          ARGV[1]
        elsif ARGV[0..1] == %w[state template]
          ARGV[2]
        end
      end

      def load
        result = all_values_paths.inject({}) do |whole, file_name|
          whole.
            deep_merge(read_values_file(file_name)).
            deep_merge(read_inline_assignments)
        end
        $release_name = read_release_name
        result.deep_symbolize_keys
      end
    end
  end
end

class Wrapper
  include Kerbi::MixerHelper

  def interpolate(file_cont)
    ERB.new(file_cont).result(binding)
  end
end
