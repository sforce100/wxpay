require 'httparty'

module Wxpay
  class Api
    class << self
      def wxpay_params(config, data)
        config = config.with_indifferent_access
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
      end

      def cancel_delivernotify data
        data.merge!({"deliver_status" => "0", "deliver_msg" => data[:deliver_msg]})
      end

      private
        def generate_package config, data
          package_data = {
            'bank_type' => 'WX',
            'body' => data[:body],
            'fee_type' => '1',
            'input_charset' => 'UTF-8',
            'notify_url' => data[:notify_url],
            'out_trade_no' => data[:out_trade_no],
            'partner' => config[:partner_id],
            'spbill_create_ip' => data[:spbill_create_ip],
            'total_fee' => data[:total_fee]
          }.sort

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
          raise "微信支付发货请求失败:#{result['errmsg']}" if result['errcode'].to_i != 0
        end 

        def delivernotify_url access_token
          "https://api.weixin.qq.com/pay/delivernotify?access_token=#{access_token}"
        end
    end
  end
end
