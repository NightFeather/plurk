module Plurk

  # Handles the state of a comet channel
  class CometChannel

    # Initialize with a url to channel (Without oauth authorization)
    # @param uri [String]
    def initialize uri
      @uri = URI(uri)
      @query = Hash[@uri.query.split("&").map { |i| i.split("=") }]
      @offset = @query["offset"]
    end

    # Runs one comet cycle
    # request -> reponse -> parse if is a HTTPOK -> store new offset
    # @raise [ServerError] when response is not a `Net::HTTPOK`
    # @return [Array<Plurk,Response>]
    def fetch
      @query["offset"] = @offset
      @uri.query = serialize_query
      resp = Net::HTTP.get_response @uri
      if resp.is_a? Net::HTTPOK
        return parse_resp resp
      else
        exception = ServerError.new(resp.code)
        case resp
        when Net::HTTPRedirection
          raise exception, resp['Location']
        else
          raise exception, resp.message
        end
      end
    end


    private

    # Parse responses from comet into corresponding wrapper class
    # @param resp [Net::HTTPResponse] response from comet server
    # @raise [InvalidBodyError] when a irregular body recieved
    # @return [Array<Plurk,Response>]
    def parse_resp resp
      if resp.body.match(/^CometChannel\.scriptCallback\((.+)\);$/).nil?
        raise InvalidBodyError, resp.body
      end
      extracted = JSON.parse($~[1])
      @offset = extracted["new_offset"]
      data = extracted["data"]
      return [] unless data
      data.map! do |i|
        case i.delete("type")
        when "new_plurk"
          Plurk.new(i)
        when "new_response"
          Response.new(i["response"]).tap do |res|
            res.user = User.new(i["user"][res.user_id.to_s])
            res.plurk = Plurk.new(i["plurk"])
          end
        else
          i
        end
      end
      return data
    end

    # Convert hash into urlencoded-form format
    # @return [String] convert result we expected
    def serialize_query
      @query.map { |k,v| "#{k}=#{v}" }.join("&")
    end

  # Base Error Class inside here
  Error = Class.new(::Plurk::Error)

  # Error Class
  InvalidBodyError = Class.new(Error)

  # Error Class includes http status code
  class ServerError < Error
    attr_reader :code
    def initialize val; @code = val; end
  end

  end
end
