class Dorian
  class Eval
    attr_reader :ruby, :it, :debug, :stdout, :stderr, :colorize

    COLORS = {
      red: "\e[31m",
      green: "\e[32m",
      reset: "\e[0m"
    }

    def initialize(
      *args,
      ruby: "",
      it: "",
      debug: false,
      stdout: true,
      stderr: true,
      colorize: false
    )
      @ruby = ruby.empty? ? args.join(" ") : ruby
      @it = it
      @debug = !!debug
      @stdout = !!stdout
      @stderr = !!stderr
      @colorize = !!colorize
    end

    def self.eval(...)
      new(...).eval
    end

    def eval
      read_out, write_out = IO.pipe
      read_err, write_err = IO.pipe

      Process.spawn(
        RbConfig.ruby,
        "-e",
        "it = #{it.inspect}",
        "-e",
        ruby,
        out: write_out,
        err: write_err
      )

      write_out.close
      write_err.close

      out = ""
      err = ""

      while !read_out.eof? || !read_err.eof?
        out << gets(read_out, color: :green, print: stdout?).to_s
        err << gets(read_err, color: :red, print: stderr?).to_s
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

    def prefix
      debug? ? "[#{it}] " : ""
    end

    def gets(read, color: nil, print: true)
      original_string = read.gets
      return unless original_string
      string = original_string.rstrip
      string = colorize? ? colorize_string(string, color) : string
      puts([prefix, string].join) if print
      original_string
    end

    def colorize_string(string, color)
      [COLORS.fetch(color), string, COLORS.fetch(:reset)]
    end
  end
end
