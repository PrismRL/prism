--- Common fields shared by all draw commands.
--- @class BaseCommand
--- @field kind '"rect"'|'"border"'|'"text"'
--- @field x integer
--- @field y integer
--- @field layer integer                  -- stable draw layer (defaulted by callers)
--- @field order integer?                 -- stable order within a layer (set by _emit)
--- @field clip Rectangle                 -- cumulative clip rect applied during flush
--- @field content boolean

--- Filled rectangle background command.
--- @class RectCommand : BaseCommand
--- @field kind '"rect"'
--- @field w integer
--- @field h integer
--- @field bg Color4

--- Border rectangle command.
--- @class BorderCommand : BaseCommand
--- @field kind '"border"'
--- @field w integer
--- @field h integer
--- @field bg Color4
--- @field ch string?                                -- legacy single glyph
--- @field fg Color4?                                -- glyph foreground
--- @field chars StyleBorderChars?                        -- 6-glyph table
--- @field sides StyleBorderToggles

--- Text command.
--- @class TextCommand : BaseCommand
--- @field kind '"text"'
--- @field text string
--- @field fg Color4
--- @field align '"left"'|'"center"'|'"right"'|nil
--- @field width integer                  -- layout width for alignment/clipping

--- Union of all draw commands.
--- @alias DrawCommand RectCommand|BorderCommand|TextCommand