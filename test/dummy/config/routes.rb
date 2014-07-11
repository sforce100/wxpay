Rails.application.routes.draw do

  mount Wxpay::Engine => "/wxpay"
end
