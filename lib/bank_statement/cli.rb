# frozen_string_literal: true

require "thor"
require_relative "../bank_statement"

module BankStatement
  class CLI < Thor
    namespace "statement"

    def self.exit_on_failure? = true

    desc "analyse PATH", "Analyse a BankFeeds customer data JSON file"
    method_option :output, default: "analysis.txt", desc: "Plain-text copy of the report, overwritten on each run"
    def analyse(path)
      report = BankStatement.analyse(JSON.parse(File.read(path)))

      puts report.render(color: $stdout.tty?)

      File.write(options[:output], report.render)

      puts "\nReport written to #{options[:output]}"
    rescue ProviderError, UnsupportedFormat, JSON::ParserError, Errno::ENOENT => e
      raise Thor::Error, "error: #{e.message}"
    end
  end
end
