module Plurk
  class Client
    module Endpoints

      def get_me
        resp = request "/APP/Users/me"
        User.new(resp)
      end

      def get_user_channel
        resp = request "/APP/Realtime/getUserChannel"
        return CometChannel.new(resp["comet_server"])
      end

      def get_plurks offset = nil
        offset = offset.strftime("%Y-%m-%dT%H:%M:%S") if offset.is_a? Time
        resp = request "/APP/Polling/getPlurks", offset: offset
        resp["plurks"].map! { |i| Plurk.new(i) }
        resp["plurk_users"] = resp["plurk_users"].map { |k,v| User.new(v) }
        return resp
      end

      def get_plurk plurk_id
        resp = request "/APP/Timeline/getPlurk", plurk_id: plurk_id
        Plurk.new(resp["plurk"])
      end

      def add_plurk content, qual = ":", limited_to = nil
        resp = request "/APP/Timeline/plurkAdd",
                        { content: content, qualifier: qual, limited_to: limited_to }
        Plurk.new(resp)
      end

      def edit_plurk plurk_id, content
        resp = request "/APP/Timeline/plurkEdit", { plurk_id: plurk_id, content: content}
        Plurk.new(resp)
      end

      def del_plurk plurk_id
        request "/APP/Timeline/plurkDelete", { plurk_id: plurk_id }
      end

      def add_response plurk_id, content, qual = ":"
        resp = request "/APP/Timeline/responseAdd",
                        { plurk_id: plurk_id, content: content, qualifier: qual }
        Response.new(resp)
      end

      def del_response response_id, plurk_id
        request "/APP/Timeline/responseDelete", { response_id: response_id, plurk_id: plurk_id }

      end

      def add_friend friend_id
        resp = request "/APP/Timeline/becomeFriend", { friend_id: friend_id }
        User.new(resp)
      end

      def del_friend friend_id
        request "/APP/Timeline/removeAsFriend", { friend_id: friend_id }
      end

      def get_alerts
        request "/APP/Alerts/getActive"
      end

      def add_all_as_friend
        request "/APP/Alerts/addAllAsFriend"
      end

      def check_token
        OAuthToken.new request "/APP/checkToken"
      end

      def expire_token
        OAuthToken.new request "/APP/expireToken"
      end

      def ping_server payload = "pong"
        request "/APP/echo", { data: payload }
      end

    end
  end
end
