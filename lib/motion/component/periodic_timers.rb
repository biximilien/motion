# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/hash/except"

require "motion"

module Motion
  module Component
    module PeriodicTimers
      extend ActiveSupport::Concern

      DEFAULT = {}.freeze
      private_constant :DEFAULT

      # Analogous to `module_function` (available on both class and instance)
      module ModuleFunctions
        def every(interval, handler, name: handler)
          periodic_timer(name, handler, every: interval)
        end

        def periodic_timer(name, handler = name, every:)
          self._periodic_timers =
            _periodic_timers.merge(name.to_s => [handler.to_sym, every]).freeze
        end

        def stop_periodic_timer(name)
          self._periodic_timers =
            _periodic_timers.except(name.to_s).freeze
        end

        def periodic_timers
          _periodic_timers.transform_values { |_handler, interval| interval }
        end
      end

      class_methods do
        include ModuleFunctions

        attr_writer :_periodic_timers

        def _periodic_timers
          return @_periodic_timers if defined?(@_periodic_timers)
          return superclass._periodic_timers if superclass.respond_to?(:_periodic_timers)

          DEFAULT
        end
      end

      include ModuleFunctions

      def process_periodic_timer(name)
        return unless (handler, _interval = _periodic_timers[name])

        _run_action_callbacks(context: handler) do
          send(handler)
        end
      end

      private

      attr_writer :_periodic_timers

      def _periodic_timers
        return @_periodic_timers if defined?(@_periodic_timers)

        self.class._periodic_timers
      end
    end
  end
end
