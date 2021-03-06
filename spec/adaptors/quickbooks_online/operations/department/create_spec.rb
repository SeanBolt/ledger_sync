require 'spec_helper'

support :quickbooks_online_helpers

RSpec.describe LedgerSync::Adaptors::QuickBooksOnline::Department::Operations::Create do
  include QuickBooksOnlineHelpers

  let(:resource) { LedgerSync::Department.new(name: 'Test Department', active: true, sub_department: false) }
  let(:adaptor) { quickbooks_online_adaptor }

  it_behaves_like 'an operation'
  it_behaves_like 'a successful operation', stubs: :stub_create_department
end
