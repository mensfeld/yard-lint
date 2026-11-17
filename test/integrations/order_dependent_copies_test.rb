# frozen_string_literal: true

# Proves that an alias or `module_function :name` written before its method
# (in a file parsed earlier) copies the method's docs in both parse orders,
# and that a module function `?` copy is reported only once with --private
describe 'Order Dependent Copies' do
  attr_reader :fixtures_path

  before do
    @fixtures_path = [
      File.expand_path('fixtures/order_dependent_a.rb', __dir__),
      File.expand_path('fixtures/order_dependent_b.rb', __dir__)
    ]
  end

  [false, true].each do |reversed|
    it "reports no offenses with #{reversed ? 'reversed' : 'normal'} parse order" do
      files = reversed ? fixtures_path.reverse : fixtures_path
      result = Yard::Lint.run(path: files, config: test_config, progress: false)

      assert_equal(0, result.count, result.offenses.inspect)
    end
  end

  it 'reports an undocumented module function predicate once with --private' do
    config = test_config { |c| c.options = ['--private'] }
    path = File.expand_path('fixtures/module_function_predicate.rb', __dir__)
    result = Yard::Lint.run(path: path, config: config, progress: false)

    objects = result.offenses
                    .select { |o| o[:name] == 'UndocumentedObject' }
                    .map { |o| o[:object_name] || o[:message] }

    assert_equal(1, objects.size, objects.inspect)
  end
end
