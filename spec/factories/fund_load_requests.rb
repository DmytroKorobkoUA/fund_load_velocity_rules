# frozen_string_literal: true

FactoryBot.define do
  factory :fund_load_request do
    load_id { 1 }
    customer_id { 1 }
    load_amount { '9.99' }
    time { '2025-05-18 16:33:37' }
    accepted { false }
  end
end
