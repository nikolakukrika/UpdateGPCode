table 2680 "Data Search Result"
{
    DataClassification = CustomerContent;
    TableType = Temporary;
    Permissions = tabledata "Data Search Setup (Table)" = rm;

    fields
    {
        field(1; "Table No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Table Subtype"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Parent ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Parent ID';
        }
        field(5; Description; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(6; "Line Type"; Option)
        {
            OptionMembers = Header,Data,MoreHeader,MoreData;
            DataClassification = SystemMetadata;
        }
        field(7; "No. of Hits"; Integer)
        {
            Caption = 'No. of Hits';
            DataClassification = CustomerContent;
        }
        field(10; "Table Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table), "Object ID" = FIELD("Table No.")));
            Caption = 'Table Caption';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Table No.", "Table Subtype", "Entry No.")
        {
        }
        key(Key2; "No. of Hits")
        {
        }
    }

    var
        linesLbl: Label 'lines';

    internal procedure GetStyleExpr(): Text
    begin
        case "Line Type" of
            "Line Type"::Header:
                exit('Strong');
            "Line Type"::Data:
                exit('Standard');
            "Line Type"::MoreHeader:
                exit('AttentionAccent');
            "Line Type"::MoreData:
                exit('');
        end;
        exit('');
    end;

    internal procedure GetTableCaption(): Text
    var
        PageMetadata: Record "Page Metadata";
        PageNo: Integer;
        PageCaption: Text;
    begin
        PageNo := GetListPageNo();
        if PageNo <> 0 then
            if PageMetadata.Get(PageNo) then
                PageCaption := PageMetadata.Caption;
        if Rec."Table No." in
            [Database::"Sales Line", Database::"Sales Invoice Line", Database::"Sales Shipment Line", Database::"Sales Cr.Memo Line",
             Database::"Purchase Line", Database::"Purch. Inv. Line", Database::"Purch. Rcpt. Line", Database::"Purch. Cr. Memo Line",
             Database::"Service Line", Database::"Service Invoice Line", Database::"Service Cr.Memo Line"]
        then
            PageCaption += ' - ' + linesLbl;
        exit(PageCaption);
    end;

    internal procedure GetListPageNo(): Integer
    var
        TableMetaData: Record "Table Metadata";
        SalesDocumentType: Enum "Sales Document Type";
        PurchaseDocumentType: Enum "Purchase Document Type";
        ServiceDocumentType: Enum "Service Document Type";
        TableNo: Integer;
        PageNo: Integer;
    begin
        TableNo := Rec."Table No.";
        case TableNo of
            Database::"Sales Line":
                TableNo := Database::"Sales Header";
            Database::"Purchase Line":
                TableNo := Database::"Purchase Header";
            Database::"Service Line":
                TableNo := Database::"Service Header";
            Database::"Sales Invoice Line":
                TableNo := Database::"Sales Invoice Header";
            Database::"Sales Shipment Line":
                TableNo := Database::"Sales Shipment Header";
            Database::"Sales Cr.Memo Line":
                TableNo := Database::"Sales Cr.Memo Header";
            Database::"Purch. Inv. Line":
                TableNo := Database::"Purch. Inv. Header";
            Database::"Purch. Cr. Memo Line":
                TableNo := Database::"Purch. Cr. Memo Hdr.";
            Database::"Purch. Rcpt. Line":
                TableNo := Database::"Purch. Rcpt. Header";
            Database::"Service Invoice Line":
                TableNo := Database::"Service Invoice Header";
            Database::"Service Cr.Memo Line":
                TableNo := Database::"Service Cr.Memo Header";
        end;

        case TableNo of
            Database::"Sales Header":
                case Rec."Table Subtype" of
                    SalesDocumentType::"Blanket Order".AsInteger():
                        PageNo := Page::"Blanket Sales Orders";
                    SalesDocumentType::"Credit Memo".AsInteger():
                        PageNo := Page::"Sales Credit Memos";
                    SalesDocumentType::Invoice.AsInteger():
                        PageNo := Page::"Sales Invoice List";
                    SalesDocumentType::Order.AsInteger():
                        PageNo := Page::"Sales Orders";
                    SalesDocumentType::Quote.AsInteger():
                        PageNo := Page::"Sales Quotes";
                    SalesDocumentType::"Return Order".AsInteger():
                        PageNo := Page::"Sales Return Orders";
                end;
            Database::"Purchase Header":
                case Rec."Table Subtype" of
                    PurchaseDocumentType::"Blanket Order".AsInteger():
                        PageNo := Page::"Blanket Purchase Orders";
                    PurchaseDocumentType::"Credit Memo".AsInteger():
                        PageNo := Page::"Purchase Credit Memos";
                    PurchaseDocumentType::Invoice.AsInteger():
                        PageNo := Page::"Purchase Invoices";
                    PurchaseDocumentType::Order.AsInteger():
                        PageNo := Page::"Purchase Orders";
                    PurchaseDocumentType::Quote.AsInteger():
                        PageNo := Page::"Purchase Quotes";
                    PurchaseDocumentType::"Return Order".AsInteger():
                        PageNo := Page::"Purchase Return Orders";
                end;
            Database::"Service Header":
                case Rec."Table Subtype" of
                    ServiceDocumentType::"Credit Memo".AsInteger():
                        PageNo := Page::"Service Credit Memos";
                    ServiceDocumentType::Invoice.AsInteger():
                        PageNo := Page::"Service Invoices";
                    ServiceDocumentType::Order.AsInteger():
                        PageNo := Page::"Service Orders";
                    ServiceDocumentType::Quote.AsInteger():
                        PageNo := Page::"Service Quotes";
                end;
        end;
        if PageNo = 0 then
            if TableMetaData.Get(TableNo) then
                PageNo := TableMetaData.LookupPageID;
        exit(PageNo);
    end;

    internal procedure LogUserHit(RoleCenterID: Integer; TableNo: Integer; TableSubtype: Integer)
    var
        DataSearchSetupTable: Record "Data Search Setup (Table)";
    begin
        DataSearchSetupTable.LockTable();
        if DataSearchSetupTable.Get(RoleCenterID, TableNo, TableSubtype) then begin
            DataSearchSetupTable."No. of Hits" += 1;
            if DataSearchSetupTable.Modify() then;
        end;
        Commit();
    end;

    internal procedure ShowRecord(RoleCenterID: Integer; SearchString: Text)
    var
        DataSearchResultRecords: page "Data Search Result Records";
        RecRef: RecordRef;
        PageNo: Integer;
    begin
        case Rec."Line Type" of
            Rec."Line Type"::Header:
                begin
                    PageNo := Rec.GetListPageNo();
                    if PageNo > 0 then
                        Page.Run(PageNo);
                end;
            Rec."Line Type"::MoreHeader:
                begin
                    RecRef.Open(Rec."Table No.");
                    DataSearchResultRecords.SetSourceRecRef(RecRef, Rec."Table Subtype", SearchString, GetTableCaption());
                    DataSearchResultRecords.Run();
                end;
            Rec."Line Type"::Data:
                begin
                    RecRef.Open(Rec."Table No.");
                    if not RecRef.GetBySystemId(Rec."Parent ID") then
                        exit;
                    ShowPage(RecRef);
                end;
        end;
        LogUserHit(RoleCenterID, Rec."Table No.", rec."Table Subtype");
    end;

    internal procedure ShowPage(var RecRef: RecordRef)
    var
        TableMetadata: Record "Table Metadata";
        PageMetaData: Record "Page Metadata";
        PageManagement: Codeunit "Page Management";
        RecVariant: Variant;
        PageID: Integer;
    begin
        MapLinesPageToDocumentPage(RecRef);
        RecVariant := RecRef;
        if not PageManagement.PageRun(RecVariant) then begin
            if not TableMetadata.Get(RecRef.Number) then
                exit;
            PageID := TableMetadata.LookupPageID;
            if not PageMetaData.Get(PageID) then
                exit;
            if PageMetaData.CardPageID <> 0 then
                PageID := PageMetaData.CardPageID;
            Page.Run(PageID, RecVariant);
        end;
    end;

    local procedure MapLinesPageToDocumentPage(var RecRef: RecordRef): Boolean
    var
        Mapped: Boolean;
    begin
        Mapped := true;
        case RecRef.Number of
            Database::"Sales Line":
                SalesLineToHeader(RecRef, RecRef);
            Database::"Purchase Line":
                PurchaseLineToHeader(RecRef, RecRef);
            Database::"Sales Invoice Line":
                SalesInvoiceLineToHeader(RecRef, RecRef);
            Database::"Sales Shipment Line":
                SalesShipmentLineToHeader(RecRef, RecRef);
            Database::"Sales Cr.Memo Line":
                SalesCreditMemoLineToHeader(RecRef, RecRef);
            Database::"Purch. Inv. Line":
                PurchaseInvLineToHeader(RecRef, RecRef);
            Database::"Purch. Rcpt. Line":
                PurchRcptLineToHeader(RecRef, RecRef);
            Database::"Purch. Cr. Memo Line":
                PurchCrMemoLineToHeader(RecRef, RecRef);
            Database::"Service Line":
                ServiceLineToHeader(RecRef, RecRef);
            Database::"Sales Line Archive":
                SalesLineArchiveToHeader(RecRef, RecRef);
            Database::"Purchase Line Archive":
                PurchaseLineArchiveToHeader(RecRef, RecRef);
            Database::"Service Contract Line":
                ServiceContractLineToHeader(RecRef, RecRef);
            Database::"Prod. Order Line":
                ProdOrderLineToHeader(RecRef, RecRef);
            Database::"Production BOM Line":
                ProductionBOMLineToHeader(RecRef, RecRef);
            Database::"Routing Line":
                RoutingLineToHeader(RecRef, RecRef);
            Database::"Warehouse Shipment Line":
                WarehouseShipmentLineToHeader(RecRef, RecRef);
            Database::"Warehouse Receipt Line":
                WarehouseReceiptLineToHeader(RecRef, RecRef);
            Database::"Warehouse Activity Line":
                WarehouseActivityLineToHeader(RecRef, RecRef);
            Database::"Registered Whse. Activity Line":
                RegisteredWhseActivityLineToHeader(RecRef, RecRef);
            Database::"Posted Whse. Receipt Line":
                PostedWhseReciptLineToHeader(RecRef, RecRef);
            Database::"Assembly Line":
                AssemblyLineToHeader(RecRef, RecRef);
            else
                Mapped := false;
        end;
        exit(Mapped);
    end;

    local procedure SalesLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LineRecRef.SetTable(SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        HeaderRecRef.GetTable(SalesHeader);
    end;

    local procedure PurchaseLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LineRecRef.SetTable(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        HeaderRecRef.GetTable(PurchaseHeader);
    end;

    local procedure SalesInvoiceLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        LineRecRef.SetTable(SalesInvoiceLine);
        SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.");
        HeaderRecRef.GetTable(SalesInvoiceHeader);
    end;

    local procedure SalesShipmentLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        LineRecRef.SetTable(SalesShipmentLine);
        SalesShipmentHeader.Get(SalesShipmentLine."Document No.");
        HeaderRecRef.GetTable(SalesShipmentHeader);
    end;

    local procedure SalesCreditMemoLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        LineRecRef.SetTable(SalesCrMemoLine);
        SalesCrMemoHeader.Get(SalesCrMemoLine."Document No.");
        HeaderRecRef.GetTable(SalesCrMemoHeader);
    end;

    local procedure PurchaseInvLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        PurchaseInvHeader: Record "Purch. Inv. Header";
        PurchaseInvLine: Record "Purch. Inv. Line";
    begin
        LineRecRef.SetTable(PurchaseInvLine);
        PurchaseInvHeader.Get(PurchaseInvLine."Document No.");
        HeaderRecRef.GetTable(PurchaseInvHeader);
    end;

    local procedure PurchRcptLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        LineRecRef.SetTable(PurchRcptLine);
        PurchRcptHeader.Get(PurchRcptLine."Document No.");
        HeaderRecRef.GetTable(PurchRcptHeader);
    end;

    local procedure PurchCrMemoLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        LineRecRef.SetTable(PurchCrMemoLine);
        PurchCrMemoHdr.Get(PurchCrMemoLine."Document No.");
        HeaderRecRef.GetTable(PurchCrMemoHdr);
    end;

    local procedure ServiceLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        LineRecRef.SetTable(ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        HeaderRecRef.GetTable(ServiceHeader);
    end;

    local procedure ServiceContractLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        LineRecRef.SetTable(ServiceContractLine);
        ServiceContractHeader.Get(ServiceContractLine."Contract Type", ServiceContractLine."Contract No.");
        HeaderRecRef.GetTable(ServiceContractHeader);
    end;

    local procedure SalesLineArchiveToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesLineArchive: Record "Sales Line Archive";
    begin
        LineRecRef.SetTable(SalesLineArchive);
        SalesHeaderArchive.Get(SalesLineArchive."Document Type", SalesLineArchive."Document No.", SalesHeaderArchive."Doc. No. Occurrence", SalesLineArchive."Version No.");
        HeaderRecRef.GetTable(SalesHeaderArchive);
    end;

    local procedure PurchaseLineArchiveToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        PurchaseLineArchive: Record "Purchase Line Archive";
    begin
        LineRecRef.SetTable(PurchaseLineArchive);
        PurchaseHeaderArchive.Get(PurchaseLineArchive."Document Type", PurchaseLineArchive."Document No.", PurchaseHeaderArchive."Doc. No. Occurrence", PurchaseLineArchive."Version No.");
        HeaderRecRef.GetTable(PurchaseHeaderArchive);
    end;

    local procedure ProdOrderLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        LineRecRef.SetTable(ProdOrderLine);
        ProductionOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        HeaderRecRef.GetTable(ProductionOrder);
    end;

    local procedure ProductionBOMLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LineRecRef.SetTable(ProductionBOMLine);
        ProductionBOMHeader.Get(ProductionBOMLine."Production BOM No.");
        HeaderRecRef.GetTable(ProductionBOMHeader);
    end;

    local procedure RoutingLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LineRecRef.SetTable(RoutingLine);
        RoutingHeader.Get(RoutingLine."Routing No.");
        HeaderRecRef.GetTable(RoutingHeader);
    end;

    local procedure WarehouseShipmentLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LineRecRef.SetTable(WarehouseShipmentLine);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        HeaderRecRef.GetTable(WarehouseShipmentHeader);
    end;

    local procedure WarehouseReceiptLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LineRecRef.SetTable(WarehouseReceiptLine);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        HeaderRecRef.GetTable(WarehouseReceiptHeader);
    end;

    local procedure WarehouseActivityLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LineRecRef.SetTable(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."No.");
        HeaderRecRef.GetTable(WarehouseActivityHeader);
    end;

    local procedure RegisteredWhseActivityLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        LineRecRef.SetTable(RegisteredWhseActivityLine);
        RegisteredWhseActivityHdr.Get(RegisteredWhseActivityLine."No.");
        HeaderRecRef.GetTable(RegisteredWhseActivityHdr);
    end;

    local procedure PostedWhseReciptLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        LineRecRef.SetTable(PostedWhseReceiptLine);
        PostedWhseReceiptHeader.Get(PostedWhseReceiptLine."No.");
        HeaderRecRef.GetTable(PostedWhseReceiptHeader);
    end;


    local procedure AssemblyLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        LineRecRef.SetTable(AssemblyLine);
        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        HeaderRecRef.GetTable(AssemblyHeader);
    end;
}