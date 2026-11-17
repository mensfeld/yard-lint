# frozen_string_literal: true

# Proves that @!parse, @!method and @!attribute directives across files give
# the same result in both parse orders, without a macro (one parse pass)
describe 'Cross File Directives' do
  attr_reader :fixtures_path, :config

  before do
    @fixtures_path = [
      File.expand_path('fixtures/directives_a.rb', __dir__),
      File.expand_path('fixtures/directives_b.rb', __dir__)
    ]
    @config = test_config
  end

  [false, true].each do |reversed|
    it "reports no offenses with #{reversed ? 'reversed' : 'normal'} parse order" do
      files = reversed ? fixtures_path.reverse : fixtures_path
      result = Yard::Lint.run(path: files, config: config, progress: false)

      assert_equal(0, result.count, result.offenses.inspect)
      assert_empty(YARD::Registry.all(:macro))
      assert_equal('DirectivesBase', YARD::Registry.at('DirectivesA').superclass.path)
      assert_includes(YARD::Registry.at('DirectivesA').mixins(:instance).map(&:path), 'DirectivesB')
      %w[DirectivesA#build DirectivesA#label DirectivesA#size= DirectivesA#reset].each do |path|
        refute_nil(YARD::Registry.at(path), path)
      end
    end
  end
end
