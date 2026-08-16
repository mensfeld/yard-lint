# frozen_string_literal: true

# Proves that Tags/TagSeparator and Tags/TagGroupSeparator report a docstring
# once no matter how many code objects YARD generates from it. An attr_accessor
# registers a reader and a writer sharing one comment block, so an unseparated
# docstring there was reported twice - once per generated method - for a single
# place in the source.
%w[Tags/TagSeparator Tags/TagGroupSeparator].each do |validator|
  offense_name = (validator == 'Tags/TagSeparator') ? 'MissingTagSeparator' : 'MissingTagGroupSeparator'

  describe "#{validator} with a shared docstring" do
    attr_reader :result

    # define_method so the block closes over offense_name, which a def cannot
    define_method(:offenses_for) do |method_name|
      result.offenses.select do |offense|
        offense[:name] == offense_name && offense[:method_name] == method_name
      end
    end

    before do
      fixture_path = File.expand_path('../fixtures/shared_docstring_example.rb', __dir__)
      config = test_config do |c|
        c.set_validator_config(validator, 'Enabled', true)
      end
      @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    end

    it 'reports an unseparated attr_accessor docstring once, not once per generated method' do
      assert_equal(1, offenses_for('value').size + offenses_for('value=').size)
    end

    it 'does not report a separated attr_accessor docstring' do
      assert_empty(offenses_for('other') + offenses_for('other='))
    end

    it 'still reports an unrelated method with the same shape' do
      assert_equal(1, offenses_for('echo').size)
    end
  end
end
