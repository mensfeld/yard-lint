module Standard::Minitest
  class Plugin < LintRoller::Plugin
    def initialize(config)
      @config = config
    end

    def about
      LintRoller::About.new(
        name: "standard-minitest",
        version: VERSION,
        homepage: "https://github.com/kirillplatonov/standard-minitest",
        description: "Configuration for rubocop-minitest rules"
      )
    end

    def supported?(context)
      true
    end

    def rules(context)
      LintRoller::Rules.new(
        type: :path,
        config_format: :rubocop,
        value: Pathname.new(__dir__).join("../../../config/base.yml")
      )
    end
  end
end
