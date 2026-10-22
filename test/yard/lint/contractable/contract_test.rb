# frozen_string_literal: true

describe 'Yard::Lint::Contractable::Contract' do
  def build_contract(&)
    Class.new(Yard::Lint::Contractable::Contract) do
      self.error_messages = {
        'missing' => 'needs to be present',
        'id_format' => 'needs to be a String',
        'details.id_format' => 'details id needs to be a String'
      }

      instance_eval(&)
    end
  end

  it 'call with valid data returns success without errors' do
    contract = build_contract do
      required(:id) { |id| id.is_a?(String) }
      optional(:test) { |test| test == 5 }
    end

    result = contract.new.call({ id: '1' })

    assert_predicate(result, :success?)
    assert_empty(result.errors)
  end

  it 'call with invalid data maps error keys to messages' do
    contract = build_contract do
      required(:id) { |id| id.is_a?(String) }
      required(:name) { |name| name.is_a?(String) }
    end

    result = contract.new.call({ id: 1 })

    refute_predicate(result, :success?)
    assert_equal({ id: 'needs to be a String', name: 'needs to be present' }, result.errors)
  end

  it 'call uses a string returned by a rule as the message' do
    contract = build_contract do
      optional(:id) { |id| id.is_a?(String) || "got #{id.class}" }
    end

    assert_equal({ id: 'got Integer' }, contract.new.call({ id: 1 }).errors)
  end

  it 'call prefers a message scoped to the full path' do
    contract = build_contract do
      nested(:details) do
        required(:id) { |id| id.is_a?(String) }
      end
    end

    assert_equal(
      { 'details.id': 'details id needs to be a String' },
      contract.new.call({ details: { id: 1 } }).errors
    )
  end

  it 'call prefixes errors with the scope' do
    contract = build_contract do
      required(:id) { |id| id.is_a?(String) }
    end

    assert_equal(
      { 'outer.id': 'needs to be a String' },
      contract.new.call({ id: 1 }, scope: %i[outer]).errors
    )
  end

  it 'call reports a deeply nested path with a non hash parent as missing' do
    contract = build_contract do
      nested(:a) do
        nested(:b) do
          required(:id) { |id| id.is_a?(String) }
        end
      end
    end

    assert_predicate(contract.new.call({ a: { b: { id: '1' } } }), :success?)
    assert_equal({ 'a.b.id': 'needs to be present' }, contract.new.call({ a: 'x' }).errors)
  end

  it 'call reports required paths of a non hash root as missing' do
    contract = build_contract do
      required(:id) { |id| id.is_a?(String) }
      required(:a, :b) { |value| value.is_a?(String) }
    end

    result = contract.new.call('not-a-hash')

    assert_equal(%i[id a.b], result.errors.keys)
  end

  it 'call skips optional keys that are missing' do
    contract = build_contract do
      nested(:a) do
        optional(:id) { |id| id.is_a?(String) }
      end
    end

    assert_predicate(contract.new.call({}), :success?)
    assert_predicate(contract.new.call({ a: 'x' }), :success?)
  end

  it 'call collects virtual rule errors with the scope' do
    contract = build_contract do
      virtual { |_data, _errors, _contract| [[%i[id], 'boom']] }
    end

    assert_equal({ 'outer.id': 'boom' }, contract.new.call({}, scope: %i[outer]).errors)
  end

  it 'call treats a non array virtual rule result as no errors' do
    [false, nil, true].each do |returned|
      contract = build_contract do
        virtual { |_data, _errors, _contract| returned }
      end

      assert_predicate(contract.new.call({}), :success?)
    end
  end

  it 'call raises when an error key has no message' do
    contract = build_contract do
      required(:other) { |other| other.is_a?(String) }
    end

    assert_raises(KeyError) { contract.new.call({ other: 1 }) }
  end

  it 'validate! returns true for valid data and raises the error class otherwise' do
    contract = build_contract do
      required(:id) { |id| id.is_a?(String) }
    end

    assert(contract.new.validate!({ id: '1' }, ArgumentError))
    assert_raises(ArgumentError) { contract.new.validate!({ id: 1 }, ArgumentError) }
  end

  it 'nested does not leak its path onto later rules when its block raises' do
    contract = build_contract do
      begin
        nested(:a) { raise 'boom' }
      rescue RuntimeError
        nil
      end

      required(:id) { |id| id.is_a?(String) }
    end

    assert_equal(%i[id], contract.rules.last.path)
  end

  it 'error_messages defaults to an empty hash' do
    assert_empty(Class.new(Yard::Lint::Contractable::Contract).error_messages)
  end
end
