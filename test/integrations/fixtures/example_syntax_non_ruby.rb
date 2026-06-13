# frozen_string_literal: true

# Fixtures for Tags/ExampleSyntax SkipNonRuby (BUG-046). Each method carries an
# @example that is either an interactive console transcript (not runnable Ruby)
# or genuine Ruby, to exercise the opt-in skip.
class ExampleSyntaxNonRuby
  # @example irb session
  #   >> user.name
  #   => "Bob"
  def irb_method; end

  # @example irb prompt
  #   irb(main):001:0> 1 + 1
  #   => 2
  def irb_prompt_method; end

  # @example pry session
  #   [1] pry(main)> 2 + 2
  #   => 4
  def pry_method; end

  # @example shell session
  #   $ bundle install
  #   Fetching gem metadata...
  def shell_method; end

  # @example valid ruby using a hash rocket
  #   mapping = { :a => 1, :b => 2 }
  #   mapping.fetch(:a)
  def hash_rocket_method; end

  # @example genuinely broken ruby
  #   def broken(
  #     missing paren
  #   end
  def broken_method; end
end
