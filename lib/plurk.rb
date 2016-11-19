require 'plurk/version'
require 'oauth'
require 'json'
require 'yaml'

require 'plurk/build_class'
require 'plurk/client'
require 'plurk/comet_channel'

module Plurk
  PlurkError = Class.new(StandardError)
end

Dir[File.join(__dir__,'/plurk/fixtures/*.yml')].each do |f|
  Plurk::BuildClass.insert(Plurk, f)
end
