# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'

# if you use bundler
require 'bundler'
Bundler.require
require 'bubble-wrap/reactor'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'HueMotion'
  app.identifier = "com.moriz.huemotion"
  app.vendor_project('vendor/HueSDK.framework', :static, headers_dir: 'Headers', products: ['HueSDK'] )
  app.device_family = [:iphone, :ipad]
  app.frameworks += [ 'HueSDK' ]
end
