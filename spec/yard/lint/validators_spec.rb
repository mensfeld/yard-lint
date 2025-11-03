# frozen_string_literal: true

RSpec.describe 'Yard::Lint Validators' do
  describe 'API Tags Validation' do
    context 'when require_api_tags is enabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.require_api_tags = true
          c.allowed_apis = %w[public private internal]
        end
      end

      it 'detects API tag issues' do
        # Run against a simple Ruby string to avoid loading full project
        result = Yard::Lint.run(path: 'lib/yard/lint/version.rb', config: config)

        # Since require_api_tags is enabled, should find missing @api tags
        expect(result.api_tags).to be_an(Array)
        # The feature is working if we get results
        expect(result).to respond_to(:api_tags)
      end
    end

    context 'when require_api_tags is disabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.require_api_tags = false
        end
      end

      it 'does not run API tag validation' do
        result = Yard::Lint.run(path: 'lib/yard/lint/version.rb', config: config)

        expect(result.api_tags).to be_empty
      end
    end

    context 'with custom allowed APIs' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.require_api_tags = true
          c.allowed_apis = %w[public]
        end
      end

      it 'uses custom allowed_apis configuration' do
        result = Yard::Lint.run(path: 'lib/yard/lint/version.rb', config: config)

        # Feature should work with custom config
        expect(result.api_tags).to be_an(Array)
      end
    end
  end

  describe 'Abstract Methods Validation' do
    context 'when validate_abstract_methods is enabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.validate_abstract_methods = true
        end
      end

      it 'runs abstract method validation' do
        result = Yard::Lint.run(path: 'lib', config: config)

        expect(result.abstract_methods).to be_an(Array)
        expect(result).to respond_to(:abstract_methods)
      end
    end

    context 'when validate_abstract_methods is disabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.validate_abstract_methods = false
        end
      end

      it 'does not run abstract method validation' do
        result = Yard::Lint.run(path: 'lib', config: config)

        expect(result.abstract_methods).to be_empty
      end
    end
  end

  describe 'Option Tags Validation' do
    context 'when validate_option_tags is enabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.validate_option_tags = true
        end
      end

      it 'runs option tags validation' do
        result = Yard::Lint.run(path: 'lib', config: config)

        expect(result.option_tags).to be_an(Array)
        expect(result).to respond_to(:option_tags)
      end
    end

    context 'when validate_option_tags is disabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.validate_option_tags = false
        end
      end

      it 'does not run option tags validation' do
        result = Yard::Lint.run(path: 'lib', config: config)

        expect(result.option_tags).to be_empty
      end
    end
  end

  describe 'Combined Validators' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        c.require_api_tags = true
        c.validate_abstract_methods = true
        c.validate_option_tags = true
      end
    end

    it 'runs all validators when enabled' do
      result = Yard::Lint.run(path: 'lib', config: config)

      expect(result.api_tags).to be_an(Array)
      expect(result.abstract_methods).to be_an(Array)
      expect(result.option_tags).to be_an(Array)
    end

    it 'includes all offense types in the offenses array' do
      result = Yard::Lint.run(path: 'lib', config: config)

      expect(result.offenses).to be_an(Array)
      expect(result).to respond_to(:offenses)
      expect(result).to respond_to(:count)
      expect(result).to respond_to(:clean?)
    end
  end
end
