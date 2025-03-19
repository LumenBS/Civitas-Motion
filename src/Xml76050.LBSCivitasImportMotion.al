namespace CivitasMotion.CivitasMotion;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Project.Job;
using Civitas.Civitas;

xmlport 76050 LBSCivitasImportMotion
{
    Caption = 'Import motion file', Locked = true;
    UseRequestPage = false;
    Direction = Import;
    Format = VariableText;
    FieldSeparator = ';';

    schema
    {
        textelement(RootNodeName)
        {
            tableelement(GenJournalLineTemp; "Gen. Journal Line")
            {
                SourceTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
                UseTemporary = true;
                AutoSave = false;

                textelement(Field1)
                { }
                textelement(Field2)
                { }
                textelement(Field3)
                { }
                textelement(Field4)
                { }
                textelement(Field5)
                { }
                textelement(Field6)
                { }
                textelement(Field7)
                { }
                textelement(Field8)
                { }
                textelement(Field9)
                { }

                trigger OnBeforeInsertRecord()
                var
                    GLAccount: Record "G/L Account";
                    Job: Record Job;
                    JobTask: Record "Job Task";
                begin
                    //Check  
                    if Field4 = '' then
                        currXMLport.Skip();

                    Job.Init();

                    if (copystr(Field4, 1, 1) = '4') or (copystr(Field4, 1, 1) = '8') then begin
                        GLAccount.Get(Field4);
                        if Field3 <> '' then begin
                            Job.Get(Field3);
                            Job.TestField(Status, Job.Status::Open);
                            Job.TestBlocked();

                            JobTask.Get(Job."No.", '10');
                            JobTask.TestField(LBSBlocked, false);
                        end;
                    end else
                        GLAccount.Get(Field3);
                    GLAccount.TestField(Blocked, false);
                    GLAccount.TestField("Account Type", GLAccount."Account Type"::Posting);
                    GLAccount.TestField("Direct Posting", True);

                    //Convert
                    Field2 := copystr(field2, 7, 2) + copystr(field2, 5, 2) + copystr(field2, 1, 4);

                    //Create temp record
                    LineNo += 1;
                    GenJournalLineTemp."Journal Template Name" := CivitasInterfaceSetup.LBSMotionJournalTemplateName;
                    GenJournalLineTemp."Journal Batch Name" := CivitasInterfaceSetup.LBSMotionJournalBatchName;
                    GenJournalLineTemp."Line No." := LineNo;
                    evaluate(GenJournalLineTemp."Posting Date", Field2);
                    GenJournalLineTemp."Account No." := GLAccount."No.";
                    Evaluate(GenJournalLineTemp.Amount, Field8);
                    GenJournalLineTemp.Description := Field9;
                    GenJournalLineTemp."Job No." := Job."No.";
                    GenJournalLineTemp.Insert();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CivitasInterfaceSetup.get();
        CivitasInterfaceSetup.TestField(LBSMotionJournalTemplateName);
        CivitasInterfaceSetup.TestField(LBSMotionJournalBatchName);
    end;

    trigger OnPostXmlPort()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLineHeader: Record LBSGenJournalLineHeader;
        NoSeriesMgt: Codeunit "No. Series";
        NewDocNo: Code[20];
    begin
        if GenJournalLineTemp.findfirst then begin
            //Find last Line No
            GenJournalLine.Setrange("Journal Template Name", CivitasInterfaceSetup.LBSMotionJournalTemplateName);
            GenJournalLine.Setrange("Journal Batch Name", CivitasInterfaceSetup.LBSMotionJournalBatchName);
            if GenJournalLine.findlast then
                LineNo := GenJournalLine."Line No."
            else
                LineNo := 0;

            GenJournalTemplate.Get(CivitasInterfaceSetup.LBSMotionJournalTemplateName);
            NewDocNo := NoSeriesMgt.GetNextNo(GenJournalTemplate."No. Series");

            //Create Journal Lines
            repeat
                LineNo += 10000;
                GenJournalLine.Reset();
                GenJournalLine.Validate("Journal Template Name", CivitasInterfaceSetup.LBSMotionJournalTemplateName);
                GenJournalLine.Validate("Journal Batch Name", CivitasInterfaceSetup.LBSMotionJournalBatchName);
                GenJournalLine."Line No." := LineNo;
                GenJournalLine."Document No." := NewDocNo;
                GenJournalLine.Validate("Posting Date", GenJournalLineTemp."Posting Date");
                GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
                GenJournalLine.Validate("Account No.", GenJournalLineTemp."Account No.");
                GenJournalLine.Description := GenJournalLine.Description;
                GenJournalLine.Validate("Amount", GenJournalLineTemp.Amount);
                GenJournalLine.Validate("Job No.", GenJournalLineTemp."Job No.");
                if GenJournalLine."Job No." <> '' then
                    GenJournalLine.Validate("Job Task No.", '10');
                if CivitasInterfaceSetup.LBSMotionAutomaticRelease then
                    GenJournalLine.LBSApprovalStatus := GenJournalLine.LBSApprovalStatus::Released;
                GenJournalLine.Insert(true);
            until GenJournalLineTemp.Next = 0;

            //Check
            if CivitasInterfaceSetup.LBSMotionAutomaticRelease then begin
                GenJournalLine.Reset;
                GenJournalLine.Setrange("Journal Template Name", CivitasInterfaceSetup.LBSMotionJournalTemplateName);
                GenJournalLine.Setrange("Journal Batch Name", CivitasInterfaceSetup.LBSMotionJournalBatchName);
                GenJournalLine.Setrange("Document No.", NewDocNo);
                GenJournalLine.CalcSums(Amount);
                if GenJournalLine.Amount <> 0 then
                    Error(StrSubstNo(NotInBalanceErr, GenJournalLine.Amount));
            end;

            //Create Journal Header
            if not GenJournalLineHeader.get(CivitasInterfaceSetup.LBSMotionJournalTemplateName, CivitasInterfaceSetup.LBSMotionJournalBatchName, NewDocNo) then begin
                GenJournalLineHeader.init();
                GenJournalLineHeader.LBSJournalTemplateName := CivitasInterfaceSetup.LBSMotionJournalTemplateName;
                GenJournalLineHeader.LBSJournalBatchName := CivitasInterfaceSetup.LBSMotionJournalBatchName;
                GenJournalLineHeader.LBSDocumentNo := NewDocNo;
                GenJournalLineHeader.LBSPostingDate := GenJournalLine."Posting Date";
                GenJournalLineHeader.LBSComment := ImportMotionFxd;
                if CivitasInterfaceSetup.LBSMotionAutomaticRelease then
                    GenJournalLineHeader.Validate(LBSStatusApproval, GenJournalLineHeader.LBSStatusApproval::Released);
                GenJournalLineHeader.Insert();
            end;
            Message(StrSubstNo(LinesImportedAndJournalLinesCreatedMsg, NewDocNo));
        end else
            Message(NoLinesImportedMsg)
    end;

    var
        CivitasInterfaceSetup: Record LBSInterfaceSetup;
        LineNo: Integer;
        NoLinesImportedmsg: Label 'No lines imported';
        ImportMotionFxd: Label 'Import motion';
        LinesImportedAndJournalLinesCreatedMsg: Label 'Lines succesfully imported and journal with documentno. %1 created';
        NotInBalanceErr: Label 'Lines are not in balance (%1) while automatic release is set. No lines imported.';
}
