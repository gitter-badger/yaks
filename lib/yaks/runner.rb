module Yaks
  class Runner
    include Util
    include Anima.new(:object, :config, :options)
    include Adamantium::Flat
    extend Forwardable

    def_delegators :config, :policy, :default_format, :format_options, :primitivize, :serializers, :hooks

    def call
      steps.inject(object) {|memo, (_, step)| step.call(memo) }
    end

    def context
      {
        policy: policy,
        env: env,
        mapper_stack: []
      }.merge(slice_hash(options, :item_mapper))
    end
    memoize :context, freezer: :flat

    def env
      options.fetch(:env, {})
    end
    memoize :env, freezer: :noop

    # @return [Class]
    def format_class
      Format.by_accept_header(env['HTTP_ACCEPT']) {
        Format.by_name(options.fetch(:format) { default_format })
      }
    end
    memoize :format_class

    def steps
      insert_hooks(
        [[ :map, mapper ],
         [ :format, formatter ],
         [ :primitivize, primitivize], # really a JSON-preprocessor, should be pulled out
         [ :serialize, serializer ]])
    end
    memoize :steps

    def mapper
      options.fetch(:mapper) do
        policy.derive_mapper_from_object(object)
      end.new(context)
    end
    memoize :mapper, freezer: :noop

    def formatter
      format_class.new(format_options[format_name])
    end
    memoize :formatter

    # @param [Hash] opts
    # @return [String]
    def format_name
      options.fetch(:format) { default_format }
    end
    memoize :format_name

    def serializer
      serializers.fetch(format_class.serializer) do
        policy.serializer_for_format(format_class)
      end
    end
    memoize :serializer

    def insert_hooks(steps)
      hooks.inject(steps) do |steps, (type, target_step, name, hook)|
        steps.flat_map do |step_name, callable|
          if step_name.eql? target_step
            case type
            when :before
              [[name, hook], [step_name, callable]]
            when :after
              [[step_name, callable], [name, hook]]
            when :around
              [[step_name, ->(x) { hook.call(x, &callable) }]]
            when :skip
              []
            end
          end || [[step_name, callable]]
        end
      end
    end
  end
end
