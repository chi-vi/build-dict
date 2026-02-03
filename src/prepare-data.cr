def write_file(input : String, fpath : String)
  File.write(fpath, input)
  puts "Written #{input.size} chars to #{fpath}"
end

def extract(ipath : String, o_dir : String)
  Dir.mkdir_p(o_dir)

  count = 0
  index = 0
  limit = 1000

  sbuff = String::Builder.new

  File.each_line(ipath) do |line|
    line = line.strip
    next if line.empty?

    sbuff << line
    sbuff << "\n"
    count += line.size + 1

    next if count < limit

    write_file(sbuff.to_s, "#{o_dir}/#{index}.zh.txt")
    sbuff = String::Builder.new

    index += 1
    count = 0
  end

  write_file(sbuff.to_s, "#{o_dir}/#{index}.zh.txt") if count > 0
  puts "Extracted to #{o_dir}, total parts: #{index + 1}"
end

if ARGV.size != 2
  puts "Usage: prepare-data <input_file> <output_dir>"
  exit 1
end

extract(ARGV[0], ARGV[1])
