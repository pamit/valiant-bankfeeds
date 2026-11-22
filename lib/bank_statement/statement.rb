# frozen_string_literal: true

module BankStatement
  DecisionMetric = Data.define(:id, :name, :type, :value) do
    def provided? = !value.nil?
  end

  Statement = Data.define(:accounts, :decision_metrics) do
    # Looks up a decision metric by ID e.g. "DM001"
    def decision_metric(id)
      decision_metrics.find { |metric| metric.id == id } ||
        DecisionMetric.new(id: id, name: "", type: nil, value: nil)
    end

    def months
      BankStatement.months_between(
        accounts.filter_map(&:period_start).min,
        accounts.filter_map(&:period_end).max
      )
    end
  end
end
