require 'httparty'

module Wxpay
  class Api
    class << self
      def wxpay_params(data)
        # config = config_hash.with_indifferent_access
        package_str = wxpay_package(data)
        js_data = {
            'appid' => Wxpay.config.app_id,
            'appkey' => Wxpay.config.pay_sign_key,
            'noncestr' => SecureRandom.hex(16),
            'timestamp' => DateTime.now.to_i.to_s,
            'package' => package_str
        }

        pay_sign = generate_pay_sign(js_data)
        Rails.logger.info "package: #{package_str}"
        Rails.logger.info "pay_sign: #{pay_sign}"
        js_data.merge({'pay_sign' => pay_sign})
      end

      # params: appid、appkey、openid、transid、out_trade_no、access_token
      #         deliver_timestamp、deliver_status、deliver_msg
      def send_delivernotify data
        data.merge!({"deliver_status" => "1", "deliver_msg" => "ok"})
        delivernotify(data)
      end

      def cancel_delivernotify data
        data.merge!({"deliver_status" => "0", "deliver_msg" => data[:deliver_msg]})
        delivernotify(data)
      end

      def update_feedback data
        result = HTTParty.get(update_feedback_url(data.access_token, data.openid, data.feedbackid))
        result_hash = JSON.parse(result)
        p "delivernotify result: #{result}"
        raise "微信支付发货请求失败:#{result_hash['errmsg']}" if result_hash['errcode'].to_i != 0
      end

      def orderquery data
        prev_data = {
          "appid" => Wxpay.config.appid,
          "timestamp" => DateTime.now.to_i.to_s,
          "sign_method" => "sha1",
          "package" => orderquery_package(Wxpay.config.partner_key, Wxpay.config.partner_id, data[:out_trade_no])
        }
        prev_data.merge!({"app_signature" => generate_pay_sign({"appid" => Wxpay.config.app_id, "appkey" => Wxpay.config.pay_sign_key, "timestamp" => prev_data["timestamp"], "package" => prev_data["package"]})})

        wx_post_request(orderquery_url(data[:access_token]), prev_data)
      end

      private
        def generate_package(package_data, partner_key)
          string1 = package_data.map { |k, v| "#{k}=#{v}" }.join("&")
          stringSignTemp = "#{string1}&key=#{partner_key}"
          sign = Digest::MD5.hexdigest(stringSignTemp).upcase
          string2 = package_data.map { |k, v| "#{k}=#{urlencoding(v.to_s)}" }.join("&")  
          "#{string2}&sign=#{sign}"
        end

        def wxpay_package(data)
          package_data = data.merge({
            'partner' => Wxpay.config.partner_id,
            'bank_type' => 'WX',
            'fee_type' => '1',
            'input_charset' => 'UTF-8'
          }).sort

          generate_package(package_data, Wxpay.config.partner_key)
        end

        def orderquery_package(out_trade_no)
          package_data = { "out_trade_no" => out_trade_no, "partner" => Wxpay.config.partner_id }
          generate_package(package_data, Wxpay.config.partner_key)
        end

        def urlencoding str
          URI.encode_www_form_component(str).gsub("+", "%20")
        end

        def generate_pay_sign hash
          params_str = hash.sort.map { |k, v| "#{k}=#{v}" }.join("&")
          Digest::SHA1.hexdigest params_str
        end

        def delivernotify data
          prev_data = {
            "appid" => Wxpay.config.app_id,
            "openid" => data[:openid],
            "transid" => data[:transid],
            "out_trade_no" => data[:out_trade_no],
            "deliver_timestamp" => DateTime.now.to_i.to_s,
            "deliver_status" => data[:deliver_status],
            "deliver_msg" => data[:deliver_msg]
          }
          app_signature = generate_pay_sign(prev_data.merge("appkey" => Wxpay.config.pay_sign_key))
          prev_data.merge!({ "app_signature" => app_signature, "sign_method" => "sha1" })
          
          wx_post_request(delivernotify_url(data[:access_token]), prev_data)
        end 

        def wx_post_request(url, post_data)
          result = HTTParty.post(url, body: post_data)
          result_hash = JSON.parse(result)
          p "delivernotify result: #{result}"
          raise "微信支付发货请求失败:#{result_hash['errmsg']}" if result_hash['errcode'].to_i != 0
          result_hash
        end

        def delivernotify_url access_token
          "https://api.weixin.qq.com/pay/delivernotify?access_token=#{access_token}"
        end

        def update_feedback_url access_token, openid, feedbackid
          "https://api.weixin.qq.com/payfeedback/update?access_token=#{access_token}&openid=#{openid}&feedbackid=#{feedbackid}"
        end

        def orderquery_url access_token
          "https://api.weixin.qq.com/pay/orderquery?access_token=#{access_token}"
        end
    end
  end
end
