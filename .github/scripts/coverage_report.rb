#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'

# Turns SimpleCov's coverage.json into a pull request comment: coverage of the
# `lib` files the pull request changes, then of the whole project.
class CoverageReport
  THRESHOLD = 100
  KINDS = %w[lines branches].freeze

  def initialize(path, base_ref)
    @report = JSON.parse(File.read(path))
    @base_ref = base_ref
  end

  def comment = "#{headline}\n\n#{changed_summary}\n\n-----\n\nProject: #{summary(project_counts)}"

  def passed? = changed_counts.values.all? { |covered, total| covered * 100 >= total * THRESHOLD }

  private

  def headline
    if changed_files.empty?
      'ℹ️ No coverable code changed in `lib`'
    elsif passed?
      "✅ Changed files meet the #{THRESHOLD}% coverage threshold"
    else
      "⚠️ Changed files are below the #{THRESHOLD}% coverage threshold"
    end
  end

  def changed_summary
    if changed_files.empty?
      'No changed files to measure.'
    else
      "Changed files (#{changed_files.size}): #{summary(changed_counts)}"
    end
  end

  def summary(counts)
    counts.map { |kind, (covered, total)| "#{kind} #{percent(covered, total)}% (#{covered} of #{total})" }.join(', ')
  end

  def percent(covered, total) = total.zero? ? 100.0 : (100.0 * covered / total).floor(1)

  def project_counts = @report['total'].slice(*KINDS).transform_values { it.values_at('covered', 'total') }

  def changed_counts
    @changed_counts ||= KINDS.to_h do |kind|
      [kind, [changed_files.sum { it["covered_#{kind}"] }, changed_files.sum { it["total_#{kind}"] }]]
    end
  end

  def changed_files
    @changed_files ||= changed_paths.filter_map { @report['coverage'][it] }.reject { it['total_lines'].zero? }
  end

  def changed_paths
    output, status = Open3.capture2('git', 'diff', '--name-only', "origin/#{@base_ref}...HEAD", '--', 'lib/**/*.rb')
    abort "git diff against origin/#{@base_ref} failed" unless status.success?

    output.lines(chomp: true)
  end
end

report = CoverageReport.new(ENV.fetch('COVERAGE_JSON', 'coverage/coverage.json'), ENV.fetch('BASE_REF', 'main'))
puts report.comment

unless report.passed?
  warn "::error::Changed files are below the #{CoverageReport::THRESHOLD}% coverage threshold"
  exit 1
end
