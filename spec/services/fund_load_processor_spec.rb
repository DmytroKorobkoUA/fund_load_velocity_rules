# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FundLoadProcessor do
  describe '.prime?' do
    it 'returns true for prime numbers' do
      expect(described_class.prime?(2)).to be true
      expect(described_class.prime?(13)).to be true
    end

    it 'returns false for non-primes' do
      expect(described_class.prime?(4)).to be false
      expect(described_class.prime?(1)).to be false
    end
  end

  describe '.process_entry' do
    let(:customer_id) { 101 }
    let(:date) { Date.parse('2024-01-01') }
    let(:base_time) { date.to_time }

    before do
      # Cleaning before testing
      FundLoadRequest.delete_all
    end

    def entry(overrides = {})
      {
        'id' => '123',
        'customer_id' => customer_id.to_s,
        'load_amount' => '$1000.00',
        'time' => base_time.iso8601
      }.merge(overrides)
    end

    def process(entry_hash, prime_tracker = Hash.new { |h, k| h[k] = [] })
      described_class.process_entry(entry_hash, prime_tracker)
    end

    it 'accepts valid entry within daily and weekly limits' do
      result = process(entry)
      expect(result[:accepted]).to be true
    end

    it 'rejects if daily amount limit exceeded' do
      2.times do |i|
        FundLoadRequest.create!(
          load_id: 100 + i,
          customer_id: customer_id,
          load_amount: 3000.0,
          time: base_time,
          accepted: true
        )
      end

      result = process(entry('load_amount' => '$200.00'))
      expect(result[:accepted]).to be false
    end

    it 'rejects if weekly amount limit exceeded' do
      3.times do |i|
        FundLoadRequest.create!(
          load_id: 100 + i,
          customer_id: customer_id,
          load_amount: 7000.0,
          time: base_time - i.days,
          accepted: true
        )
      end

      result = process(entry('load_amount' => '$500.00'))
      expect(result[:accepted]).to be false
    end

    it 'rejects if daily load count exceeded' do
      3.times do |i|
        FundLoadRequest.create!(
          load_id: 100 + i,
          customer_id: customer_id,
          load_amount: 100.0,
          time: base_time,
          accepted: true
        )
      end

      result = process(entry('load_amount' => '$50.00'))
      expect(result[:accepted]).to be false
    end

    it 'rejects if second prime ID load in same day' do
      prime_tracker = Hash.new { |h, k| h[k] = [] }
      day = base_time.to_date
      prime_tracker[day] << 3

      result = process(entry('id' => '5'), prime_tracker)
      expect(result[:accepted]).to be false
    end

    it 'rejects if prime ID load is over 9999' do
      result = process(entry('id' => '7', 'load_amount' => '$10000.00'))
      expect(result[:accepted]).to be false
    end

    it 'doubles amount on Monday for limit checks' do
      monday_time = Time.parse('2024-05-13T10:00:00Z') # Monday
      FundLoadRequest.create!(
        load_id: 999,
        customer_id: customer_id,
        load_amount: 4000.0,
        time: monday_time,
        accepted: true
      )

      result = described_class.process_entry(
        {
          'id' => '11',
          'customer_id' => customer_id.to_s,
          'load_amount' => '$600.00',
          'time' => monday_time.iso8601
        },
        Hash.new { |h, k| h[k] = [] }
      )

      # 600 * 2 = 1200 → 4000 + 1200 = 5200 → exceeds limit
      expect(result[:accepted]).to be false
    end
  end
end
