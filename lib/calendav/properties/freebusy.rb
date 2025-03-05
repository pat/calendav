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

        @start_time = start_time
        @end_time = end_time
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
        return if start_time.instance_of?(Time) && end_time.instance_of?(Time)

        raise ArgumentError, "arguments must be instances of Time"
      end
    end
  end
end
