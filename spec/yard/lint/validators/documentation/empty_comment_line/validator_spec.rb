# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::EmptyCommentLine::Validator do
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
      expect(query).to include('check_leading')
      expect(query).to include('check_trailing')
    end

    it 'includes source file reading logic' do
      query = validator.send(:query)
      expect(query).to include('File.readlines')
      expect(query).to include('object.file')
    end

    it 'includes comment block detection logic' do
      query = validator.send(:query)
      expect(query).to include('comment_start')
      expect(query).to include('comment_end')
    end

    it 'includes violation detection for leading empty lines' do
      query = validator.send(:query)
      expect(query).to include('leading')
      expect(query).to include('first_content_idx')
    end

    it 'includes violation detection for trailing empty lines' do
      query = validator.send(:query)
      expect(query).to include('trailing')
      expect(query).to include('last_content_idx')
    end
  end

  describe 'configuration checks' do
    it 'responds to check_leading?' do
      expect(validator.send(:check_leading?)).to be(true)
    end

    it 'responds to check_trailing?' do
      expect(validator.send(:check_trailing?)).to be(true)
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
end
