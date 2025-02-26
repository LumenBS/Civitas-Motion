namespace CivitasMotion.CivitasMotion;

pageextension 76050 LBSCivitasMotionSetup extends LBSInterfaceSetup
{
    layout
    {
        Addafter(General)
        {
            Group(Motion)
            {
                Caption = 'Motion', Locked = true;

                field(LBSMotionJournalTemplateName; Rec.LBSMotionJournalTemplateName)
                {
                    ApplicationArea = All;
                }
                field(LBSMotionJournalBatchName; Rec.LBSMotionJournalBatchName)
                {
                    ApplicationArea = All;
                }
                field(LBSMotionAutomaticRelease; Rec.LBSMotionAutomaticRelease)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
