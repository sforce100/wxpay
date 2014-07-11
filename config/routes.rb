Wxpay::Engine.routes.draw do
  match 'package' => 'payment_notify#package', via: :post
end
