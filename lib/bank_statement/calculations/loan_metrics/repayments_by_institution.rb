# frozen_string_literal: true

module BankStatement
  module Calculations
    module LoanMetrics
      # Total amount repaid per identified institution. Transactions tagged with
      # "SACC Loans" and "Non SACC Loans" or whose description matches `loan` or
      # `repayment` are returned. The institution is fetched from `thirdParty`,
      # with fallback to the description.

      class RepaymentsByInstitution
        CATEGORY = "Loan Metrics (Aggregated)"
        TITLE = "Total amount repaid per identified institution"

        LOAN_CATEGORY = /loan/i
        DESCRIPTION = /\bloan?\b/i
        ILLION_MONTHLY_LOAN_DEBITS = "DM069"

        InstitutionResult = Data.define(:institution, :count, :total)

        Result = Data.define(:institutions, :monthly_repayments, :illion_monthly_loan_debits, :transactions) do
          def category = CATEGORY
          def title = TITLE
          def total = institutions.sum(&:total)

          def render(fmt)
            rows = institutions.map do |row|
              "  #{row.institution}: #{fmt.money(row.total)} (#{row.count} repayments)"
            end

            rows << "  Total: #{fmt.paint(fmt.money(total)).green}"
            rows << "  Per month: #{fmt.paint(fmt.money(monthly_repayments)).green} (#{fmt.illion(illion_monthly_loan_debits)})"

            rows
          end
        end

        def initialize(statement)
          @statement = statement
        end

        def call
          Result.new(
            institutions: institutions,
            monthly_repayments: BankStatement.per_month(repayments.sum(&:amount), @statement.months),
            illion_monthly_loan_debits: @statement.decision_metric(ILLION_MONTHLY_LOAN_DEBITS),
            transactions: repayments
          )
        end

        private

        def institutions
          repayments
            .group_by { |tx| tx.third_party || tx.description } # Fallback to description if third_party is not set
            .map { |name, txs| institution(name, txs) }
            .sort_by { |row| -row.total }
        end

        def institution(name, transactions)
          InstitutionResult.new(institution: name, count: transactions.size, total: transactions.sum(&:amount))
        end

        def repayments
          @repayments ||= @statement
                          .accounts
                          .flat_map(&:debits)
                          .select { |tx| tx.matches?(LOAN_CATEGORY, DESCRIPTION) }
        end
      end
    end
  end
end
