require "open-uri"
require "json"
require_relative "functions"

include Functions

CDK_VERSION_FILE = "#{__dir__}/../CDK_VERSION"

release = JSON.parse(URI.open("https://api.github.com/repos/aws/aws-cdk/releases?per_page=1", &:read)).first
version = release.fetch("tag_name")[1..]

unless read_if_exist(CDK_VERSION_FILE)&.strip == version
  File.write(CDK_VERSION_FILE, version + "\n")
end

python_doc_asset = release.fetch("assets").find {|a| a.fetch("name") == zip_name } || raise("Cannot found `#{zip_name}` in release: #{release.inspect}")

download("zip/#{zip_name}", python_doc_asset.fetch("browser_download_url"))
