unit AEQuery.TThreadTimer;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs;

type
  TThreadTimer = class
  private
    FEvent: TEvent;
    fWorker: TThread;
    FInterval: Cardinal;
    FOnTimer: TProc;
  protected
    procedure Go;
  public
    constructor Create;
    procedure Start; virtual;
    procedure Stop;
    destructor Destroy; override;
    property Interval: Cardinal read FInterval write FInterval;
    property OnTimer: TProc read FOnTimer write FOnTimer;
  end;

implementation

{ TThreadTimer }

constructor TThreadTimer.Create;
begin
  inherited Create();
  FEvent := TEvent.Create();
  FInterval := 1000;
end;

destructor TThreadTimer.Destroy;
begin
  Stop;
  FEvent.Free;
  inherited Destroy;
end;

procedure TThreadTimer.Go;
begin
  if Assigned(OnTimer) then
    OnTimer();
end;

procedure TThreadTimer.Start;
begin
  if Assigned(fWorker) then
    Exit;
  fWorker := TThread.CreateAnonymousThread(
    procedure
    var
      lWaitResult: TWaitResult;
    begin
      while True do
      begin
        lWaitResult := FEvent.WaitFor(FInterval);
        if lWaitResult = wrTimeout then
          Go
        else
          Break;
      end;
    end);
  fWorker.FreeOnTerminate := False;
  fWorker.Start;
end;

procedure TThreadTimer.Stop;
begin
  FEvent.SetEvent;
  if Assigned(fWorker) then
    fWorker.WaitFor;
  FreeAndNil(fWorker);
end;

end.
