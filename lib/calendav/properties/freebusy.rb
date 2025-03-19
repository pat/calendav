# frozen_string_literal: true

module Calendav
  module Properties
    class Freebusy
      attr_reader :start_time, :end_time

      def self.from_ical_period(period)
        new(start_time: period.first.to_time, end_time: period.last.to_time)
      end

      def initialize(start_time:, end_time:)
        validate_arguments(start_time, end_time)

        @start_time = if start_time.respond_to?(:to_time)
                        start_time.to_time
                      else
                        start_time
                      end
        @end_time = end_time.respond_to?(:to_time) ? end_time.to_time : end_time
      end

      def to_h
        {
          start_time: start_time,
          end_time: end_time
        }
      end

      def to_range
        Range.new(start_time, end_time)
      end

      def duration
        end_time - start_time
      end

      private

      def validate_arguments(start_time, end_time)
        return if (start_time.is_a?(Time) || start_time.respond_to?(:to_time)) &&
                  (end_time.is_a?(Time) || end_time.respond_to?(:to_time))

        raise ArgumentError,
              "arguments must be instances of Time or respond to to_time"
      end
    end
  end
end
