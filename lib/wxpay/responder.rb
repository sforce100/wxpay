require "wxpay/helpers/params_helper"

module Wxpay
  module Responder
    extend ActiveSupport::Concern
    include WxHelper::ParamsHelper

    included do 
      self.skip_before_filter :verify_authenticity_token
      self.before_filter :parse_wxpay_package, only: [:package]
      self.before_filter :parse_wxpay_notify, only: [:notify]
    end
    
    module ClassMethods
      attr_accessor :wxconfig

      ['config', 'package', 'notify'].each do |mtd|
        define_method "#{mtd}_block" do |&block|
          @wxconfig ||= {}
          @wxconfig["#{mtd}_block".to_sym] = block
        end
      end

      ['package', 'notify'].each do |mtd|
        define_method "get_#{mtd}_data" do |post_data|
          payment_data = {}
          payment_data[:config] = @wxconfig[:config_block].call(post_data, OpenStruct.new).to_h
          payment_data[mtd.to_sym] = @wxconfig["#{mtd}_block".to_sym].call(post_data, payment_data[:config], OpenStruct.new).to_h
          payment_data
        end
      end

      def package_action_alias mtd
        alias mtd :package
        self.before_filter :parse_wxpay_package, only: [mtd]
      end

      def notify_action_alias mtd
        alias mtd :notify
        self.before_filter :parse_wxpay_notify, only: [mtd]
      end
    end

    def notify
      order_data = self.class.get_notify_data(@wx_post.get_data)
      if @wx_post.is_validate_sign? @app_key
        "app_signature invalidate"
      end

      render text: 'success'
    end

    def package
      order_data = self.class.get_package_data(@wx_post.get_data)
      @app_id = order_data[:config][:app_id]
      @app_key = order_data[:config][:app_key]
      @paterner_key = order_data[:config][:paterner_key]
      @time_stamp = DateTime.now.to_i
      @nonce_str = SecureRandom.hex 32
      if @wx_post.is_validate_sign? @app_key
        "app_signature invalidate"
      end
      # 生产package
      @package = Wxpay::Native::PayPackage.new(order_data[:package]).get_package(@paterner_key)

      @pay_sign = get_sign({ appid: @app_id, appkey: @app_key, timestamp: @time_stamp, noncestr: @nonce_str, package: @package })
      
      render xml: generate_response_message
    end

    def notify
      
    end

    private
      def parse_wxpay_package
        raw = request.body.read
        @wx_post = Wxpay::PackagePostData.new(raw)
      end

      def parse_wxpay_notify
        raw = request.body.read
        @wx_post = Wxpay::PackagePostData.new(raw)
      end

      def generate_response_message
        notify_response = WxHelper::XmlHelper::ResponseMessage.new
        notify_response.app_id = @app_id
        notify_response.package = @package
        notify_response.time_stamp = @time_stamp
        notify_response.nonce_str = @nonce_str
        notify_response.ret_code = 0
        notify_response.ret_err_msg = 'ok'
        notify_response.app_signature = @pay_sign
        notify_response.to_xml
      end
  end
end