#!/usr/bin/env ruby

########################################################################
# Copyright 2011 Mikhail Slyusarev
#
# ruby-omegle is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ruby-omegle is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ruby-omegle. If not, see <http://www.gnu.org/licenses/>.
########################################################################

require 'uri'
require 'net/http'
require 'json'

# Class for handling connections with omegle.

class Omegle
  attr_accessor :id

  # Establish connection here to the omegle host
  # (ie. omegle.com or cardassia.omegle.com).
  def initialize options = {}
    @options = {:host => 'omegle.com'}.merge(options)
    @omegle = Net::HTTP.start @options[:host]
  end

  # Static method that will handle connecting/disconnecting to
  # a person on omegle. Same options as constructor.
  def self.start options = {}
    s = Omegle.new options
    s.start
    yield s
    s.disconnect
  end

  # Make a GET request to <omegle url>/start to get an id.
  def start
    @id = @omegle.get('/start').body[1..6]
  end

  # POST to <omegle url>/events to get events from Stranger.
  def event
    begin
      JSON.parse(@omegle.post('/events', "id=#{@id}").body)
    rescue
    end
  end

  # Send a message to the Stranger with id = @id.
  def send msg
    @omegle.post '/send', "id=#{@id}&msg=#{msg}"
  end

  # Let them know you're typing.
  def typing
    @omegle.post '/typing', "id=#{@id}"
  end

  # Let them know you've stopped typing.
  def stopped_typing
    @omegle.post '/stoppedTyping', "id=#{@id}"
  end

  # Disconnect from Stranger
  def disconnect
    begin
      @omegle.post '/disconnect', "id=#{@id}"
    rescue
    end
  end

  # Pass a code block to deal with each events as they come.
  def listen
    while (e = event) != nil
      yield e
    end
  end
end
