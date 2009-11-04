require 'uri'
require 'net/http'
require 'nokogiri'

module Mollie

  module RequestOptions

    DEFAULT_URI = "http://www.mollie.nl/xml/sms/"

    def self.query_attributes
      [:username, :password, :recipients, :originator, :gateway, :md5_password, :udh, :receipt, :deliverydate, :message, :message_type, :delivery_url]
    end

    def self.included(klass)
      klass.__send__(:attr_accessor, *(query_attributes + [ :uri ]))
    end

    def uri
      @uri || DEFAULT_URI
    end

  end

  class SMS

    include RequestOptions

    attr_accessor :deliver_at, :message_type, :delivery_url

    def initialize(options = {})
      options.each_pair do |key,value| 
        send("#{key}=", value)
      end
    end

    def uri
      @uri || RequestOptions::DEFAULT_URI
    end

    def recipient=(recipient)
      self.recipients = [recipient]
    end

  end

  class Send

    attr_reader :query

    def self.send(query)
      new(query).send!
    end

    def initialize(query)
      @query = query
    end

    def send!
      self
    end

    def success?
      resultcode == 10
    end

    def resultcode
      $1.to_i if response.body =~ /<resultcode>(.*)<\/resultcode>/m
    end

    def response
      Net::HTTP.get_response(query.request_uri)
    end


  end

  class Query

    # Let's provide some friendly names instead of Mollie's weird short names
    QUERY_ALIASES = { :message_type => :type, :delivery_url => :dlrurl, :receipt => :return }

    attr_reader :sms

    def initialize(sms)
      @sms = sms
    end

    def deliverydate
      DateTime.parse(value(:deliver_at)).strftime("%Y%m%d%H%M%S")
    rescue TypeError
      nil
    end

    def request_uri
      request_uri = URI.parse(value(:uri))
      request_uri.query = query
      request_uri
    end

    def recipients
      sms.recipients.join(',')
    end

    private

    def attribute_name(attribute)
      QUERY_ALIASES.has_key?(attribute) ? QUERY_ALIASES[attribute] : attribute
    end

    def value(attribute)
      (respond_to?(attribute) ? self : sms).__send__(attribute)
    end

    def query_format
      lambda { |attribute| "#{attribute_name(attribute)}=#{URI.encode(value(attribute))}" }
    end

    def empty_attribute?
      lambda { |attribute| value(attribute).nil? }
    end

    def query
      query_attributes.reject(&empty_attribute?).map(&query_format).join("&")
    end

    def query_attributes
      RequestOptions.query_attributes
    end

  end

end
