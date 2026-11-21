# frozen_string_literal: true

# Proves that a constant made private in a file parsed before its definition
# stays private in both parse orders, with one parse pass and with two
describe 'Private Constant' do
  attr_reader :fixtures_path, :macro_path

  before do
    @fixtures_path = [
      File.expand_path('fixtures/private_constant_a.rb', __dir__),
      File.expand_path('fixtures/private_constant_b.rb', __dir__)
    ]
    @macro_path = File.expand_path('fixtures/private_constant_macro.rb', __dir__)
  end

  [false, true].each do |reversed|
    [false, true].each do |macro|
      it "reports no offenses with #{reversed ? 'reversed' : 'normal'} parse order " \
         "#{macro ? 'with' : 'without'} a macro" do
        files = reversed ? fixtures_path.reverse : fixtures_path
        files += [macro_path] if macro
        result = Yard::Lint.run(path: files, config: test_config, progress: false)

        assert_equal(0, result.count, result.offenses.inspect)
        assert_equal(macro, !YARD::Registry.all(:macro).empty?)
        assert_equal(:private, YARD::Registry.at('PrivateConstantHolder::SECRET').visibility)
      end
    end
  end
end
