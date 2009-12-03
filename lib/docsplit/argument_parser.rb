module DocSplit

  module ArgumentParser

    # Flatten an options hash into an arguments string suitable for the command
    # line.
    def parse_options(opts)
      opts.map {|k, v| ["--#{k}", normalize_value(v)] }.flatten.join(' ')
    end

    # Normalize a value in an options hash for the command line.
    # Ranges look like: 1-10, Arrays like: 1,2,3.
    def normalize_value(value)
      case value
      when Range then normalize_range(value)
      when Array then value.map! {|v| v.is_a?(Range) ? normalize_range(v) : v }.join(',')
      else            value.to_s
      end
    end

    # Serialize a Ruby range into it's command-line equivalent.
    def normalize_range(range)
      arr = range.to_a
      arr.empty? ? range.first.to_s : "#{range.first}-#{arr.last}"
    end

  end

  extend ArgumentParser

end
