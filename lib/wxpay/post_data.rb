require "wxpay/helpers/params_helper"
require "wxpay/helpers/xml_helper"

module Wxpay
  class PostDataBase 
    include WxHelper::XmlHelper
    include WxHelper::ParamsHelper
    
    def get_data
      @post_data
    end
  end
  
  class PackagePostData < PostDataBase
    def initialize post_data
      @post_data = PackageMessage.new(post_data)
    end

    def is_validate_sign? app_key
      hash = {appid: @post_data.app_id, appkey: app_key, issubscribe: @post_data.is_subscribe, noncestr: @post_data.nonce_Str, productid: @post_data.product_id, timestamp: @post_data.time_stamp}
      signature = get_sign(hash)
      signature == @post_data.app_signature
    end
  end

  class NotifyPostData < PostDataBase
    def initialize post_data
      @post_data = NotifyMessage.new(post_data)
    end

    def is_validate_sign? app_key
      hash = {appid: @post_data.app_id, appkey: app_key, issubscribe: @post_data.is_subscribe, noncestr: @post_data.nonce_Str, openid: @post_data.open_id, timestamp: @post_data.time_stamp}
      signature = get_sign(hash)
      signature == @post_data.app_signature
    end
  end
end