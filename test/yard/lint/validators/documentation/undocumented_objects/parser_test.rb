# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UndocumentedObjects::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Documentation::UndocumentedObjects::Parser.new
  end

  it 'initialize inherits from parser base class' do
    assert_kind_of(Yard::Lint::Parsers::Base, parser)
  end

  it 'call parses input and returns array' do
    result = parser.call('')
    assert_kind_of(Array, result)
  end

  it 'call handles empty input' do
    result = parser.call('')
  end

  describe 'ExcludedObjects' do
    let(:input) do
      [
        'file.rb:5: ATui::Input::KEY_A_Z',
        'file.rb:6: ATui::Input::KEY_0_9',
        'file.rb:7: ATui::Input#helper|0',
        'file.rb:8: ATui::Input#call|1'
      ].join("\n")
    end

    def config_for(patterns)
      Yard::Lint::Config.new do |c|
        c.set_validator_config('Documentation/UndocumentedObjects', 'ExcludedObjects', patterns)
      end
    end

    it 'excludes constants matching a full-path regex' do
      result = parser.call(input, config: config_for(['/^ATui::Input::KEY_/']))
      elements = result.map { |o| o[:element] }

      refute_includes(elements, 'ATui::Input::KEY_A_Z')
      refute_includes(elements, 'ATui::Input::KEY_0_9')
      assert_includes(elements, 'ATui::Input#helper')
    end

    it 'excludes a single constant by its fully-qualified name' do
      result = parser.call(input, config: config_for(['ATui::Input::KEY_A_Z']))
      elements = result.map { |o| o[:element] }

      refute_includes(elements, 'ATui::Input::KEY_A_Z')
      assert_includes(elements, 'ATui::Input::KEY_0_9')
    end

    it 'excludes methods by their fully-qualified name' do
      result = parser.call(input, config: config_for(['/^ATui::Input#/']))
      elements = result.map { |o| o[:element] }

      refute_includes(elements, 'ATui::Input#helper')
      assert_includes(elements, 'ATui::Input::KEY_A_Z')
    end

    it 'excludes a method by full-path arity notation only at the matching arity' do
      result = parser.call(input, config: config_for(['ATui::Input#call/1']))
      elements = result.map { |o| o[:element] }

      refute_includes(elements, 'ATui::Input#call')
      # helper has arity 0, so the /1 pattern must not exclude it.
      assert_includes(elements, 'ATui::Input#helper')
    end

    it 'does not exclude a method when the full-path arity does not match' do
      result = parser.call(input, config: config_for(['ATui::Input#call/0']))
      elements = result.map { |o| o[:element] }

      # call has arity 1, not 0, so it stays reported.
      assert_includes(elements, 'ATui::Input#call')
    end

    it 'ignores arity notation for constants (constants have no arity)' do
      result = parser.call(input, config: config_for(['ATui::Input::KEY_A_Z/0']))
      elements = result.map { |o| o[:element] }

      assert_includes(elements, 'ATui::Input::KEY_A_Z')
    end

    it 'does not exclude objects when no pattern matches' do
      result = parser.call(input, config: config_for(['/^Other::/']))
      elements = result.map { |o| o[:element] }

      assert_equal(4, elements.size)
    end
  end
end

