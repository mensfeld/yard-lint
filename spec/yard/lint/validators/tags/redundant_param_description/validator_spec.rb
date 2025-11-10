# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::RedundantParamDescription::Validator do
  let(:config) { Yard::Lint::Config.new }
  let(:selection) { ['lib/example.rb'] }
  let(:validator) { described_class.new(config, selection) }

  describe '#initialize' do
    it 'inherits from Base validator' do
      expect(validator).to be_a(Yard::Lint::Validators::Base)
    end

    it 'stores config and selection' do
      expect(validator.config).to eq(config)
      expect(validator.selection).to eq(selection)
    end
  end

  describe '#call' do
    it 'returns hash with stdout, stderr, exit_code' do
      result = validator.call
      expect(result).to have_key(:stdout)
      expect(result).to have_key(:stderr)
      expect(result).to have_key(:exit_code)
    end
  end

  describe 'query generation' do
    it 'generates a valid YARD query' do
      query = validator.send(:query)
      expect(query).to be_a(String)
      expect(query).to include('tag.tag_name')
      expect(query).to include('tag.text')
    end

    it 'includes word count check' do
      query = validator.send(:query)
      expect(query).to include('word_count')
      expect(query).to include('split.length')
    end

    it 'includes pattern matching logic' do
      query = validator.send(:query)
      expect(query).to include('pattern_type')
      expect(query).to include('article_param')
      expect(query).to include('possessive_param')
      expect(query).to include('type_restatement')
    end

    it 'checks all enabled patterns' do
      query = validator.send(:query)
      expect(query).to include('param_to_verb')
      expect(query).to include('id_pattern')
      expect(query).to include('directional_date')
      expect(query).to include('type_generic')
    end

    it 'includes max word count threshold' do
      query = validator.send(:query)
      expect(query).to include('> 6')  # Default MaxRedundantWords
    end
  end

  describe 'yard_cmd generation' do
    it 'generates a valid yard command' do
      cmd = validator.send(:yard_cmd, '/tmp/yardoc', '/tmp/files.txt')

      expect(cmd[:stdout]).to be_a(String)
      expect(cmd[:stderr]).to be_a(String)
      expect(cmd[:exit_code]).to be_a(Integer)
    end
  end

  describe 'config accessors' do
    it 'reads Articles config' do
      expect(validator.send(:config_articles)).to eq(%w[The the A a An an])
    end

    it 'reads GenericTerms config' do
      expect(validator.send(:config_generic_terms)).to eq(%w[object instance value data item element])
    end

    it 'reads MaxRedundantWords config' do
      expect(validator.send(:config_max_redundant_words)).to eq(6)
    end

    it 'reads CheckedTags config' do
      expect(validator.send(:config_checked_tags)).to eq(%w[param option])
    end

    it 'reads EnabledPatterns config' do
      patterns = validator.send(:config_enabled_patterns)
      expect(patterns).to be_a(Hash)
      expect(patterns['ArticleParam']).to be true
    end
  end
end
