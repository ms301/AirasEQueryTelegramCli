program AirasEQueryTg;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  AEQuery.Main in 'AEQuery.Main.pas',
  TelegramBotApi.Tools.UserDataStorage.Abstract in 'TelegaPi\TelegramBotApi.Tools.UserDataStorage.Abstract.pas',
  TelegramBotApi.Tools.UserDataStorage.Json in 'TelegaPi\TelegramBotApi.Tools.UserDataStorage.Json.pas',
  TelegramBotApi.Tools.UserDataStorage.Ram in 'TelegaPi\TelegramBotApi.Tools.UserDataStorage.Ram.pas',
  TelegramBotApi.Tools.Router in 'TelegaPi\TelegramBotApi.Tools.Router.pas',
  AEQuery.TThreadTimer in 'AEQuery.TThreadTimer.pas';

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
