require 'json'
require 'yaml'
require_relative './../utils/kubectl'

module Kerbi
  class StateManManager

    attr_accessor :options

    def initialize
      self.options = Utils::Utils.args2options(PARAM_SCHEMA)
    end

    def patch
      puts "OPTIONS"
      puts self.options
      create_configmap_if_missing
      patch_values = extract_patch_values
      config_map = get_configmap
      crt_values = get_configmap_values(config_map)
      merged_vars = crt_values.deep_merge(patch_values)
      new_body = { **config_map, data: { variables: JSON.dump(merged_vars) } }
      yaml_body = YAML.dump(new_body.deep_stringify_keys)
      Utils::Kubectl.apply_tmpfile(yaml_body, opts2ktl_args)
    end

    def extract_patch_values
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

    def opts2ktl_args
      TRANSLATION.inject([]) do |whole, part|
        option_key = part[:option]
        if !options[option_key].nil?
          whole + ["#{part[:arg]} #{options[option_key]}"]
        else
          whole
        end
      end.join(" ")
    end

    def get_crt_vars
      create_configmap_if_missing
      get_configmap_values(get_configmap)
    end

    def get_configmap_values(configmap)
      json_enc_vars = configmap.dig(:data, :variables) || '{}'
      JSON.parse(json_enc_vars).deep_symbolize_keys
    end

    def get_configmap(raise_on_er: true)
      kmd = "get cm state #{opts2ktl_args}"
      puts "for"
      puts kmd

      if (configmap = Utils::Kubectl.jkmd(kmd, print_err: true))
        configmap
      else
        raise if raise_on_er
      end
    end

    def create_configmap_if_missing
      unless get_configmap(raise_on_er: false)
        kmd = "create cm state #{opts2ktl_args}"
        puts "back"
        puts kmd
        Utils::Kubectl.kmd(kmd)
      end
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
      interface: ["-bf=", "--blacklist-file", "Variables to not commit"]
    },
    {
      key: 'inlines',
      interface: ["--set=", "--set=", "Inline assignments"],
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