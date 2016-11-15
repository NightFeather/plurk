
require_relative 'client/endpoints'

module Plurk
  class Client

    include Endpoints

    DEFAULT_OAUTH_OPTIONS = {
      :site               => 'http://www.plurk.com',
      :scheme             => :header,
      :http_method        => :post,
      :request_token_path => '/OAuth/request_token',
      :access_token_path  => '/OAuth/access_token',
      :authorize_path     => '/OAuth/authorize'
    }

    def initialize(key, secret)
        @key, @secret = key, secret
        @consumer = OAuth::Consumer.new(@key, @secret, DEFAULT_OAUTH_OPTIONS)
        # Default request handler
        @access_token = OAuth::AccessToken.new(@consumer, nil, nil)
    end

    # output: authorize url
    def get_authorize_url
        @request_token = @consumer.get_request_token
        return @request_token.authorize_url
    end

    # case 1: has access token already
    # input: access token, access token secret
    # case 2: no access token, auth need
    # input: verification code    
    def authorize(key, secret=nil)
        @access_token = case secret
                           when nil then
                             @request_token.get_access_token :oauth_verifier=>key
                           else
                             OAuth::AccessToken.new(@consumer, key, secret)
                        end
        return @access_token
    end

    # input: plurk APP url, options in hash
    # output: result in JSON
    def request(url, body=nil, headers=nil)
      resp = @access_token.post(url, body, headers)
      if resp.code == 200
        return JSON.parse(resp.body)
      else
        raise RequestError, "#{resp.code}: " + JSON.parse(resp.body)["error_text"]
      end
    end

    PlurkError = Class.new(StandardError)
    RequestError = Class.new(PlurkError)

  end
end
