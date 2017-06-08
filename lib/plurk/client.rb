
require_relative 'client/endpoints'

module Plurk

  # Contains credentials
  class Client

    include Endpoints

    DEFAULT_OAUTH_OPTIONS = {
      :site               => 'https://www.plurk.com',
      :scheme             => :header,
      :http_method        => :post,
      :request_token_path => '/OAuth/request_token',
      :access_token_path  => '/OAuth/access_token',
      :authorize_path     => '/OAuth/authorize'
    }


    # Initializes a `Plurk::Client` instance
    # @param key [String] application key
    # @param secret [String] application secret
    # @return [Plurk::Client] with a default handler that can access public resource
    def initialize(key, secret)
        @key, @secret = key, secret
        @consumer = OAuth::Consumer.new(@key, @secret, DEFAULT_OAUTH_OPTIONS)
        # Default request handler
        @access_token = OAuth::AccessToken.new(@consumer, nil, nil)
    end

    # Generate a authorization request url
    # @return [String] authrization request url
    def get_authorize_url
        @request_token = @consumer.get_request_token
        return @request_token.authorize_url
    end

    # Authorize this client with access to an account.
    # @param key [String] represents access token or oauth verifier depends on secret representation
    # @param secret [String] default to `nil`
    # @return [OAuth::AccessToken] this will be stored in current instance, no need to take care about
    def authorize(key, secret=nil)
        @access_token = case secret
                           when nil then
                             @request_token.get_access_token :oauth_verifier=>key
                           else
                             OAuth::AccessToken.new(@consumer, key, secret)
                        end
        return @access_token
    end

    # Request with aouth authorizations
    # @param url [String] uri string to the api endpoint
    # @param body [Hash] addition params you want to request with. default to `nil`
    # @param headers [hash] default to `nil`
    # @return [Hash] parsed response body
    # @raise [Plurk::Client::RequestError] when the response is not 200
    #   or contains exceptions
    def request(url, body=nil, headers=nil)
      resp = @access_token.post(url, body, headers)
      if resp.is_a? Net::HTTPOK
        parsed = JSON.parse(resp.body)
        return parsed unless parsed.key? "error_text"
        raise RequestError, parsed["error_text"]
      else
        raise RequestError, "#{resp.code}: " + JSON.parse(resp.body)["error_text"]
      end
    end

    RequestError = Class.new(Error)

  end
end
