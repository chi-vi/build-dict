require "json"
require "yaml"
require "colorize"
require "http/client"
require "wait_group"
require "option_parser"

struct Endpoint
  include YAML::Serializable

  getter endpoint : String
  getter api_key : String

  def openai_endpoint
    "#{@endpoint}/v1/chat/completions"
  end

  def openai_headers
    HTTP::Headers{
      "Authorization" => "Bearer #{@api_key}",
      "Content-Type"  => "application/json",
    }
  end

  def call_openai(body : String, label : String) : String
    HTTP::Client.post(self.openai_endpoint, headers: self.openai_headers, body: body) do |resp|
      output = resp.body_io.gets_to_end
      case output
      when .blank?,
           .starts_with?("Token error"),
           .starts_with?("{\"id\":\"chatcmpl-unknown\"")
        raise "<#{label}> Empty response from API."
      when .starts_with?("{\"error\"")
        raise "<#{label}> API Error: #{output}"
      else
        output
      end
    end
  end

  SYSTEM_PROMPT = {{ read_file("#{__DIR__}/system-prompt.md") }}

  def openai_body(content : String, model = "gemini-3-pro-low", temperature = 0.4, reasoning_effort = "minimal") : String
    {
      model: model,
      messages: [
        {role: "system", content: SYSTEM_PROMPT},
        {role: "user", content: content},
      ],
      temperature: temperature, reasoning_effort: reasoning_effort,
    }.to_json
  end
end

class CallGemini
  getter config_path = "config.yml"
  getter endpoint : Endpoint

  getter conns = 3

  getter model = "gemini-3-pro-low"
  getter f_ext = ".3pl.json"

  getter temperature = 0.4
  getter reasoning_effort = "minimal"

  getter i_dirs : Array(String) = [] of String

  getter f_min = 0
  getter f_max = -1

  MAP_EXT = {
    "gemini-3-flash"    => ".3ft.json",
    "gemini-3-pro-high" => ".3ph.json",
    "gemini-3-pro-low"  => ".3pl.json",
    "gemini-2.5-flash"  => ".25f.json",
  }

  def initialize(env = ENV)
    OptionParser.parse do |opts|
      opts.on("-c PATH", "Path to config YAML file") do |path|
        @config_path = path
      end

      opts.on("-w CONNS", "Number of concurrent connections (default: 3)") do |conns|
        @conns = conns.to_i
      end

      opts.on("-m MODEL", "Model to use (default: gemini-3-pro-low)") do |model|
        @model = model
      end

      opts.on("-t TEMPERATURE", "Temperature setting (default: 0.4)") do |temp|
        @temperature = temp.to_f
      end

      opts.on("-r REASONING_LEVEL", "Reasoning effort level (default: minimal)") do |level|
        @reasoning_effort = level
      end

      opts.on("-f MIN", "Minimum file index to process (default: 0)") do |fmin|
        @f_min = fmin.to_i
      end

      opts.on("-u MAX", "Maximum file index to process (default: -1, no limit)") do |fmax|
        @f_max = fmax.to_i
      end

      opts.unknown_args do |args|
        @i_dirs = args
      end
    end

    @endpoint = Endpoint.from_yaml(File.read(@config_path))
    @f_ext = MAP_EXT[@model]
  end

  def call_api(ipath : String, label : String)
    opath = ipath.sub(".zh.txt", @f_ext)

    if File.file?(opath)
      Log.info { "<#{label}> Skipped #{opath}, already exists.".colorize.blue }
      return
    end

    Log.info { "<#{label}> Processing #{ipath}, model: #{@model}" }
    ibody = @endpoint.openai_body(File.read(ipath), model: @model, temperature: @temperature, reasoning_effort: @reasoning_effort)

    time_span = Time.measure do
      output = @endpoint.call_openai(ibody, label)
      File.write(opath, output)
      Log.info { "<#{label}> Output written to #{opath}".colorize.green }
    rescue ex
      Log.error { "<#{label}> Error processing #{ipath}: #{ex.message}".colorize.red }
    end

    Log.info { "Time taken: #{time_span.total_seconds} seconds".colorize.yellow }
  end

  def call_all(queue : Array(String))
    qsize = queue.size
    conns = {@conns, qsize}.min

    inp_ch = Channel({String, String}).new(qsize)
    res_wg = WaitGroup.new(qsize)

    spawn do
      queue.each_with_index(1) do |fpath, index|
        inp_ch.send({fpath, "#{index}/#{qsize}"})
      end
    end

    conns.times do
      spawn do
        loop do
          call_api(*inp_ch.receive)
        rescue ex
          Log.error(exception: ex) { ex.message.colorize.red }
        ensure
          res_wg.done
        end
      end
    end

    res_wg.wait
  end

  def invoke!
    @i_dirs.each do |i_dir|
      files = Dir.glob("#{i_dir}/*.zh.txt")
      files.sort_by! { |x| File.basename(x, ".zh.txt").to_i }

      files = files[@f_min..@f_max]
      call_all(files)
    end
  end
end

worker = CallGemini.new
worker.invoke!
