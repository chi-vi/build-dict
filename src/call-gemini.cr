require "json"
require "yaml"
require "colorize"
require "http/client"

struct Config
  include YAML::Serializable

  getter endpoint : String
  getter api_key : String
  getter model : String = "gemini-3-pro-low"

  def openai_headers
    HTTP::Headers{
      "Authorization" => "Bearer #{api_key}",
      "Content-Type"  => "application/json",
    }
  end

  def openai_endpoint
    "#{endpoint}/v1/chat/completions"
  end

  def call_openai(body : String)
    HTTP::Client.post(openai_endpoint, headers: openai_headers, body: body) do |resp|
      output = resp.body_io.gets_to_end
      case output
      when .blank?
        raise "Empty response from API"
      when .starts_with?("{\"error\"")
        raise "API Error: #{output}"
      else
        output
      end
    end
  end

  SYSTEM_PROMPT = {{ read_file("#{__DIR__}/system-prompt.md") }}

  def openai_body(content : String)
    {
      model:    @model,
      messages: [
        {role: "system", content: SYSTEM_PROMPT},
        {role: "user", content: content},
      ],
      temperature: 0.4,
      reasoning:   {effort: "minimal"},
    }.to_json
  end

  def self.load(path : String)
    self.from_yaml(File.read(path))
  end
end

MAP_EXT = {
  "gemini-3-flash"    => ".3ft.json",
  "gemini-3-pro-high" => ".3ph.json",
  "gemini-3-pro-low"  => ".3pl.json",
  "gemini-2.5-flash"  => ".25f.json",
}

CONFIG = Config.load("config.yml")

def call_api(ipath : String)
  opath = ipath.sub(".zh.txt", MAP_EXT[CONFIG.model])

  if File.file?(opath)
    Log.info { "Skipped #{opath}, already exists.".colorize.blue }
    return
  end

  Log.info { "Processing #{ipath}, model: #{CONFIG.model}" }
  ibody = CONFIG.openai_body(File.read(ipath))

  time_span = Time.measure do
    output = CONFIG.call_openai(ibody)
    File.write(opath, output)
    Log.info { "Output written to #{opath}".colorize.green }
  rescue ex
    Log.error { "Error processing #{ipath}: #{ex.message}".colorize.red }
  end

  Log.info { "Time taken: #{time_span.total_seconds} seconds".colorize.yellow }
end

if ARGV.size == 0
  puts "Usage: call-gemini <input_name1> [<input_name2> ...]"
  exit 1
end

ARGV.each do |iname|
  files = Dir.glob("data/#{iname}/*.zh.txt")
  files.sort_by! { |x| File.basename(x, ".zh.txt").to_i }

  files.each do |fpath|
    call_api(fpath)
  end
end
