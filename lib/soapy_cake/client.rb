# frozen_string_literal: true
module SoapyCake
  class Client
    HEADERS = { 'Content-Type' => 'application/soap+xml;charset=UTF-8' }.freeze

    def initialize(opts = {})
      @opts = opts
      @domain = fetch_opt(:domain) || raise(Error, 'Cake domain missing')
      @api_key = fetch_opt(:api_key) || raise(Error, 'Cake API key missing')
      @retry_count = fetch_opt(:retry_count, 4)
      @write_enabled = ['yes', true].include?(fetch_opt(:write_enabled))
      @time_converter = TimeConverter.new(fetch_opt(:time_zone), fetch_opt(:time_offset))
    end

    def xml_response?
      opts[:xml_response] == true
    end

    def read_only?
      !write_enabled
    end

    protected

    attr_reader :domain, :api_key, :time_converter, :opts, :logger, :retry_count, :write_enabled

    def run(request)
      check_write_enabled!(request)
      request.api_key = api_key
      request.time_converter = time_converter

      with_retries do
        response = Response.new(response_body(request), request.short_response?, time_converter)
        xml_response? ? response.to_xml : response.to_enum
      end
    end

    private

    def fetch_opt(key, fallback = nil)
      opts.fetch(key, ENV.fetch("CAKE_#{key.to_s.upcase}", fallback))
    end

    def check_write_enabled!(request)
      unless request.read_only? || write_enabled
        raise Error, 'Writes not enabled (pass write_enabled: true or set CAKE_WRITE_ENABLED=yes)'
      end
    end

    def with_retries(&block)
      opts = { tries: retry_count + 1, on: [RateLimitError, SocketError], sleep: -> (n) { 3**n } }
      Retryable.retryable(opts, &block)
    end

    def logger
      @logger ||= opts[:logger] || (defined?(::Rails) && ::Rails.logger)
    end

    def response_body(request)
      request.opts[:response].presence || http_response(request)
    end

    def http_response(request)
      logger.info("soapy_cake:request #{request}") if logger

      uri = URI::HTTPS.build(host: domain, path: request.path)
      HTTParty.post(uri, headers: HEADERS, body: request.xml, timeout: NET_TIMEOUT).tap do |res|
        raise RequestFailed, "Request failed with HTTP #{res.code}: #{res.body}" unless res.success?
      end
    end
  end
end
