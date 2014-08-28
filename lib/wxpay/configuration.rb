module Wxpay
  class << self
    attr_accessor :configuration

    def config
      self.configuration ||= Configuration.new
    end

    def configure
      yield config if block_given?
    end
  end

  class Configuration
    attr_accessor  :app_id, :app_secret, :pay_sign_key, :partner_id, :partner_key
    attr_accessor  :is_multi, :custom_config

    def initialize
      @is_multi = false
    end

    def setup_config *args
      custom_config.call(args) if is_multi
    end
  end
end