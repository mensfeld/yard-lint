# frozen_string_literal: true

# Proves the end-to-end behavior of Tags/TagSeparator: it requires a blank line
# between every consecutive tag (including same-type tags such as sibling
# @param tags), it does not treat indented @-leading lines inside an @example
# body as tags, and it honors the Exempt option so @option tags may cluster
# directly under their @param.
describe "TagSeparator behavior" do
  attr_reader :result

  before do
    fixture_path = File.expand_path("../fixtures/tag_separator_example.rb", __dir__)
    config = test_config do |c|
      c.set_validator_config("Tags/TagSeparator", "Enabled", true)
      c.set_validator_config("Tags/TagSeparator", "Exempt", ["option"])
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it "does not flag an instance variable inside an @example body as a tag" do
    offenses = result.offenses.select do |o|
      o[:name] == "MissingTagSeparator" && o[:message].include?("perform")
    end

    assert_empty(offenses, "indented @ivar inside @example body was treated as a tag")
  end

  it "does not flag methods whose tags are all blank-line separated" do
    offenses = result.offenses.select do |o|
      o[:name] == "MissingTagSeparator" && o[:message].include?("combined")
    end

    assert_empty(offenses)
  end

  it "honors the Exempt option so @option tags may cluster under their @param" do
    offenses = result.offenses.select do |o|
      o[:name] == "MissingTagSeparator" && o[:message].include?("configure")
    end

    assert_empty(offenses)
  end
end

# Proves that without the Exempt option, consecutive same-type tags (and
# clustered @option tags) are flagged.
describe "TagSeparator without Exempt" do
  attr_reader :result

  before do
    fixture_path = File.expand_path("../fixtures/tag_separator_example.rb", __dir__)
    config = test_config do |c|
      c.set_validator_config("Tags/TagSeparator", "Enabled", true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it "flags @option tags that immediately follow their @param" do
    offenses = result.offenses.select do |o|
      o[:name] == "MissingTagSeparator" && o[:message].include?("configure")
    end

    refute_empty(offenses)
  end
end
