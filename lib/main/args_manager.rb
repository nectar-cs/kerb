module Kerbi
  class ArgsManager

    attr_reader :options

    def initialize(schema=PARAM_SCHEMA)
      @options = args2options(schema)
    end

    def get_run_env
      self.options[:run_env] || ENV['KERBI_ENV'] || 'development'
    end

    def get_fnames
      self.options[:file] || []
    end

    def get_inlines
      self.options[:inlines] || []
    end

    def get_res_filters
      self.options[:resource_filters] || []
    end

    def get_kmd_arg_str
      TRANSLATION.inject([]) do |whole, part|
        option_key = part[:option].to_sym
        if self.options[option_key]
          whole + ["#{part[:arg]} #{options[option_key]}"]
        else
          whole
        end
      end.join(" ")
    end
  end
end

#noinspection RubyEmptyRescueBlockInspection
def args2options(schema)
  options = {}
  parser = OptionParser.new do |opts|
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
  end

  begin
    parser.parse!
  rescue OptionParser::InvalidOption
  end

  options.deep_symbolize_keys!
end

def args_manager
  $_instance ||= Kerbi::ArgsManager.new
end

def reload_args_manager
  $_instance = Kerbi::ArgsManager.new
end


PARAM_SCHEMA = [
  {
    key: 'run_env',
    interface: ["-e=", "--environment", "Values file environment"]
  },
  {
    key: 'file',
    interface: ["-f=", "--file", "Source file"],
    many: true
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
  {
    key: "resource_filters",
    interface: ["--only=", "Resource filters"],
    many: true
  }
]

TRANSLATION = [
  { option: 'namespace', arg: "-n" },
  { option: 'context', arg: "--context" }
]
