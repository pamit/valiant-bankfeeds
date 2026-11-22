# frozen_string_literal: true

require "bigdecimal"
require "date"
require "json"
require "rainbow"

require_relative "bank_statement/transaction"
require_relative "bank_statement/account"
require_relative "bank_statement/statement"
require_relative "bank_statement/parser"
require_relative "bank_statement/formatter"
require_relative "bank_statement/calculations/account_aggregation/average_monthly_sales"
require_relative "bank_statement/calculations/risk_and_expenditure/gambling_percentage"
require_relative "bank_statement/calculations/loan_metrics/repayments_by_institution"
require_relative "bank_statement/report"

module BankStatement
  DAYS_PER_MONTH = 30

  CALCULATIONS = [
    Calculations::AccountAggregation::AverageMonthlySales,
    Calculations::LoanMetrics::RepaymentsByInstitution,
    Calculations::RiskAndExpenditure::GamblingPercentage
  ].freeze

  def self.analyse(payload)
    statement = Parser.new(payload).statement
    results = CALCULATIONS.map { |calculation| calculation.new(statement).call }
    Report.new(statement, results)
  end

  # Calculates the number of months between two dates (e.g. 2025-01-02 and 2025-04-03)
  # Returns BigDecimal for monetary calculations
  def self.months_between(start_date, end_date)
    return BigDecimal(0) unless start_date && end_date

    days = (end_date - start_date).to_i + 1 # Includes both start and end dates

    [BigDecimal(days) / DAYS_PER_MONTH, BigDecimal(1)].max # Floors at one month
  end

  def self.per_month(amount, months)
    months.zero? ? BigDecimal(0) : amount / months
  end
end
