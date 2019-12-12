require 'spec_helper'

support :adaptor_helpers

RSpec.describe LedgerSync::Adaptors::QuickBooksOnline::Department::Operations::Create do
  include AdaptorHelpers

  let(:department) { LedgerSync::Department.new(name: 'Test', active: true, sub_department: false) }

  it do
    instance = described_class.new(resource: department, adaptor: quickbooks_adaptor)
    expect(instance).to be_valid
  end
end
