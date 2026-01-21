# frozen_string_literal: true

RSpec.describe 'Unicode Characters in Type Specifications' do
  let(:fixture_path) { File.expand_path('../fixtures/unicode_type_characters.rb', __dir__) }
  let(:config) do
    test_config do |c|
      c.set_validator_config('Tags/NonAsciiType', 'Enabled', true)
    end
  end

  describe 'when type specification contains Unicode characters' do
    it 'does not crash with Encoding::CompatibilityError' do
      # Issue #39: yard-lint crashes with "invalid byte sequence in UTF-8"
      # when encountering Unicode characters in type specifications
      # instead of handling them gracefully
      expect do
        Yard::Lint.run(path: fixture_path, config: config)
      end.not_to raise_error
    end

    it 'continues processing and returns a valid result' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      # Should complete processing and return a proper result object
      expect(result).to respond_to(:offenses)
      expect(result.offenses).to be_an(Array)
    end

    it 'reports NonAsciiType offenses for each method with Unicode in type specs' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

      # Should detect the 3 methods with Unicode characters in type specs:
      # - unicode_ellipsis (…)
      # - unicode_arrow (→)
      # - unicode_em_dash (—)
      expect(non_ascii_offenses.size).to eq(3)
    end

    it 'includes the Unicode character and code point in the message' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

      # Each message should identify the problematic character
      non_ascii_offenses.each do |offense|
        expect(offense[:message]).to match(/U\+[0-9A-F]{4}/)
      end
    end

    it 'does not report offenses for valid ASCII type specifications' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

      # valid_ascii_types method should not be flagged
      valid_method_offenses = non_ascii_offenses.select do |o|
        o[:method_name]&.include?('valid_ascii_types')
      end

      expect(valid_method_offenses).to be_empty
    end

    it 'detects horizontal ellipsis (U+2026)' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      ellipsis_offenses = result.offenses.select do |o|
        o[:name] == 'NonAsciiType' && o[:message]&.include?('U+2026')
      end

      expect(ellipsis_offenses.size).to eq(1)
      expect(ellipsis_offenses.first[:message]).to include("'…'")
    end

    it 'detects right arrow (U+2192)' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      arrow_offenses = result.offenses.select do |o|
        o[:name] == 'NonAsciiType' && o[:message]&.include?('U+2192')
      end

      expect(arrow_offenses.size).to eq(1)
      expect(arrow_offenses.first[:message]).to include("'→'")
    end

    it 'detects em dash (U+2014)' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      em_dash_offenses = result.offenses.select do |o|
        o[:name] == 'NonAsciiType' && o[:message]&.include?('U+2014')
      end

      expect(em_dash_offenses.size).to eq(1)
      expect(em_dash_offenses.first[:message]).to include("'—'")
    end

    it 'includes helpful guidance in the error message' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

      non_ascii_offenses.each do |offense|
        expect(offense[:message]).to include('Ruby type names must use ASCII characters only')
      end
    end

    it 'sets severity to warning' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

      non_ascii_offenses.each do |offense|
        expect(offense[:severity]).to eq('warning')
      end
    end

    it 'provides correct file location' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

      non_ascii_offenses.each do |offense|
        expect(offense[:location]).to include('unicode_type_characters.rb')
      end
    end
  end

  describe 'when validator is disabled' do
    let(:config) do
      test_config do |c|
        c.set_validator_config('Tags/NonAsciiType', 'Enabled', false)
      end
    end

    it 'does not report NonAsciiType offenses' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }
      expect(non_ascii_offenses).to be_empty
    end

    it 'still does not crash with encoding errors' do
      expect do
        Yard::Lint.run(path: fixture_path, config: config)
      end.not_to raise_error
    end
  end

  describe 'interaction with TypeSyntax validator' do
    let(:config) do
      test_config do |c|
        c.set_validator_config('Tags/NonAsciiType', 'Enabled', true)
        c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
      end
    end

    it 'both validators can run together without crashing' do
      expect do
        Yard::Lint.run(path: fixture_path, config: config)
      end.not_to raise_error
    end

    it 'NonAsciiType reports its offenses independently' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }
      expect(non_ascii_offenses.size).to eq(3)
    end
  end

  describe 'with custom ValidatedTags configuration' do
    let(:config) do
      test_config do |c|
        c.set_validator_config('Tags/NonAsciiType', 'Enabled', true)
        c.set_validator_config('Tags/NonAsciiType', 'ValidatedTags', %w[return])
      end
    end

    it 'only validates configured tags' do
      result = Yard::Lint.run(path: fixture_path, config: config)

      non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

      # Only @return tags should be checked, so only unicode_arrow should be detected
      # (it's the only one with Unicode in the @return tag in the fixture)
      expect(non_ascii_offenses.size).to be <= 1
    end
  end
end
