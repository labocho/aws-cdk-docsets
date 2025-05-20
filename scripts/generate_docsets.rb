require "sqlite3"
require "active_record"
require "find"
require "pathname"
require "shellwords"
require "fileutils"
include FileUtils

require_relative "functions"
include Functions

docset = "docsets/#{docset_name}"
mkdir_p "#{docset}/Contents/Resources/Documents"
exit $?.exitstatus unless system("cp -R html/* #{"#{docset}/Contents/Resources/Documents".shellescape}")
cp "assets/Arch_AWS-Systems-Manager_64.svg", "#{docset}/Contents/Resources/Documents/icon.svg"

File.write("#{docset}/Contents/Info.plist", <<~XML)
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key>
      <string>AWS CDK Python Reference v#{cdk_version}</string>
      <key>CFBundleName</key>
      <string>AWS CDK Python Reference v#{cdk_version}</string>
      <key>DocSetPlatformFamily</key>
      <string>AWS CDK Python Reference v#{cdk_version}</string>
      <key>isDashDocset</key>
      <true/>
      <key>dashIndexFilePath</key>
      <string>doc/index.html</string>
    </dict>
  </plist>
XML

rm "#{docset}/Contents/Resources/docSet.dsidx", force: true

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "#{docset}/Contents/Resources/docSet.dsidx",
)

ActiveRecord::Base.connection.execute <<-SQL
  CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT)
SQL

class SearchIndex < ActiveRecord::Base
  self.table_name = "searchIndex"
end

html_dir = "#{docset}/Contents/Resources/Documents"

Find.find(html_dir) do |file|
  next unless FileTest.file?(file) && File.extname(file) == ".html"

  item = {key: "", type: ""}
  path = Pathname.new(file).relative_path_from(Pathname.new(html_dir)).to_s

  case path
  when %r(^(aws_cdk)\.html$) # package
    item[:key] = $1
    item[:type] = "Package"
  when %r(^(aws_cdk/.+)\.html$) # package
    item[:key] = $1
    item[:type] = "Module"
  when %r(^(aws_cdk\.[^/]+)\.html$) # package
    item[:key] = $1
    item[:type] = "Package"
  when %r(^(aws_cdk\.[^/]+/.+)\.html$) # package
    item[:key] = $1
    item[:type] = "Module"
  when %r(^(constructs)\.html$) # package
    item[:key] = $1
    item[:type] = "Package"
  when %r(^(constructs/.+)\.html$) # package
    item[:key] = $1
    item[:type] = "Module"
  when %r(^(genindex|index|modules|search)\.html$)
    item[:key] = $1
    item[:type] = "Guide"
  else
    raise "Unknown html file: #{file}}"
  end

  index = SearchIndex.new
  index.name = item[:key]
  index.type = item[:type]
  index.path = path
  index.save!
  print "."
end

