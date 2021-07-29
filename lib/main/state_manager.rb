require 'json'
require 'yaml'
require_relative './../utils/kubectl'

module Kerbi
  class StateManManager
    class << self

      def patch
        options = Utils::Utils.args2options(PARAM_SCHEMA)
        patch_values = extract_patch_values(options)
        config_map = get_configmap
        crt_values = get_configmap_values(config_map)
        merged_vars = crt_values.deep_merge(patch_values)
        new_body = { **config_map, data: { variables: JSON.dump(merged_vars) } }
        yaml_body = YAML.dump(new_body.deep_stringify_keys)
        Utils::Kubectl.apply_tmpfile(yaml_body, opts2ktl_args(options))
      end

      def extract_patch_values(options)
        values = {}
        if (fname = options[:file])
          values = YAML.load_file(fname).deep_symbolize_keys
        end
        if (inlines = options[:inlines])
          inlines.each do |assignment_str|
            assignment = Utils::Utils.str_assign_to_h(assignment_str)
            values.deep_merge!(assignment)
          end
        end
        values
      end

      def opts2ktl_args(options)
        TRANSLATION.inject([]) do |whole, part|
          option_key = part[:option]
          if !options[option_key].nil?
            whole + ["#{part[:arg]} #{options[option_key]}"]
          else
            whole
          end
        end.join(" ")
      end

      def get_configmap_values(configmap)
        JSON.parse(configmap[:data][:variables]).deep_symbolize_keys
      end

      def get_configmap
        options = Utils::Utils.args2options(PARAM_SCHEMA)
        kmd = "get cm state #{opts2ktl_args(options)}"
        Utils::Kubectl.jkmd(kmd, print_err: true) or raise("abort!")
      end


    end

    TRANSLATION = [
      { option: 'namespace', arg: "-n" },
      { option: 'context', arg: "--context" }
    ]

    PARAM_SCHEMA = [
      {
        key: 'file',
        interface: ["-f=", "--file", "Source file"]
      },
      {
        key: 'blacklist',
        interface: ["-bf", "--blacklist-file", "Variables to not commit"]
      },
      {
        key: 'inlines',
        interface: ["--set=", "Inline assignments"],
        many: true
      },
      {
        key: 'namespace',
        interface: ["-n=", "--namespace", "Kubernetes namespace"]
      },
      {
        key: 'context',
        interface: ["-c=", "--context", "Kubernetes context"]
      },
    ]
  end
end