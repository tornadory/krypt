module Krypt
  class HMAC

    def initialize(digest, key)
      @digest = digest
      @key = process_key(key)

      # hash ipad
      hash_pad("\x36")
    end

    def update(data)
      @digest << data
    end
    alias << update

    def digest
      inner_digest = @digest.digest
      # hash opad
      hash_pad("\x5c")
      @digest << inner_digest
      @digest.digest
    end

    def hexdigest
      Krypt::Hex.encode(digest)
    end

    class << self

      def digest(md, key, data)
        hmac = self.new(md, key)
        hmac << data
        hmac.digest
      end

      def hexdigest(md, key, data)
        Krypt::Hex.encode(digest(md, key, data))
      end

    end

    private

      def process_key(key)
        block_len = @digest.block_length

        if key.size > block_len
          key = @digest.digest(key)
        end

        if key.size < block_len
          key + ("\0" * (block_len - key.size))
        else
          key
        end
      end

      def hash_pad(pad_char)
        @digest << Krypt::Helper::String.xor!(pad_char * @key.size, @key)
      end

  end
end
