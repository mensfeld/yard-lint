# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsExampleStyleLinterDetectorTest < Minitest::Test
  attr_reader :temp_dir

  def setup
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(temp_dir)
  end

  def test_detect_when_linter_is_explicitly_set_to_none_returns_none
    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('none', project_root: temp_dir)
    assert_equal(:none, result)
  end

  def test_detect_when_linter_is_explicitly_set_to_rubocop_returns_rubocop_if_rubocop_is_available
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)
    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('rubocop', project_root: temp_dir)
    assert_equal(:rubocop, result)
  end

  def test_detect_when_linter_is_explicitly_set_to_rubocop_returns_none_if_rubocop_is_not_available
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('rubocop', project_root: temp_dir)
    assert_equal(:none, result)
  end

  def test_detect_when_linter_is_explicitly_set_to_standard_returns_standard_if_standard_is_available
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(true)
    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('standard', project_root: temp_dir)
    assert_equal(:standard, result)
  end

  def test_detect_when_linter_is_explicitly_set_to_standard_returns_none_if_standard_is_not_available
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)
    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('standard', project_root: temp_dir)
    assert_equal(:none, result)
  end

  def test_detect_with_auto_detection_detects_standard_from_standard_yml
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(true)
    File.write(File.join(temp_dir, '.standard.yml'), 'parallel: true')

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:standard, result)
  end

  def test_detect_with_auto_detection_detects_rubocop_from_rubocop_yml
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)
    File.write(File.join(temp_dir, '.rubocop.yml'), 'AllCops:')

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:rubocop, result)
  end

  def test_detect_with_auto_detection_prefers_standard_over_rubocop_when_both_configs_exist
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(true)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)
    File.write(File.join(temp_dir, '.standard.yml'), 'parallel: true')
    File.write(File.join(temp_dir, '.rubocop.yml'), 'AllCops:')

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:standard, result)
  end

  def test_detect_with_auto_detection_detects_standard_from_gemfile
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(true)
    File.write(File.join(temp_dir, 'Gemfile'), "gem 'standard'")

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:standard, result)
  end

  def test_detect_with_auto_detection_detects_rubocop_from_gemfile
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)
    File.write(File.join(temp_dir, 'Gemfile'), "gem 'rubocop'")

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:rubocop, result)
  end

  def test_detect_with_auto_detection_detects_standard_from_gemfile_lock
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(true)
    File.write(File.join(temp_dir, 'Gemfile.lock'), "  standard (1.0.0)")

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:standard, result)
  end

  def test_detect_with_auto_detection_detects_rubocop_from_gemfile_lock
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)
    File.write(File.join(temp_dir, 'Gemfile.lock'), "  rubocop (1.0.0)")

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:rubocop, result)
  end

  def test_detect_with_auto_detection_returns_none_when_no_linter_is_detected
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:none, result)
  end

  def test_rubocop_available_returns_true_if_rubocop_can_be_required
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:require).with('rubocop').returns(true)
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.rubocop_available?)
  end

  def test_rubocop_available_returns_false_if_rubocop_cannot_be_required
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:require).with('rubocop').raises(LoadError)
    assert_equal(false, Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.rubocop_available?)
  end

  def test_standard_available_returns_true_if_standard_can_be_required
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:require).with('standard').returns(true)
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.standard_available?)
  end

  def test_standard_available_returns_false_if_standard_cannot_be_required
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:require).with('standard').raises(LoadError)
    assert_equal(false, Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.standard_available?)
  end
end
