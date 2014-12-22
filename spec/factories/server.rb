require 'ipaddr'

FactoryGirl.define do

  factory :server do
    addresses { IPAddr.new(rand(2**32),Socket::AF_INET) }
  end

end
