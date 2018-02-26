
local PANEL = {}

AccessorFunc( PANEL, "m_bBackground",		"PaintBackground",	FORCE_BOOL )
AccessorFunc( PANEL, "m_bBackground",		"DrawBackground",	FORCE_BOOL ) -- deprecated
AccessorFunc( PANEL, "m_bIsMenuComponent",	"IsMenu",			FORCE_BOOL )
AccessorFunc( PANEL, "m_bDisableTabbing",	"TabbingDisabled",	FORCE_BOOL )

AccessorFunc( PANEL, "m_bDisabled",	"Disabled" )
AccessorFunc( PANEL, "m_bgColor",	"BackgroundColor" )

Derma_Hook( PANEL, "Paint", "Paint", "Panel" )
Derma_Hook( PANEL, "ApplySchemeSettings", "Scheme", "Panel" )
Derma_Hook( PANEL, "PerformLayout", "Layout", "Panel" )

function PANEL:Init()

	self:SetPaintBackground( true )

	-- This turns off the engine drawing
	self:SetPaintBackgroundEnabled( false )
	self:SetPaintBorderEnabled( false )

end

function PANEL:SetDisabled( bDisabled )

	self.m_bDisabled = bDisabled

	if ( bDisabled ) then
		self:SetAlpha( 75 )
		self:SetMouseInputEnabled( false )
	else
		self:SetAlpha( 255 )
		self:SetMouseInputEnabled( true )
	end

end

function PANEL:SetEnabled( bEnabled )

	self:SetDisabled( !bEnabled )

end

function PANEL:IsEnabled()

	return !self:GetDisabled()

end

function PANEL:OnMousePressed( mousecode )

	if ( self:IsSelectionCanvas() && !dragndrop.IsDragging() ) then
		self:StartBoxSelection()
		return
	end

	if ( self:IsDraggable() ) then

		self:MouseCapture( true )
		self:DragMousePress( mousecode )

	end

end

function PANEL:OnMouseReleased( mousecode )

	if ( self:EndBoxSelection() ) then return end

	self:MouseCapture( false )

	if ( self:DragMouseRelease( mousecode ) ) then
		return
	end

end

function PANEL:SetHHeight(h)
	self.HeaderHeight = h
end

function PANEL:SetHText(text)
	self.HText = text
end

function PANEL:Paint(w, h)
	draw.RoundedBox(8, 0, 0, w, h, cols.head_panel_outline)
	draw.RoundedBox(8, 1, 1, w - 2, h - 2, cols.head_panel_bg)

	self.HeaderHeight = self.HeaderHeight or 0

	draw.RoundedBox(8, 0, 0, w, self.HeaderHeight, cols.head_panel_head_bg)
	draw.RoundedBox(0, 1, self.HeaderHeight / 2, w - 2, self.HeaderHeight * 3 / 4, cols.head_panel_bg)

	draw.SimpleText(self.HText, "adminme_header", 15, self.HeaderHeight * 1 / 4, cols.head_panel_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

function PANEL:UpdateColours()
end

derma.DefineControl( "am.HeaderPanel", "", PANEL, "Panel" )