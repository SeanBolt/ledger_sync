# frozen_string_literal: true

module LedgerSync
  module Adaptors
    module QuickBooksOnline
      module Department
        class LedgerSerializer < QuickBooksOnline::LedgerSerializer
          id

          attribute ledger_attribute: 'Name',
                    resource_attribute: :name
          attribute ledger_attribute: 'Active',
                    resource_attribute: :active
          attribute ledger_attribute: 'SubDepartment',
                    resource_attribute: :sub_department
          attribute ledger_attribute: 'FullyQualifiedName',
                    resource_attribute: :fully_qualified_name

          attribute ledger_attribute: 'ParentRef.value',
                    resource_attribute: 'parent.ledger_id'

          # Sending "ParentRef": {"value": null} results in QBO API crash
          # This patches serialized hash to exclude it unless we don't set value
          def to_ledger_hash(deep_merge_unmapped_values: {}, only_changes: false)
            ret = super(only_changes: only_changes)
            ret = ret.except('ParentRef') unless resource.parent_changed?
            return ret unless deep_merge_unmapped_values.any?

            deep_merge_if_not_mapped(
              current_hash: ret,
              hash_to_search: deep_merge_unmapped_values
            )
          end
        end
      end
    end
  end
end
