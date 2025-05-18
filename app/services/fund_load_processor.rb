# frozen_string_literal: true

require 'json'
require 'date'

# FundLoadProcessor is a service responsible for processing incoming fund load requests
# from a text file (`input.txt`), evaluating them against business rules such as
# velocity limits and special conditions, and writing the results to `output.txt`.
class FundLoadProcessor
  DAILY_LIMIT = 5000.0
  WEEKLY_LIMIT = 20_000.0
  MAX_LOADS_PER_DAY = 3
  PRIME_MAX = 9_999.0

  # Runs the fund load processing.
  #
  # @param input_path [String] the path to the input file
  # @param output_path [String] the path to the output file
  #
  # @return [void]
  def self.run(input_path: 'input.txt', output_path: 'output.txt')
    loads = File.readlines(input_path).map { |line| JSON.parse(line.strip) }

    results = []
    prime_tracker = Hash.new { |h, k| h[k] = [] } # Tracks prime ID loads per day

    loads.each do |entry|
      result = process_entry(entry, prime_tracker)
      results << result
      Rails.logger.debug result.to_json
    end

    File.open(output_path, 'w') do |file|
      results.each { |r| file.puts r.to_json }
    end
  end

  # Processes a single fund load request entry.
  #
  # @param entry [Hash] JSON-parsed input line representing a fund load request
  # @param prime_tracker [Hash{Date => Array<Integer>}] tracks prime ID loads per day
  #
  # @return [Hash] output hash with `id`, `customer_id`, and `accepted`
  def self.process_entry(entry, prime_tracker)
    id = entry['id'].to_i
    customer_id = entry['customer_id'].to_i
    amount = entry['load_amount'].delete('$').to_f
    time = DateTime.parse(entry['time'])

    accepted = accepted?(id: id, customer_id: customer_id, amount: amount, time: time, prime_tracker: prime_tracker)

    FundLoadRequest.create!(
      load_id: id,
      customer_id: customer_id,
      load_amount: amount,
      time: time,
      accepted: accepted
    )

    {
      id: entry['id'],
      customer_id: entry['customer_id'],
      accepted: accepted
    }
  end

  # Evaluates whether the entry passes all business rules.
  #
  # @param id [Integer] Load ID
  # @param customer_id [Integer] Customer ID
  # @param amount [Float] Load amount
  # @param time [DateTime] Load timestamp
  # @param prime_tracker [Hash{Date => Array<Integer>}] tracks prime ID loads per day
  #
  # @return [Boolean] true if accepted, false otherwise
  def self.accepted?(id:, customer_id:, amount:, time:, prime_tracker:)
    day = time.to_date
    effective_amount = amount * (time.wday == 1 ? 2 : 1)

    return false if prime_violation?(id, amount, day, prime_tracker)

    customer_loads = FundLoadRequest.where(customer_id: customer_id)

    return false if exceeds_daily_limit?(customer_loads, day, effective_amount)
    return false if exceeds_daily_count?(customer_loads, day)
    return false if exceeds_weekly_limit?(customer_loads, day, effective_amount)

    true
  end

  # Determines if a given number is prime.
  #
  # @param number [Integer] the number to check
  #
  # @return [Boolean] true if prime, false otherwise
  def self.prime?(number)
    return false if number <= 1

    (2..Math.sqrt(number)).none? { |i| (number % i).zero? }
  end

  private_class_method def self.prime_violation?(id, amount, day, prime_tracker)
    return false unless prime?(id)

    prime_tracker[day] << id
    prime_tracker[day].size > 1 || amount > PRIME_MAX
  end

  private_class_method def self.exceeds_daily_limit?(customer_loads, day, amount)
    daily_total = customer_loads.where(time: day.all_day).sum(:load_amount)
    (daily_total + amount) > DAILY_LIMIT
  end

  private_class_method def self.exceeds_daily_count?(customer_loads, day)
    daily_count = customer_loads.where(time: day.all_day).count
    daily_count >= MAX_LOADS_PER_DAY
  end

  private_class_method def self.exceeds_weekly_limit?(customer_loads, day, amount)
    week_start = day - day.wday
    range = week_start.beginning_of_day..(week_start + 6).end_of_day
    weekly_total = customer_loads.where(time: range).sum(:load_amount)
    (weekly_total + amount) > WEEKLY_LIMIT
  end
end
