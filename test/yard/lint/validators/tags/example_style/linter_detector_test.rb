# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector' do
  attr_reader :temp_dir

  before do
    @temp_dir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  it 'detect when linter is explicitly set to none returns none' do
    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('none', project_root: temp_dir)
    assert_equal(:none, result)
  end

  it 'detect when linter is explicitly set to rubocop returns rubocop if rubocop is available' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)
    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('rubocop', project_root: temp_dir)
    assert_equal(:rubocop, result)
  end

  it 'detect when linter is explicitly set to rubocop returns none if rubocop is not available' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('rubocop', project_root: temp_dir)
    assert_equal(:none, result)
  end

  it 'detect when linter is explicitly set to standard returns standard if standard is available' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(true)
    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('standard', project_root: temp_dir)
    assert_equal(:standard, result)
  end

  it 'detect when linter is explicitly set to standard returns none if standard is not available' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)
    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('standard', project_root: temp_dir)
    assert_equal(:none, result)
  end

  it 'detect with auto detection detects standard from standard yml' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(true)
    File.write(File.join(temp_dir, '.standard.yml'), 'parallel: true')

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:standard, result)
  end

  it 'detect with auto detection detects rubocop from rubocop yml' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)
    File.write(File.join(temp_dir, '.rubocop.yml'), 'AllCops:')

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:rubocop, result)
  end

  it 'detect with auto detection prefers standard over rubocop when both configs exist' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(true)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)
    File.write(File.join(temp_dir, '.standard.yml'), 'parallel: true')
    File.write(File.join(temp_dir, '.rubocop.yml'), 'AllCops:')

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:standard, result)
  end

  it 'detect with auto detection detects standard from gemfile' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(true)
    File.write(File.join(temp_dir, 'Gemfile'), "gem 'standard'")

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:standard, result)
  end

  it 'detect with auto detection detects rubocop from gemfile' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)
    File.write(File.join(temp_dir, 'Gemfile'), "gem 'rubocop'")

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:rubocop, result)
  end

  it 'detect with auto detection detects standard from gemfile lock' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(true)
    File.write(File.join(temp_dir, 'Gemfile.lock'), "  standard (1.0.0)")

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:standard, result)
  end

  it 'detect with auto detection detects rubocop from gemfile lock' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)
    File.write(File.join(temp_dir, 'Gemfile.lock'), "  rubocop (1.0.0)")

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:rubocop, result)
  end

  it 'detect with auto detection returns none when no linter is detected' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:none, result)
  end

  it 'rubocop available returns true if rubocop can be required' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:require).with('rubocop').returns(true)
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.rubocop_available?)
  end

  it 'rubocop available returns false if rubocop cannot be required' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:require).with('rubocop').raises(LoadError)
    assert_equal(false, Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.rubocop_available?)
  end

  it 'standard available returns true if standard can be required' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:require).with('standard').returns(true)
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.standard_available?)
  end

  it 'standard available returns false if standard cannot be required' do
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:require).with('standard').raises(LoadError)
    assert_equal(false, Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.standard_available?)
  end
end

