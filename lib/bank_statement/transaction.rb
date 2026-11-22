# frozen_string_literal: true

module BankStatement
  Transaction = Data.define(
    :date, :description, :amount, :credit_debit, :categories, :third_party
  ) do
    def credit? = credit_debit == :credit
    def debit? = credit_debit == :debit

    def category?(pattern)
      categories.any? { |category| category.match?(pattern) }
    end

    # Check for a match in the category tag or description.
    def matches?(category_pattern, description_pattern)
      category?(category_pattern) || description.match?(description_pattern)
    end
  end
end
