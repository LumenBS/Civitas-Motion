namespace CivitasMotion.CivitasMotion;

page 76051 LBSCivitasStartMotionImport
{
    ApplicationArea = All;
    Caption = 'Motion file Import';
    PageType = Card;
    UsageCategory = Tasks;

    Trigger OnOpenPage()
    begin
        XmlPort.Run(XmlPort::LBSCivitasImportMotion);
        ERROR('');
    end;
}
