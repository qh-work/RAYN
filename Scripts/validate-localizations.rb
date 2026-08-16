#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

ROOT = File.expand_path("..", __dir__)
SUPPORTED_LOCALES = %w[en fr de es it ja ko zh-Hans zh-Hant].freeze
CATALOGS = %w[
  RAYN/Resources/Localizable.xcstrings
  RAYN/Resources/InfoPlist.xcstrings
].freeze
PLACEHOLDER_PATTERN = /%(?:\d+\$)?(?:@|lld)/
VALID_PERCENT_PATTERN = /%(?:%|\d+\$(?:@|lld)|@|lld)/

errors = []

CATALOGS.each do |relative_path|
  path = File.join(ROOT, relative_path)
  catalog = JSON.parse(File.read(path))
  errors << "#{relative_path}: source language must be en" unless catalog["sourceLanguage"] == "en"

  catalog.fetch("strings").each do |key, entry|
    errors << "#{relative_path}: #{key.inspect} is stale" if entry["extractionState"] == "stale"
    localizations = entry.fetch("localizations", {})
    missing = SUPPORTED_LOCALES - localizations.keys
    extra = localizations.keys - SUPPORTED_LOCALES
    errors << "#{relative_path}: #{key.inspect} missing #{missing.join(', ')}" unless missing.empty?
    errors << "#{relative_path}: #{key.inspect} has unsupported #{extra.join(', ')}" unless extra.empty?

    english = localizations.dig("en", "stringUnit", "value")
    next unless english

    expected_placeholders = english.scan(PLACEHOLDER_PATTERN).sort
    SUPPORTED_LOCALES.each do |locale|
      unit = localizations.dig(locale, "stringUnit")
      next unless unit

      value = unit["value"]
      errors << "#{relative_path}: #{key.inspect} #{locale} is not translated" unless unit["state"] == "translated"
      errors << "#{relative_path}: #{key.inspect} #{locale} is empty" unless value.is_a?(String) && !value.empty?
      next unless value.is_a?(String)

      actual_placeholders = value.scan(PLACEHOLDER_PATTERN).sort
      if actual_placeholders != expected_placeholders
        errors << "#{relative_path}: #{key.inspect} #{locale} placeholder mismatch"
      end
      remainder = value.gsub(VALID_PERCENT_PATTERN, "")
      errors << "#{relative_path}: #{key.inspect} #{locale} has an unescaped percent" if remainder.include?("%")
    end
  end
end

unless errors.empty?
  warn errors.join("\n")
  exit 1
end

puts "Localization catalogs are complete for #{SUPPORTED_LOCALES.length} locales."
