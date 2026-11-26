# frozen_string_literal: true

require 'gitalytics/cli_text'

module Gitalytics
  # The plain-text summary printed by default: repository totals, the period
  # covered and a table of the top authors. Colors are used only when writing
  # to a terminal and NO_COLOR is not set.
  class CliReport
    DEFAULT_TOP = 10
    DEFAULT_WIDTH = 80
    MIN_WIDTH = 60
    MAX_WIDTH = 120
    include CliText

    def self.color?(io, env = ENV)
      return false if env.key?('NO_COLOR') && !env['NO_COLOR'].empty?
      return false if env['TERM'] == 'dumb'

      io.respond_to?(:tty?) && io.tty?
    end

    def self.width_for(io)
      cols = io.winsize[1] if io.respond_to?(:winsize) && io.tty?
      cols = ENV['COLUMNS'].to_i if cols.to_i.zero?
      cols.to_i.zero? ? DEFAULT_WIDTH : cols
    rescue StandardError
      DEFAULT_WIDTH
    end

    def initialize(report, color: false, width: DEFAULT_WIDTH, top: DEFAULT_TOP)
      @report = report
      @color  = color
      @width  = width.to_i.clamp(MIN_WIDTH, MAX_WIDTH)
      @top    = top.to_i.positive? ? top.to_i : report.users.size
    end

    def render
      return "No commits found.\n" if @report.empty?

      (header + [''] + overview + [''] + authors_table).join("\n") << "\n"
    end

    private

    attr_reader :report

    # ---- Sections -----------------------------------------------------------

    def header
      r = report
      title = "#{paint(r.repo_name, :bold)}  #{r.plural(r.commits.size, 'commit')} by " \
              "#{r.plural(r.users.size, 'author')}"
      period = "#{r.fmt_date(r.first_commit.date)} to #{r.fmt_date(r.last_commit.date)} " \
               "(#{r.plural(r.span_days, 'day')})"
      [title, paint(period, :dim)]
    end

    def overview
      r = report
      busiest_date, busiest = r.busiest_day
      left = [
        ['Lines', "#{paint("+#{r.num(r.total_insertions)}", :green)} #{paint("-#{r.num(r.total_deletions)}", :red)}"],
        ['Files touched', r.num(r.files_touched)],
        ['Active days', "#{r.num(r.active_days)} of #{r.num(r.span_days)}"]
      ]
      right = [
        ['Longest streak', r.plural(r.longest_streak, 'day')],
        ['Busiest day', "#{r.fmt_date(busiest_date)} (#{r.plural(busiest.size, 'commit')})"],
        ['Commits/day', format('%.1f', r.commits.size.to_f / r.active_days)]
      ]
      two_columns(left, right)
    end

    # Two label/value columns side by side, or one stacked list when narrow.
    def two_columns(left, right)
      left_cells = label_list(left)
      right_cells = label_list(right)
      col = widest(left_cells) + 4
      return label_list(left + right).map { |c| "  #{c}" } if 2 + col + widest(right_cells) > @width

      left_cells.zip(right_cells).map { |l, r| "  #{pad(l, col)}#{r}" }
    end

    def widest(cells)
      cells.map { |c| visible_length(c) }.max
    end

    def label_list(pairs)
      lw = pairs.map { |l, _| l.length }.max
      pairs.map { |label, value| "#{paint(label.ljust(lw), :dim)}  #{value}" }
    end

    def authors_table
      cols = columns
      lines = [paint("  #{cols.map { |c| align(c[:title], c) }.join('  ')}".rstrip, :bold)]
      shown_users.each_index do |i|
        lines << "  #{cols.map { |c| align(c[:cells][i], c) }.join('  ')}".rstrip
      end
      rest = report.users.size - shown_users.size
      return lines unless rest.positive?

      lines << paint("  ... and #{report.plural(rest, 'more author')} (use --top 0 to list everyone)", :dim)
    end

    # ---- Author table columns ---------------------------------------------

    def columns
      cols = [
        col('Author', :left) { |u| u.name.to_s },
        col('Commits', :right) { |u| report.num(u.commits.size) },
        col('Share', :right) { |u| format('%.1f%%', report.share(u)) },
        col('', :left, priority: 4) { |u| paint(bar(report.share(u)), :cyan) },
        col('Added', :right, priority: 3) { |u| paint("+#{report.num(u.total_insertions)}", :green) },
        col('Deleted', :right, priority: 3) { |u| paint("-#{report.num(u.total_deletions)}", :red) },
        col('Days', :right, priority: 1) { |u| report.num(u.working_days) },
        col('Last commit', :left, priority: 2) { |u| u.last_commit.date.to_s }
      ]
      fit(cols)
    end

    def col(title, side, priority: 9, &value)
      { title: title, side: side, priority: priority, value: value }
    end

    def shown_users
      @shown_users ||= report.users.first(@top)
    end

    # Size every column to its content, then drop the least important ones
    # until the author name has room.
    def fit(cols)
      cols.each { |c| measure(c) }
      author = cols.first
      name_needed = author[:width].clamp(6, 28)
      loop do
        lowest = cols.map { |c| c[:priority] }.select { |p| p < 9 }.min
        break if name_room(cols) >= name_needed || lowest.nil?

        cols.reject! { |c| c[:priority] == lowest }
      end
      author[:width] = name_room(cols).clamp(6, name_needed)
      cols
    end

    def name_room(cols)
      @width - 2 - cols.drop(1).sum { |c| c[:width] + 2 }
    end

    def measure(column)
      column[:cells] = shown_users.map { |u| column[:value].call(u) }
      column[:width] = column[:cells].map { |t| visible_length(t) }.push(column[:title].length).max
    end

    def align(text, column)
      text = truncate(text, column[:width])
      column[:side] == :right ? pad(text, column[:width], left: true) : pad(text, column[:width])
    end
  end
end
