require_dependency "wxpay/application_controller"

module Wxpay
  class PaymentNotifyController < ApplicationController
    def notify
      
    end

    def package
      
    end

    private
      def generate_weixin_pay_url
        "weixin://wxpay/bizpayurl?sign=XXXXX&appid=XXXXXX&productid=order_id&timestamp=XXXXXX&noncestr=XXXXXX"
      end
  end
end
