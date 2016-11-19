module Plurk
  class CometChannel
    def initialize uri
      uri = URI(uri) if uri.is_a? String
      @uri = uri
      @query = Hash[@uri.query.split("&").map { |i| i.split("=") }]
      @offset = @query["offset"]
    end

    def fetch
      @query["offset"] = @offset
      @uri.query = serialize_query
      resp = Net::HTTP.get_response @uri
      if resp.is_a? Net::HTTPOK
        extracted = JSON.parse(resp.body.match(/^CometChannel\.scriptCallback\((.+)\);$/)[1])
        @offset = extracted["new_offset"]
        p data = extracted["data"]
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
        raise CometError, "#{resp.code}: #{resp.body}"
      end
    end


    private

    def serialize_query
      @query.map { |k,v| "#{k}=#{v}" }.join("&")
    end

  CometError = Class.new(PlurkError)

  end
end
