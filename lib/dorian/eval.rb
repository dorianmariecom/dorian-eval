# frozen_string_literal: true

class Dorian
  class Eval
    attr_reader :ruby, :it, :debug, :stdout, :stderr, :colorize, :rails

    COLORS = { red: "\e[31m", green: "\e[32m", reset: "\e[0m" }.freeze

    def initialize(
      *args,
      ruby: "",
      it: "",
      debug: false,
      stdout: true,
      stderr: true,
      colorize: false,
      rails: false
    )
      @ruby = ruby.empty? ? args.join(" ") : ruby
      @it = it
      @debug = !!debug
      @stdout = !!stdout
      @stderr = !!stderr
      @colorize = !!colorize
      @rails = !!rails
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

      [out, err]
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

    def prefix
      debug? ? "[#{it}] " : ""
    end

    def full_ruby
      full_ruby = <<~RUBY
        it = #{it.inspect}
        #{ruby}
      RUBY

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
