# frozen_string_literal: true

# ExampleProject - Source Available Commercial Software
# Copyright (c) 2024-present Example Author. All rights reserved.
#
# This banner heads every source file and is intentionally separated from the code
# below it by a blank line. It is not documentation for the namespace it precedes.

module ReopenedShared
  # A leaf documented in this file - unaffected.
  # @return [Integer] the answer
  def self.answer
    42
  end
end

# A genuinely detached docstring: this class is documented nowhere else, and the blank
# line below orphans its only documentation - this must still be reported.

class BlankLineDetachedExample
end
