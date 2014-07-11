require "wxpay/engine"
require "wxpay/params_helper"
require "wxpay/xml_helper"

module Wxpay
  class Package
    include WxHelper::XmlHelper
    include WxHelper::ParamsHelper

    def initialize post_data
      @package = Message.new(post_data)
    end

    def is_validate_sign? app_key
      hash = {appid: @package.app_id, appkey: app_key, issubscribe: @package.is_subscribe, noncestr: @package.nonce_Str, productid: @package.product_id, timestamp: @package.time_stamp}
      signature = get_sign(hash)
      signature == @package.app_signature
    end

    def generate_package
      hash = {
        app_id: 1,
        package: 2,
        nonce_str: 3,
        app_signature: get_sign({appid: 1, appkey: 1, package: 1, timestamp: 1, noncestr: 1, ret_code: 1, reterrmsg: 0})
      }
      ResponseMessage.new(hash)
    end
  end
end
