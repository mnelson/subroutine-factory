# frozen_string_literal: true

require "securerandom"
require "subroutine"
require "subroutine/factory/version"
require "subroutine/factory/config"
require "subroutine/factory/builder"
require "subroutine/factory/spec_helper"

module Subroutine
  module Factory

    @@configs = {}
    @@sequence = 0

    def self.configs
      @@configs
    end

    def self.define(name, options = {}, &block)
      config = ::Subroutine::Factory::Config.new(options)
      @@configs[name.to_sym] = config
      config.instance_eval(&block) if block_given?
      config.validate!
      config
    end

    def self.get_config(name)
      @@configs[name.to_sym]
    end

    def self.get_config!(name)
      config = get_config(name)
      raise "Unknown Subroutine::Factory `#{name}`" unless config

      config
    end

    def self.create(name, *args)
      builder(name, *args).execute!
    end

    def self.inputs(name, *args)
      builder(name, *args).inputs
    end

    def self.builder(name, *args)
      config = get_config!(name)
      ::Subroutine::Factory::Builder.new(config, *args)
    end

    def self.sequence(&lambda)
      if block_given?
        proc do |*options|
          @@sequence += 1
          lambda.call(*[@@sequence, *options].compact)
        end
      else
        @@sequence += 1
      end
    end

    def self.random(length: 8, &lambda)
      if block_given?
        proc  do |*options|
          x = ::SecureRandom.hex[0...length]
          lambda.call(*[x, *options].compact)
        end
      else
        ::SecureRandom.hex[0...length]
      end
    end

    def self.set_sequence(n)
      @@sequence = n
    end

  end
end
