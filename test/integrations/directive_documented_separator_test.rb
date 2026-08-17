# frozen_string_literal: true

# Proves that an object documented by a `@!method` directive is linted like any
# other. Such an object has no docstring line range, which is the same signal
# `module_function_copy?` uses to recognize the normalized half of a
# module_function pair - so each way a directive-created object can sit next to
# an opposite-scope namesake is covered here: no namesake at all, one defined
# normally at another line, and one created by a second directive at the same
# location.
%w[Tags/TagSeparator Tags/TagGroupSeparator].each do |validator|
  offense_name = (validator == 'Tags/TagSeparator') ? 'MissingTagSeparator' : 'MissingTagGroupSeparator'

  describe "#{validator} with directive-documented objects" do
    attr_reader :result

    # define_method so the block closes over offense_name, which a def cannot
    define_method(:offenses_for) do |method_name|
      result.offenses.select do |offense|
        offense[:name] == offense_name && offense[:method_name] == method_name
      end
    end

    before do
      fixture_path = File.expand_path('../fixtures/directive_documented_example.rb', __dir__)
      config = test_config do |c|
        c.set_validator_config(validator, 'Enabled', true)
      end
      @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    end

    it 'reports a directive-created method that has no opposite-scope namesake' do
      assert_equal(1, offenses_for('solo').size)
    end

    it 'reports both a directive-created method and its namesake defined elsewhere' do
      offenses = offenses_for('paired')

      assert_equal(2, offenses.size, 'the two are separate docstrings and must be reported separately')
      assert_equal(2, offenses.map { |o| o[:line] }.uniq.size)
    end

    it 'reports a same-location directive pair once' do
      # Neither half is a module function, so neither is skipped as a normalized
      # copy. Both are linted, and because the two directives carry the same text
      # they produce one offense between them rather than one each
      assert_equal(1, offenses_for('both').size)
    end
  end
end
