module Kerbi
  module Utils
    class Utils

      class << self
        def real_files_for(*candidates)
          candidates.select do |fname|
            File.exists?(fname)
          end
        end

        def flatten_hash(hash)
          hash.each_with_object({}) do |(k, v), h|
            if v.is_a? Hash
              flatten_hash(v).map do |h_k, h_v|
                h["#{k}.#{h_k}".to_sym] = h_v
              end
            else
              h[k] = v
            end
          end
        end

        def str_assign_to_h(str_assign)
          key_expr, value = str_assign.split("=")
          assign_parts = key_expr.split(".") << value
          assignment = assign_parts.reverse.inject{ |a,n| { n=>a } }
          assignment.deep_symbolize_keys
        end

        def args2options(schema)
          options = {}
          OptionParser.new do |opts|
            schema.each do |part|
              opts.on(*part[:interface]) do |value|
                if part[:many]
                  options[part[:key]] ||= []
                  options[part[:key]] << value
                else
                  options[part[:key]] = value
                end
              end
            end
          end.parse!
          options.deep_symbolize_keys
        end
      end
    end
  end
end