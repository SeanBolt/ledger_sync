require 'spec_helper'

support :quickbooks_online_helpers

RSpec.describe LedgerSync::Adaptors::QuickBooksOnline::Department::Operations::Update do
  include QuickBooksOnlineHelpers

  let(:resource) { LedgerSync::Department.new(ledger_id: '123', name: 'Test Department', active: true, sub_department: false)}
  let(:adaptor) { quickbooks_online_adaptor }

  it_behaves_like 'an operation'
  it_behaves_like 'a successful operation',
                  stubs: %i[
                    stub_find_department
                    stub_update_department
                  ]
end
