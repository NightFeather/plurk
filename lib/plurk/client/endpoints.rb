module Plurk
  class Client

    # wrap up some frequesntly used (maybe) api endpoints
    module Endpoints

      # Access "/APP/Users/me"
      # Cached version
      # @return [User] current user the bot login with
      def get_me
        return @me if @me
        get_me!
      end

      # Access "/APP/Users/me"
      # actual do the request everytime
      # @return [User] current user the bot login with
      def get_me!
        resp = request "/APP/Users/me"
        @me = User.new(resp)
      end

      # Access "/APP/Realtime/getUserChannel"
      # @return [CometChannel] the update channel handler
      def get_user_channel
        resp = request "/APP/Realtime/getUserChannel"
        return CometChannel.new(resp["comet_server"])
      end

      # Access "/APP/Polling/getPlurks"
      # @param offset [Time] get the plurks newer than this
      # @return [Array<Plurk>] list of plurks with users merged
      def get_plurks offset = nil
        offset = offset.strftime("%Y-%m-%dT%H:%M:%S") if offset.is_a? Time
        resp = request "/APP/Polling/getPlurks", offset: offset
        _users = p Hash[resp["plurk_users"].map { |k,v| [k, User.new(v)] } + [[@me.id, @me]]]
        return resp["plurks"].map { |i| Plurk.new(i.merge(user: _users[i["user_id"]])) }
      end

      # Access "/APP/Timeline/getPlurk"
      # @param plurk_id [Integer] target plurk id
      # @return [Plurk]
      def get_plurk plurk_id
        resp = request "/APP/Timeline/getPlurk", plurk_id: plurk_id
        Plurk.new(resp["plurk"])
      end

      # Access "/APP/Timeline/plurkAdd"
      # @param content    [String]
      # @param qual       [String]
      # @param limited_to [Array<Integer>] list of the user you want to talk
      # @return [Plurk]
      def add_plurk content, qual = ":", limited_to = nil
        resp = request "/APP/Timeline/plurkAdd",
                        { content: content, qualifier: qual, limited_to: limited_to }
        Plurk.new(resp)
      end

      # Access "/APP/Timeline/plurkEdit"
      # @param plurk_id  [Integer]
      # @param content   [String]
      # @return [Plurk]
      def edit_plurk plurk_id, content
        resp = request "/APP/Timeline/plurkEdit", { plurk_id: plurk_id, content: content}
        Plurk.new(resp)
      end

      # Access "/APP/Timeline/plurkDelete"
      # @param plurk_id  [Integer]
      def del_plurk plurk_id
        request "/APP/Timeline/plurkDelete", { plurk_id: plurk_id }
      end

      # Access "/APP/Responses/responseAdd"
      # @param plurk_id [Integer]
      # @param content  [String]
      # @param qual     [String]
      # @return [Response]
      def add_response plurk_id, content, qual = ":"
        resp = request "/APP/Responses/responseAdd",
                        { plurk_id: plurk_id, content: content, qualifier: qual }
        Response.new(resp)
      end

      # Access "/APP/Responses/responseDelete"
      # @param plurk_id [Integer]
      # @param response_id [Integer]
      def del_response plurk_id, response_id
        request "/APP/Responses/responseDelete", { response_id: response_id, plurk_id: plurk_id }
      end

      # Access "/APP/FriendsFans/becomeFriend"
      # @param friend_id [Integer] the id of user you want to friend with
      # @return [User]
      def add_friend friend_id
        resp = request "/APP/FriendsFans/becomeFriend", { friend_id: friend_id }
        User.new(resp)
      end

      # Access "/APP/FriendsFans/removeAsFriend"
      # @param friend_id [Integer] the id of user you don't want to friend with
      def del_friend friend_id
        request "/APP/FriendsFans/removeAsFriend", { friend_id: friend_id }
      end

      # Access "/APP/Alerts/getActive"
      def get_alerts
        request "/APP/Alerts/getActive"
      end

      # Access "/APP/Alerts/addAllAsFriend"
      def add_all_as_friend
        request "/APP/Alerts/addAllAsFriend"
      end

      # Access "/APP/checkToken"
      def check_token
        OAuthToken.new request "/APP/checkToken"
      end

      # Access "/APP/expireToken"
      def expire_token
        OAuthToken.new request "/APP/expireToken"
      end

      # Poke the server
      def ping_server payload = "pong"
        request "/APP/echo", { data: payload }
      end

    end
  end
end
