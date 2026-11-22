require "tmpdir"
require_relative "../../lib/bank_statement/cli"

RSpec.describe BankStatement::CLI do
  describe "analyse" do
    around do |example|
      Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
    end

    it "prints every calculation" do
      expect { described_class.start(["analyse", FIXTURE_PATH]) }
        .to output(
          a_string_including(
            "# Category: Account Aggregation",
            "# Category: Risk & Expenditure",
            "# Category: Loan Metrics (Aggregated)",
            "illion: DM007 Gambling Expenditure",
            "# Category: Pending transactions"
          )
        ).to_stdout
    end

    it "overwrites analysis.txt with the report" do
      File.write("analysis.txt", "stale")

      expect { described_class.start(["analyse", FIXTURE_PATH]) }.to output(/written to analysis.txt/).to_stdout
      expect(File.read("analysis.txt")).to start_with("Accounts analysed:")
      expect(File.read("analysis.txt")).not_to include("\e[")
    end

    it "writes to the --output path" do
      expect { described_class.start(["analyse", FIXTURE_PATH, "--output", "report.txt"]) }.to output.to_stdout
      expect(File).to exist("report.txt")
    end

    it "exits non-zero with a readable error for a missing file" do
      expect { described_class.start(["analyse", "missing.json"]) }
        .to raise_error(SystemExit)
        .and output(/error: No such file/).to_stderr
    end
  end
end
