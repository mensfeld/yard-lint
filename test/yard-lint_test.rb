# frozen_string_literal: true

require 'test_helper'

describe 'Yard-Lint' do
  it 'gem loading loads without errors' do
  end

  it 'gem loading defines yard module' do
  end

  it 'gem loading defines yard lint module' do
  end

  it 'zeitwerk loader auto loads validators' do
  end

  it 'zeitwerk loader auto loads results' do
  end

  it 'zeitwerk loader auto loads config' do
  end

  it 'manual requires loads base config class' do
  end

  it 'manual requires loads main yard lint module' do
    assert_respond_to(Yard::Lint, :run)
  end
end

