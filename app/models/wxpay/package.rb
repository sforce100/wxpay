#encoding: utf-8

# bank_type 是银行通道类型，由于这里是使用的微信公众号支付，因此这个字段固定为 WX，注意大写。参数取值："WX"。
# body 是 商品描述。参数长度：128 字节以下。
# attach 否 附加数据，原样返回。128 字节以下。
# partner 是 商户号,即注册时分配的 partnerId。
# out_trade_no 是商户系统内部的订单号,32 个字符内、可包含字母,确保在商户系统唯一。参数取值范围：32 字节以下。
# total_fee 是 订单总金额，单位为分。
# fee_type 是 现金支付币种,取值：1（人民币）,默认值是 1，暂只支持 1。
# notify_url 是 通知 URL,在支付完成后,接收微信通知支付结果的 URL,需给 绝 对 路 径 ,255 字 符 内 , 格 式如:http://wap.tenpay.com/tenpay.asp。取值范围：255 字节以内。
# spbill_create_ip 是订单生成的机器 IP，指用户浏览器端 IP，不是商户服务器IP，格式为 IPV4 整型。取值范围：15 字节以内。
# time_start 否 交 易 起 始 时 间 ， 也 是 订 单 生 成 时 间 ， 格 式 为yyyyMMddHHmmss，如 2009 年 12 月 25 日 9 点 10 分 10秒表示为 20091225091010。时区为 GMT+8 beijing。该时间取自商户服务器。取值范围：14 字节。
# time_expire 否 交 易 结 束 时 间 ， 也 是 订 单 失 效 时 间 ， 格 式 为yyyyMMddHHmmss，如 2009 年 12 月 27 日 9 点 10 分 10秒表示为 20091227091010。时区为 GMT+8 beijing。该时间取自商户服务器。取值范围：14 字节。
# transport_fee 否 物流费用，单位为分。如果有值，必须保证 transport_fee +product_fee=total_fee。
# product_fee 否 商品费用，单位为分。如果有值，必须保证 transport_fee +product_fee=total_fee。goods_tag 否 商品标记，优惠券时可能用到。
# input_charset 是 传入参数字符编码。取值范围："GBK"、"UTF-8"。默认："GBK"

require 'open-uri'

module Wxpay
  class Package
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    include ActiveModel::Validations
    include ActiveModel::Model

    define_model_callbacks :initialize, :only => :after
    
    attr_accessor :bank_type, :body, :partner, :out_trade_no, :total_fee, :notify_url, :spbill_create_ip, :input_charset
    attr_accessor :attach, :time_start, :time_expire, :transport_fee, :product_fee, :goods_tag

    validates_presence_of :bank_type, :body, :partner, :out_trade_no, :total_fee, :notify_url, :spbill_create_ip, :input_charset
    validates_length_of :body, :attach, :maximum => 128
    validates_length_of :out_trade_no, :maximum => 32
    validates_length_of :notify_url, :maximum => 255
    validates_length_of :spbill_create_ip, :maximum => 15
    validate :check_total_fee

    def initialize(attributes = {})
      super(attributes)
      run_callbacks :initialize do
        @bank_type ||= 'WX'
        @fee_type ||= 1
        @input_charset ||= 'UTF-8'
        @total_fee = @total_fee.to_f unless @total_fee.blank?
        @transport_fee = @transport_fee.to_f unless @transport_fee.blank?
        @product_fee = @product_fee.to_f unless @product_fee.blank?
      end
    end

    def to_hash_reject_blank
      JSON.parse(self.to_json).reject { |k, v| v.blank? }
    end

    def generate_sign_str
      to_hash_reject_blank.sort.map { |k, v| "#{k}=#{v}" }.join("&")
    end

    def urlencode_sign_str
      to_hash_reject_blank.sort.map { |k, v| "#{k}=#{URI::encode(v.to_s)}" }.join("&")  
    end

    private
      def check_total_fee
        errors.add(:base, "订单总价格必须大于0") if @total_fee <= 0
        total_fee_status = true
        if !@product_fee.blank? and !@transport_fee.blank?
          total_fee_status = false if @total_fee != @product_fee.to_f + @transport_fee.to_f
        elsif !@product_fee.blank?
          total_fee_status = false if @total_fee != @product_fee.to_f
        elsif !@transport_fee.blank?
          total_fee_status = false if @total_fee != @transport_fee.to_f 
        end
        errors.add(:base, "订单总价格不等于商品价格＋运费") unless total_fee_status
      end
  end
end
