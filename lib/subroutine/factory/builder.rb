require 'active_support/inflector/methods'

module Subroutine
  module Factory
    class Builder

      def initialize(config, *args)
        @config = config
        @options = config.options.dup
        @args = args.dup
        @overrides = @args.extract_options!
      end

      def execute!
        args = @args.dup

        Array(@options[:setups]).each{|block| block.call(args, extras) }

        args.push(inputs)

        op = op_class.new(*args)

        Array(@options[:befores]).each{|block| block.call(op, extras) }

        op.submit!

        output = extract_output(op)

        Array(@options[:afters]).each{|block| block.call(op, output, extras) }

        output
      end

      def inputs
        @inputs ||= begin
          out = {}

          @options[:inputs].each_pair do |k,v|
            if @overrides.has_key?(k)
              out[k] = @overrides[k]
            else
              out[k] = invoke_input(v)
            end
          end

          out
        end
      end

      def extras
        @extras ||= begin
          out = {}

          @options[:extras].each_pair do |k, v|
            if @overrides.has_key?(k)
              out[k] = @overrides[k]
            elsif !v.nil?
              out[k] = invoke_input(v)
            end
          end

          out
        end
      end

      def invoke_input(input)
        return input unless input.respond_to?(:call)
        input.arity.zero? ? input.call : input.call(extras)
      end

      def op_class
        @options[:op].constantize
      end

      def extract_output(op)
        if @options[:output]
          return op.send(@options[:output])
        elsif @options[:outputs]
          if @options[:outputs].length == 1 && @options[:outputs][0].is_a?(Array)
            @options[:outputs][0].map{|output| op.send(output) }
          else
            @options[:outputs].inject({}){|out, output| out[output] = op.send(output); out }
          end
        else
          op
        end
      end

    end
  end
end
