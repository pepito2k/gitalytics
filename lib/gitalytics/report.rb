# frozen_string_literal: true

require 'date'
require 'erb'

module Gitalytics
  # Builds the data behind the HTML report and renders it into a single,
  # self-contained HTML page (no external CSS/JS, charts are inline SVG).
  class Report
    include ERB::Util

    TEMPLATE = File.expand_path('../../assets/report.html.erb', __dir__)

    # Categorical palette for the top authors; everyone else shares OTHER_COLOR.
    PALETTE = %w[#4f6bed #e8743b #19a979 #ed4a7b #945ecf #13a4b4 #d6a419 #6c8893].freeze
    OTHER_COLOR = '#a3abb8'
    AUTHORS_SHOWN = 15

    attr_reader :users, :commits, :repo_name, :generated_at

    def initialize(users:, commits:, repo_name: 'repository', generated_at: Time.now)
      @users        = users.reject { |u| u.commits.empty? }
                           .sort_by { |u| [-u.commits.size, u.name.to_s] }
      @commits      = commits.sort_by(&:time)
      @repo_name    = repo_name
      @generated_at = generated_at
    end

    def render
      ERB.new(File.read(TEMPLATE, encoding: 'UTF-8'), trim_mode: '-').result(binding)
    end

    def empty?
      commits.empty?
    end

    # ---- Totals -----------------------------------------------------------

    def first_commit
      commits.first
    end

    def last_commit
      commits.last
    end

    def total_insertions
      @total_insertions ||= commits.sum(&:insertions)
    end

    def total_deletions
      @total_deletions ||= commits.sum(&:deletions)
    end

    def files_touched
      @files_touched ||= commits.flat_map(&:files_committed).uniq.size
    end

    def active_days
      @active_days ||= commits.map(&:date).uniq.size
    end

    def span_days
      (last_commit.date - first_commit.date).to_i + 1
    end

    def longest_streak
      @longest_streak ||= begin
        best = run = 0
        prev = nil
        commits.map(&:date).uniq.sort.each do |d|
          run = prev && d == prev + 1 ? run + 1 : 1
          best = run if run > best
          prev = d
        end
        best
      end
    end

    def busiest_day
      @busiest_day ||= commits.group_by(&:date).max_by { |d, cs| [cs.size, d] }
    end

    # ---- Authors ----------------------------------------------------------

    def color_for(user)
      idx = users.index(user)
      idx && idx < PALETTE.size ? PALETTE[idx] : OTHER_COLOR
    end

    def share(user)
      return 0 if commits.empty?

      (user.commits.size * 100.0 / commits.size)
    end

    # ---- Timeline ---------------------------------------------------------

    # :week for histories shorter than ~18 months, :month otherwise.
    def bucket_unit
      span_days > 540 ? :month : :week
    end

    def bucket_start(date)
      if bucket_unit == :month
        Date.new(date.year, date.month, 1)
      else
        date - ((date.wday - 1) % 7) # Monday
      end
    end

    def buckets
      @buckets ||= begin
        list = []
        cursor = bucket_start(first_commit.date)
        last   = bucket_start(last_commit.date)
        while cursor <= last
          list << cursor
          cursor = bucket_unit == :month ? cursor >> 1 : cursor + 7
        end
        list
      end
    end

    def timeline(list = commits)
      counts = Hash.new(0)
      list.each { |c| counts[bucket_start(c.date)] += 1 }
      buckets.map { |b| [b, counts[b]] }
    end

    def bucket_label(date)
      bucket_unit == :month ? date.strftime('%b %Y') : "Week of #{date.strftime('%b %-d, %Y')}"
    end

    # ---- Punch card ---------------------------------------------------------

    # 7 x 24 matrix of commit counts, rows Monday..Sunday.
    def punch_card
      @punch_card ||= begin
        grid = Array.new(7) { Array.new(24, 0) }
        commits.each { |c| grid[(c.time.wday - 1) % 7][c.time.hour] += 1 }
        grid
      end
    end

    def weekday_totals
      punch_card.map(&:sum)
    end

    # ---- Files ------------------------------------------------------------

    def top_files(limit = 10)
      stats = Hash.new { |h, k| h[k] = { commits: 0, insertions: 0, deletions: 0 } }
      commits.each do |c|
        c.summary.each do |s|
          f = stats[s[:filename]]
          f[:commits]    += 1
          f[:insertions] += s[:insertions]
          f[:deletions]  += s[:deletions]
        end
      end
      stats.sort_by { |name, s| [-(s[:insertions] + s[:deletions]), name] }.first(limit)
    end

    def top_directories(limit = 8)
      churn = Hash.new(0)
      commits.each do |c|
        c.summary.each do |s|
          dir = s[:filename].include?('/') ? "#{s[:filename].split('/').first}/" : '(root)'
          churn[dir] += s[:insertions] + s[:deletions]
        end
      end
      churn.sort_by { |d, n| [-n, d] }.first(limit)
    end

    # ---- Messages ---------------------------------------------------------

    def shortest_message
      commits.reject { |c| c.subject.to_s.strip.empty? }.min_by { |c| c.subject.length }
    end

    def longest_message
      commits.max_by { |c| c.subject.to_s.length }
    end

    # ---- Formatting / SVG helpers ----------------------------------------

    def num(value)
      value.to_i.to_s.reverse.scan(/\d{1,3}/).join(',').reverse
    end

    def fmt_date(date)
      date.strftime('%b %-d, %Y')
    end

    def plural(count, word)
      "#{num(count)} #{count == 1 ? word : "#{word}s"}"
    end

    def timeline_svg(width: 960, height: 220)
      data = timeline
      max = [data.map(&:last).max, 1].max
      pad_l = 36
      pad_b = 24
      plot_w = width - pad_l
      plot_h = height - pad_b - 8
      slot = plot_w.to_f / data.size
      bar_w = [slot - (slot > 4 ? 2 : 0.5), 1].max

      parts = []
      ticks(max).each do |t|
        y = 8 + plot_h - (t * plot_h / max.to_f)
        parts << %(<line class="grid" x1="#{pad_l}" x2="#{width}" y1="#{y.round(1)}" y2="#{y.round(1)}"/>)
        parts << %(<text class="axis" x="#{pad_l - 6}" y="#{(y + 4).round(1)}" text-anchor="end">#{t}</text>)
      end
      data.each_with_index do |(bucket, count), i|
        x = pad_l + (i * slot)
        h = count * plot_h / max.to_f
        y = 8 + plot_h - h
        title = h("#{bucket_label(bucket)}: #{plural(count, 'commit')}")
        parts << %(<rect class="bar" x="#{x.round(2)}" y="#{y.round(2)}" width="#{bar_w.round(2)}" height="#{[h,
                                                                                                              0].max.round(2)}" rx="1.5"><title>#{title}</title></rect>)
      end
      label_years(data).each do |i, text|
        x = pad_l + (i * slot)
        parts << %(<text class="axis" x="#{x.round(1)}" y="#{height - 6}">#{text}</text>)
      end

      %(<svg viewBox="0 0 #{width} #{height}" class="chart" role="img" aria-label="Commits over time">#{parts.join}</svg>)
    end

    def sparkline_svg(user, width: 96, height: 28)
      data = timeline(user.commits).map(&:last)
      max = [data.max, 1].max
      step = data.size > 1 ? width.to_f / (data.size - 1) : width
      points = data.each_with_index.map do |v, i|
        "#{(i * step).round(1)},#{(height - 2 - (v * (height - 4) / max.to_f)).round(1)}"
      end
      points = ["0,#{height - 2}", "#{width},#{height - 2}"] if data.size < 2
      color = color_for(user)
      %(<svg viewBox="0 0 #{width} #{height}" class="spark" aria-hidden="true"><polyline points="#{points.join(' ')}" fill="none" stroke="#{color}" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round"/></svg>)
    end

    def punch_card_svg(width: 960)
      cell = (width - 48) / 24.0
      r_max = cell * 0.42
      height = ((cell * 7) + 22).round
      max = [punch_card.flatten.max, 1].max
      days = %w[Mon Tue Wed Thu Fri Sat Sun]
      parts = []
      punch_card.each_with_index do |row, d|
        cy = (d * cell) + (cell / 2)
        parts << %(<text class="axis" x="40" y="#{(cy + 4).round(1)}" text-anchor="end">#{days[d]}</text>)
        row.each_with_index do |count, hr|
          cx = 48 + (hr * cell) + (cell / 2)
          r = count.zero? ? 1.5 : [Math.sqrt(count / max.to_f) * r_max, 2.5].max
          cls = count.zero? ? 'dot empty' : 'dot'
          title = h("#{days[d]} #{format('%02d:00', hr)}: #{plural(count, 'commit')}")
          parts << %(<circle class="#{cls}" cx="#{cx.round(1)}" cy="#{cy.round(1)}" r="#{r.round(2)}"><title>#{title}</title></circle>)
        end
      end
      [0, 6, 12, 18, 23].each do |hr|
        cx = 48 + (hr * cell) + (cell / 2)
        parts << %(<text class="axis" x="#{cx.round(1)}" y="#{height - 4}" text-anchor="middle">#{format('%02d',
                                                                                                         hr)}h</text>)
      end
      %(<svg viewBox="0 0 #{width} #{height}" class="chart" role="img" aria-label="Commits by weekday and hour">#{parts.join}</svg>)
    end

    private

    def ticks(max)
      step = nice_step(max / 3.0)
      (1..(max / step)).map { |i| i * step }
    end

    def nice_step(raw)
      return 1 if raw <= 1

      mag = 10**Math.log10(raw).floor
      [1, 2, 5, 10].map { |m| m * mag }.find { |s| s >= raw }
    end

    def label_years(data)
      seen = {}
      labels = data.each_with_index.filter_map do |(bucket, _), i|
        next if seen[bucket.year]

        seen[bucket.year] = true
        [i, bucket.year.to_s]
      end
      thin_labels(labels, data.size)
    end

    # Keep year labels from colliding on long histories.
    def thin_labels(labels, total)
      min_gap = (total / 12.0).ceil
      last = -min_gap
      labels.select { |i, _| (i - last >= min_gap).tap { |ok| last = i if ok } }
    end
  end
end
