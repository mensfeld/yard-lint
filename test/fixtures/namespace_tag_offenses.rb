# frozen_string_literal: true

# Fixture for namespace-level tag validation tests. Offenses here live on
# class/module docstrings, which Tags/Order and Tags/TagGroupSeparator
# used to skip entirely (calling is_alias? on namespace objects raised a
# silently-swallowed NameError).

# Class documented with tags in the wrong order
# @note remember to configure it first
# @example Usage
#   ClassWithWrongTagOrder.new
class ClassWithWrongTagOrder
end

# Class with correctly ordered tags
#
# @example Usage
#   ClassWithValidTagOrder.new
#
# @note remember to configure it first
class ClassWithValidTagOrder
end

# Module whose meta and example tag groups lack a blank line separator
# @see ClassWithValidTagOrder
# @example Usage
#   ModuleWithJoinedTagGroups.call
module ModuleWithJoinedTagGroups
end
