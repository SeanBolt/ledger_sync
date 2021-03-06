# frozen_string_literal: true

module LedgerSync
  class BillLineItem < LedgerSync::Resource
    references_one :account, to: Account
    attribute :amount, type: Type::Integer
    attribute :description, type: Type::String

    def name
      description
    end
  end
end
