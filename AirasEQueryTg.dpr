program AirasEQueryTg;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  AEQuery.Main in 'AEQuery.Main.pas',
  TelegramBotApi.Tools.UserDataStorage in 'TelegaPi\TelegramBotApi.Tools.UserDataStorage.pas';

procedure Run;
var
  lQ: TAEQuery;
begin
  lQ := TAEQuery.Create;
  try
    lQ.Start;
    Writeln('Press Enter for end Service');
    Readln;
    lQ.Stop;
  finally
    lQ.Free;
  end;
end;

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
    Run;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
