unit AEQuery.Route.Start;

interface

uses
  TelegramBotApi.Tools.Router;

function RouteStart: TtgRoute;

implementation

uses
  TelegramBotApi.Types,
  TelegramBotApi.Types.AvailableMethods;

function RouteStart: TtgRoute;
begin
  Result.Name := '/start';
  Result.OnStartCallback := procedure(AUserID: Int64; AMsg: TtgMessage)
    var
      lSendMsg: TtgSendMessageArgument;
    begin
      lSendMsg := TtgSendMessageArgument;
      try

      finally
        lSendMsg.Free;
      end;
    end;
end;

end.
