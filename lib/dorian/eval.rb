# frozen_string_literal: true

require "yaml"

class Dorian
  class Eval
    Return =
      Data.define(:stdout, :stderr, :returned) do
        def initialize(stdout: "", stderr: "", returned: nil)
          super
        end
      end

    attr_reader :ruby,
                :it,
                :debug,
                :stdout,
                :stderr,
                :colorize,
                :rails,
                :returns,
                :fast

    COLORS = { red: "\e[31m", green: "\e[32m", reset: "\e[0m" }.freeze

    def initialize(
      ruby: nil,
      it: nil,
      debug: false,
      stdout: true,
      stderr: true,
      colorize: false,
      rails: false,
      returns: false,
      fast: false
    )
      @ruby = ruby.to_s.empty? ? "nil" : ruby
      @it = it.to_s.empty? ? nil : it
      @debug = !!debug
      @stdout = !!stdout
      @stderr = !!stderr
      @colorize = !!colorize
      @rails = !!rails
      @returns = !!returns
      @fast = !!fast
    end

    def self.eval(...)
      new(...).eval
    end

    def eval
      fast? ? eval_fast : eval_slow
    end

    def eval_fast
      Return.new(returned: Kernel.eval(full_ruby))
    end

    def eval_slow
      read_out, write_out = IO.pipe
      read_err, write_err = IO.pipe

      spawn(write_out:, write_err:)

      write_out.close
      write_err.close

      out = ""
      err = ""

      thread_out =
        Thread.new do
          out +=
            gets(
              read_out,
              print: stdout?,
              method: :puts
            ).to_s until read_out.eof?
        end

      thread_err =
        Thread.new do
          err +=
            gets(
              read_err,
              color: :red,
              print: stderr?,
              method: :warn
            ).to_s until read_err.eof?
        end

      thread_out.join
      thread_err.join

      if returns?
        Return.new(stdout: out, stderr: err, returned: YAML.safe_load(out))
      else
        Return.new(stdout: out, stderr: err)
      end
    end

    def fast?
      !!fast
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
      case ruby
      when Struct
        keys = ruby.to_h.keys.map { |key| to_ruby(key) }
        values = ruby.to_h.values.map { |value| to_ruby(value) }
        "Struct.new(#{keys.join(", ")}).new(#{values.join(", ")})"
      when String, Symbol, NilClass, TrueClass, FalseClass, Float, Integer
        ruby.inspect
      when Array
        "[#{ruby.map { |element| to_ruby(element) }.join(", ")}]"
      when Hash
        "{#{ruby.map { |key, value| "#{to_ruby(key)} => #{to_ruby(value)}" }}}"
      else
        raise "#{ruby.class} not supported"
      end
    end

    def slow?
      !fast?
    end

    def full_ruby
      full_ruby = "it = #{to_ruby(it)}\n"
      full_ruby +=
        if returns? && slow?
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
