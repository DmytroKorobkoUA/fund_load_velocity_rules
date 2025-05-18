# frozen_string_literal: true

# Creates fund_load_requests table with load tracking fields.
class CreateFundLoadRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :fund_load_requests do |t|
      t.integer :load_id
      t.integer :customer_id
      t.decimal :load_amount
      t.datetime :time
      t.boolean :accepted, null: false, default: false

      t.timestamps
    end
  end
end
