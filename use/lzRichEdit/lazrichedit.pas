{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit LazRichEdit;

{$warn 5023 off : no warning about unused units}
interface

uses
  RichBox, WSRichBoxFactory, WSRichBox, Win32WSRichBox, Win32WSRichBoxFactory, 
  Gtk2WSRichBox, Gtk2WSRichBoxFactory, Gtk2RTFTool, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('RichBox', @RichBox.Register);
end;

initialization
  RegisterPackage('LazRichEdit', @Register);
end.
