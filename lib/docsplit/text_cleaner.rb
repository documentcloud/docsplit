require 'strscan'

module Docsplit

  # Cleans up OCR'd text by using a series of heuristics to remove garbage
  # words. Algorithms taken from:
  #
  #     Automatic Removal of "Garbage Strings" in OCR Text: An Implementation
  #       -- Taghva, Nartker, Condit, and Borsack
  #
  #     Improving Search and Retrieval Performance through Shortening Documents,
  #     Detecting Garbage, and Throwing out Jargon
  #       -- Kulp
  #
  class TextCleaner

    # Cached regexes we plan on using.
    WORD        = /\S+/
    SPACE       = /\s+/
    NEWLINE     = /[\r\n]/
    ALNUM       = /[a-z0-9]/i
    PUNCT       = /[[:punct:]]/i
    REPEAT      = /([^0-9])\1{2,}/
    UPPER       = /[A-Z]/
    LOWER       = /[a-z]/
    ACRONYM     = /^\(?[A-Z0-9\.-]+('?s)?\)?[.,:]?$/
    ALL_ALPHA   = /^[a-z]+$/i
    CONSONANT   = /(^y|[bcdfghjklmnpqrstvwxz])/i
    VOWEL       = /([aeiou]|y$)/i
    CONSONANT_5 = /[bcdfghjklmnpqrstvwxyz]{5}/i
    VOWEL_5     = /[aeiou]{5}/i
    REPEATED    = /(\b\S{1,2}\s+)(\S{1,3}\s+){5,}(\S{1,2}\s+)/
    SINGLETONS  = /^[AaIi]$/

    # For the time being, `clean` uses the regular StringScanner, and not the
    # multibyte-aware version, coercing to ASCII first.
    def clean(text)
      if String.method_defined?(:encode)
        text.encode!('ascii', :invalid => :replace, :undef => :replace, :replace => '?')
      else
        require 'iconv' unless defined?(Iconv)
        text = Iconv.iconv('ascii//translit//ignore', 'utf-8', text).first
      end

      scanner = StringScanner.new(text)
      cleaned = []
      spaced  = false
      loop do
        if space = scanner.scan(SPACE)
          cleaned.push(space) unless spaced && (space !~ NEWLINE)
          spaced = true
        elsif word = scanner.scan(WORD)
          unless garbage(word)
            cleaned.push(word)
            spaced = false
          end
        elsif scanner.eos?
          return cleaned.join('').gsub(REPEATED, '')
        end
      end
    end

    # Is a given word OCR garbage?
    def garbage(w)
      acronym = w =~ ACRONYM

      # More than 30 bytes in length.
      (w.length > 30) ||

      # If there are three or more identical characters in a row in the string.
      (w =~ REPEAT) ||

      # More punctuation than alpha numerics.
      (!acronym && (w.scan(ALNUM).length < w.scan(PUNCT).length)) ||

      # Ignoring the first and last characters in the string, if there are three or
      # more different punctuation characters in the string.
      (w[1...-1].scan(PUNCT).uniq.length >= 3) ||

      # Four or more consecutive vowels, or five or more consecutive consonants.
      ((w =~ VOWEL_5) || (w =~ CONSONANT_5)) ||

      # Number of uppercase letters greater than lowercase letters, but the word is
      # not all uppercase + punctuation.
      (!acronym && (w.scan(UPPER).length > w.scan(LOWER).length)) ||

      # Single letters that are not A or I.
      (w.length == 1 && (w =~ ALL_ALPHA) && (w !~ SINGLETONS)) ||

      # All characters are alphabetic and there are 8 times more vowels than
      # consonants, or 8 times more consonants than vowels.
      (!acronym && (w.length > 2 && (w =~ ALL_ALPHA)) &&
        (((vows = w.scan(VOWEL).length) > (cons = w.scan(CONSONANT).length) * 8) ||
          (cons > vows * 8)))
    end

  end

end
