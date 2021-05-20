program OrdersManager.OrderLoader;

{$APPTYPE CONSOLE}
{$DEFINE NOFORMS}
{$R *.res}

uses
  System.SysUtils,
  uxServer in 'uxServer.pas',
  uxService in '..\..\Components\Common\uxService.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  PrepareProcessParams(SvcStart, SvcLoop, SvcStop);
end.
