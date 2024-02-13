module SoftwareVersion
  class Version
    include Comparable

    attr_reader :v

    def initialize(raw_version)
      @v = raw_version
    end

    def <=>(other)
      other_tokens = other.is_a?(Version) ? other.tokens : parse(other.to_s)
      tokens.zip(other_tokens) do |left, right|
        cmp = left[0] <=> right[0]
        cmp = left[1] <=> right[1] if cmp == 0
        return cmp if cmp != 0
      end
      0
    end

    def to_s
      @v.to_s
    end

    def to_str
      to_s
    end

    def epoch
      if !tokens.empty? && tokens[0][0] == Token::EPOCH
        tokens[0][1]
      else
        0
      end
    end

    def major
      version_parts[0]
    end

    def minor
      version_parts[1]
    end

    def patch
      version_parts[2]
    end

    protected

    module Token
      # Token types. Their value must be ordered such that :
      #
      #     1alpha (PREVERSION)
      #   < 1 (EOV)
      #   < 1-1 (DASH)
      #   < 1+1 (PLUS)
      #   < 1~1 (TILDE)
      #   < 1g (WORD)
      #   < 1_1 (UNDERSCORE)
      #   < 1.1 (DOT)
      #   < 1:1 (EPOCH)
      #   < ^ (MAX)
      #
      # COLON, DOT and TILDE are only used as a literal tokens and are stripped
      # from the semantic tokens. Their only use is to separate numbers. Some
      # special words are stripped for the same reason. Thus: 1.1 = 1~1 = 1u1.
      #
      PREVERSION = 10
      EOV = 20 # end of version
      DASH = 30
      PLUS = 31
      TILDE = 32
      COLON = 33
      CARET = 34
      WORD = 40
      UNDERSCORE = 50
      DOT = 51
      NUMBER = 52
      EPOCH = 60
      MAX = 99
    end

    # Returns an Array of Token. It is fully loaded and cached to boost future
    # comparisons.
    def tokens
      @tokens ||= parse(@v.to_s)
    end

    private

    # Associate characters to their token types. Multiple characters of the
    # same type are grouped together to form a single unit.
    CHARACTERS_TOKEN = {
        '.' => Token::DOT,
        '~' => Token::TILDE,
        '+' => Token::PLUS,
        '-' => Token::DASH,
        ':' => Token::COLON,
        '^' => Token::CARET,
        '_' => Token::UNDERSCORE,
        '0' => Token::NUMBER,
        '1' => Token::NUMBER,
        '2' => Token::NUMBER,
        '3' => Token::NUMBER,
        '4' => Token::NUMBER,
        '5' => Token::NUMBER,
        '6' => Token::NUMBER,
        '7' => Token::NUMBER,
        '8' => Token::NUMBER,
        '9' => Token::NUMBER,
      }.tap { |h| h.default = Token::WORD }.freeze

    # Cut the version string into literal tokens, without further
    # interpretation. 1:2.3beta becomes NUMBER COLON NUMBER NUMBER WORD EOV. Returns an Array of Token.
    def lex(version_string)
      tokens = []
      chunk_type = nil
      chunk_value = ''
      commit = ->() {
        case chunk_type
        when nil then return
        when Token::NUMBER then tokens << [Token::NUMBER, chunk_value.to_i]
        when Token::WORD then tokens << [Token::WORD, chunk_value.downcase]
        else tokens << [chunk_type, chunk_value]
        end
        chunk_type = nil
        chunk_value = ''
      }
      version_string.each_char do |c|
        char_type = CHARACTERS_TOKEN[c]
        commit.call if chunk_type != char_type
        chunk_type = char_type
        chunk_value << c
      end
      commit.call
      tokens << [Token::EOV, nil]
      tokens
    end

    # Return an enumarable of semantic Token from a version string.
    def parse(version_string)
      semantic_tokens = []

      literal_tokens = lex(version_string)
      literal_tokens << nil # Sentinel for each_cons.
      literal_tokens.each_cons(2) do |current, ahead|
        case current[0]
        when Token::NUMBER
          # When emitting a zero number followed by a colon, we turn it into
          # an EPOCH so that 1:1 > 2, as most Linux distributions expect.
          if ahead[0] == Token::COLON
            semantic_tokens << [Token::EPOCH, current[1]]
          else
            semantic_tokens << current
          end

        # Dots are always dropped because they bear no semantic value.
        when Token::DOT

        # Tildes are ignored unconditionally because they are usually used
        # for preversions without extra semantic meaning.
        when Token::TILDE

        # Underscores are sometimes used to specify subversions on
        # distributions, like el6_7. They’re like dots, so dropped.
        when Token::UNDERSCORE

        # Colon tokens are dropped because their only use is to turn the
        # previous NUMBER into an EPOCH, which is handled by the NUMBER case.
        when Token::COLON

        # In case the version ends with '^', we consider that it is highest version possible
        # For example: '6.0.^' > '6.0.999999'
        # If this is not the final character, then we treat it as the literal CARET character
        when Token::CARET
          semantic_tokens << (ahead[0] == Token::EOV ? [Token::MAX, current[1]] : current)

        when Token::WORD
          case current[1]
          # Some special words are just fancy ways of making a subversion.
          # Semantically, they are nothing more than dots, so 1u1 = 1.1. Some
          # softwares have versions like 1a, 1b, 1c, so we skip these word
          # tokens only when immediately followed by a number.
          when 'r', 'u', 'p', 'v'
            semantic_tokens << current unless ahead[0] == Token::NUMBER
          when 'rev', 'revision', 'update', 'patch'
            # Drop.
          # 52.0a2 is assumed to mean 52.0alpha2, while 52b would be the
          # version before 52c. We distinguish them with the token ahead.
          when 'a', 'b'
            if ahead[0] == Token::NUMBER
              semantic_tokens << [Token::PREVERSION, current[1]]
            else
              semantic_tokens << current
            end
          # Non-abbreviated pre-versions may or may not be followed by a
          # number. 1.0alpha < 1.0.
          when 'alpha', 'beta', 'rc'
            semantic_tokens << [Token::PREVERSION, current[1]]
          # Unknown words are left intact.
          else
            semantic_tokens << current
          end

        # Other tokens like + and - are left intact.
        else
          semantic_tokens << current
        end
      end

      normalize(semantic_tokens)
    end

    # Normalize versions by dropping useless zeroes in order to have 1.0.0 = 1.
    # This step is performed after semantic parsing because we want 1.0.r1 ≠
    # 1r1, but also 1.0.noarch = 1.noarch.
    # Token::MAX should work as Token::NUMBER so 6.^ != 6.0.^ and 6.0.^ < 6.1
    def normalize(tokens)
      new_tokens = []
      held_tokens = []
      tokens.each do |token|
        if [Token::NUMBER, Token::MAX].include?(token[0])
          if token[1] == 0
            held_tokens << token
            next
          else
            new_tokens.concat(held_tokens)
          end
        end
        held_tokens.clear
        new_tokens << token
      end
      new_tokens
    end

    # Return the first number sequence in the version as an array of Integer,
    # skipping the epoch.
    def version_parts
      return @version_parts if @version_parts

      parts = []
      tokens.each do |t|
        if t[0] == Token::NUMBER
          parts << t[1]
        elsif !parts.empty?
          break
        end
      end
      parts << 0 while parts.length < 3
      @version_parts = parts
    end
  end

  # Convert the argument to a Version, unless it already is one.
  def Version(version)
    version.is_a?(Version) ? version : Version.new(version)
  end
  module_function :Version
end
