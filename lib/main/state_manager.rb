require 'json'
require 'yaml'
require_relative './../utils/kubectl'

module Kerbi
  class StateManager
    def patch
      self.create_configmap_if_missing
      patch_values = self.compile_patch
      config_map = self.get_configmap
      crt_values = self.get_configmap_values(config_map)
      merged_vars = crt_values.deep_merge(patch_values)
      new_body = { **config_map, data: { variables: JSON.dump(merged_vars) } }
      yaml_body = YAML.dump(new_body.deep_stringify_keys)
      Utils::Kubectl.apply_tmpfile(yaml_body, args_manager.get_kmd_arg_str)
    end

    def compile_patch
      values = {}

      args_manager.get_fnames.each do |fname|
        new_values = YAML.load_file(fname).deep_symbolize_keys
        values.deep_merge!(new_values)
      end

      args_manager.get_inlines.each do |assignment_str|
        assignment = Utils::Utils.str_assign_to_h(assignment_str)
        values.deep_merge!(assignment)
      end
      values
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
      kmd = "get cm state #{args_manager.get_kmd_arg_str}"
      if (configmap = Utils::Kubectl.jkmd(kmd, print_err: true))
        configmap
      else
        raise if raise_on_er
      end
    end

    def create_configmap_if_missing
      unless get_configmap(raise_on_er: false)
        kmd = "create cm state #{args_manager.get_kmd_arg_str}"
        Utils::Kubectl.kmd(kmd)
      end
    end
  end
end