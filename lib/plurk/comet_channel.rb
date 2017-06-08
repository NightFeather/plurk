module Plurk

  # Handles the state of a comet channel
  class CometChannel

    # Initialize with a url to channel (Without oauth authorization)
    # @param uri [String] or [URI]
    def initialize uri
      uri = URI(uri) if uri.is_a? String
      @uri = uri
      @query = Hash[@uri.query.split("&").map { |i| i.split("=") }]
      @offset = @query["offset"]
    end

    # Runs one comet cycle
    # request -> reponse -> parse if is a HTTPOK -> store new offset
    # @raise [CometError] when response is not a `Net::HTTPOK`
    def fetch
      @query["offset"] = @offset
      @uri.query = serialize_query
      resp = Net::HTTP.get_response @uri
      if resp.is_a? Net::HTTPOK
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
            Response.new(i["response"]).tap { |res|
              res.user = User.new(i["user"][res.user_id.to_s])
              res.plurk = Plurk.new(i["plurk"])
            }
          else
            i
          end
        end
        return data
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

    # Why ruby doesn't have a builtin method to convert between a `Hash` and a HTTP::GET query
    def serialize_query
      @query.map { |k,v| "#{k}=#{v}" }.join("&")
    end

  Error = Class.new(::Plurk::Error)
  CometError = Class.new(Error)
  InvalidBodyError = Class.new(CometError)

  class ServerError < Error
    attr_reader :code
    def initialize val; @code = val; end
  end

  end
end
