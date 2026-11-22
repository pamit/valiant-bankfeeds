RSpec.describe BankStatement::Report do
  def report_for(statement)
    described_class.new(
      statement,
      BankStatement::CALCULATIONS.map { |calculation| calculation.new(statement).call }
    )
  end

  context "with the sample" do
    subject(:output) { report_for(fixture_statement).render }

    it "starts with a header listing each account" do
      expect(output).to start_with("Accounts analysed:\n")
      expect(output).to include("Bank of Statements Savings Account (***5315): 73 transactions (6 pending)")
    end

    it "groups sections under the required categories" do
      headings = output.lines.grep(/^# /).map(&:strip)

      expect(headings).to eq(
        [
          "# Category: Account Aggregation",
          "# Category: Loan Metrics (Aggregated)",
          "# Category: Risk & Expenditure",
          "# Category: Pending transactions"
        ]
      )
    end

    it "formats money with two decimals" do
      expect(output).to include("Gambling spend:    $1385.26 (5 transactions)")
    end

    # it "prints illion's metrics next to our metrics" do
    #   expect(output).to include("(illion: DM004 Number of Dishonours: 0)")
    # end

    it "lists only a pending count per account" do
      expect(output.lines.map(&:strip)).to include(
        "# Category: Pending transactions",
        "- Bank of Statements Transaction Account (***6789): 2 pending",
        "- Bank of Statements Savings Account (***5315): 6 pending",
        "- Bank of Statements Credit Card (***7654): 3 pending"
      )
    end
  end

  context "without pending transactions or decision metrics" do
    subject(:output) { report_for(statement_with([tx("2022-01-01", "SALARY", 100)])).render }

    it "says there are no pending transactions" do
      expect(output.strip).to end_with("# Category: Pending transactions")
    end
  end
end
