require 'spec_helper'

support :input_helpers
support :adaptor_helpers
support :quickbooks_helpers

RSpec.describe 'quickbooks_online/payments/create', type: :feature do
  include InputHelpers
  include AdaptorHelpers
  include QuickBooksHelpers

  before {
    stub_create_payment
  }

  let(:customer) do
    LedgerSync::Customer.new(customer_resource({ledger_id: '123'}))
  end

  let(:resource) do
    LedgerSync::Payment.new(payment_resource({customer: customer}))
  end

  let(:input) do
    {
      adaptor: quickbooks_adaptor,
      resource: resource
    }
  end

  context '#perform' do
    subject { LedgerSync::Adaptors::QuickBooksOnline::Payment::Operations::Create.new(**input).perform }
    it { expect(subject).to be_success }
    it { expect(subject).to be_a(LedgerSync::OperationResult::Success)}
  end
end
