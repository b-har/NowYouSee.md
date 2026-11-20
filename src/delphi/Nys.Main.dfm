object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'NowYouSee.md'
  ClientHeight = 800
  ClientWidth = 1100
  Color = clBtnFace
  Constraints.MinHeight = 360
  Constraints.MinWidth = 800
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Padding.Left = 8
  Padding.Top = 8
  Padding.Right = 8
  Padding.Bottom = 8
  Position = poScreenCenter
  ShowHint = True
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  TextHeight = 15
  object Bar: TPanel
    Left = 8
    Top = 8
    Width = 1084
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    DoubleBuffered = True
    ParentBackground = False
    ParentDoubleBuffered = False
    TabOrder = 0
    object BtnView: TSpeedButton
      Left = 6
      Top = 6
      Width = 72
      Height = 32
      Hint = 'Show the rendered page (Ctrl+E switches)'
      GroupIndex = 1
      Down = True
      Caption = 'View'
      OnClick = ViewClick
    end
    object BtnEdit: TSpeedButton
      Left = 80
      Top = 6
      Width = 72
      Height = 32
      Hint = 'Edit the Markdown source (Ctrl+E switches)'
      GroupIndex = 1
      Caption = 'Edit'
      OnClick = EditClick
    end
    object BtnOpen: TSpeedButton
      Left = 170
      Top = 6
      Width = 72
      Height = 32
      Hint = 'Open a Markdown file (Ctrl+O)'
      Caption = 'Open'
      OnClick = OpenClick
    end
    object BtnSave: TSpeedButton
      Left = 246
      Top = 6
      Width = 72
      Height = 32
      Hint = 'Save (Ctrl+S).  Save as: Ctrl+Shift+S'
      Caption = 'Save'
      OnClick = SaveClick
    end
    object BtnZoomOut: TSpeedButton
      Left = 336
      Top = 6
      Width = 38
      Height = 32
      Hint = 'Zoom out'
      Caption = '-'
      OnClick = ZoomOutClick
    end
    object LblZoom: TLabel
      Left = 376
      Top = 6
      Width = 52
      Height = 32
      Alignment = taCenter
      AutoSize = False
      Caption = '100%'
      Transparent = True
      Layout = tlCenter
    end
    object BtnZoomIn: TSpeedButton
      Left = 430
      Top = 6
      Width = 38
      Height = 32
      Hint = 'Zoom in'
      Caption = '+'
      OnClick = ZoomInClick
    end
    object BtnTheme: TSpeedButton
      Left = 486
      Top = 6
      Width = 72
      Height = 32
      Hint = 'Switch between light and dark'
      Caption = 'Dark'
      OnClick = ThemeClick
    end
    object BtnClose: TSpeedButton
      Left = 1006
      Top = 6
      Width = 72
      Height = 32
      Hint = 'Close NowYouSee.md'
      Anchors = [akTop, akRight]
      Caption = 'Close'
      OnClick = CloseClick
    end
  end
  object EditBar: TPanel
    Left = 8
    Top = 52
    Width = 1084
    Height = 32
    Align = alTop
    BevelOuter = bvNone
    DoubleBuffered = True
    ParentBackground = False
    ParentDoubleBuffered = False
    TabOrder = 1
    object BtnH1: TSpeedButton
      Left = 6
      Top = 0
      Width = 32
      Height = 26
      Hint = 'Heading 1'
      Caption = '#'
      OnClick = FormatClick
    end
    object BtnH2: TSpeedButton
      Tag = 1
      Left = 40
      Top = 0
      Width = 36
      Height = 26
      Hint = 'Heading 2'
      Caption = '##'
      OnClick = FormatClick
    end
    object BtnH3: TSpeedButton
      Tag = 2
      Left = 78
      Top = 0
      Width = 44
      Height = 26
      Hint = 'Heading 3'
      Caption = '###'
      OnClick = FormatClick
    end
    object BtnBold: TSpeedButton
      Tag = 3
      Left = 134
      Top = 0
      Width = 30
      Height = 26
      Hint = 'Bold'
      Caption = 'B'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = FormatClick
    end
    object BtnItalic: TSpeedButton
      Tag = 4
      Left = 166
      Top = 0
      Width = 30
      Height = 26
      Hint = 'Italic'
      Caption = 'I'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
      OnClick = FormatClick
    end
    object BtnStrike: TSpeedButton
      Tag = 5
      Left = 198
      Top = 0
      Width = 30
      Height = 26
      Hint = 'Strikethrough'
      Caption = 'S'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsStrikeOut]
      ParentFont = False
      OnClick = FormatClick
    end
    object BtnCode: TSpeedButton
      Tag = 6
      Left = 230
      Top = 0
      Width = 36
      Height = 26
      Hint = 'Inline code'
      Caption = '<>'
      OnClick = FormatClick
    end
    object BtnLink: TSpeedButton
      Tag = 7
      Left = 278
      Top = 0
      Width = 48
      Height = 26
      Hint = 'Link'
      Caption = 'Link'
      OnClick = FormatClick
    end
    object BtnImage: TSpeedButton
      Tag = 8
      Left = 328
      Top = 0
      Width = 44
      Height = 26
      Hint = 'Image'
      Caption = 'Img'
      OnClick = FormatClick
    end
    object BtnQuote: TSpeedButton
      Tag = 9
      Left = 384
      Top = 0
      Width = 56
      Height = 26
      Hint = 'Quote'
      Caption = 'Quote'
      OnClick = FormatClick
    end
    object BtnList: TSpeedButton
      Tag = 10
      Left = 442
      Top = 0
      Width = 48
      Height = 26
      Hint = 'Bullet list'
      Caption = 'List'
      OnClick = FormatClick
    end
    object BtnNumber: TSpeedButton
      Tag = 11
      Left = 492
      Top = 0
      Width = 36
      Height = 26
      Hint = 'Numbered list'
      Caption = '1.'
      OnClick = FormatClick
    end
    object BtnTask: TSpeedButton
      Tag = 12
      Left = 530
      Top = 0
      Width = 52
      Height = 26
      Hint = 'Task'
      Caption = 'Task'
      OnClick = FormatClick
    end
    object BtnFence: TSpeedButton
      Tag = 13
      Left = 594
      Top = 0
      Width = 44
      Height = 26
      Hint = 'Code fence'
      Caption = '```'
      OnClick = FormatClick
    end
    object BtnTable: TSpeedButton
      Tag = 14
      Left = 640
      Top = 0
      Width = 56
      Height = 26
      Hint = 'Table'
      Caption = 'Table'
      OnClick = FormatClick
    end
    object BtnRule: TSpeedButton
      Tag = 15
      Left = 698
      Top = 0
      Width = 32
      Height = 26
      Hint = 'Horizontal rule'
      Caption = #8212
      OnClick = FormatClick
    end
  end
  object StatusFrame: TPanel
    AlignWithMargins = True
    Left = 8
    Top = 764
    Width = 1084
    Height = 28
    Margins.Left = 0
    Margins.Top = 8
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alBottom
    BevelOuter = bvNone
    Padding.Left = 1
    Padding.Top = 1
    Padding.Right = 1
    Padding.Bottom = 1
    ParentBackground = False
    TabOrder = 3
    object StatusPanel: TPanel
      Left = 1
      Top = 1
      Width = 1082
      Height = 26
      Align = alClient
      BevelOuter = bvNone
      ParentBackground = False
      TabOrder = 0
      object LblPath: TLabel
        AlignWithMargins = True
        Left = 10
        Top = 0
        Width = 772
        Height = 26
        Margins.Left = 10
        Margins.Top = 0
        Margins.Right = 10
        Margins.Bottom = 0
        Align = alClient
        AutoSize = False
        Caption = 'Untitled'
        EllipsisPosition = epPathEllipsis
        ShowAccelChar = False
        Transparent = True
        Layout = tlCenter
      end
      object LblState: TLabel
        AlignWithMargins = True
        Left = 792
        Top = 0
        Width = 70
        Height = 26
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 10
        Margins.Bottom = 0
        Align = alRight
        Alignment = taRightJustify
        AutoSize = False
        Transparent = True
        Layout = tlCenter
      end
      object LblEnc: TLabel
        AlignWithMargins = True
        Left = 872
        Top = 0
        Width = 70
        Height = 26
        Hint = 'How the file is stored. Save keeps it.'
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 10
        Margins.Bottom = 0
        Align = alRight
        Alignment = taRightJustify
        AutoSize = False
        Caption = 'UTF-8'
        Transparent = True
        Layout = tlCenter
      end
      object LblPos: TLabel
        AlignWithMargins = True
        Left = 952
        Top = 0
        Width = 120
        Height = 26
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 10
        Margins.Bottom = 0
        Align = alRight
        Alignment = taRightJustify
        AutoSize = False
        Caption = 'View'
        Transparent = True
        Layout = tlCenter
      end
    end
  end
  object Host: TPanel
    AlignWithMargins = True
    Left = 8
    Top = 92
    Width = 1084
    Height = 664
    Margins.Left = 0
    Margins.Top = 8
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 1
    Padding.Top = 1
    Padding.Right = 1
    Padding.Bottom = 1
    ParentBackground = False
    TabOrder = 2
    object FailLabel: TLabel
      Left = 1
      Top = 1
      Width = 1082
      Height = 662
      Align = alClient
      Alignment = taCenter
      AutoSize = False
      Caption =
        'The view needs the Microsoft Edge WebView2 Runtime, and WebView2' +
        'Loader.dll beside NowYouSee.exe.'
      Transparent = False
      Layout = tlCenter
      Visible = False
      WordWrap = True
    end
  end
  object OpenDialog: TOpenDialog
    Filter =
      'Markdown (*.md;*.markdown;*.txt)|*.md;*.markdown;*.txt|All files' +
      ' (*.*)|*.*'
    Options = [ofFileMustExist, ofEnableSizing]
    Left = 24
    Top = 160
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'md'
    Filter =
      'Markdown (*.md;*.markdown;*.txt)|*.md;*.markdown;*.txt|All files' +
      ' (*.*)|*.*'
    Options = [ofOverwritePrompt, ofEnableSizing]
    Left = 112
    Top = 160
  end
end
