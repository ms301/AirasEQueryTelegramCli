unit AEQuery.Main;

interface

uses
  Airas.EQuery.Client,
  TelegaPi,
  TelegramBotApi.Tools.Router;

type
  TAEQuery = class
  private
    FQuery: TAirasQuery;
    FTelegram: TTelegramBotApi;
    FTgPool: TtgPollingConsole;
    FRouteUserStates: TtgRouteUserStateManagerAbstract;
    FTgRouter: TtgRouter;
  protected
    function RouteStart: TtgRoute;
    function RouteWork: TtgRoute;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
  end;

implementation

uses
  Airas.EQuery.Types,
  TelegramBotApi.Types.AvailableMethods,
  TelegramBotApi.Types.Keyboards,
  TelegramBotApi.Types.Request,
  System.SysUtils;

{ TAEQuery }

constructor TAEQuery.Create;
begin
  FQuery := TAirasQuery.Create;
  FQuery.Server := 'http://192.168.77.33:3219';
  FTelegram := TTelegramBotApi.Create('878129409:AAEOYHFmTimbbeEZ64kETJKRlHi-nEKZcnU');
  FTgPool := TtgPollingConsole.Create(FTelegram);
  FTgPool.OnMessage := procedure(AMsg: TtgMessage)
    begin
      FTgRouter.SendMessage(AMsg);
    end;
  FTgPool.OnCallbackQuery := procedure(ACQ: TtgCallbackQuery)
    begin
      FTgRouter.SendCallbackQuery(ACQ);
    end;
  FRouteUserStates := TtgRouteUserStateManagerRAM.Create;
  FTgRouter := TtgRouter.Create(FRouteUserStates, FTelegram);
  FTgRouter.RegisterRoute(RouteStart);
  FTgRouter.OnRouteNotFound := procedure(AUserID: Int64; ARoute: string)
    begin

    end;
  FTgRouter.OnRouteMove := procedure(AUserID: Int64; AFrom, ATo: TtgRoute)
    begin
      Writeln(format('%d %s %s', [AUserID, AFrom.Name, ATo.Name]));
    end;
end;

destructor TAEQuery.Destroy;
begin
  Stop;
  FTgPool.Free;
  FQuery.Free;
  FTelegram.Free;
  FRouteUserStates.Free;
  FTgRouter.Free;
  inherited;
end;

function TAEQuery.RouteStart: TtgRoute;
begin
  Result.Name := '/start';
  Result.OnStartCallback := procedure(AUserID: Int64; AMsg: TtgMessage)
    var
      lSendMsg: TtgSendMessageArgument;
      lUsersKb: TtgInlineKeyboardMarkup;
      lUserKbBtn: TtgInlineKeyboardButton;
      i: Integer;
      lUsers: TArray<TeqOperator>;
    begin
      lSendMsg := TtgSendMessageArgument.Create;
      try
        lSendMsg.ChatId := AMsg.Chat.ID;
        lSendMsg.Text := '😎 Оберіть адміністратора для авторизації у електронній черзі:';

        lUsersKb := TtgKeyboardBuilder.InlineKb;
        lUsers := FQuery.GetOperators;
        for i := low(lUsers) to High(lUsers) do
        begin
          if (i mod 2 = 0) then
            lUsersKb.AddRow;
          lUserKbBtn := lUsersKb.AddButton;
          lUserKbBtn.Text := lUsers[i].Name;
          lUserKbBtn.CallbackData := lUsers[i].Login;

        end;
        lSendMsg.ReplyMarkup := lUsersKb;
        FTelegram.SendMessage(lSendMsg);
      finally
        lSendMsg.Free;
      end;
    end;
  Result.OnCallbackQuery := procedure(ACQ: TtgCallbackQuery)
    var
      AnswerCQ: TtgAnswerCallbackQueryArgument;
      lEQAuth: TeqOperatorAuth;
    begin
      lEQAuth := FQuery.UserCheck(ACQ.Data);
      AnswerCQ.CallbackQueryId := ACQ.ID;
      AnswerCQ.CacheTime := 3000;
      if lEQAuth.sessionid.IsEmpty then
      begin
        AnswerCQ.Text := '⛔️Ошибка авторизации. Обратитесь к администратору';
        AnswerCQ.ShowAlert := True;
      end
      else
      begin
        AnswerCQ.Text := '✅ Успешно авторизовано';
        AnswerCQ.ShowAlert := False;
      end;
      FTelegram.AnswerCallbackQuery(AnswerCQ);
    end;
end;

function TAEQuery.RouteWork: TtgRoute;
begin
  Result.Name := '/work';
  Result.OnStartCallback := procedure(AUserID: Int64; AMsg: TtgMessage)
    var
      lSendMsg: TtgSendMessageArgument;
      lUsersKb: TtgInlineKeyboardMarkup;
      lUserKbBtn: TtgInlineKeyboardButton;
      i: Integer;
      lUsers: TArray<TeqOperator>;
    begin
      lSendMsg := TtgSendMessageArgument.Create;
      try
        lSendMsg.ChatId := AMsg.Chat.ID;
        lSendMsg.Text := '😎 Оберіть адміністратора для авторизації у електронній черзі:';
        lUsersKb := TtgKeyboardBuilder.InlineKb;
        lUsers := FQuery.GetOperators;
        for i := low(lUsers) to High(lUsers) do
        begin
          if (i mod 2 = 0) then
            lUsersKb.AddRow;
          lUserKbBtn := lUsersKb.AddButton;
          lUserKbBtn.Text := lUsers[i].Name;
          lUserKbBtn.CallbackData := lUsers[i].Login;
        end;
        lSendMsg.ReplyMarkup := lUsersKb;
        FTelegram.SendMessage(lSendMsg);
      finally
        lSendMsg.Free;
      end;
    end;
end;

procedure TAEQuery.Start;
begin
  FTgPool.Start;
end;

procedure TAEQuery.Stop;
begin
  FTgPool.Stop;
end;

end.
