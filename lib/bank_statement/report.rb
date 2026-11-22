# frozen_string_literal: true

module BankStatement
  # Lays out the report; each calculation result renders its own section.
  class Report
    def initialize(statement, calculation_results)
      @accounts = statement.accounts
      @results = calculation_results
    end

    def render(color: false)
      fmt = Formatter.new(color: color)

      groups = @results.group_by(&:category).map do |category, results|
        [
          fmt.paint("# Category: #{category}").cyan.bright,
          results.map { |result| category_section(result, fmt) }
        ].join("\n\n")
      end

      "#{[header(fmt), groups, pending_section(fmt)].join("\n\n")}\n"
    end

    private

    # Prints the analysed accounts and their transaction counts
    def header(fmt)
      lines = @accounts.map do |account|
        "- #{account.label}: #{account.transactions.size} transactions " \
          "(#{account.pending_transactions.size} pending), " \
          "#{account.period_start} to #{account.period_end}"
      end

      [
        fmt.paint("Accounts analysed:").bright.underline,
        lines
      ].join("\n")
    end

    def category_section(result, fmt)
      [
        fmt.paint("* #{result.title}").bright,
        result.render(fmt)
      ].join("\n")
    end

    def pending_section(fmt)
      rows = @accounts.reject { |account| account.pending_transactions.empty? }.map do |account|
        "- #{account.label}: #{account.pending_transactions.size} pending"
      end

      [
        fmt.paint("# Category: Pending transactions\n").cyan.bright,
        rows
      ].join("\n")
    end
  end
end
