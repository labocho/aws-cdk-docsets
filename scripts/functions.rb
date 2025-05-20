require "rest-client"
require "logger"
require "json"

module Functions
  def download(path, url)
    etag_file = "#{path}.etag"
    etag = File.exist?(path) ? read_if_exist(etag_file)&.strip : nil
    headers = etag ? {"If-None-Match" => etag} : {}
    logger.debug({type: "RestClient.get", url: url, headers: headers})

    begin
      resp = RestClient.get(url, headers)
      new_etag = resp.headers.fetch(:etag)
      logger.debug({type: "download.save", path: path, etag: new_etag, url: url})
      File.write(path, resp.body)
      File.write(etag_file, new_etag)
    rescue RestClient::NotModified => e
      logger.debug({type: "download.not_modified", path: path, url: url})
    end

    nil
  end

  def read_if_exist(path)
    File.exist?(path) ? File.read(path) : nil
  end

  def logger
    @logger ||= Logger.new($stderr, formatter: -> (severity, time, progname, msg) { msg.merge(severity: severity, time: time).to_json + "\n" })
  end

  def root_dir
    @root_dir = "#{__dir__}/../"
  end

  def cdk_version
    @cdk_version ||= File.read("#{root_dir}/CDK_VERSION").strip
  end

  def zip_name
    @zip_name ||= "aws-cdk-python-docs-#{cdk_version}.zip"
  end

  def docset_name
    @docset_name ||= "AWS CDK Python Reference v#{cdk_version}.docset"
  end
end
