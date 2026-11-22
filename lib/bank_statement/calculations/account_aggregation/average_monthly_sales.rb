# frozen_string_literal: true

module BankStatement
  module Calculations
    module AccountAggregation
      # Average monthly sales (deposits/credits) for each account.
      # Credits that are not income are excluded:
      # - "Refunds and Returns" and "Loans" categories,
      # - gambling winnings.
      # Wages are shown next to DM001 "Wages - Monthly".

      class AverageMonthlySales
        CATEGORY = "Account Aggregation"
        TITLE = "Average monthly sales (deposits/credits) for each account"

        WAGES_CATEGORY = /wages/i
        NON_SALES_CATEGORY = /\brefunds\b|\bloans\b/i # TODO: add other non-sales categories
        ILLION_MONTHLY_WAGES = "DM001"

        AccountResult = Data.define(:account, :total_credits, :months, :monthly_average)

        Result = Data.define(:accounts, :monthly_wages, :illion_monthly_wages, :transactions) do
          def category = CATEGORY
          def title = TITLE

          def render(fmt)
            rows = accounts.map do |row|
              "  #{row.account.label}: #{fmt.paint("#{fmt.money(row.monthly_average)}/month").green} " \
                "(total: #{fmt.money(row.total_credits)})"
            end

            rows << "  Wages per month: #{fmt.money(monthly_wages)} (#{fmt.illion(illion_monthly_wages)})"

            rows
          end
        end

        def initialize(statement)
          @statement = statement
        end

        def call
          credits = @statement.accounts.flat_map(&:credits)
          wages = credits.select { |tx| tx.category?(WAGES_CATEGORY) }

          Result.new(
            accounts: @statement.accounts.map { |account| account_result(account) },
            monthly_wages: BankStatement.per_month(wages.sum(&:amount), @statement.months),
            illion_monthly_wages: @statement.decision_metric(ILLION_MONTHLY_WAGES),
            transactions: wages
          )
        end

        private

        def account_result(account)
          total = account.credits.reject { |tx| non_sales?(tx) }.sum(&:amount)

          AccountResult.new(
            account: account,
            total_credits: total,
            months: account.months,
            monthly_average: BankStatement.per_month(total, account.months)
          )
        end

        def non_sales?(transaction)
          transaction.category?(NON_SALES_CATEGORY) ||
            RiskAndExpenditure::GamblingPercentage.gambling?(transaction)
          # TODO: add other non-sales checks
        end
      end
    end
  end
end
