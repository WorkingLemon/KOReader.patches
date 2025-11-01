--[[
    This user patch is primarily for use with the Project: Title plugin.

    It hides progress bars in Cover Grid when a book has been unopened.
    This patch shows a page count instead of progress bar.
--]]

local userpatch = require("userpatch")
local logger = require("logger")

local function patchCoverBrowser(plugin)
    local MosaicMenu = require("mosaicmenu")
    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")

       local Blitbuffer = require("ffi/blitbuffer")
    local Screen = require("device").screen
    local Font = require("ui/font")
    local Size = require("ui/size")
    local TextWidget = require("ui/widget/textwidget")
    local FrameContainer = require("ui/widget/container/framecontainer")
    local BookInfoManager = require("bookinfomanager")
    local ptutil = require("ptutil")
    
    -- Get the corner_mark_size upvalue
    local corner_mark_size = userpatch.getUpValue(MosaicMenu._recalculateDimen, "corner_mark_size")
    local is_pathchooser = userpatch.getUpValue(MosaicMenuItem.paintTo, "is_pathchooser")
    
    -- Store original paintTo function
    local original_paintTo = MosaicMenuItem.paintTo
    
    -- Override paintTo to add page count badge for unopened books
    function MosaicMenuItem:paintTo(bb, x, y)
        -- Call original paintTo first
        original_paintTo(self, bb, x, y)
        
        -- Only add badge for files, not directories
        self.is_directory = not (self.entry.is_file or self.entry.file)
        if self.is_directory or self.file_deleted then return end
        
        -- Get bookinfo
        local bookinfo = BookInfoManager:getBookInfo(self.filepath, false)
        if not bookinfo or not self.init_done then return end
        
        -- Only show page count badge if book is unopened and not in progress bar mode
        if not self.been_opened and not self.show_progress_bar and not is_pathchooser then
            local page_count = self.pages
            
            if page_count then
                -- Get the target (cover image) for positioning
                local target = self[1][1][1]
                
                -- Create page count text
                local page_text = " p." .. page_count .. " "
                local font_size = math.floor(corner_mark_size * 0.35)
                
                local pages_text = TextWidget:new{
                    text = page_text,
                    face = Font:getFace("cfont", font_size),
                    alignment = "left",
                    fgcolor = Blitbuffer.COLOR_BLACK,
                    bold = false,
                    padding = 1,
                }
                
                local pages_badge = FrameContainer:new{
                    linesize = Screen:scaleBySize(2),
                    radius = Screen:scaleBySize(5),
                    color = Blitbuffer.COLOR_GRAY,
                    bordersize = Size.line.thin,
                    background = Blitbuffer.COLOR_WHITE,
                    padding = Screen:scaleBySize(1),
                    margin = 0,
                    pages_text,
                }
                
                -- Calculate position (bottom right of cover)
                local cover_left = x + math.floor((self.width - target.width) / 2)
                local cover_bottom = y + self.height - math.floor((self.height - target.height) / 2)
                local pad = Screen:scaleBySize(4)
                local pos_x_badge = cover_left + target.width - pages_badge:getSize().w - pad
                local pos_y_badge = cover_bottom - (pad + pages_badge:getSize().h)
                
                -- Paint the badge
                pages_badge:paintTo(bb, pos_x_badge, pos_y_badge)
            end
        end
    end
    
    logger.info("User patch: Page count badge for unopened books applied")
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
