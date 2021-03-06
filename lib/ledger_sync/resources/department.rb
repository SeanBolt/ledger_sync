# frozen_string_literal: true

module LedgerSync
  class Department < LedgerSync::Resource
    attribute :name, type: Type::String
    attribute :fully_qualified_name, type: Type::String
    attribute :active, type: Type::Boolean
    attribute :sub_department, type: Type::Boolean

    references_one :parent, to: Department
  end
end
