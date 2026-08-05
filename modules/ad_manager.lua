local event = require("event.event")
local utils = require("utils.utils")
---@class M
local M = {}

local EVENT_TEXTS = {}
if admob then
    EVENT_TEXTS = {
        [admob.EVENT_CLOSED] = "AD_EVENT_CLOSED: %s closed",
        [admob.EVENT_FAILED_TO_SHOW] = "AD_EVENT_FAILED_TO_SHOW: %s failed to show",
        [admob.EVENT_OPENING] = "AD_EVENT_OPENING: %s is opening",
        [admob.EVENT_FAILED_TO_LOAD] = "AD_EVENT_FAILED_TO_LOAD: %s failed to load",
        [admob.EVENT_LOADED] = "AD_EVENT_LOADED: %s loaded",
        [admob.EVENT_NOT_LOADED] = "AD_EVENT_NOT_LOADED: %s can't call show before EVENT_LOADED",
        [admob.EVENT_EARNED_REWARD] = "AD_EVENT_EARNED_REWARD: %s Reward",
        [admob.EVENT_IMPRESSION_RECORDED] = "AD_EVENT_IMPRESSION_RECORDED: %s did record impression",
        [admob.EVENT_CLICKED] = "AD_EVENT_CLICKED: %s clicked",
        [admob.EVENT_JSON_ERROR] = "AD_EVENT_JSON_ERROR: %s Internal NE json error",
    }
end
local function print_event(ad_type, message)
    local text = EVENT_TEXTS[message.event]
    if text then
        text = text:format(ad_type)
        if message.code then
            text = text .. "\nCode: " .. message.code
        end
        if message.error then
            text = text .. "\nError: " .. message.error
        end
        if message.amount then
            text = text .. "\nAmount: " .. message.amount .. " " .. message.type
        end
        print(text)
    end
end

local function admob_callback(self, message_id, message)
    if message_id == admob.MSG_INTERSTITIAL then
        print_event("INTERSTITIAL", message)
        self.onInterLoaded:trigger()
    elseif message_id == admob.MSG_BANNER then
        print_event("BANNER", message)
        self.onBannerLoaded:trigger()
    elseif message_id == admob.MSG_REWARDED then
        if message.event == admob.EVENT_LOADED then
            self.isLoading = false
            self.onRewardedLoaded:trigger(true)
            pprint("AD LOADED")
        elseif message.event == admob.EVENT_FAILED_TO_LOAD then
            self.isLoading = false
        elseif message.event == admob.EVENT_CLOSED then
            pprint("CLOSED AD")
            self.onRewardedLoaded:trigger(false)
        end
        print_event("Rewarded", message)
    end
    if message.event == admob.EVENT_STATUS_AUTHORIZED then
        print("ATTrackingManagerAuthorizationStatusAuthorized")
    elseif message.event == admob.EVENT_STATUS_DENIED then
        print("ATTrackingManagerAuthorizationStatusDenied")
    elseif message.event == admob.EVENT_STATUS_NOT_DETERMINED then
        print("ATTrackingManagerAuthorizationStatusNotDetermined")
    elseif message.event == admob.EVENT_STATUS_RESTRICTED then
        print("ATTrackingManagerAuthorizationStatusRestricted")
    elseif message.event == admob.EVENT_NOT_SUPPORTED then
        print("IDFA request not supported on this platform or OS version")
    end
end

function M:init()
    self.isLoading = false
    self.onRewardedLoaded = event.create()
    self.onBannerLoaded = event.create()
    self.onInterLoaded = event.create()
    self.onRewardedWatched = event.create()
    if admob then
        admob.set_callback(function(_, message_id, message)
            admob_callback(self, message_id, message)
        end)
        admob.set_privacy_settings(true)
        admob.initialize()
    end
end

function M:cache_ad()
    if not admob then return end
    utils.retryUntil(function()
        pprint("FETCHING...")
        if self.isLoading then return end
        if not admob.is_interstitial_loaded() then
            self.isLoading = true
            admob.load_interstitial(sys.get_config_string("admob.app_id_interstitial"));
        end
    end, 10, function()
        return false;
    end)
end

function M:load_interstitial()
    if not admob then return end
    pprint("INTER LOADING")
    if not admob.is_interstitial_loaded() then
        admob.load_interstitial(sys.get_config_string("admob.app_id_interstitial"));
    end
end

function M:show_interstitial()
    if not admob then return end
    if admob.is_interstitial_loaded() then
        admob.show_interstitial();
        return;
    end
end

function M:load_banner(size)
    if not admob then return end
    if not admob.is_banner_loaded() then
        admob.load_banner(sys.get_config_string("admob.app_id_banner"), size);
    end
end

function M:hide_banner()
    if admob then
        admob.hide_banner()
    end
end

function M:destory_banner()
    if admob then
        admob.destroy_banner()
    end
end

function M:show_banner(position)
    if admob then
        if admob.is_banner_loaded() then
            admob.show_banner(position)
        end
    end
end

function M:is_banner_loaded()
    if admob then 
        return admob.is_banner_loaded()
    end
    return false
end


function M:show_rewarded()
    if not admob then return end
    if admob.is_rewarded_loaded() then
        self.onRewardedWatched:trigger()
        admob.show_rewarded();
        return;
    end
end

function M:is_rewarded_loaded()
    if admob then
        return admob.is_rewarded_loaded()
    end
    return false
end

return M
