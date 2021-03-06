# -*- coding: utf-8 -*-

module Yaks
  class Format
    # Hypertext Application Language (http://stateless.co/hal_specification.html)
    #
    # A lightweight JSON Hypermedia message format.
    #
    # Options: +:plural_links+ In HAL, a single rel can correspond to
    # a single link, or to a list of links. Which rels are singular
    # and which are plural is application-dependant. Yaks assumes all
    # links are singular. If your resource might contain multiple
    # links for the same rel, then configure that rel to be plural. In
    # that case it will always be rendered as a collection, even when
    # the resource only contains a single link.
    #
    # @example
    #
    #   yaks = Yaks.new do
    #     format_options :hal, {plural_links: [:related_content]}
    #   end
    #
    class Hal < self
      register :hal, :json, 'application/hal+json'

      protected

      # @param [Yaks::Resource] resource
      # @return [Hash]
      def serialize_resource(resource)
        # The HAL spec doesn't say explicitly how to deal missing values,
        # looking at client behavior (Hyperagent) it seems safer to return an empty
        # resource.
        #
        result = resource.attributes
        result = result.merge(:_links => serialize_links(resource.links)) unless resource.links.empty?
        result = result.merge(:_embedded => serialize_embedded(resource.subresources)) unless resource.subresources.empty?
        result
      end

      # @param [Array] links
      # @return [Hash]
      def serialize_links(links)
        links.reduce({}, &method(:serialize_link))
      end

      # @param [Hash] memo
      # @param [Yaks::Resource::Link]
      # @return [Hash]
      def serialize_link(memo, link)
        hal_link = {href: link.uri}
        hal_link.merge!(link.options)

        memo[link.rel] = if singular?(link.rel)
                           hal_link
                         else
                           (memo[link.rel] || []) + [hal_link]
                         end
        memo
      end

      # @param [String] rel
      # @return [Boolean]
      def singular?(rel)
        !options.fetch(:plural_links) { [] }.include?(rel)
      end

      # @param [Array] subresources
      # @return [Hash]
      def serialize_embedded(subresources)
        subresources.each_with_object({}) do |(rel, resources), memo|
          memo[rel] = if resources.collection?
                        resources.map( &method(:serialize_resource) )
                      else
                        serialize_resource(resources) unless resources.null_resource?
                      end
        end
      end

    end
  end
end
