unit AEQuery.Main;

interface

uses
  Airas.EQuery.Client,
  Airas.EQuery.Types,
  AEQuery.TThreadTimer,
  TelegaPi,
  TelegramBotApi.Tools.Router,
  TelegramBotApi.Tools.UserDataStorage.Json;

type
  TAEQuery = class
  private
    FQuery: TAirasQuery;
    FTelegram: TTelegramBotApi;
    FTgPool: TtgPollingConsole;
    FRouteUserStates: TtgUserDataStorage;
    FTgRouter: TtgRouter;
    FTimer: TThreadTimer;
    function QueryState(AEQAuth: TeqOperatorAuth): string;
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
  FRouteUserStates := TtgUserDataStorage.Create('data.json');
  FTgRouter := TtgRouter.Create(FRouteUserStates, FTelegram);
  FTgRouter.RegisterRoutes([RouteStart, RouteWork]);
  FTgRouter.OnRouteNotFound := procedure(AUserID: Int64; ARoute: string)
    begin
      Writeln(format('%d - не найден маршрут: %s', [AUserID, ARoute]));
    end;
  FTgRouter.OnRouteMove := procedure(AUserID: Int64; AFrom, ATo: TtgRoute)
    begin
      Writeln(format('%d %s %s', [AUserID, AFrom.Name, ATo.Name]));
    end;
  FTimer := TThreadTimer.Create;
  FTimer.Interval := 1000;
  FTimer.Start;
  FTimer.OnTimer := procedure
    var
      i: Int64;
      lUsers: TArray<Int64>;
      lToken: string;
    begin
      lUsers := FRouteUserStates.GetUsers;
      for i in lUsers do
        lToken := FRouteUserStates[i, 'auth'];

    end;
end;

destructor TAEQuery.Destroy;
begin
  FTimer.Free;
  Stop;
  FTgPool.Free;
  FQuery.Free;
  FTelegram.Free;
  FRouteUserStates.Free;
  FTgRouter.Free;
  inherited;
end;

function TAEQuery.QueryState(AEQAuth: TeqOperatorAuth): string;
var
  Params: TeqParamEQueryOper;
begin
  Params := FQuery.ShowParamEqueryOper(AEQAuth);
  Result := format('Всего: %s' + #13#10 + 'Мои: %s' + #13#10 + 'Сейчас: %s' + #13#10 + 'Следующие: %s',
    [Params.allAllClients, Params.allClients, Params.near, Params.next]);
  if Length(Params.Users) > 0 then
    Result := Result + #13#10 + format('', [Params.Users[0].docstate]);
end;

function TAEQuery.RouteStart: TtgRoute;
begin
  Result.Name := '/start';
  Result.OnStartCallback := procedure(AUserID: Int64; AMsg: TtgMessage)
    var
      lSendMsg: TtgSendMessageArgument;
      lUsersKb: TtgInlineKeyboardMarkup;
      lUserKbBtn: TtgInlineKeyboardButton;
      i: integer;
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
      lDeleteMsgArg: TtgDeleteMessageArgument;
    begin
      lEQAuth := FQuery.UserCheck(ACQ.Data);
      AnswerCQ.CallbackQueryId := ACQ.ID;
      AnswerCQ.CacheTime := 3;
      if lEQAuth.sessionid.IsEmpty then
      begin
        AnswerCQ.Text := '⛔️Ошибка авторизации. Обратитесь к администратору';
        AnswerCQ.ShowAlert := True;
        FTelegram.AnswerCallbackQuery(AnswerCQ);
      end
      else
      begin
        FRouteUserStates[ACQ.From.ID, 'auth'] := lEQAuth.sessionid;
        AnswerCQ.Text := '✅ Успешно авторизовано' + #13#10 + QueryState(lEQAuth);
        AnswerCQ.ShowAlert := True;
        FTelegram.AnswerCallbackQuery(AnswerCQ);
        lDeleteMsgArg := TtgDeleteMessageArgument.Create;
        try
          lDeleteMsgArg.ChatId := ACQ.Message.Chat.ID;
          lDeleteMsgArg.MessageID := ACQ.Message.MessageID;
          // FTelegram.DeleteMessage(lDeleteMsgArg);
        finally
          lDeleteMsgArg.Free;
        end;
      end;
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
      i: integer;
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
