local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')

I.Settings.registerPage({
  key = 'OMWCamera',
  l10n = 'OMWCamera',
  name = 'Camera',
  description = 'settingsPageDescription',
})

local thirdPersonGroup = 'SettingsOMWCameraThirdPerson'
local headBobbingGroup = 'SettingsOMWCameraHeadBobbing'

local function boolSetting(prefix, key, default)
    return {
        key = key,
        renderer = 'checkbox',
        name = prefix..key,
        description = prefix..key..'Description',
        default = default,
    }
end

local function floatSetting(prefix, key, default)
    return {
        key = key,
        renderer = 'number',
        name = prefix..key,
        description = prefix..key..'Description',
        default = default,
    }
end

I.Settings.registerGroup({
    key = thirdPersonGroup,
    page = 'OMWCamera',
    l10n = 'OMWCamera',
    name = 'thirdPersonSettings',
    permanentStorage = true,
    order = 0,
    settings = {
        boolSetting('', 'viewOverShoulder', true),
        floatSetting('', 'shoulderOffsetX', 30),
        floatSetting('', 'shoulderOffsetY', -10),
        boolSetting('', 'autoSwitchShoulder', true),
        floatSetting('', 'zoomOutWhenMoveCoef', 20),
        boolSetting('', 'previewIfStandStill', true),
        boolSetting('', 'deferredPreviewRotation', true),
        boolSetting('', 'ignoreNC', true),
        boolSetting('', 'move360', false),
        floatSetting('', 'move360TurnSpeed', 5),
        boolSetting('', 'slowViewChange', false),
        boolSetting('', 'povAutoSwitch', false),
    },
})

I.Settings.registerGroup({
    key = headBobbingGroup,
    page = 'OMWCamera',
    l10n = 'OMWCamera',
    name = 'headBobbingSettings',
    permanentStorage = true,
    order = 1,
    settings = {
        boolSetting('headBobbing_', 'enabled', true),
        floatSetting('headBobbing_', 'step', 90),
        floatSetting('headBobbing_', 'height', 3),
        floatSetting('headBobbing_', 'roll', 0.2),
    },
})

local settings = {
    thirdPerson = storage.playerSection(thirdPersonGroup),
    headBobbing = storage.playerSection(headBobbingGroup),
}

local function updateViewOverShoulderDisabled()
    local shoulderDisabled = not settings.thirdPerson:get('viewOverShoulder')
    I.Settings.updateRendererArgument(thirdPersonGroup, 'shoulderOffsetX', {disabled = shoulderDisabled})
    I.Settings.updateRendererArgument(thirdPersonGroup, 'shoulderOffsetY', {disabled = shoulderDisabled})
    I.Settings.updateRendererArgument(thirdPersonGroup, 'autoSwitchShoulder', {disabled = shoulderDisabled})
    I.Settings.updateRendererArgument(thirdPersonGroup, 'zoomOutWhenMoveCoef', {disabled = shoulderDisabled})

    local move360Disabled = not settings.thirdPerson:get('move360')
    I.Settings.updateRendererArgument(thirdPersonGroup, 'move360TurnSpeed', {disabled = move360Disabled})
end

local function updateHeadBobbingDisabled()
    local disabled = not settings.headBobbing:get('enabled')
    I.Settings.updateRendererArgument(headBobbingGroup, 'step', {disabled = disabled, min = 1})
    I.Settings.updateRendererArgument(headBobbingGroup, 'height', {disabled = disabled})
    I.Settings.updateRendererArgument(headBobbingGroup, 'roll', {disabled = disabled, min = 0, max = 90})
end

updateViewOverShoulderDisabled()
updateHeadBobbingDisabled()

settings.thirdPerson:subscribe(async:callback(updateViewOverShoulderDisabled))
settings.headBobbing:subscribe(async:callback(updateHeadBobbingDisabled))

return settings