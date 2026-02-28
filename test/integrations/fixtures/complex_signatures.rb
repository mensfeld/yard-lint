# frozen_string_literal: true

# Example class with complex method signatures
class ComplexSignaturesExample
  # Method with default parameter (documented)
  # @param name [String] the name
  # @param greeting [String] optional greeting
  # @return [String] greeting message
  def greet(name, greeting = 'Hello')
    "#{greeting}, #{name}"
  end

  # Method with default parameter (undocumented)
  def process(value, multiplier = 2)
    value * multiplier
  end

  # Method with keyword arguments (documented)
  # @param name [String] the name
  # @param age [Integer] the age
  # @param city [String] optional city
  # @return [Hash] user info
  def create_user(name:, age:, city: nil)
    { name: name, age: age, city: city }
  end

  # Method with keyword arguments (undocumented)
  def configure(host:, port: 3000, ssl: false)
    { host: host, port: port, ssl: ssl }
  end

  # Method with splat operator (documented)
  # @param items [Array<String>] list of items
  # @return [String] joined items
  def join_items(*items)
    items.join(', ')
  end

  # Method with splat operator (undocumented)
  def sum_all(*numbers)
    numbers.sum
  end

  # Method with double splat (documented)
  # @param options [Hash] configuration options
  # @return [Hash] processed options
  def process_options(**options)
    options.transform_values(&:to_s)
  end

  # Method with double splat (undocumented)
  def merge_config(**config)
    { default: true }.merge(config)
  end

  # Method with block parameter (documented)
  # @param value [Integer] initial value
  # @yield [Integer] yields the value for transformation
  # @yieldreturn [Integer] transformed value
  # @return [Integer] final result
  def transform(value, &block)
    block ? block.call(value) : value
  end

  # Method with block parameter (undocumented)
  def process_with_block(data, &block)
    block ? block.call(data) : data
  end

  # Complex signature with everything (documented)
  # @param required [String] required parameter
  # @param optional [String] optional parameter
  # @param args [Array] additional arguments
  # @param keyword [String] keyword argument
  # @param opts [Hash] additional options
  # @yield [String] yields for processing
  # @return [Hash] processed result
  def complex_method(required, optional = nil, *args, keyword:, **opts, &block)
    result = { required: required, optional: optional, args: args, keyword: keyword, opts: opts }
    block ? block.call(result) : result
  end

  # Complex signature (undocumented)
  def another_complex(base, modifier = 1, *extras, flag:, **settings, &handler)
    { base: base, modifier: modifier, extras: extras, flag: flag, settings: settings }
  end
end
