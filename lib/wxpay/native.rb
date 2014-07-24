# require "app/models/wxpay/package"
require 'digest'

module Wxpay
  module Native

    class << self
      # 生成支付url
      def pay_url data_hash
        "weixin://wxpay/bizpayurl?sign=#{get_pay_sign(data_hash)}&appid=#{data_hash[:appid]}&productid=#{data_hash[:productid]}&timestamp=#{data_hash[:timestamp]}&noncestr=#{data_hash[:noncestr]}"
      end

      # 生成签名
      # appid、timestnamp、noncestr、productid 以及 appkey。
      def get_pay_sign data_hash
        keyvaluestring = data_hash.sort.map { |k, v| "#{k}=#{v}" }.join("&")
        Digest::SHA1.hexdigest keyvaluestring
      end

      def delivernotify access_token
        
      end
    end

    class PayPackage
      attr_accessor :package, :sign_str, :sign_str_final, :sign_val

      def initialize(attributes = {})
        @package = Wxpay::Package.new(attributes)
      end

      def get_package paterner_key
        return @errors if @package.invalid?
        @sign_str = @package.generate_sign_str
        get_sign_val paterner_key
        @sign_val = Digest::MD5.hexdigest(@sign_str_final).upcase
        "#{@package.urlencode_sign_str}&sign=#{@sign_val}"
      end

      def get_sign_val paterner_key
        @sign_str_final ||= "#{@sign_str}&key=#{paterner_key}"
      end
    end   
  end
end