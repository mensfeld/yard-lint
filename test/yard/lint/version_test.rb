# frozen_string_literal: true

require 'test_helper'

class YardLintVersionTest < Minitest::Test

  def test_version_has_a_version_number
    refute_nil(Yard::Lint::VERSION)
  end

  def test_version_version_is_a_string
    assert_kind_of(String, Yard::Lint::VERSION)
  end

  def test_version_version_follows_semantic_versioning_format
    assert_match(/\A\d+\.\d+\.\d+/, Yard::Lint::VERSION)
  end

  def test_version_version_is_frozen
    assert_predicate(Yard::Lint::VERSION, :frozen?)
  end
end

