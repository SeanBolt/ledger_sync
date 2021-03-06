# frozen_string_literal: true

require_relative 'error_matcher'

module LedgerSync
  module Adaptors
    module QuickBooksOnline
      module Util
        class ErrorParser
          attr_reader :error

          def initialize(error:)
            @error = error
          end

          def error_klass
            raise NotImplementedError
          end

          def parse
            raise NotImplementedError
          end
        end
      end
    end
  end
end
