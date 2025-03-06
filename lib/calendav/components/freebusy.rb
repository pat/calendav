# frozen_string_literal: true

require_relative "../properties/freebusy"

module Calendav
  module Components
    class Freebusy
      attr_reader :dtend, :dtstart, :dtstamp, :freebusy, :ical_name, :name,
                  :parent, :uid

      def self.from_http_response(response)
        ical_freebusy = Icalendar::Freebusy.parse(response).first

        attributes = attributes_from_ical_freebusy(ical_freebusy)
        new(attributes)
      end

      def initialize(attributes)
        @dtend = attributes[:dtend].to_time
        @dtstart = attributes[:dtstart].to_time
        @dtstamp = attributes[:dtstamp].to_time
        @freebusy = attributes[:freebusy].map do |fb|
          Properties::Freebusy.from_ical_period(fb)
        end
        @ical_name = attributes[:ical_name]
        @name = attributes[:name]
        @uid = attributes[:uid]
      end

      def to_h
        {
          dtend: dtend,
          dtstart: dtstart,
          dtstamp: dtstamp,
          freebusy: freebusy,
          ical_name: ical_name,
          name: name,
          parent: parent,
          uid: uid
        }
      end

      class << self
        private

        def attributes_from_ical_freebusy(ical_freebusy)
          {
            dtend: ical_freebusy.dtend,
            dtstamp: ical_freebusy.dtstamp,
            dtstart: ical_freebusy.dtstart,
            freebusy: ical_freebusy.freebusy,
            ical_name: ical_freebusy.ical_name,
            name: ical_freebusy.name,
            uid: ical_freebusy.uid
          }
        end
      end
    end
  end
end
