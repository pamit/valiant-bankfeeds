# frozen_string_literal: true

module BankStatement
  module Calculations
    module RiskAndExpenditure
      # Percentage of gambling as total of all expenditure for each account.
      # `category` is the main signal. The DM007 decision metric is a monthly
      # amount without transaction breakdown which is also reported.

      class GamblingPercentage
        CATEGORY = "Risk & Expenditure"
        TITLE = "Percentage of gambling as total of all expenditure"

        GAMBLING_CATEGORY = /gambling/i
        MERCHANTS = /\bsportsbet\b/i # This is a sample list, all gaming merchants should be added.
        ILLION_MONTHLY_GAMBLING = "DM007"

        Result = Data.define(
          :total_expenditure, :gambling_spend, :percentage,
          :monthly_gambling, :illion_monthly_gambling, :transactions
        ) do
          def category = CATEGORY
          def title = TITLE

          def render(fmt)
            [
              "  Total expenditure: #{fmt.money(total_expenditure)}",
              "  Gambling spend:    #{fmt.money(gambling_spend)} (#{transactions.size} transactions)",
              "  Percentage:        #{fmt.paint(fmt.percentage(percentage)).red.bright}",
              "  Gambling per month: #{fmt.money(monthly_gambling)} (#{fmt.illion(illion_monthly_gambling)})",
              transactions.map { |tx| "  - #{tx.date}\t#{fmt.money(tx.amount)}\t#{tx.description}" }
            ]
          end
        end

        def self.gambling?(transaction)
          transaction.matches?(GAMBLING_CATEGORY, MERCHANTS)
        end

        def initialize(statement)
          @statement = statement
        end

        def call
          debits = @statement.accounts.flat_map(&:debits)
          gambling = debits.select { |tx| self.class.gambling?(tx) }
          total = debits.sum(&:amount)
          spend = gambling.sum(&:amount)

          Result.new(
            total_expenditure: total,
            gambling_spend: spend,
            percentage: total.zero? ? BigDecimal(0) : (spend / total) * 100,
            monthly_gambling: BankStatement.per_month(spend, @statement.months),
            illion_monthly_gambling: @statement.decision_metric(ILLION_MONTHLY_GAMBLING),
            transactions: gambling
          )
        end
      end
    end
  end
end
