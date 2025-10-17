---@class UIResponseBase
---@field id string
---@field lclicked boolean
---@field rclicked boolean

---@class ButtonResponse : UIResponseBase

---@class TextInputResponse : UIResponseBase
---@field changed boolean

---@class CheckboxResponse : UIResponseBase
---@field changed boolean

---@class SliderResponse : UIResponseBase
---@field changed boolean

---@class ListResponse : UIResponseBase
---@field changed boolean

---@class ImageResponse : UIResponseBase

---@class LabelResponse : UIResponseBase

---@class CollapsibleResponse : UIResponseBase
---@field toggled boolean

---@alias UIResponse
---| ButtonResponse
---| TextInputResponse
---| CheckboxResponse
---| SliderResponse
---| ListResponse
---| ImageResponse
---| LabelResponse
---| CollapsibleResponse
