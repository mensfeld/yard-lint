# frozen_string_literal: true

# Test fixture for literal types in YARD tags
# YARD accepts these as valid type literals, but TypesExplainer::Parser rejects them
# See: https://github.com/mensfeld/yard-lint/issues/109

class SymbolLiteralTypes
  # --- Simple symbol literals ---

  # @return [:ok, :error] the status
  def simple_symbol_return
    :ok
  end

  # @param level [:debug, :info, :warn, :error] the log level
  # @return [void]
  def simple_symbol_param(level)
    level
  end

  # @param direction [:asc, :desc] sort direction
  # @return [:asc, :desc] applied direction
  def simple_symbol_param_and_return(direction)
    direction
  end

  # --- Single symbol literal ---

  # @return [:singleton] always returns this one symbol
  def single_symbol
    :singleton
  end

  # --- Symbols with underscores and numbers ---

  # @param key [:foo_bar, :baz_123, :a_b_c] the key
  # @return [void]
  def symbol_with_underscores(key)
    key
  end

  # --- Predicate, bang, and setter symbols ---

  # @param check [:empty?, :nil?, :valid?] predicate to call
  # @return [Boolean]
  def predicate_symbol(check)
    send(check)
  end

  # @param action [:save!, :destroy!, :reload!] action to perform
  # @return [void]
  def bang_symbol(action)
    send(action)
  end

  # @param attr [:name=, :value=] attribute to set
  # @return [void]
  def setter_symbol(attr)
    send(attr, nil)
  end

  # --- Quoted symbol literals ---

  # @param header [:"content-type", :"x-request-id"] the HTTP header
  # @return [String]
  def quoted_symbol(header)
    header.to_s
  end

  # --- String literals ---

  # @param mode ["read", "write", "append"] the file mode
  # @return [void]
  def string_literal_param(mode)
    mode
  end

  # @return ["success", "failure"] the outcome
  def string_literal_return
    'success'
  end

  # @param sep [".", "/", "-"] the separator character
  # @return [void]
  def string_literal_special_chars(sep)
    sep
  end

  # --- Mixed literals with regular types ---

  # @param type [:text, :html, Symbol] content type or custom symbol
  # @return [String] rendered content
  def symbol_mixed_with_class(type)
    type.to_s
  end

  # @param val ["on", "off", Boolean] string or boolean
  # @return [void]
  def string_mixed_with_class(val)
    val
  end

  # @param input [:ok, "error", nil] symbol, string, or nil
  # @return [void]
  def symbol_string_nil_mix(input)
    input
  end

  # --- Literals in @option tags ---

  # @param opts [Hash] options hash
  # @option opts [:asc, :desc] :direction sort direction
  # @option opts ["csv", "json"] :format output format
  # @return [Array] sorted results
  def literals_in_option(opts)
    opts
  end

  # --- Literals in @yieldreturn ---

  # @yieldreturn [:success, :failure] the outcome
  def symbol_in_yieldreturn
    yield
  end

  # @yieldreturn ["done", "pending"] the status
  def string_in_yieldreturn
    yield
  end

  # --- Multiple symbol-only types across tags ---

  # @param status [:active, :inactive, :pending, :archived] the status
  # @param priority [:low, :medium, :high, :critical] the priority
  # @return [:ok, :error] the result
  def many_symbol_params(status, priority)
    :ok
  end

  # --- Multiple string-only types across tags ---

  # @param level ["DEBUG", "INFO", "WARN", "ERROR"] the log level
  # @param format ["text", "json", "xml"] the output format
  # @return ["ok", "fail"] the result
  def many_string_params(level, format)
    'ok'
  end
end
