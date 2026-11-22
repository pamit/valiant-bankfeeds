# frozen_string_literal: true

module BankStatement
  # Shared text helpers for rendering results. Colour is a no-op when disabled.
  class Formatter
    def initialize(color: false)
      @rainbow = Rainbow::Wrapper.new(color)
    end

    def paint(text) = @rainbow.wrap(text)

    def money(amount) = "$#{format('%.2f', amount)}"

    def percentage(value) = "#{format('%.2f', value)}%"

    def illion(metric)
      return paint("illion #{metric.id}: not provided").faint unless metric.provided?

      # DM004 (Dishonours) is an integer
      value = metric.type == "money" ? money(metric.value) : metric.value

      paint("illion: #{metric.id} #{metric.name}: #{value}").yellow
    end
  end
end
