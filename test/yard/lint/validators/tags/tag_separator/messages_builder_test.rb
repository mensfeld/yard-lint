# frozen_string_literal: true

describe "Yard::Lint::Validators::Tags::TagSeparator::MessagesBuilder" do
  it "call with single missing separator generates message for single transition" do
    offense = {
      method_name: "call",
      separators: "param->param"
    }
    message = Yard::Lint::Validators::Tags::TagSeparator::MessagesBuilder.call(offense)

    assert_equal(
      "The `call` is missing a blank line between the `param` and `param` tags.",
      message
    )
  end

  it "call with multiple missing separators generates message listing all transitions" do
    offense = {
      method_name: "process",
      separators: "param->param,param->return"
    }
    message = Yard::Lint::Validators::Tags::TagSeparator::MessagesBuilder.call(offense)

    assert_equal(
      "The `process` is missing blank lines between tags: " \
      "`param` -> `param`, `param` -> `return`.",
      message
    )
  end

  it "call with description to tag transition handles description in message" do
    offense = {
      method_name: "initialize",
      separators: "description->param"
    }
    message = Yard::Lint::Validators::Tags::TagSeparator::MessagesBuilder.call(offense)

    assert_equal(
      "The `initialize` is missing a blank line between the `description` and `param` tags.",
      message
    )
  end
end
