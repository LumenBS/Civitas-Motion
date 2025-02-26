namespace CivitasMotion.CivitasMotion;
using Microsoft.Finance.GeneralLedger.Journal;


tableextension 76050 LBSCivitasMotionSetup extends LBSInterfaceSetup
{
    fields
    {
        field(76000; LBSMotionJournalTemplateName; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Journal Template";
            ToolTip = 'Specifies the Journal Template Name to be used';
            AllowInCustomizations = Always;

            Trigger OnValidate()
            var
                GenJournalBatch: Record "Gen. Journal Batch";
                EasyFundersBatchDescriptionLbl: Label 'EasyFunders Journal';
            begin
                if Rec.LBSMotionJournalTemplateName <> '' then begin
                    GenJournalBatch.SetRange("Journal Template Name", Rec.LBSMotionJournalTemplateName);
                    GenJournalBatch.SetRange(Name, Rec.LBSMotionJournalTemplateName);
                    if not GenJournalBatch.FindFirst() then begin
                        GenJournalBatch.Reset();
                        GenJournalBatch.Init();
                        GenJournalBatch."Journal Template Name" := Rec.LBSMotionJournalTemplateName;
                        GenJournalBatch.Name := Rec.LBSMotionJournalTemplateName;
                        GenJournalBatch.Description := MotionBatchDescriptionLbl;
                        GenJournalBatch.Insert(true);
                    end;
                end;
            end;
        }
        field(76001; LBSMotionJournalBatchName; Code[10])
        {
            Caption = 'Journal Batch Name';
            ToolTip = 'Specifies the Journal Batch Name to be used';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Journal Batch" where("Journal Template Name" = field(LBSMotionJournalTemplateName));
            AllowInCustomizations = Always;
        }
        field(76002; LBSMotionAutomaticRelease; Boolean)
        {
            Caption = 'Automatic Releasse';
            ToolTip = 'Specifies if the journal should be automatic set to released.';
            DataClassification = SystemMetadata;
            AllowInCustomizations = Always;
        }
    }

    var
        MotionBatchDescriptionLbl: Label 'Motion Journal';
}
