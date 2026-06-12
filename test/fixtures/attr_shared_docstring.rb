# frozen_string_literal: true

# Fixture for offense dedup tests. The attr_accessor docstring is shared by
# the generated reader and writer methods, so docstring-scanning validators
# and YARD warning capture see it twice.
class AttrSharedDocstring
  # Stored value kept between runs of the processing pipeline so that repeated invocations can reuse previously computed results
  # @returnz [String] the stored value
  attr_accessor :value
end
