---@class WhoDat: AceAddon, AceConsole-3.0, AceEvent-3.0
---@field categoryID number
---@field db AceDBObject-3.0

---@class Locale: AceLocale-3.0

---@class WhoDatGRMUtil
---@field IsGRMLoaded fun(): boolean, boolean
---@field IsGRMInitialized fun(): boolean
---@field GetLinkedToons fun(character: string): string[]

---@class GRM
---@field GetAltGroup fun(altGroupID: string): table
GRM = {}

---@class GRM_API
---@field Initialized boolean
---@field GetMember fun(character: string): table
GRM_API = {}

---@class GRM_R
---@field GetAllMembersAsArray fun(nameFilter: string): table[]
GRM_R = {}

---@class WhoDatGRMImport: Frame
---@field TitleText FontString
---@field TopBorder Texture
---@field CloseButton Button
---@field CharInstructions FontString
---@field CharacterInput EditBox
---@field NicknameInstructions FontString
---@field NicknameInput EditBox
---@field ImportButton Button
WhoDatGRMImport = {}
