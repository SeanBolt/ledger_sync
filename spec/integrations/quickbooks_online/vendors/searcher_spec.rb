require 'spec_helper'

support :input_helpers
support :quickbooks_online_helpers

RSpec.describe 'quickbooks_online/vendors/search', type: :feature do
  include InputHelpers
  include QuickBooksOnlineHelpers

  before {
    stub_search_vendor
  }

  let(:input) do
    {
      adaptor: quickbooks_online_adaptor,
      query: 'Sample Vendor'
    }
  end

  context '#resources' do
    subject { LedgerSync::Adaptors::QuickBooksOnline::Vendor::Searcher.new(**input).search }
    it { expect(subject).to be_success }
    it { expect(subject).to be_a(LedgerSync::SearchResult::Success) }
  end
end
