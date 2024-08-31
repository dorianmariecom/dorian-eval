# frozen_string_literal: true

require "yaml"

class Dorian
  class Eval
    Return = Data.define(:stdout, :stderr, :returned)

    attr_reader :ruby,
                :it,
                :debug,
                :stdout,
                :stderr,
                :colorize,
                :rails,
                :returns

    COLORS = { red: "\e[31m", green: "\e[32m", reset: "\e[0m" }.freeze

    def initialize(
      ruby: nil,
      it: nil,
      debug: false,
      stdout: true,
      stderr: true,
      colorize: false,
      rails: false,
      returns: false
    )
      @ruby = ruby.to_s.empty? ? "nil" : ruby
      @it = it.to_s.empty? ? nil : it
      @debug = !!debug
      @stdout = !!stdout
      @stderr = !!stderr
      @colorize = !!colorize
      @rails = !!rails
      @returns = !!returns
    end

    def self.eval(...)
      new(...).eval
    end

    def eval
      read_out, write_out = IO.pipe
      read_err, write_err = IO.pipe

      spawn(write_out:, write_err:)

      write_out.close
      write_err.close

      out = ""
      err = ""

      while !read_out.eof? || !read_err.eof?
        out += gets(read_out, print: stdout?, method: :puts).to_s
        err += gets(read_err, color: :red, print: stderr?, method: :warn).to_s
      end

      if returns?
        Return.new(stdout: out, stderr: err, returned: YAML.safe_load(out))
      else
        Return.new(stdout: out, stderr: err, returned: nil)
      end
    end

    def debug?
      !!debug
    end

    def stdout?
      !!stdout
    end

    def stderr?
      !!stderr
    end

    def colorize?
      !!colorize
    end

    def rails?
      !!rails
    end

    def returns?
      !!returns
    end

    def prefix
      debug? && !returns? && it ? "[#{it}] " : ""
    end

    def to_ruby(ruby)
      if ruby.is_a?(Struct)
        keys = ruby.to_h.keys.map { |key| to_ruby(key) }
        values = ruby.to_h.values.map { |value| to_ruby(value) }
        "Struct.new(#{keys.join(", ")}).new(#{values.join(", ")})"
      elsif ruby.is_a?(String) || ruby.is_a?(Symbol) || ruby.is_a?(NilClass) ||
        ruby.is_a?(TrueClass) || ruby.is_a?(FalseClass) || ruby.is_a?(Float) ||
        ruby.is_a?(Integer)
        ruby.inspect
      elsif ruby.is_a?(Array)
        "[#{ruby.map { |element| to_ruby(element) }.join(", ")}]"
      elsif ruby.is_a?(Hash)
        "{#{ruby.map { |key, value| "#{to_ruby(key)} => #{to_ruby(value)}" }}}"
      else
        raise "#{ruby.class} not supported"
      end
    end

    def full_ruby
      full_ruby = "it = #{to_ruby(it)}\n"
      full_ruby +=
        if returns?
          <<~RUBY
            require "yaml"
            puts (#{ruby}).to_yaml
          RUBY
        else
          <<~RUBY
            #{ruby}
          RUBY
        end

      full_ruby = <<~RUBY if rails?
        require "#{Dir.pwd}/config/environment"
        #{full_ruby}
      RUBY

      full_ruby
    end

    def spawn(write_out:, write_err:)
      Process.spawn(
        RbConfig.ruby,
        "-e",
        full_ruby,
        out: write_out,
        err: write_err
      )
    end

    def gets(read, color: nil, print: true, method: :puts)
      original_string = read.gets
      return unless original_string

      string = original_string.rstrip
      string = colorize_string(string, color) if colorize? && color

      if method == :puts && print
        puts [prefix, string].join
      elsif method == :warn && print
        warn [prefix, string].join
      end

      original_string
    end

    def colorize_string(string, color)
      return string unless color

      [COLORS.fetch(color), string, COLORS.fetch(:reset)].join
    end
  end
end
