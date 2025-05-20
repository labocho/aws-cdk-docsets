require "open-uri"
require "json"
require_relative "scripts/functions"

include Functions

task "zip" do
  mkdir_p "zip"
  ruby "scripts/download_zip.rb"
end

task "html" => "zip" do
  mkdir_p "html"
  next if read_if_exist("html/CDK_VERSION")&.strip == cdk_version

  sh "unzip", "zip/#{zip_name}", "-d", "html"
  cp "CDK_VERSION", "html/CDK_VERSION"
end

task "docsets" => "html" do
  mkdir_p "docsets"
  next if read_if_exist("docsets/CDK_VERSION")&.strip == cdk_version

  ruby "scripts/generate_docsets.rb"
  cp "CDK_VERSION", "docsets/CDK_VERSION"
end

task "install" => "docsets" do
  source = "docsets/#{docset_name}"
  dest = "#{Dir.home}/Library/Application Support/Dash/DocSets/#{docset_name}"
  rm_rf dest
  mkdir_p dest
  cp_r source, dest
end

task "clean" do
  rm_rf "CDK_VERSION"
  rm_rf "zip"
  rm_rf "html"
  rm_if "docsets"
end
