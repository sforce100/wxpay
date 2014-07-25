module Wxpay
  class Api
    class << self
      def wxpay_params(config, data)
        package_str = generate_package(config, data)
        data = {
            'appid' => config[:app_id],
            'appkey' => config[:pay_sign_key],
            'noncestr' => SecureRandom.hex(16),
            'timestamp' => DateTime.now.to_i.to_s,
            'package' => package_str
        }

        string1 = data.sort.map { |k, v| "#{k}=#{v}" }.join("&")
        pay_sign = Digest::SHA1.hexdigest string1
        Rails.logger.info "package: #{package_str}"
        Rails.logger.info "pay_sign: #{pay_sign}"
        data.merge({'pay_sign' => pay_sign})
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

    end
  end
end
