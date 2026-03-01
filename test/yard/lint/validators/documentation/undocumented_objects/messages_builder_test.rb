# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Documentation::UndocumentedObjects::MessagesBuilder' do
  it 'call builds message for undocumented object' do
    offense = { element: 'MyClass' }

    message = Yard::Lint::Validators::Documentation::UndocumentedObjects::MessagesBuilder.call(offense)

    end
  it 'call builds message for undocumented module' do
    offense = { element: 'MyModule::MyClass' }

    message = Yard::Lint::Validators::Documentation::UndocumentedObjects::MessagesBuilder.call(offense)

    end
end

