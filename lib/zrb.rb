module ZRB
  class Parser
    attr_reader :data, :source, :filename, :lineno

    def initialize(data, filename, lineno)
      @data = data
      @filename = filename
      @lineno = lineno
      @source = ""
      @state = :ruby
      generate
    end

    SPACE = /[\t ]/

    TOKEN = /
      (.*?) # Regular text
      (?:
        ( # Expression start
          \#\{
        ) 

      | (?: # Statement
          (^#{SPACE}*)? 
          \<\? (.*?) \?>
          (#{SPACE}*\n)?  # Remove trailing newline
        ) 
      | \z
      )
    /mx

    EXPR_CLOSE = '}'

    def parse
      pos = 0
      while pos < data.size
        match = data.match(TOKEN, pos)
        raise SyntaxError, "#{filename}:#{lineno}: parse error" unless match
        all, text, expr, _, statement, statement_space = *match
        pos += all.size

        yield :text, text unless text.empty?

        if expr
          # Start looking for a closing brace
          closing_pos = pos
          begin
            closing_pos = data.index(EXPR_CLOSE, closing_pos + 1)
            break unless closing_pos
            expr = data[pos...closing_pos]
          end until valid_ruby?(expr)

          if !closing_pos
            raise SyntaxError, "#{filename}:#{lineno}: unclosed brace"
          end

          yield :expression, expr

          pos = closing_pos + 1
        end

        if statement
          case statement[0]
          when ?=
            # block expression
            yield :block_expression, statement[1..-1]
          when ?#
            # comment
            yield :comment, statement[1..-1]
          else
            yield :statement, statement
          end
        end

        yield :newline if statement_space
      end 
    end

    def valid_ruby?(text)
      catch(:halt) do
        eval("BEGIN{throw :halt};#{text}")
      end
    rescue SyntaxError
      false
    else
      true
    end

    def ensure_string
      if @state != :string
        source << 'buffer << "'
        @state = :string
      end
    end

    def append_text(text)
      escaped = text.split("\n", -1).map { |part| part.inspect[1..-2] }.join("\n")

      ensure_string
      source << escaped
    end

    def append_expr(ruby)
      ensure_string
      source << "\#{buffer.escape((#{ruby}))}"
    end

    def append_ruby(ruby)
      source << '";' if @state == :string
      source << ruby
      @state = :ruby
    end

    def append_newline
      if @state == :string
        source << "\"\\\n\""
      else
        source << "\n"
      end
    end

    def generate
      append_ruby('buffer = build_zrb_buffer;')

      parse do |type, value|
        case type
        when :text
          append_text(value)
        when :expression
          append_expr(value)
        when :block_expression
          append_ruby("buffer.safe_append=#{value};")
        when :statement
          append_ruby("#{value};")
        when :newline
          append_newline
        when :comment
          # no nothing
        else
          raise "internal error: unknown parsing type"
        end
      end

      append_ruby('buffer')
    end
  end

  require 'tilt'

  class Template < Tilt::Template
    def prepare
      @src = Parser.new(data, eval_file, line).source
    end

    def precompiled_template(locals)
      @src
    end

    Tilt.register Template, 'zrb'
  end

  class Buffer < String
    def escape(other)
      other.to_s
    end

    def safe_append=(other)
      self << escape(other)
    end

    def capture(blk, *args)
      start = self.size
      blk.call(*args)
    ensure
      return self.slice!(start..-1)
    end
  end

  require 'cgi'

  class HTMLBuffer < Buffer
    def to_html; self end

    def escape(other)
      if other.respond_to?(:to_html)
        other.to_html
      else
        CGI.escape_html(other.to_s)
      end
    end
  end
end

