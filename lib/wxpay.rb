require "wxpay/engine"
require "wxpay/helpers/params_helper"
require "wxpay/helpers/xml_helper"
require "wxpay/post_data"
require "wxpay/native"
require "wxpay/responder"
require "wxpay/api"

module Wxpay

end

if defined? ActionController::Base
  class ActionController::Base
    def self.wechat_responder opts={}
      self.send(:include, Wxpay::Responder)
      package_action_alias(opts[:action_package].to_sym) unless opts[:action_package].blank?
      notify_action_alias(opts[:action_notify].to_sym) unless opts[:action_notify].blank?
    end
  end
end