RSpec.describe BankStatement::Calculations::RiskAndExpenditure::GamblingPercentage do
  subject(:result) { described_class.new(statement).call }

  context "with the sample" do
    let(:statement) { fixture_statement }

    it "counts debits illion tagged Gambling, ignoring winnings" do
      expect(result.transactions.map(&:description).uniq).to eq(["Money to Crownbet"])
      expect(result.gambling_spend).to eq(BigDecimal("1385.26"))
    end

    it "computes the share of expenditure" do
      expect(result.percentage.round(2)).to eq(BigDecimal("7.67"))
    end

    it "reports gambling per month next to illion's DM007" do
      expect(result.monthly_gambling.round(2)).to eq(BigDecimal("451.72"))
      expect(result.illion_monthly_gambling.value).to eq(BigDecimal("944.50"))
    end
  end

  context "with untagged debits" do
    let(:statement) do
      statement_with(
        [
          tx("2022-01-01", "Sportsbet", -50, { "creditDebit" => "debit" }),
          # `Bet365` is not listed in GamblingPercentage::MERCHANTS yet
          tx("2022-01-02", "Bet365", -25, { "creditDebit" => "debit" }),
          tx("2022-01-04", "Groceries", -25, { "creditDebit" => "debit" })
        ]
      )
    end

    it "reports gambling spend" do
      expect(result.gambling_spend).to eq(BigDecimal("50"))
      expect(result.percentage).to eq(BigDecimal("50"))
      expect(result.illion_monthly_gambling).not_to be_provided
    end
  end
end
