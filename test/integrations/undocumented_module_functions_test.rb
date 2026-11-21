# frozen_string_literal: true

# Proves that Documentation/UndocumentedObjects reports an undocumented
# module_function method once, on its public module method, with and without
# --private and in both parse orders. Before, --private gave a second offense
# on the private instance copy, and a `?` method passed to module_function by
# name was reported only on that copy.
describe 'Undocumented module functions' do
  attr_reader :fixtures_path

  before do
    @fixtures_path = %w[
      undocumented_module_functions.rb
      undocumented_module_functions_late.rb
      undocumented_module_functions_late_defs.rb
    ].map { |name| File.expand_path("fixtures/#{name}", __dir__) }
  end

  def undocumented_objects(files, options)
    config = test_config { |c| c.options = options }
    result = Yard::Lint.run(path: files, config: config, progress: false)

    result.offenses
          .select { |o| o[:name] == 'UndocumentedObject' }
          .map { |o| o[:message][/`(.+)`/, 1] }
          .sort
  end

  [[], ['--private']].each do |options|
    [false, true].each do |reversed|
      it "reports each module function once with #{options.inspect} and #{reversed ? 'reversed' : 'normal'} order" do
        files = reversed ? fixtures_path.reverse : fixtures_path
        expected = %w[
          UndocBare.ready? UndocBare.run
          UndocLate.ready? UndocLate.run
          UndocSymbol.inline UndocSymbol.inline? UndocSymbol.ready? UndocSymbol.run
        ]
        expected << 'UndocSymbol#helper' unless options.empty?

        assert_equal(expected.sort, undocumented_objects(files, options))
      end
    end
  end
end
