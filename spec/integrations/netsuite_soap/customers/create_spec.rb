# frozen_string_literal: true

require 'spec_helper'

support :input_helpers
support :netsuite_soap_helpers
support :operation_helpers

RSpec.describe LedgerSync::Adaptors::NetSuiteSOAP::Customer::Operations::Create, type: :feature do
  include InputHelpers
  include NetSuiteSOAPHelpers
  include OperationHelpers

  let(:resource) do
    LedgerSync::Customer.new(
      customer_resource.merge(
        subsidiary: LedgerSync::Subsidiary.new(
          ledger_id: 1003
        )
      )
    )
  end

  let(:initialized_operation) { described_class.new(**input) }

  let(:input) do
    {
      adaptor: netsuite_soap_adaptor,
      resource: resource
    }
  end

  context '#perform' do
    subject { described_class.new(**input).perform }

    it { expect_valid(operation: initialized_operation) }
    it 'creates', vcr: true do
      VCR.use_cassette('netsuite_soap/customers/create') do
        expect(subject).to be_a(LedgerSync::OperationResult::Success)
        expect(subject.resource.ledger_id).to eq('123')
      end
    end
  end
end
