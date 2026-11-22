# frozen_string_literal: true

module BankStatement
  class ProviderError < StandardError; end
  class UnsupportedFormat < StandardError; end

  class Parser
    def initialize(payload)
      @payload = payload
    end

    def statement
      raise ProviderError, "#{@payload['errorCode']}: #{@payload['error']}" if @payload["error"]

      Statement.new(accounts: accounts, decision_metrics: decision_metrics)
    end

    private

    def accounts
      banks.flat_map do |bank|
        bank.fetch("bankAccounts", []).map { |raw| build_account(bank, raw) }
      end
    end

    def decision_metrics
      @payload.fetch("decisionMetrics", []).map do |raw|
        # type is "integer" for DM004 (Dishonours)
        value = raw["type"] == "money" ? BigDecimal(raw["value"].to_s) : raw["value"]

        DecisionMetric.new(
          id: raw["id"],
          name: raw["name"].to_s.strip,
          type: raw["type"],
          value: value
        )
      end
    end

    def banks
      return @payload["banks"] if @payload["banks"] # Data version: 20190901

      raise UnsupportedFormat, "expected `banks` in payload (dataVersion 20190901)"
    end

    # Pending transactions are skipped in the calculations, but kept for reporting
    def build_account(bank, raw)
      pending, settled = raw
                         .fetch("transactions", [])
                         .partition { |tx| tag_values(tx, "pending").any? }

      transactions = build_transactions(settled)

      summary = raw.fetch("statementSummary", {})

      Account.new(
        id: raw["id"],
        bank_name: bank["bankName"],
        name: raw["accountName"],
        account_type: raw["accountType"],
        masked_number: mask(raw["accountNumber"]),
        period_start: parse_date(summary["searchPeriodStart"]) || transactions.first&.date,
        period_end: parse_date(summary["searchPeriodEnd"]) || transactions.last&.date,
        transactions: transactions,
        pending_transactions: build_transactions(pending)
      )
    end

    def build_transactions(raws)
      raws.map { |raw| build_transaction(raw) }.compact.sort_by(&:date)
    end

    def build_transaction(raw)
      amount = BigDecimal(raw.fetch("amount").to_s)
      credit_debit = credit_debit_for(raw, amount)
      return if credit_debit == :informational # Skip informational rows, $0 transactions

      Transaction.new(
        date: Date.iso8601(raw.fetch("date")),
        description: raw["description"].to_s.strip,
        amount: amount.abs,
        credit_debit: credit_debit,
        categories: tag_values(raw, "category"),
        third_party: tag_values(raw, "thirdParty").first
      )
    end

    def credit_debit_for(raw, amount)
      # Skip informational rows, $0 transactions
      return :informational if amount.zero? || raw["type"] == "Informational"

      tagged = tag_values(raw, "creditDebit").first
      return tagged.to_sym if %w[credit debit].include?(tagged)

      # Fallback to the sign of the amount
      amount.negative? ? :debit : :credit
    end

    # [{"category" => "Wages"}, {"creditDebit" => "credit"}, { "thirdParty" => "Woolworths" }]
    def tag_values(raw, key)
      raw.fetch("tags", []).filter_map { |tag| tag[key] }
    end

    def parse_date(value)
      value && Date.iso8601(value)
    end

    def mask(account_number)
      return "unknown" if account_number.to_s.empty?

      "***#{account_number.to_s[-4..] || account_number}"
    end
  end
end
