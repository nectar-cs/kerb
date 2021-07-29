require 'open3'
require 'json'

module Kerbi
  module Utils
    class Kubectl
      class << self
        def kmd(cmd, options = {})
          cmd = "kubectl #{cmd}"
          self.eval_shell_cmd(cmd, options)
        end

        def jkmd(cmd, options={})
          cmd = "kubectl #{cmd} -o json"
          begin
            output = self.eval_shell_cmd(cmd, options)
            as_hash = JSON.parse(output).deep_symbolize_keys
            if as_hash.has_key?(:items)
              as_hash[:items]
            else
              as_hash
            end
          rescue
            nil
          end
        end

        def eval_shell_cmd(cmd, print_err: false)
          begin
            output, status = Open3.capture2e(cmd)
            if status.success?
              output = output[0..output.length - 2] if output.end_with?("\n")
              output
            else
              if print_err
                puts "Command \"#{cmd}\" error status #{status} with message:"
                puts output
                puts "---"
              end
              nil
            end
          rescue Exception => e
            if print_err
              puts "Command \"#{cmd}\" failed with message:"
              puts e.message
              puts "---"
            end
            nil
          end
        end

        def apply_tmpfile(yaml_str, append)
          tmp_fname = "/tmp/man-#{SecureRandom.hex(32)}.yaml"
          File.write(tmp_fname, yaml_str)
          kmd("apply -f #{tmp_fname} #{append}", print_err: true)
          File.delete(tmp_fname)
        end
      end
    end
  end
end