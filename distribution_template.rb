#!/usr/bin/env ruby

require 'optparse'

options = {:template_file=>"distribution_template.html",:app_version=>""}
option_parser = OptionParser.new do |opts|
  executable_name = File.basename($PROGRAM_NAME)
  opts.banner = "Generate a distribution HTML file from a given template
  
Usage: #{executable_name} [options] output_file_name
    "
	opts.on('-n APPLICATION_NAME', 'The name of the application as it appears in the HTML file') do |app_name|
		options[:app_name] = app_name
	end
	opts.on('-v VERSION', 'The version number of the application build - concatenated together with app_name separated by a whitespace') do |app_version|
	  options[:app_version] = app_version
  end
	opts.on('-t PAGE_TITLE', 'The HTML title for the generated page, optional, defaults to application name') do |page_title|
		options[:page_title] = page_title
	end
  opts.on('-m MANIFEST_PATH', 'The full path where the manifest plist file will reside') do |manifest_path|
    options[:manifest_path] = manifest_path
  end
end

option_parser.parse!

if (options[:app_name] == nil)
  raise ArgumentError, "You must specify an app name with -n NAME"
end

if (options[:manifest_path] == nil)
  raise ArgumentError, "You must specify the full manifest path with -m MANIFEST_PATH"
end


if (options[:page_title] == nil)
  options[:page_title] = options[:app_name]
end

output_file_name = ARGV.shift

if (output_file_name == nil) 
  raise ArgumentError, "You must specify the output file as an argument"
end

File.open(options[:template_file], 'r') do |template_file|
  File.open("#{output_file_name}",'w') do |output_file|
    template_file.readlines.each do |template_line|
      output_line = template_line.sub("\[PAGE_TITLE\]", options[:page_title])
      output_line = output_line.sub("\[APP_NAME\]", options[:app_name])
      output_line = output_line.sub("\[MANIFEST_PATH\]", options[:manifest_path])
      output_line = output_line.sub("\[APP_VERSION\]", options[:app_version])
      output_file.puts(output_line)
    end
  end
end