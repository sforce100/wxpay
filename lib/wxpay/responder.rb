require "wxpay/helpers/params_helper"

module Wxpay
  module Responder
    extend ActiveSupport::Concern
    include WxHelper::ParamsHelper

    included do 
      self.skip_before_filter :verify_authenticity_token
      self.before_filter :parse_wxpay_package, only: [:package]
      self.before_filter :parse_wxpay_notify, only: [:notify]
      self.before_filter :parse_wxpay_payfeedback, only: [:payfeedback]
      self.before_filter :parse_wxpay_warning, only: [:warning]
      self.before_filter :generate_config_data
    end
    
    module ClassMethods
      attr_accessor :wxconfig

      ['config', 'package', 'notify', 'payfeedback', 'warning'].each do |mtd|
        define_method "#{mtd}_block" do |&block|
          @wxconfig ||= {}
          @wxconfig["#{mtd}_block".to_sym] = block
        end
      end

      ['package', 'notify', 'payfeedback', 'warning'].each do |mtd|
        define_method "get_#{mtd}_data" do |post_data, params|
          'success' if @wxconfig["#{mtd}_block".to_sym].blank?
          @wxconfig["#{mtd}_block".to_sym].call(post_data, params, @wxconfig)
        end
      end

      def configuration post_data, params
        @wxconfig[:config_block].call(post_data, params, OpenStruct.new).to_h
      end

      ['package', 'notify', 'payfeedback', 'warning'].each do |type|
        define_method "#{type}_action_alias" do |mtd|
          alias mtd type.to_sym
          self.before_filter "parse_wxpay_#{type}".to_sym, only: [mtd]
        end
      end
    end

    def notify
      result = 
      if @wx_post.is_validate_sign? @config[:pay_sign_key]
        Rails.logger.info "app_signature validate"
        self.class.get_notify_data(@wx_post.get_data, params) 
      else
        Rails.logger.info "app_signature invalidate"
        'fail'
      end

      render text: result
    end

    def payfeedback
      result = 
      if @wx_post.is_validate_sign? @config[:pay_sign_key]
        Rails.logger.info "app_signature validate"
        self.class.get_payfeedback_data(@wx_post.get_data, params)
      else
        Rails.logger.info "app_signature invalidate"
        'fail'
      end

      render text: result      
    end

    def warning
      result = 
      if @wx_post.is_validate_sign? @config[:pay_sign_key]
        Rails.logger.info "app_signature validate"
        self.class.get_warning_data(@wx_post.get_data, params)
      else
        Rails.logger.info "app_signature invalidate"
        'fail'
      end

      render text: result 
    end

    def package
      @app_id = @config[:app_id]
      @app_key = @config[:pay_sign_key]
      @paterner_key = @config[:paterner_key]
      @time_stamp = DateTime.now.to_i
      @nonce_str = SecureRandom.hex 32
      if @wx_post.is_validate_sign? @app_key
        order_data = self.class.get_package_data(@wx_post.get_data)
        "app_signature invalidate"
        # 生产package
        @package = Wxpay::Native::PayPackage.new(order_data[:package]).get_package(@paterner_key)

        @pay_sign = get_sign({ appid: @app_id, appkey: @app_key, timestamp: @time_stamp, noncestr: @nonce_str, package: @package })
      end
      render xml: generate_response_message
    end

    private
      def parse_wxpay_package
        raw = request.body.read
        Rails.logger.info "package raw: #{raw}"
        @wx_post = Wxpay::PackagePostData.new(raw)
      end

      def parse_wxpay_notify
        raw = request.body.read
        Rails.logger.info "notify raw: #{raw}"
        @wx_post = Wxpay::NotifyPostData.new(raw)
      end

      def parse_wxpay_payfeedback
        raw = request.body.read
        Rails.logger.info "notify raw: #{raw}"
        @wx_post = Wxpay::PayFeedbackPostData.new(raw)
      end
      
      def parse_wxpay_warning
        raw = request.body.read
        Rails.logger.info "notify raw: #{raw}"
        @wx_post = Wxpay::WarningPostData.new(raw)
      end

      def generate_config_data
        @config = self.class.configuration(@wx_post.get_data, params)
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