module SoftwareVersion
  class Version
    include Comparable

    attr_reader :v,
                :epoch,
                :version,
                :revision,
                :release,
                :arch

    def initialize(raw_version)
      @v = raw_version
      parse_raw_version(to_s)
    end

    def <=>(other)
      raise ArgumentError unless other.class == SoftwareVersion::Version

      # Compare the epoch of both versions
      result = version_compare_part(@epoch, other.epoch)
      return result if result.nonzero?

      # Compare the version of both versions
      result = version_compare_part(@version, other.version)
      return result if result.nonzero?

      # Compare the revision of both versions
      result = version_compare_part(@revision, other.revision)
      return result if result.nonzero?

      # Compare the release of both versions
      version_compare_part(@release, other.release)
    end

    def to_s
      @v.to_s
    end

    def to_str
      to_s
    end

    def major
      sv[0]
    end

    def minor
      sv[1]
    end

    def patch
      sv[2]
    end

    private

    # parse the raw version to separate the version, the epoch and the revision
    def parse_raw_version(raw_version)
      version = raw_version

      if (parsed_raw = version.match(/\A([^:]*):(.+)\z/))
        @epoch = parsed_raw[1]
        version = parsed_raw[2]
      else
        @epoch = '0'
      end

      if (parsed_release = version.match(/(.*)\.(el[4-8](?:_\d+(?:\.\d+)?)?)/))
        version = parsed_release[1]
        @release = parsed_release[2]
      else
        @release = '0'
      end

      @version, @revision = version.split('-', 2)
      @version ||= version
      @revision ||= '0'
    end

    # Parse the version to get the major, minor and patch parts
    def sv
      @sv ||= version.scan(/(?:\d+|[a-zA-Z]+)/)
    end

    def version_split_digits(part)
      part.scan(/(?:\d+|\D+)/)
    end

    def version_compare_part(self_part, other_part)
      return 0 if (self_part <=> other_part) == 0

      self_part = version_split_digits(self_part)
      other_part = version_split_digits(other_part)

      index = 0
      loop do
        return 0 unless self_part[index] || other_part[index]

        self_part[index] ||= 0
        other_part[index] ||= 0

        if (self_part[index] <=> other_part[index]) == 0
          index += 1
          next
        end

        if numeric?(self_part[index]) && numeric?(other_part[index])
          # Numerical comparison
          result = self_part[index].to_f <=> other_part[index].to_f
          return result if result.nonzero?
        else
          # String comparison
          result = version_compare_string(self_part[index].to_s, other_part[index].to_s)
          return result if result.nonzero?
        end

        index += 1
      end
    end

    def version_compare_string(self_part, other_part)
      self_part = self_part.chars.map { |x| version_order(x) }
      other_part = other_part.chars.map { |x| version_order(x) }

      index = 0

      loop do
        return 0 unless self_part[index] || other_part[index]

        self_part[index] ||= 0 # Default order for "no character"
        other_part[index] ||= 0
        return 1 if self_part[index] > other_part[index]
        return -1 if self_part[index] < other_part[index]

        index += 1
      end
    end

    # convert character into number
    def version_order(part)
      if part.eql? '~'
        -1
      elsif part =~ /^[A-Za-z\d]$/
        part.ord
      else
        part.ord + 128
      end
    end

    def numeric?(obj)
      true if Float(obj)
    rescue StandardError
      false
    end
  end
end
