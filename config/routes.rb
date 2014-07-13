Wxpay::Engine.routes.draw do
  match 'notify' => 'payment_notify#notify', via: :get
end
