#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH" 

User Function CCADK19(cCodigo)
    
Local oDlg
Local oFWLayer
Local oPanContra
Local aCoors := FWGetDialogSize(oMainWnd)//{0,0,550,1300}  

Local oBrwContra	

Private aLocais   := {}     
Private cZcmCod   := cCodigo

Define MsDialog oDlg Title 'LOCAIS DE CONTRATO - Para Geração de CNABS' From aCoors[1], aCoors[2] To aCoors[3], aCoors[4] Pixel

oFWLayer := FWLayer():New()
oFWLayer:Init( oDlg, .F., .T. )

oFWLayer:addLine( 'UP', 100, .F. )
oPanContra := oFWLayer:getLinePanel('UP')

//oBrwContra := FWMBrowse():New()
oBrwContra:= FWMarkBrowse():New()
oBrwContra:SetAlias('ZR8')
oBrwContra:SetDescription('Locais de Contrato:')
//oBrwContra:SetDetails (.T., /*bDetails*/) 
oBrwContra:DisableDetails()
//oBrwContra:SetFilterDefault("ZCM_TIPO == '1'" )
oBrwContra:SetProfileID("1")
oBrwContra:SetOwner( oPanContra )
oBrwContra:SetIgnoreARotina( .T.)
oBrwContra:SetMenuDef("CCADK19") 

oBrwContra:ForceQuitButton()
oBrwContra:Activate()

Activate MsDialog oDlg  

Return

//-------------------------------------------------------------------
/*{Protheus.doc} MenuDef
Menu Funcional
@return aRotina - Estrutura
			[n,1] Nome a aparecer no cabecalho
			[n,2] Nome da Rotina associada
			[n,3] Reservado
			[n,4] Tipo de Transação a ser efetuada:
				1 - Pesquisa e Posiciona em um Banco de Dados
				2 - Simplesmente Mostra os Campos
				3 - Inclui registros no Bancos de Dados
				4 - Altera o registro corrente
				5 - Remove o registro corrente do Banco de Dados
				6 - Alteração sem inclusão de registros
				7 - Cópia
			[n,5] Nivel de acesso
			[n,6] Habilita Menu Funcional
/*/
//-------------------------------------------------------------------
Static Function MenuDef()

Local aRotina:= {}

ADD OPTION aRotina TITLE "Incluir"			    ACTION "U_CADK19LOC()"	OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Excluir"    			ACTION "U_CADK19EXC()" 	OPERATION 5 ACCESS 144

Return aRotina	

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
/*/
//-------------------------------------------------------------------
Static Function ModelDef()

Local oStruct := Nil
Local oModel  := Nil
//-----------------------------------------
//Monta a estrutura do formulário com base no dicionário de dados
//-----------------------------------------
oStruct := FWFormStruct(1,"ZR8",,,,.F.)
//-----------------------------------------
//Monta o modelo do formulário
//-----------------------------------------
oModel:= MPFormModel():New("ZR8001",{ |oModel| /*PreVldMdl( oModel ) }*/,.T.},/*PosVldMdl( oModel ) }*/,/*Cancel*/)
oModel:AddFields("ZR8001_", Nil/*cOwner*/, oStruct ,/*Pre-Validacao*/,/*Pos-Validacao*/,/*Carga*/)
oModel:GetModel("ZR8001_"):SetDescription("Locais de Contrato")
oModel:SetPrimaryKey({"ZR8_FILIAL","ZR8_CODIGO","ZR8_LOCCTR"})

Return(oModel)

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
/*/
//-------------------------------------------------------------------
Static Function ViewDef() 

Local oStruct:= FWFormStruct( 2,'ZR8' )
Local oModel:= FWLoadModel( 'CCADK19' )
Local oView

oView := FWFormView():New()
oView:SetModel( oModel )
oView:AddField( 'ZR8001_',oStruct, )
oView:GetViewStruct('ZR8001_'):RemoveField("ZR8_FILIAL")
oView:CreateHorizontalBox('GERAL',100)
oView:SetOwnerView( 'ZR8001_','GERAL') 
oView:EnableControlBar(.T.)

Return oView 


User Function CADK19EXC()

Local aArea   := GetArea()
Local cCodigo := Alltrim(ZR8->ZR8_CODIGO)
Local cCodCtr := Alltrim(ZR8->ZR8_LOCCTR)
Local cTab    := GetNextAlias()

If MsgYesNo("Deseja realmente excluir esse local!?", "Exclusão")
	BeginSql Alias cTab				
		SELECT R_E_C_N_O_ AS ZR8REC  FROM %TABLE:ZR8% 
		WHERE ZR8_CODIGO=%exp:cCodigo%
		AND ZR8_LOCCTR=%exp:cCodCtr%
		AND D_E_L_E_T_=''									
	EndSql

	(cTab)->(dbSelectArea((cTab)))                    
	(cTab)->(dbGoTop())      
								
	While (cTab)->(!EOF())
		
		dbGoto((cTab)->ZR8REC) 	
		RecLock("ZR8",.F.)
		ZR8->(DbDelete())
		MsUnlock()

		(cTab)->(DbSkip())

	EndDo

	(cTab)->(dbCloseArea())

	U_CAK19ZC1EX(cCodigo,cCodCtr)

EndIf

RestArea(aArea)

Return .T.


User Function CAK19ZC1EX(cCodigo,cCodCtr)

Local aArea   := GetArea()
Local cTab    := ""

cTab:= GetNextAlias()
	
BeginSql Alias cTab				
	SELECT R_E_C_N_O_ AS ZC1REC FROM %TABLE:ZC1% 
	WHERE ZC1_CODIGO=%exp:cCodigo%
	AND ZC1_LOCCTR=%exp:cCodCtr%
	AND D_E_L_E_T_='' ORDER BY ZC1REC									
EndSql

//(cTab)->(dbSelectArea((cTab)))                    
(cTab)->(dbGoTop())      
                         	
While (cTab)->(!EOF())
	
	ZC1->(DBGOTO((cTab)->ZC1REC))
	RecLock("ZC1",.F.)
		ZC1->ZC1_XOK := " "
	MsUnlock()

	(cTab)->(DbSkip())

EndDo

(cTab)->(dbCloseArea())

RestArea(aArea)

Return


User Function CADK19LOC(lCont)
    
Local aCpoBro     := {} 
Local oDlgLocal 
Local aCores      := {}
Local aSize       := {} 
Local oPanel 
Local oSay1	 
Local cAliAux     := GetNextAlias()
Local oConta
Local aCampos     := {}
Local cQuery      := ""
Local _oConMan
Local oCheck1 
Local lCheck      := .F.
Local oChk
Local cCodigo     := ""
Local cDCTot      := ""

Private cMark     := "OK"
Private lInverte  := .F. 
Private lConcilia := .F.

Default lCont     := .F.


AADD(aCampos,{"ZC1_XOK"       ,"C",TamSX3("ZC1_XOK")[1],0})
AADD(aCampos,{"ZC1_FILIAL"    ,"C",TamSX3("ZC1_FILIAL")[1],0})
AADD(aCampos,{"ZC1_CODIGO"    ,"C",TamSX3("ZC1_CODIGO"  )[1],0})
AADD(aCampos,{"ZC1_LOCCTR"    ,"C",TamSX3("ZC1_LOCCTR"  )[1],0})
AADD(aCampos,{"ZC1_RAZSOC"    ,"C",TamSX3("ZC1_RAZSOC"  )[1],0})

If Empty(cCodigo)
	cCodigo := Alltrim(cZcmCod)
EndIf

BEGINSQL ALIAS cAliAux
	COLUMN R_E_C_N_O_ AS NUMERIC(16,0)
	SELECT ZC1.ZC1_FILIAL,ZC1.ZC1_CODIGO,ZC1.ZC1_LOCCTR,ZC1.ZC1_RAZSOC, ZC1.ZC1_XOK
	FROM %table:ZC1% ZC1
	WHERE ZC1.%notDel%
	AND ZC1.ZC1_FILIAL=%xFilial:ZC1%
	AND ZC1.ZC1_CODIGO=%exp:cCodigo% 
	AND ZC1.ZC1_XOK = ''
ENDSQL

If _oConMan <> Nil
	_oConMan:Delete() 
	_oConMan := Nil
EndIf
_oConMan := FwTemporaryTable():New("cArqTrb")

// Criando a estrutura do objeto  
_oConMan:SetFields(aCampos)

// Criando o indice da tabela
_oConMan:AddIndex("1",{"ZC1_CODIGO"})

_oConMan:Create()

(cAliAux)->(dbGoTop())

Do While (cAliAux)->(!Eof())
	
	RecLock("cArqTrb",.T.)
	
	cArqTrb->ZC1_XOK        := (cAliAux)->ZC1_XOK
	cArqTrb->ZC1_FILIAL     := (cAliAux)->ZC1_FILIAL
	cArqTrb->ZC1_CODIGO     := (cAliAux)->ZC1_CODIGO
	cArqTrb->ZC1_LOCCTR     := (cAliAux)->ZC1_LOCCTR  
	cArqTrb->ZC1_RAZSOC     := (cAliAux)->ZC1_RAZSOC

	MsUnLock()
	
	(cAliAux)->(DbSkip())
		
EndDo

DbGoTop() 

aCpoBro     := {{ "ZC1_XOK"		 ,, "Sel."             ,"@!"},; 
			{  "ZC1_FILIAL"   ,, "Filial"           ,PesqPict("ZC1","ZC1_FILIAL")},;             
			{  "ZC1_CODIGO"   ,, "Cod. Contrato"    ,PesqPict("ZC1","ZC1_CODIGO")},;
			{  "ZC1_LOCCTR"   ,, "Local Contrato"   ,PesqPict("ZC1","ZC1_LOCCTR")},;
			{  "ZC1_RAZSOC"   ,, "Razão Social"     ,PesqPict("ZC1","ZC1_RAZSOC")}}
			
aSize := MSADVSIZE()

DEFINE MSDIALOG oDlg TITLE "Seleção de Local de Contrato" From /*aSize[7]*/50,0 To 450,700 OF oMainWnd PIXEL 

oPanel := TPanel():New(0,0,'',oDlg,, .T., .T.,, ,100,100,.T.,.T. )
oPanel:Align := CONTROL_ALIGN_TOP

@15,10 CHECKBOX oChk VAR lCheck PROMPT "Selecionar Todos" SIZE 60,007 PIXEL OF oPanel ON CLICK U_CADK19Inv(lCheck) 

@15,250 button "Concluir" size 45,11 pixel of oPanel action {||U_CK19ZR8(),If(lConcilia,oDlg:end(),lConcilia := .F.)}

//@15,250 button "Sair" size 45,11 pixel of oPanel action {||oDlg:end(),lConcilia := .F.}  

aCores := {} 

oMark := MsSelect():New("cArqTrb","ZC1_XOK","",aCpoBro,@lInverte,@cMark,{40,1,oDlg:nBottom - 285,oDlg:nRight-360},,,,,aCores) 

oMark:bMark := {| | U_CADK11Disp(cMark)} 

ACTIVATE MSDIALOG oDlg CENTERED

("cArqTrb")->(dbCloseArea())

If _oConMan <> Nil
	_oConMan:Delete() 
	_oConMan := Nil
EndIf


Return .T.

User Function CK19ZR8()

FWMsgRun(,{|| U_CADK19PRC() },,"Processando locais de contrato, aguarde..." )

Return

User Function CADK19PRC()

Local aArea     := GetArea()
Local lRet      := .F.
Local nx        := 0
Local lExiste   := .F.

aLocais := {}

DbSelectArea("cArqTrb") 
DbGotop()

Do While ("cArqTrb")->(!Eof()) 

	lExiste := .T.
	
	aAdd(aLocais,{cArqTrb->ZC1_XOK, cArqTrb->ZC1_FILIAL,cArqTrb->ZC1_CODIGO,cArqTrb->ZC1_LOCCTR,cArqTrb->ZC1_RAZSOC})
	
	("cArqTrb")->(DbSkip())
	
EndDo

For nx := 1 To Len(aLocais)
	If !Empty(aLocais[nx][1]) 
		lRet := .T.
		Exit
	EndIf
Next

If !lRet
	If lExiste
		MsgInfo("Selecione ao menos um local de contrato!","Atenção")
		lConcilia := .F.
	Else	
		MsgInfo("Contrato sem locais a serem selecionados!","Atenção")
		lConcilia := .T.
	EndIf
Else
	lConcilia := .T.
	U_CAK19GRV()
EndIf

RestArea(aArea)

Return lRet


User Function CADK19Inv(lCheck)

Local aArea := GetArea()

dbSelectArea( "cArqTrb" ) 
dbGotop() 

Do While !EoF()
 
    If lCheck
    
		If RecLock( "cArqTrb", .F. ) 
			
			If Empty(cArqTrb->ZC1_XOK)
				cArqTrb->ZC1_XOK  := cMark 
			EndIf
			
			MsUnLock() 
		
		EndIf 
	Else
	
		If RecLock( "cArqTrb", .F. ) 
			
			If !Empty(cArqTrb->ZC1_XOK)
				cArqTrb->ZC1_XOK  := ''
			EndIf 
			
			MsUnLock() 
		
		EndIf 
	
	EndIf
	
	dbSkip() 

EndDo 

dbGotop() 
oMark:oBrowse:Refresh() 

Return


User Function CAK19GRV()

Local aArea       := GetArea()
Local nx          := 0

DbSelectArea("ZR8") 

//CAK11EXC(aLocais)

For nx := 1 To Len(aLocais)
	
	If ZR8->(DbSeek(xFilial("ZR8")+ aLocais[nx][3] + aLocais[nx][4])) 
		lGrava := .F.
	Else
		lGrava := .T.
	EndIf
	
	If !Empty(Alltrim(aLocais[nx][1]))
	
		RecLock("ZR8",lGrava)
		
		ZR8->ZR8_FILIAL   := xFilial("ZR8") 
		ZR8->ZR8_CODIGO   := aLocais[nx][3] 
		ZR8->ZR8_LOCCTR   := aLocais[nx][4] 
		ZR8->ZR8_RAZSOC   := aLocais[nx][5]
	
		MsUnLock()

	EndIf
Next

U_CADK11ATU(aLocais)

aLocais := {}

RestArea(aArea)

Return

