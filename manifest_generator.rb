#!/usr/bin/env ruby

require 'optparse'
require 'rubygems'
require 'zip/zip'

options = {}
option_parser = OptionParser.new do |opts|
  executable_name = File.basename($PROGRAM_NAME)
  opts.banner = "Generates a manifest plist file for Ad-Hoc distribution
  
Usage: #{executable_name} [options] output_file_name
    "
	opts.on('-p IPA_PATH', 'The path to your .ipa file') do |ipa_path|
		options[:ipa_path] = ipa_path
	end
  opts.on('-d DEPLOYMENT_ADDRESS', 'The deployment address where the .ipa file will reside - without the .ipa file in the path') do |deployment_address|
    options[:deployment_address] = deployment_address
  end
end

option_parser.parse!

if (options[:deployment_address] == nil)
  raise ArgumentError, "You must specify the deployment address with -d DEPLOYMENT_ADDRESS"
end

if (options[:ipa_path] == nil)
  raise ArgumentError, "You must specify the path to your ipa file with -p IPA_PATH"
end

output_file_name = ARGV.shift

if (output_file_name == nil) 
  raise ArgumentError, "You must specify the output file as an argument"
end

info_plist_content = nil
Zip::ZipFile.open(options[:ipa_path]) do |zip_file|
  zip_file.each do |f|
    next unless "#{f}" =~ /Info.plist$/
    info_plist_content = f.get_input_stream.read
  end
end

File.open("_tmp.Info.plist",'w') do |output_file|
  output_file.write(info_plist_content)
end

bundle_version = `/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" _tmp.Info.plist`.strip
bundle_identifier = `/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" _tmp.Info.plist`.strip
bundle_name = `/usr/libexec/PlistBuddy -c "Print :CFBundleName" _tmp.Info.plist`.strip

ipa_file_name = File.basename(options[:ipa_path])

File.open("#{output_file_name}",'w') do |output_file|
  output_file.puts("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
  <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
  <plist version=\"1.0\">
  <dict>
  	<key>items</key>
  	<array>
  		<dict>
  			<key>assets</key>
  			<array>
  				<dict>
  					<key>kind</key>
  					<string>software-package</string>
  					<key>url</key>
  					<string>#{options[:deployment_address]}/#{ipa_file_name}.ipa</string>
  				</dict>
  			</array>
  			<key>metadata</key>
  			<dict>
  				<key>bundle-identifier</key>
  				<string>#{bundle_identifier}</string>
  				<key>bundle-version</key>
  				<string>#{bundle_version}</string>
  				<key>kind</key>
  				<string>software</string>
  				<key>title</key>
  				<string>#{bundle_name}</string>
  			</dict>
  		</dict>
  	</array>
  </dict>
  </plist>
  ")
end

File.delete("_tmp.Info.plist")