# encoding: utf-8

require "rubygems"
require "bundler/setup"
require 'rspec'
require 'tempfile'
require 'tempfile'

require 'carrierwave'
require 'carrierwave/orm/mongomapper'

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', *paths))
end

def public_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'public', *paths))
end

CarrierWave.root = public_path

module CarrierWave
  module Test
    module MockStorage
      def mock_storage(kind)
        storage = mock("storage for #{kind} uploader")
        storage.stub!(:setup!)
        storage
      end
    end

    module MockFiles
      def stub_file(filename, mime_type=nil, fake_name=nil)
        f = File.open(file_path(filename))
        return f
      end

      def stub_tempfile(filename, mime_type=nil, fake_name=nil)
        raise "#{path} file does not exist" unless File.exist?(file_path(filename))

        t = Tempfile.new(filename)
        FileUtils.copy_file(file_path(filename), t.path)

        # This is stupid, but for some reason rspec won't play nice...
        eval <<-EOF
        def t.original_filename; '#{fake_name || filename}'; end
        def t.content_type; '#{mime_type}'; end
        def t.local_path; path; end
        EOF

        return t
      end

    end

    module I18nHelpers
      def change_locale_and_store_translations(locale, translations, &block)
        current_locale = I18n.locale
        begin
          I18n.backend.store_translations locale, translations
          I18n.locale = locale
          yield
        ensure
          I18n.reload!
          I18n.locale = current_locale
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include CarrierWave::Test::Matchers
  config.include CarrierWave::Test::MockFiles
  config.include CarrierWave::Test::I18nHelpers
end
