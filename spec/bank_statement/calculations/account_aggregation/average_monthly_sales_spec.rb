RSpec.describe BankStatement::Calculations::AccountAggregation::AverageMonthlySales do
  subject(:result) { described_class.new(statement).call }

  context "with the sample" do
    let(:statement) { fixture_statement }

    it "averages sales per account over the search period" do
      expect(result.accounts.map { |row| row.monthly_average.round(2) })
        .to eq([BigDecimal("938.26"), BigDecimal("2075.87"), BigDecimal("699.91")])
    end

    it "reports wages per month next to illion's DM001" do
      expect(result.monthly_wages.round(2)).to eq(BigDecimal("616.10"))
      expect(result.illion_monthly_wages.value).to eq(BigDecimal("718.78"))
    end
  end

  context "with credits that are not sales" do
    let(:statement) do
      statement_with(
        [
          tx("2022-01-01", "Wages", 1000, { "category" => "Wages" }, { "creditDebit" => "credit" }),
          tx("2022-01-02", "Salary", 500, { "creditDebit" => "credit" }), # No `Salary` in BankFeeds data
          tx("2022-01-03", "Misc", 400, { "category" => "Non SACC Loans" }, { "creditDebit" => "credit" }),
          tx("2022-01-04", "Misc", 300, { "category" => "Refunds and Returns" }, { "creditDebit" => "credit" }),
          tx("2022-01-06", "Sportsbet", 150, { "creditDebit" => "credit" })
        ]
      )
    end

    it "excludes loan and refund categories, keeping untagged credits as sales" do
      expect(result.accounts.first.total_credits).to eq(BigDecimal("1500"))
    end

    it "counts only Wages-tagged credits as wages and floors the period at one month" do
      expect(result.monthly_wages).to eq(BigDecimal("1000"))
      expect(result.illion_monthly_wages).not_to be_provided
    end
  end
end
