require 'httparty'

module Wxpay
  class Api
    class << self
      def wxpay_params(config_hash, data)
        config = config_hash.with_indifferent_access
        package_str = generate_package(config, data)
        data = {
            'appid' => config[:app_id],
            'appkey' => config[:pay_sign_key],
            'noncestr' => SecureRandom.hex(16),
            'timestamp' => DateTime.now.to_i.to_s,
            'package' => package_str
        }

        pay_sign = generate_pay_sign(data)
        Rails.logger.info "package: #{package_str}"
        Rails.logger.info "pay_sign: #{pay_sign}"
        data.merge({'pay_sign' => pay_sign})
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

      private
        def generate_package config, data
          package_data = data.merge({
            'bank_type' => 'WX',
            'fee_type' => '1',
            'input_charset' => 'UTF-8'
          }).sort

          string1 = package_data.map { |k, v| "#{k}=#{v}" }.join("&")
          stringSignTemp = "#{string1}&key=#{config[:partner_key]}"
          sign = Digest::MD5.hexdigest(stringSignTemp).upcase
          string2 = package_data.map { |k, v| "#{k}=#{urlencoding(v.to_s)}" }.join("&")  
          "#{string2}&sign=#{sign}"
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
            "appid" => data[:appid],
            "openid" => data[:openid],
            "transid" => data[:transid],
            "out_trade_no" => data[:out_trade_no],
            "deliver_timestamp" => DateTime.now.to_i.to_s,
            "deliver_status" => data[:deliver_status],
            "deliver_msg" => data[:deliver_msg],
            "sign_method" => "sha1"
          }

          app_signature = generate_pay_sign(prev_data.merge("appkey" => data[:appkey]))
          prev_data.merge!({"app_signature" => app_signature})
          
          result = HTTParty.post(delivernotify_url(data[:access_token]), body: prev_data)
          result_hash = JSON.parse(result)
          p "delivernotify result: #{result}"
          raise "微信支付发货请求失败:#{result_hash['errmsg']}" if result_hash['errcode'].to_i != 0
        end 

        def delivernotify_url access_token
          "https://api.weixin.qq.com/pay/delivernotify?access_token=#{access_token}"
        end

        def update_feedback_url access_token, openid, feedbackid
          "https://api.weixin.qq.com/payfeedback/update?access_token=#{access_token}&openid=#{openid}&feedbackid=#{feedbackid}"
        end
    end
  end
end
