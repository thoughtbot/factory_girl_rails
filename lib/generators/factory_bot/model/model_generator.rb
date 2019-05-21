require "generators/factory_bot"
require "factory_bot_rails"

module FactoryBot
  module Generators
    class ModelGenerator < Base
      argument(
        :attributes,
        type: :array,
        default: [],
        banner: "field:type field:type",
      )

      class_option(
        :dir,
        type: :string,
        default: "test/factories",
        desc: "The directory or file root where factories belong",
      )

      class_option(
        :suffix,
        type: :string,
        default: nil,
        desc: "Suffix to add factory file",
      )

      def create_fixture_file
        if File.exist?(factories_file)
          insert_factory_into_existing_file
        else
          create_factory_file
        end
      end

      private

      def factories_file
        options[:dir] + ".rb"
      end

      def insert_factory_into_existing_file
        insert_into_file(
          factories_file,
          factory_definition,
          after: "FactoryBot.define do\n",
        )
      end

      def create_factory_file
        file = File.join(options[:dir], "#{filename}.rb")
        template "factories.erb", file
      end

      def factory_definition
        <<~RUBY
            factory :#{singular_table_name}#{explicit_class_option} do
          #{factory_attributes.gsub(/^/, '    ')}
            end

        RUBY
      end

      def factory_attributes
        i = 0
        attributes.map do |attribute|
          if attribute.reference?
            "association :#{attribute.name}, factory: :#{attribute.name}"
          elsif attribute.name == 'email'
            "sequence(:#{attribute.name}) {|n| \"email#\{format '%03d', n}@gmail.com\" }"
          elsif attribute.name =~ /(.*)_url$/
            "sequence(:#{attribute.name}) {|n| \"http://#\{$1}#\{format '%03d', n}.com\" }"
          elsif attribute.name == 'password'
            "password 'password'"
          elsif attribute.name == 'position'
            "sequence(:#{attribute.name}) {|n| n }"
          elsif %i[string text].include? attribute.type
            "sequence(:#{attribute.name}) {|n| \"#{attribute.name.capitalize.gsub('_', ' ')}#\{format '%03d', n}\" }"
          elsif attribute.type == :integer
            i += 1
            "sequence(:#{attribute.name}) {|n| \"#\{i}#\{format '%03d', n}\" }"
          else
            "#{attribute.name} { #{attribute.default.inspect} }"
          end
        end.join("\n")
      end

      def filename
        if factory_bot_options[:filename_proc].present?
          factory_bot_options[:filename_proc].call(table_name)
        else
          name = File.join(class_path, plural_name)
          [name, filename_suffix].compact.join("_")
        end
      end

      def filename_suffix
        factory_bot_options[:suffix] || options[:suffix]
      end

      def factory_bot_options
        generators.options[:factory_bot] || {}
      end

      def generators
        FactoryBotRails::Railtie.config.app_generators
      end
    end
  end
end
