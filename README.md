# Fund Load Processor

A service that validates and adjudicates incoming fund load requests (`input.txt`) against business rules such as **velocity limits** and **special sanctions**, and writes decisions to `output.txt`.

Built with **Ruby 3.3.3**, **Rails 7.1.5**, and **PostgreSQL**.

---

## Features

- Daily, weekly, and per-day load count limits
- Prime ID restriction (across all users)
- Monday multiplier rule
- JSON file input/output interface
- Robust test suite (RSpec)
- Code linting (RuboCop)

---

## Setup

### 1. Clone the repository and install dependencies

```bash
git clone git@github.com:DmytroKorobkoUA/fund_load_velocity_rules.git
cd fund_load_velocity_rules
bundle install
```

### 2. Configure your environment
Copy .env.example to .env and fill in your PostgreSQL credentials:
```bash
DEV_TEST_DB_USERNAME=your_dev_test_db_username
DEV_TEST_DB_PASSWORD=your_dev_test_db_password
PROD_DB_USERNAME=your_prod_db_username
PROD_DB_PASSWORD=your_prod_db_password
```

### 3. Create and migrate the database
```bash
rails db:create db:migrate
```

## Run the processor
Place your `input.txt` file in the project root, then run:

```bash
rails runner 'FundLoadProcessor.run'
```

## Sample `input.txt`
```bash
{"id":"15887","customer_id":"528","load_amount":"$3318.47","time":"2000-01-01T00:00:00Z"}
{"id":"30081","customer_id":"154","load_amount":"$1413.18","time":"2000-01-01T01:01:22Z"}
{"id":"26540","customer_id":"426","load_amount":"$404.56","time":"2000-01-01T02:02:44Z"}
{"id":"10694","customer_id":"1","load_amount":"$785.11","time":"2000-01-01T03:04:06Z"}
{"id":"15089","customer_id":"205","load_amount":"$2247.28","time":"2000-01-01T04:05:28Z"}
{"id":"3211","customer_id":"409","load_amount":"$314.45","time":"2000-01-01T05:06:50Z"}
{"id":"27106","customer_id":"630","load_amount":"$1404.95","time":"2000-01-01T06:08:12Z"}
```

The output will be written to `output.txt`.

## Business Rules
### Velocity Limits
```bash
Type	        | Rule
Daily Limit	| Max $5,000 per customer per day
Weekly Limit	| Max $20,000 per customer per week
Daily Count	| Max 3 loads per customer per day
```

### Special Sanctions
```bash
Condition	| Rule
Prime ID	| Only one prime id load per day across all customers, and must be <= $9,999
Mondays	        | Loads on Mondays count as double their value for limit checking
```

## Running Tests

This project uses RSpec for testing:
```bash
bundle exec rspec
```

Fixtures are located in `spec/fixtures/input.txt`.

## Code Style
We use RuboCop for static code analysis.

To check code style:
```bash
bundle exec rubocop
```

To auto-correct offenses:
```bash
bundle exec rubocop -A
```

## Sample `output.txt`
```bash
{"id":"15337","customer_id":"999","accepted":false}
{"id":"34781","customer_id":"343","accepted":true}
{"id":"26440","customer_id":"222","accepted":true}
{"id":"12394","customer_id":"133","accepted":false}
{"id":"15689","customer_id":"445","accepted":true}
{"id":"32551","customer_id":"264","accepted":true}
{"id":"27446","customer_id":"328","accepted":true}
```

## Tech Stack
```bash
Ruby 3.3.3
Rails 7.1.5.1
PostgreSQL
RSpec (testing)
RuboCop (linting)
```

## Notes
- Input file must follow single-line JSON format as per the challenge specification.
- This service assumes well-formed JSON input and valid time formats.
- Load results are persisted in the database for audit purposes.