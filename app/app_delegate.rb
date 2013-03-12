# note:
#
# add to your Gemfile:
#
#       gem 'bubble-wrap'
#
# add to your Rakefile:
#
#       require 'bubble-wrap/reactor'
#
class AppDelegate
  attr_accessor :bridge_mac, :bridge_ip, :cache, :switch

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @phHueSDK = PHHueSDK.alloc.init
    @phHueSDK.notificationManager = build_notifications_manager
    @phHueSDK.startUpSDK
    @switch = true

    enable_heartbeat

    timer = EM.add_periodic_timer 5.0 do
      blink!
    end

    true
  end

  def build_notifications_manager
    notificationManager = PHNotificationManager.defaultManager
    notificationManager.registerObject(self, withSelector: :local_connection,    forNotification: 'LOCAL_CONNECTION_NOTIFICATION')
    notificationManager.registerObject(self, withSelector: :no_local_connection, forNotification: 'NO_LOCAL_CONNECTION_NOTIFICATION')
    notificationManager.registerObject(self, withSelector: :not_authenticated,   forNotification: 'NO_LOCAL_AUTHENTICATION_NOTIFICATION')
    notificationManager.registerObject(self, withSelector: :button_not_pressed,  forNotification: 'PUSHLINK_BUTTON_NOT_PRESSED_NOTIFICATION')
    notificationManager
  end

  def blink!
    @switch ^= true # on/off/on/off/…

    @state ||= begin
                @state = PHLightState.alloc.init
                @state.transitionTime = 24 # 2.4s
                @state.saturation = 254 # max
                @state.brightness = 254 # max
                @state
    end

    @state.setOnBool(@switch)

    @bridgeSendAPI ||= PHOverallFactory.alloc.init.bridgeSendAPI

    @cache.lights.each_pair do |name, light|
      @bridgeSendAPI.updateLightStateForId(light.identifier, withLighState: @state, completionHandler: -> (error) {
        puts error.inspect
      })

    end
  end


  def local_connection(*foo)
    puts "local"
    puts foo.inspect
  end

  def no_local_connection(*foo)
    puts "no local"
    puts foo.inspect
  end

  def not_authenticated(*foo)
    puts "no auth"
    puts foo.inspect
  end

  def button_not_pressed(*foo)
    puts "no button"
    puts foo.inspect
  end

  def enable_heartbeat
    @cache = PHBridgeResourcesReader.readBridgeResourcesCache

    if @cache && @cache.bridgeConfiguration && @cache.bridgeConfiguration.ipaddress
      @phHueSDK.enableLocalConnectionUsingInterval(30) # 30 seconds
    else
      search_bridge
    end
  end

  def search_bridge
    bridgeSearch = PHBridgeSearching.alloc.initWithUpnpSearch(true, andPortalSearch: true)
    bridgeSearch.startSearchWithCompletionHandler -> (bridges_hash) do
      # todo allow multiple bridges
      # {"00:17:88:00:00:00"=>"10.1.2.3"}
      bridges_hash.each_pair { |mac, ip|
        @bridge_mac = mac
        @bridge_ip  = ip
      }

      pair!
    end
  end

  def pair!
    username = PHUtilities.whitelistIdentifier
    puts "username: #{username}"

    @phHueSDK.setBridgeToUseWithIpAddress(@bridge_ip, macAddress: @bridge_mac, andUsername: username)

    enable_heartbeat
  end
end
