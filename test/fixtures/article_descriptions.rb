# frozen_string_literal: true

# Fixture for article-matching tests. Words that merely start with "a",
# "an", or "the" (authenticated, auto-generated, theme) are not articles
# and the descriptions below are meaningful.
class ArticleDescriptions
  # Authenticates the request
  # @param user [User] authenticated user
  # @param id [Integer] auto-generated id
  # @param style [String] themed style
  # @return [void]
  def authorize(user, id, style)
    [user, id, style]
  end

  # Reads the stored name
  # @param name [String] the name
  # @return [String] stored value
  def read(name)
    name
  end
end
