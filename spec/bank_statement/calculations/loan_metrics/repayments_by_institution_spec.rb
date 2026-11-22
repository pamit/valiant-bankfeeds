RSpec.describe BankStatement::Calculations::LoanMetrics::RepaymentsByInstitution do
  subject(:result) { described_class.new(statement).call }

  context "with the sample" do
    let(:statement) { fixture_statement }

    it "totals loan debits per illion thirdParty, largest first" do
      expect(result.institutions.map { |row| [row.institution, row.total] })
        .to eq(
          [
            ["Loan Repayment Debit", BigDecimal("4054.09")],
            ["Ferratum", BigDecimal("1521.41")],
            ["Sunshine Loans", BigDecimal("1136.94")],
            ["Good To Go", BigDecimal("902.37")],
            ["MoneyMe", BigDecimal("153.30")]
          ]
        )
    end

    it "ignores loan advances and reports per month next to illion's DM069" do
      expect(result.total).to eq(BigDecimal("7768.11"))
      expect(result.monthly_repayments.round(2)).to eq(BigDecimal("2533.08"))
      expect(result.illion_monthly_loan_debits.value).to eq(BigDecimal("2656.01"))
    end
  end

  context "with an untagged repayment" do
    let(:statement) do
      statement_with(
        [
          tx("2022-01-01", "ACME LOAN REPAYMENT", -120, { "creditDebit" => "debit" }),
          tx("2022-01-02", "GROCERIES", -40, { "creditDebit" => "debit" })
        ]
      )
    end

    it "matches the description and groups by it" do
      expect(result.institutions.map(&:institution)).to eq(["ACME LOAN REPAYMENT"])
      expect(result.illion_monthly_loan_debits).not_to be_provided
    end
  end
end
