require "byebug"

require_relative "../lib/bank_statement"

FIXTURE_PATH = File.expand_path("../fixtures/mary_and_tom_jones.json", __dir__)

module PayloadHelpers
  def fixture_statement
    BankStatement::Parser.new(JSON.parse(File.read(FIXTURE_PATH))).statement
  end

  def statement_with(transactions)
    BankStatement::Parser.new(
      { "banks" => [{ "bankAccounts" => [{ "transactions" => transactions }] }] }
    ).statement
  end

  def tx(date, description, amount, *tags)
    { "date" => date, "description" => description, "amount" => amount, "type" => "", "tags" => tags }
  end
end

RSpec.configure do |config|
  config.include PayloadHelpers
  config.disable_monkey_patching!
  config.order = :random
end
