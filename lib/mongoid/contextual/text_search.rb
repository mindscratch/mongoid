# encoding: utf-8
module Mongoid
  module Contextual
    class TextSearch
      include Enumerable
      include Command

      delegate :[], to: :results
      delegate :==, :empty?, to: :entries

      def each
        if block_given?
          documents.each do |doc|
            yield doc
          end
        else
          to_enum
        end
      end

      def initialize(collection, criteria, search_string)
        @collection, @criteria = collection, criteria
        command[:text] = collection.name.to_s
        command[:search] = search_string
        apply_criteria_options
      end

      # Inspect the text search object.
      #
      # @example Inspect the text search.
      #   text_search.inspect
      #
      # @return [ String ] The inspection.
      #
      # @since 4.0.0
      def inspect
%Q{#<Mongoid::Contextual::TextSearch
  selector:   #{criteria.selector.inspect}
  class:      #{criteria.klass}
  search:     #{command[:search]}
  filter:     #{command[:filter] || "N/A"}
  project:    #{command[:project] || "N/A"}
  limit:      #{command[:limit] || "N/A"}
  language:   #{command[:language] || "default"}>
}
      end

      def execute
        results
      end

      # Set the language of the text search.
      #
      # @example Set the text search language.
      #   text_search.language("deutsch")
      #
      # @param [ String ] value The name of the language.
      #
      # @return [ TextSearch ] The modified text search.
      #
      # @since 4.0.0
      def language(value)
        command[:language] = value
        self
      end

      # Limits the fields returned by the text search for each document. By
      # default, _id is always included.
      #
      # @example Limit the returned fields.
      #   text_search.project(name: 1, title: 1)
      #
      # @param [ Hash ] value The fields to project.
      #
      # @return [ TextSearch ] The modified text search.
      #
      # @since 4.0.0
      def project(value)
        command[:project] = value
        self
      end

      def stats
        results["stats"]
      end

      def time
        stats["time"]
      end

      private

      def apply_criteria_options
        command[:filter] = criteria.selector
        if limit = criteria.options[:limit]
          command[:limit] = limit
        end
      end

      def documents
        results["results"].map do |attributes|
          Factory.from_db(criteria.klass, attributes["obj"], criteria.object_id)
        end
      end

      def results
        @results ||= session.command(command)
      end
    end
  end
end