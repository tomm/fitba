# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: true
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/sprockets-rails/all/sprockets-rails.rbi
#
# sprockets-rails-2.3.3

module Sprockets
end
module Sprockets::Rails
end
module Sprockets::Rails::Helper
  def asset_digest(path, options = nil); end
  def asset_digest_path(path, options = nil); end
  def asset_needs_precompile?(source, filename); end
  def asset_path(source, options = nil); end
  def assets; end
  def check_dependencies!(dep); end
  def check_errors_for(source, options); end
  def compute_asset_path(path, options = nil); end
  def javascript_include_tag(*sources); end
  def lookup_asset_for_path(path, options = nil); end
  def path_to_asset(source, options = nil); end
  def precompile; end
  def raise_runtime_errors; end
  def request_debug_assets?; end
  def self.assets; end
  def self.assets=(arg0); end
  def self.extended(obj); end
  def self.included(klass); end
  def self.precompile; end
  def self.precompile=(arg0); end
  def self.raise_runtime_errors; end
  def self.raise_runtime_errors=(arg0); end
  def stylesheet_link_tag(*sources); end
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::AssetUrlHelper
  include ActionView::Helpers::TagHelper
end
class Sprockets::Rails::Helper::AssetFilteredError < StandardError
  def initialize(source); end
end
class Sprockets::Rails::Helper::AbsoluteAssetPathError < Sprockets::ArgumentError
  def initialize(bad_path, good_path, prefix); end
end
module Rails
end
class Rails::Application < Rails::Engine
  def assets_manifest; end
  def assets_manifest=(arg0); end
end
class Rails::Application::Configuration < Rails::Engine::Configuration
end
class Rails::Engine < Rails::Railtie
end
class Sprockets::Railtie < Rails::Railtie
end
class Sprockets::Railtie::OrderedOptions < ActiveSupport::OrderedOptions
  def configure(&block); end
end
