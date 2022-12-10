unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  Spin, EditBtn, lclintf, DividerBevel;

type

  { Tfrmmain }

  Tfrmmain = class(TForm)
    chkRemoveAlpha: TCheckBox;
    chkRemoveDigits: TCheckBox;
    chkRemoveNoneAlpha: TCheckBox;
    cmdAbout: TButton;
    cmdRename: TButton;
    cmdRemove: TButton;
    cboMask: TComboBox;
    DividerBevel1: TDividerBevel;
    DividerBevel2: TDividerBevel;
    lblMask: TLabel;
    txtFind: TEdit;
    txtReplace: TEdit;
    lblFind: TLabel;
    lblReplace: TLabel;
    SBar1: TStatusBar;
    txtSrcFolder: TDirectoryEdit;
    IdInc: TSpinEdit;
    lblNameRule1: TLabel;
    lblNameRule2: TLabel;
    lblSrcFolder: TLabel;
    StartAt: TSpinEdit;
    txtRule: TEdit;
    ImgList: TImageList;
    lblNameRule: TLabel;
    lstFiles: TListView;
    procedure cboMaskChange(Sender: TObject);
    procedure chkCounterChange(Sender: TObject);
    procedure chkRemoveAlphaChange(Sender: TObject);
    procedure chkRemoveDigitsChange(Sender: TObject);
    procedure chkRemoveNoneAlphaChange(Sender: TObject);
    procedure cmdAboutClick(Sender: TObject);
    procedure cmdRemoveClick(Sender: TObject);
    procedure cmdRenameClick(Sender: TObject);
    procedure cmdUpdateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IdIncChange(Sender: TObject);
    procedure lstFilesDblClick(Sender: TObject);
    procedure lstFilesSelectItem(Sender: TObject; Item: TListItem;
      Selected: boolean);
    procedure StartAtChange(Sender: TObject);
    procedure txtFindChange(Sender: TObject);
    procedure txtReplaceChange(Sender: TObject);
    procedure txtRuleChange(Sender: TObject);
    procedure txtSrcFolderAcceptDirectory(Sender: TObject; var Value: string);
    procedure txtSrcFolderChange(Sender: TObject);
  private
    procedure ResizeCols;
    procedure AddFilesFromFolder(Path: string);
    function GetFileTitle(FileName: string): string;
    function IsFleInList(Filename: string; LV: TListView): boolean;
    function FixPath(S: string): string;
    procedure UpdateNameingRule;
    function IsGoodFilename(S: string): boolean;
    function RemoveAlpha(src: string): string;
    function RemoveDigits(Src: string): string;
    function RemoveNoneAlpha(Src: string): string;
  public

  end;

var
  frmmain: Tfrmmain;
  FileCounter: integer;
  SrcPath: string;
  IsReplace: boolean;
  liSelected: TListItem;

implementation

{$R *.lfm}

{ Tfrmmain }

function Tfrmmain.RemoveAlpha(Src: string): string;
var
  S: string;
  X: integer;
begin
  S := '';
  for X := 1 to length(Src) do
  begin
    if not (Src[X] in ['A'..'Z', 'a'..'z']) then
    begin
      S := S + Src[X];
    end;
  end;
  Result := S;
end;

function Tfrmmain.RemoveDigits(Src: string): string;
var
  S: string;
  X: integer;
begin
  S := '';
  for X := 1 to length(Src) do
  begin
    if not (Src[X] in ['0'..'9']) then
    begin
      S := S + Src[X];
    end;
  end;
  Result := S;
end;

function Tfrmmain.RemoveNoneAlpha(Src: string): string;
var
  S: string;
  X: integer;
begin
  S := '';
  for X := 1 to length(Src) do
  begin
    if (Src[X] in ['A'..'Z', 'a'..'z', '0'..'9']) then
    begin
      S := S + Src[X];
    end;
  end;
  Result := S;
end;

function Tfrmmain.FixPath(S: string): string;
begin
  if rightstr(S, 1) <> PathDelim then
  begin
    Result := S + PathDelim;
  end
  else
  begin
    Result := S;
  end;
end;

procedure Tfrmmain.ResizeCols;
var
  X: integer;
begin
  for X := 0 to lstFiles.ColumnCount - 1 do
  begin
    lstFiles.Column[X].AutoSize := True;
  end;
end;

procedure tFrmmain.AddFilesFromFolder(Path: string);
var
  li: TListItem;
  sr: TSearchRec;
  lzPath, lzFile: string;
begin
  lzPath := FixPath(Path);
  //Set src path
  SrcPath := lzPath;


  lstFiles.BeginUpdate;
  //Clear the files list
  lstFiles.Clear;

  if FindFirst(SrcPath + cboMask.Text, faAnyFile, sr) = 0 then
  begin
    repeat
      //Get filename
      lzFile := sr.Name;

      if (lzFile <> '.') and (lzfile <> '..') and
        ((sr.Attr and faDirectory) <> faDirectory) then
      begin
        if not IsFleInList(lzFile, lstFiles) then
        begin
          li := lstFiles.Items.Add;
          li.Caption := lzFile;
          li.ImageIndex := 0;
          li.SubItems.Add(lzFile);
          li.SubItems.Add(lzPath);
        end;

      end;

    until FindNext(sr) <> 0;
  end;
  lstFiles.EndUpdate;
end;

function Tfrmmain.GetFileTitle(FileName: string): string;
var
  S: string;
  sPos: integer;
begin
  //Returns a filename with out the file .ext
  S := FileName;

  sPos := Pos('.', S);
  if sPos > 0 then
  begin
    Result := LeftStr(S, sPos - 1);
  end
  else
  begin
    Result := S;
  end;

end;

function Tfrmmain.IsFleInList(Filename: string; LV: TListView): boolean;
var
  X: integer;
  li: TListItem;
  flag: boolean;
begin
  //Find a string in the listview first colunm
  flag := False;
  for X := 0 to lstFiles.Items.Count - 1 do
  begin
    //Get list item
    li := lstFiles.Items[X];
    //Check caption to filename
    if lowercase(li.Caption) = lowercase(Filename) then
    begin
      flag := True;
      Break;
    end;
  end;

  Result := flag;
end;

procedure Tfrmmain.UpdateNameingRule;
var
  li: TListItem;
  X: integer;
  sOldFile: string;
  sNewFile: string;
  sOldFileExt: string;
begin
  //Main file nameing rules

  //File counter to start at
  FileCounter := StartAt.Value;

  for X := 0 to lstFiles.Items.Count - 1 do
  begin
    //Get list item
    li := lstFiles.Items[X];
    sOldFile := GetFileTitle(li.Caption);
    sOldFileExt := ExtractFileExt(li.Caption);
    sNewFile := txtRule.Text;

    if chkRemoveAlpha.Checked then
    begin
      sOldFile := RemoveAlpha(sOldFile);
    end;

    if chkRemoveDigits.Checked then
    begin
      sOldFile := RemoveDigits(sOldFile);
    end;

    if chkRemoveNoneAlpha.Checked then
    begin
      sOldFile := RemoveNoneAlpha(sOldFile);
    end;

    sOldFile := StringReplace(sOldFile, txtFind.Text, txtReplace.Text,
      [rfReplaceAll, rfIgnoreCase]);
    //File INC counter
    sNewFile := StringReplace(sNewFile, '%c', IntToStr(FileCounter), [rfReplaceAll]);
    //File ext to lowercase
    sNewFile := StringReplace(sNewFile, '%ext', lowercase(sOldFileExt), [rfReplaceAll]);
    //File ext to uppercase
    sNewFile := StringReplace(sNewFile, '%EXT', uppercase(sOldFileExt), [rfReplaceAll]);
    //Original filename lower case without file ext
    sNewFile := StringReplace(sNewFile, '%fn', LowerCase(sOldFile), [rfReplaceAll]);
    //Original filename uppercase without file ext
    sNewFile := StringReplace(sNewFile, '%FN', uppercase(sOldFile), [rfReplaceAll]);
    //Original filename uppercase without file ext
    sNewFile := StringReplace(sNewFile, '%fo', sOldFile, [rfReplaceAll]);
    //Date day short eg Mon
    sNewFile := StringReplace(sNewFile, '%A', FormatDateTime('DDD', Now),
      [rfReplaceAll]);
    //Date day long eh Monday
    sNewFile := StringReplace(sNewFile, '%a', FormatDateTime('DDDD', Now),
      [rfReplaceAll]);
    //Date Month short eg Dec
    sNewFile := StringReplace(sNewFile, '%B', FormatDateTime('MMM', Now),
      [rfReplaceAll]);
    //Date Month long eg December
    sNewFile := StringReplace(sNewFile, '%b', FormatDateTime('MMMM', Now),
      [rfReplaceAll]);
    //Date day as decimal eg 05
    sNewFile := StringReplace(sNewFile, '%d', FormatDateTime('DD', Now), [rfReplaceAll]);
    //Date month as decimal eg 07
    sNewFile := StringReplace(sNewFile, '%m', FormatDateTime('mm', Now), [rfReplaceAll]);
    //Date current year short eg 22
    sNewFile := StringReplace(sNewFile, '%Y', FormatDateTime('YY', Now), [rfReplaceAll]);
    //Date current year full eg 2020
    sNewFile := StringReplace(sNewFile, '%y', FormatDateTime('YYYY', Now),
      [rfReplaceAll]);
    //Time hour
    sNewFile := StringReplace(sNewFile, '%H', FormatDateTime('hh', Now), [rfReplaceAll]);
    //Time minute
    sNewFile := StringReplace(sNewFile, '%M', FormatDateTime('nn', Now), [rfReplaceAll]);
    //Time second
    sNewFile := StringReplace(sNewFile, '%S', FormatDateTime('ss', Now), [rfReplaceAll]);
    //INC File counter
    Inc(FileCounter, IdInc.Value);
    //Update the subitem
    li.SubItems[0] := sNewFile;
  end;
end;

function Tfrmmain.IsGoodFilename(S: string): boolean;
var
  X: integer;
  Flag: boolean;
begin
  Flag := True;

  for X := 1 to Length(S) do
  begin
    if (S[X] in ['<', '>', '/', '\', ':', '|', '*', '?', '"']) then
    begin
      Flag := False;
      Break;
    end;
  end;

  Result := Flag;
end;

procedure Tfrmmain.FormCreate(Sender: TObject);
begin
  ResizeCols;
end;

procedure Tfrmmain.IdIncChange(Sender: TObject);
begin
  if IdInc.Value < 1 then IdInc.Value := 1;
  UpdateNameingRule;
end;

procedure Tfrmmain.lstFilesDblClick(Sender: TObject);
begin
  if liSelected <> nil then
  begin
    //Open selected filename.
    OpenDocument(liSelected.SubItems[1] + liSelected.Caption);
  end;
end;

procedure Tfrmmain.lstFilesSelectItem(Sender: TObject; Item: TListItem;
  Selected: boolean);
begin
  liSelected := Item;
  cmdRemove.Enabled := True;
end;

procedure Tfrmmain.StartAtChange(Sender: TObject);
begin
  if StartAt.Value < 1 then StartAt.Value := 1;
  UpdateNameingRule;
end;

procedure Tfrmmain.txtFindChange(Sender: TObject);
begin
  UpdateNameingRule;
end;

procedure Tfrmmain.txtReplaceChange(Sender: TObject);
begin
  UpdateNameingRule;
end;

procedure Tfrmmain.txtRuleChange(Sender: TObject);
begin
  UpdateNameingRule;
end;

procedure Tfrmmain.txtSrcFolderAcceptDirectory(Sender: TObject; var Value: string);
begin
  AddFilesFromFolder(Value);
  SBar1.Panels[0].Text := ' ' + IntToStr(lstFiles.Items.Count - 1) + ' files found.';
  UpdateNameingRule;
  ResizeCols;
end;

procedure Tfrmmain.txtSrcFolderChange(Sender: TObject);
begin

end;

procedure Tfrmmain.cmdRenameClick(Sender: TObject);
var
  X: integer;
  li: TListItem;
  lzOldFile, lzNewFile: string;
begin
  if lstFiles.Items.Count = 0 then
  begin
    MessageDlg(Text, 'There are no files to rename.' + sLineBreak + 'Please add some files first.',
      mtInformation, [mbOK], 0);
  end
  else if not IsGoodFilename(txtRule.Text) then
  begin
    MessageDlg(Text, 'The naming rule contains illegal characters.',
      mtError, [mbOK], 0);
  end
  else
  begin
    for X := 0 to lstFiles.Items.Count - 1 do
    begin
      li := lstFiles.Items[X];
      //Get old filename
      lzOldFile := li.SubItems[1] + li.Caption;
      lzNewFile := li.SubItems[1] + li.SubItems[0];
      RenameFile(lzOldFile, lzNewFile);
    end;

    //Update the list view
    AddFilesFromFolder(SrcPath);

    if MessageDlg(Text, 'All done, Do you want to open the folder now?',
      mtInformation, [mbYes, mbNo], 0) = mrYes then
    begin
      OpenDocument(SrcPath);
    end;
    ResizeCols;
  end;
end;

procedure Tfrmmain.cmdUpdateClick(Sender: TObject);
begin

end;

procedure Tfrmmain.cmdRemoveClick(Sender: TObject);
var
  X: integer;
  li: TListItem;
begin
  if liSelected <> nil then
    if MessageDlg(Text,
      'Are you sure you want to remove the selected items from this list?',
      mtInformation, [mbYes, mbNo], 0) = mrYes then
    begin

      for X := lstFiles.Items.Count - 1 downto 0 do
      begin
        li := lstFiles.Items[X];
        if li.Selected then
        begin
          li.Delete;
        end;
      end;
      cmdRemove.Enabled := False;
    end;
end;

procedure Tfrmmain.chkRemoveAlphaChange(Sender: TObject);
begin
  UpdateNameingRule;
end;

procedure Tfrmmain.cboMaskChange(Sender: TObject);
begin
  if (Trim(txtSrcFolder.Text) <> '') and (DirectoryExists(txtSrcFolder.Text)) then
  begin
    AddFilesFromFolder(txtSrcFolder.Text);
    SBar1.Panels[0].Text := ' ' + IntToStr(lstFiles.Items.Count - 1) + ' files found.';
    UpdateNameingRule;
    ResizeCols;
  end;
end;

procedure Tfrmmain.chkCounterChange(Sender: TObject);
begin
  ;
end;

procedure Tfrmmain.chkRemoveDigitsChange(Sender: TObject);
begin
  UpdateNameingRule;
end;

procedure Tfrmmain.chkRemoveNoneAlphaChange(Sender: TObject);
begin
  UpdateNameingRule;
end;

procedure Tfrmmain.cmdAboutClick(Sender: TObject);
begin
  MessageDlg('About ' + Caption + ' v1,0' + sLineBreak +
    'Simple filename rename tool.' + sLineBreak + 'By Ben J a.k.a DreamVB',
    mtInformation, [mbOK], 0);
end;

end.
