require_relative 'base'
require_relative '../model/session'
require_relative '../util/utils'

module Consul
  module Client
    # Consul Session Client
    class Session < Base

      # Public: Creates an instance of Consul::Model::Session with as many preset
      # defaults as possible.
      #
      # Params -
      # name              - (Required) The name of the session.
      # opts              - (Optional) Options hash
      # opts[:lock_delay]  - Allowance window for leaders to Valid values between '0s' and '60s'
      # opts[:node]        - The name of the node, defaults to the node the agent is running on
      # opts[:checks]      - Health Checks to associate to this session
      # opts[:behavior]   - 'release' or 'destroy' Behaviour when session is invalidated.
      # opts[:ttl]         - When provided  Must be between '10s' and '3600s'
      #
      # Returns: Consul::Model::Session instance.
      def self.for_name(name, opts = {})
          # lock_delay = '15s',
          # node = nil,
          # checks = ['serfHealth'],
          # behaviour = 'release',
          # ttl = nil)
        raise ArgumentError.new "Illegal Name: #{name}" if name.nil?
        opts = {} if opts.nil?
        session = Consul::Model::Session.new(name: name)
        session.lock_delay = opts[:lock_delay] unless opts.has_key?(:lock_delay)
        session.node = opts[:node]  unless opts.has_key?(:node)
        session.checks = opts[:checks] if opts.has_key?(:checks)
        session.behavior = opts[:behavior] if opts.has_key?(:behavior)
        session.ttl = opts[:ttl] unless opts.has_key?(:ttl)
        session
      end

      # Public: Creates a new Consul Session.
      #
      # session - Session to create.
      # dc      - Consul data center
      #
      # Returns The Session ID
      def create(session, dc = nil)
        raise TypeError, 'Session must be of type Consul::Model::Session' unless session.kind_of? Consul::Model::Session
        params = {}
        params[:dc] = dc unless dc.nil?
        success, body = _put(build_url('create'), session.extend(Consul::Model::Session::Representer).to_json, params)
        return Consul::Model::Session.new.extend(Consul::Model::Service::Representer).from_json(body) if success
        logger.warn("Unable to create session with #{session} reason: #{body}")
        nil
      end

      # Public: Destroys a given session
      def destroy(session, dc = nil)
        return false if session.nil?
        session = extract_session_id(session)
        params = nil
        params = {:dc => dc} unless dc.nil?
        success, _ = _put build_url("destroy/#{session}"), '', params
        success
      end

      # Public: Return the session info for a given session name.
      #ccs
      def info(session, dc = nil)
        return nil if session.nil?
        session = extract_session_id(session)
        params = {}
        params[:dc] = dc unless dc.nil?
        resp = _get build_url("info/#{session}"), params
        JSON.parse(resp).map{|session_hash| session(session_hash)} unless resp.nil?
      end

      # Lists sessions belonging to a node
      def node(session, dc = nil)
        return nil if session.nil?
        session = extract_session_id(session)
        params = {}
        params[:dc] = dc unless dc.nil?
        resp = _get build_url("node/#{session}"), params
        JSON.parse(resp).map{|session_hash| session(session_hash)} unless resp.nil?
      end

      # Lists all active sessions
      def list(dc = nil)
        params = {}
        params[:dc] = dc unless dc.nil?
        resp = _get build_url('list'), params
        JSON.parse(resp).map{|session_hash| session(session_hash)} unless resp.nil?
      end

      # Renews a TTL-based session
      def renew(session, dc = nil)
        return nil if session.nil?
        session = extract_session_id(session)
        params = {}
        params[:dc] = dc unless dc.nil?
        success, _ = _put build_url("renew/#{session}"), session.to_json
        success
      end

      private

      # Private: Extracts the Session
      def extract_session_id(session)
        raise TypeError, 'Session cannot be null' if session.nil?
        session = session.id if session.kind_of? Consul::Model::Session
        session = session.to_str if session.respond_to?(:to_str)
        session
      end

      def session(obj)
        if Consul::Utils.valid_json?(obj)
          Consul::Model::Session.new.extend(Consul::Model::Session::Representer).from_json(obj)
        elsif obj.is_a?(Hash)
          Consul::Model::Session.new.extend(Consul::Model::Session::Representer).from_hash(obj)
        end
      end

      # Private: Create the url for a session endpoint.
      #
      # suffix - Suffix of the url endpoint
      #
      # Return: The URL for a reachable endpoint
      def build_url(suffix)
        "#{base_versioned_url}/session/#{suffix}"
      end

    end
  end
end
