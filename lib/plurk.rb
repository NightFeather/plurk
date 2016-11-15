require 'plurk/version'
require 'oauth'
require 'json'
require 'yaml'

require_relative './plurk/build_class'
require_relative './plurk/client'

module Plurk
end

Dir[File.join(__dir__,'/plurk/fixtures/*.yml')].each do |f|
  Plurk::BuildClass.insert(Plurk, f)
end
