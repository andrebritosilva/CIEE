#Include 'Protheus.ch'

USER FUNCTION FA200RE2()
Local aArea := GetArea()
lOCAL cIdArq:= ""
lOCAL cIdTit:= ""

//Grava log dos motivos de rejeição no banco
if SE1->(!EOF()) 
    
    cIdArq:= FI0->FI0_IDARQ
    cIdTit:= If(Empty(SE1->E1_IDCNAB), SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO), SE1->E1_IDCNAB)
	
    RecLock("FI1", .T.)
	FI1->FI1_FILIAL	:= xFilial("FI1")
	FI1->FI1_IDARQ	:= cIdArq
	FI1->FI1_IDTIT	:= cIdTit
	FI1->FI1_OCORB	:= SEB->EB_REFBAN
	FI1->FI1_OCORS	:= SEB->EB_OCORR
	FI1->FI1_SEQ	:= FI0->FI0_SEQ 
    FI1->FI1_XMOTIV := SEB->EB_MOTBAN
    FI1->FI1_XDESMO := SEB->EB_DESCMOT
	FI1->(Msunlock())
	
	if SE1->E1_XINTDW3 != "S"
		//Gera fila DW3
		U_CICOBDW3("","0")	
	else
		//Gera fila DW3
		U_CICOBDW3(SEB->EB_REFBAN,"")	
	endif

Endif

RestArea(aArea)
return

