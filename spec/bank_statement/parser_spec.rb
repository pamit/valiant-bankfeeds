RSpec.describe BankStatement::Parser do
  describe "#statement" do
    context "with the dataVersion 20190901 sample" do
      subject(:statement) { fixture_statement }

      it "reads every account, skipping pending and informational rows" do
        transaction_account = statement.accounts.first

        expect(statement.accounts.map(&:name)).to eq(["Transaction Account", "Savings Account", "Credit Card"])
        expect(transaction_account.transactions.size).to eq(51)
        expect(transaction_account.masked_number).to eq("***6789")
        expect(transaction_account.period_start).to eq(Date.new(2025, 1, 2))
      end

      it "keeps each account's pending transactions" do
        expect(statement.accounts.map { |account| account.pending_transactions.size }).to eq([2, 6, 3])
      end

      it "parses decision metrics, converting money values to BigDecimal" do
        expect(statement.decision_metric("DM007")).to have_attributes(
          name: "Gambling Expenditure - Monthly", type: "money", value: BigDecimal("944.50")
        )
        expect(statement.decision_metric("DM004").value).to eq(0)
      end
    end

    it "stores the description and a positive BigDecimal amount" do
      sample_transaction = tx("2022-01-01", " Coffee ", -4.5, { "creditDebit" => "debit" })
      statement = statement_with([sample_transaction])

      expect(statement.accounts.first.transactions.first)
        .to have_attributes(description: "Coffee", amount: BigDecimal("4.5"), credit_debit: :debit)
    end

    it "keeps pending transactions apart from the calculated ones" do
      sample_transaction = tx("2022-01-01", "Visa Pending: EFTPOS WOOLWORTHS 1111DATETEST WA AU", -10,
                              { "pending" => "pending" })
      statement = statement_with([sample_transaction])
      account = statement.accounts.first

      expect(account.transactions).to be_empty
      expect(account.pending_transactions.map(&:description))
        .to eq(["Visa Pending: EFTPOS WOOLWORTHS 1111DATETEST WA AU"])
    end

    it "uses the creditDebit tag over the sign of amount" do
      sample_transaction = tx("2022-01-01", "Refunds and Returns", -10, { "creditDebit" => "credit" })
      statement = statement_with([sample_transaction])

      expect(statement.accounts.first.transactions.first.credit_debit).to eq(:credit)
    end

    it "falls back to the sign of amount without a creditDebit tag" do
      statement = statement_with([tx("2022-01-01", "X", -10), tx("2022-01-02", "Y", 10)])

      expect(statement.accounts.first.transactions.map(&:credit_debit)).to eq(%i[debit credit])
    end

    it "raises ProviderError for an illion error payload" do
      payload = {
        "error" => "The provided callback URL is not allowed; callback URLs must be whitelisted.",
        "errorCode" => 30_203
      }

      expect { described_class.new(payload).statement }
        .to raise_error(BankStatement::ProviderError, /30203/)
    end

    it "raises UnsupportedFormat when there is no bank data" do
      expect { described_class.new({}).statement }.to raise_error(BankStatement::UnsupportedFormat)
    end

    it "raises UnsupportedFormat for the older 20170401 bankData shape" do
      expect { described_class.new({ "bankData" => { "bankAccounts" => [] } }).statement }
        .to raise_error(BankStatement::UnsupportedFormat, /20190901/)
    end
  end
end
