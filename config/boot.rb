# typed: strict
require 'sorbet-runtime'
T::Configuration.default_checked_level = ENV['RAILS_ENV'] == 'test' ? :always : :never

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
