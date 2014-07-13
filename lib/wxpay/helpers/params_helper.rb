require 'digest'

module WxHelper
  module ParamsHelper
    def get_timestamp
      DateTime.now.to_i
    end

    def get_noncestr
      SecureRandom.hex 32
    end

    def get_sign sign_hash
      keyvaluestring = sign_hash.sort.map { |k, v| "#{k}=#{v}" }.join("&")
      Digest::SHA1.hexdigest keyvaluestring
    end

  end
end