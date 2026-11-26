# frozen_string_literal: true

module Gitalytics
  # Width-aware text helpers for the terminal summary. Expects @color.
  module CliText
    BAR_WIDTH = 10
    BLOCKS = [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█'].freeze
    STYLES = { bold: 1, dim: 2, green: 32, red: 31, cyan: 36 }.freeze

    private

    def bar(percent)
      eighths = (percent / 100.0 * BAR_WIDTH * 8).round
      eighths = 1 if eighths.zero? && percent.positive?
      full, part = eighths.divmod(8)
      (('█' * full) + (part.positive? ? BLOCKS[part] : '')).ljust(BAR_WIDTH)
    end

    def truncate(text, width)
      return text if visible_length(text) <= width

      "#{text[0, width - 1]}…"
    end

    def pad(text, width, left: false)
      spaces = ' ' * [width - visible_length(text), 0].max
      left ? spaces + text : text + spaces
    end

    def visible_length(text)
      text.gsub(/\e\[[\d;]*m/, '').length
    end

    def paint(text, style)
      return text unless @color

      "\e[#{STYLES.fetch(style)}m#{text}\e[0m"
    end
  end
end
