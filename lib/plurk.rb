# Namespace Module for this
module Plurk
  # Base Error Class
  Error = Class.new(StandardError)
end

require 'plurk/version'
require 'oauth'
require 'json'
require 'yaml'

require 'plurk/client'
require 'plurk/comet_channel'
require 'plurk/build_class'

Dir[File.join(__dir__,'/plurk/fixtures/*.yml')].each do |f|
  name = Plurk::BuildClass.insert(Plurk, f)
  name.scan(/[A-Z]+[a-z0-9]*/).map(&:downcase).join("_").tap do |fname|
    require "plurk/#{fname}" if File.exists? File.join(__dir__, "plurk", fname + ".rb")
  end
end
