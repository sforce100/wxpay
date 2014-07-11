require 'digest'

module Wxpay
  module ParamsHelper
    def get_timestamp
      DateTime.now.to_i
    end

    def get_noncestr
      SecureRandom.hex 32
    end

    def get_sign sign_hash
      keyvaluestring = sign_hash.sort.map { |k, v| "#{k}=#{v}" }.join("&")
      Digest::SHA1.dexdigest keyvaluestring
    end

    def get_package order_hash
      package_hash = order_hash.merge({bank_type: 'WX'})
      package_str = 
    end
  end
end