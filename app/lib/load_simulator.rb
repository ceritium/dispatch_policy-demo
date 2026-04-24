# frozen_string_literal: true

# 1D Perlin noise used to give jobs a smoothly-varying simulated workload.
# Each partition key samples a different offset into the same noise field,
# so accounts see independent curves that drift over tens of seconds —
# perfect for watching the adaptive gate chase a moving target.
module LoadSimulator
  PERM = (0..255).to_a.shuffle(random: Random.new(42)).then { |a| a + a }

  class << self
    # 0..1 intensity for `key` at time `now`. `period` controls how fast
    # the curve evolves: at period=30s, the noise walks ~1 unit per 30s.
    def intensity(key, now: Time.current.to_f, period: 30.0)
      x = now / period + offset_for(key)
      (fbm(x) + 1.0) / 2.0
    end

    # Sleep `base_ms + amplitude_ms * intensity(key)` and return the
    # actual duration so the caller can log it if interesting.
    def sleep_for(key, base_ms:, amplitude_ms:, period: 30.0)
      total_ms = base_ms + amplitude_ms * intensity(key, period: period)
      sleep(total_ms / 1000.0)
      total_ms
    end

    private

    # Fractal Brownian motion: sum octaves for richer curves. Result in ~[-1, 1].
    def fbm(x, octaves: 3, lacunarity: 2.0, gain: 0.5)
      total = 0.0
      amp   = 1.0
      freq  = 1.0
      norm  = 0.0
      octaves.times do
        total += amp * noise1d(x * freq)
        norm  += amp
        amp   *= gain
        freq  *= lacunarity
      end
      total / norm
    end

    def noise1d(x)
      xi = x.floor & 255
      xf = x - x.floor
      u  = fade(xf)
      lerp(grad(PERM[xi], xf), grad(PERM[xi + 1], xf - 1), u)
    end

    def fade(t) = t * t * t * (t * (t * 6 - 15) + 10)

    def lerp(a, b, t) = a + t * (b - a)

    def grad(hash, x) = (hash & 1).zero? ? x : -x

    # Stable per-key offset so accounts get distinct but reproducible curves.
    def offset_for(key)
      (Digest::MD5.hexdigest(key.to_s)[0, 8].to_i(16) % 10_000) / 13.37
    end
  end
end
