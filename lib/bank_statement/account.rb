# frozen_string_literal: true

module BankStatement
  Account = Data.define(
    :id, :bank_name, :name, :account_type, :masked_number,
    :period_start, :period_end, :transactions, :pending_transactions
  ) do
    def label = "#{bank_name} #{name} (#{masked_number})"
    def credits = transactions.select(&:credit?)
    def debits = transactions.select(&:debit?)
    def months = BankStatement.months_between(period_start, period_end)
  end
end
