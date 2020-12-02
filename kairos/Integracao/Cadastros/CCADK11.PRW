#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH" 

/*/{Protheus.doc} User Function CCADK11
    Tela de amarração dos contratos que devem gerar CNAB de pagamento de bolsa com os dados do cliente (igual TJ)
    @type  Function
    @author Luiz Enrique de Araujo
    @since 01/06/2020 
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function CCADK11()
    
Local oDlg
Local oFWLayer
Local oPanContra
Local aCoors := FWGetDialogSize(oMainWnd)//{0,0,550,1300}  

Local oBrwContra	

Private cContrato:= (ZCM->ZCM_CODIGO)      
Private aLocais   := {}     

Define MsDialog oDlg Title 'AMARRAÇÃO DE CONTRATOS - Para Geração de CNABS' From aCoors[1], aCoors[2] To aCoors[3], aCoors[4] Pixel

oFWLayer := FWLayer():New()
oFWLayer:Init( oDlg, .F., .T. )

oFWLayer:addLine( 'UP', 100, .F. )
oPanContra := oFWLayer:getLinePanel('UP')

//oBrwContra := FWMBrowse():New()
oBrwContra:= FWMarkBrowse():New()
oBrwContra:SetAlias('ZCM')
oBrwContra:SetDescription('CONTRATOS:')
//oBrwContra:SetDetails (.T., /*bDetails*/) 
oBrwContra:DisableDetails()
//oBrwContra:SetFilterDefault("ZCM_TIPO == '1'" )
oBrwContra:SetProfileID("1")
oBrwContra:SetOwner( oPanContra )
oBrwContra:SetIgnoreARotina( .T.)
oBrwContra:SetMenuDef("CCADK11") 
//oBrwContra:AddLegend( "ZCM_STATUS=='1'"	, "RED"		, "X")
//oBrwContra:AddLegend( "ZCM_STATUS=='2'"	, "GREEN"	, "Y")
//oBrwContra:AddLegend( "ZCM_STATUS=='3'"	, "BLACK"	, "Z")
//oBrwContra:AddButton("descri. funcao",funcao(),/*uParam1*/,1,/*nVerify*/)
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

ADD OPTION aRotina TITLE "Pesquisar"  			ACTION "PesqBrw"           	OPERATION 1 ACCESS 0 DISABLE MENU
ADD OPTION aRotina TITLE "Visualizar" 			ACTION "VIEWDEF.CCADK11" 	OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Locais Contrato"  	ACTION "U_CADK11VISU()" 	OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Incluir"			    ACTION "VIEWDEF.CCADK11"	OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Alterar"    			ACTION "VIEWDEF.CCADK11" 	OPERATION 4 ACCESS 143 
ADD OPTION aRotina TITLE "Excluir"    			ACTION "U_CADK11EXC()" 	    OPERATION 5 ACCESS 144
ADD OPTION aRotina TITLE "Imprimir"   			ACTION "VIEWDEF.CCADK11" 	OPERATION 8 ACCESS 0

Return aRotina	//FWMVCMenu( "CCADK11" )

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
oStruct := FWFormStruct(1,"ZCM")
//-----------------------------------------
//Monta o modelo do formulário
//-----------------------------------------
oModel:= MPFormModel():New("ZCM001",{ |oModel| /*PreVldMdl( oModel ) }*/,.T.},/*PosVldMdl( oModel ) }*/,/*Cancel*/)
oModel:AddFields("ZCM001_", Nil/*cOwner*/, oStruct ,/*Pre-Validacao*/,{||U_CAK11GRV(oModel)}/*Pos-Validacao*/,/*Carga*/)
oModel:GetModel("ZCM001_"):SetDescription("Amarração de Contratos - CNABS")
oModel:SetPrimaryKey({"ZCM_FILIAL","ZCM_CODIGO","ZCM_LOCCTR"})
oModel:lModify := .T.

Return(oModel)

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
/*/
//-------------------------------------------------------------------
Static Function ViewDef() 

Local oStruct:= FWFormStruct( 2,'ZCM' )
Local oModel:= FWLoadModel( 'CCADK11' )
Local oView

oView := FWFormView():New()
oView:SetModel( oModel )
oView:AddField( 'ZCM001_',oStruct, )

oView:CreateHorizontalBox('GERAL',100)
oView:SetOwnerView( 'ZCM001_','GERAL') 
oView:AddUserButton("Locais de Contrato","MAGIC_BMP", {|| U_CADK11CON(oModel)} ,"Locais de Contrato")
oView:EnableControlBar(.T.)

Return oView 

//-----------------------------------------------------------------------------------------------------------------------------------------
 /*/{Protheus.doc} CCADK11A
    FUNCAO PARA Retornar o nome do Usuario ativo.
    Usado no Inicializador padrao em campos das Tabelas ZCM - Amarração de Contratos para Geração de CNABS
    @type  Function
    @author Luiz Enrique de Araujo
    @since 01/06/2020
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
USER Function CCADK11A()

Local cNomeUser:= ""
Local aUSers:= {}

Default cCodUsu:= RetCodUsr() 				//Retorna o Codigo do Usuario					

PswOrder(2)				
			 
If PswSeek(cCodUsu,.T. )
	aUSers := PSWRET() 						// Retorna vetor com informações do usuário
	If Len(aUSers) > 0
		//ALert(aUSers[1,1]) 				// Código do Login
		cNomeUser:= Alltrim(aUSers[1,2])	// Nome
		//ALert(aUSers[1,3])]
	Endif
Else
	cNomeUser:= Alltrim(UsrRetName(cCodUsu))//Retorna o nome do usuario 		
EndIf

Return cNomeUser

/*/{Protheus.doc} VldCnpj(oModel)
    Valida a duplicação do Contrato + Local de Contrato
    @type  Static Function
    @author Luiz Enrique de Araujo
    @since 03/06/2020
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
Static Function VldCnpj(oModel)

Local lret      := .t.
Local nReg      := ZCM->(Recno())

Local nOper     := oModel:GetOperation()
Local cXnpj     := oModel:GetValue("ZCM001_","ZCM_DOCLOC") 
Local cContra   := oModel:GetValue("ZCM001_","ZCM_CODIGO") 
Local cLocContr := oModel:GetValue("ZCM001_","ZCM_LOCCTR") 

Do CASE
    CASE nOper == 3     //Inclusao 

    CASE nOper == 4     //alteracao
        
    OTHERWISE
        Return .t.
ENDCASE


ZCM->(dbSetOrder(2))  //FILIAL + CNPJ
cXnpj:= Padr(cXnpj,TamSx3("ZCM_DOCLOC")[1]) 
IF ZCM->(dbSeek(Xfilial("ZCM") + cXnpj ))
    If ZCM->(Recno()) == nReg .And. nOper == 4
        lret:= .T.
    Else
        Alert("Operação invalida. CNPJ: " + Alltrim(cXnpj) + " Já existe.")
        lret:= .f.
    Endif  
ENDIF 
/*
ZCM->(dbSetOrder(1))    //FILIAL + CONTRATO + LOCAL DE CONTRATO
IF ZCM->(dbSeek(Xfilial("ZCM") + cContra + cLocContr ))
    If ZCM->(Recno()) == nReg .And. nOper == 4
        lret:= .T.
    Else
        Alert("Operação invalida. Contrato: " + Alltrim(cContra) + " Local: " + Alltrim(cLocContr) + " Já existe.")
        lret:= .f.
    Endif   
ENDIF
*/ 

ZCM->(DBGOTO(nReg))

Return lret
/*/{Protheus.doc} CADK11LOC
Tela de eleção de locais
@author André Brito
@since 12/11/2020
@version 1.0
@type function
/*/

User Function CADK11LOC(lCont)
    
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
Local cCodigo     := Alltrim(M->ZCM_CODIGO)
Local cDCTot      := ""
Local oModelAtv   := FWModelActive()
Local nOpc        := oModelAtv:GetOperation()

Private cMark     := "OK"
Private lInverte  := .F. 
Private lConcilia := .F.

Default lCont     := .F.

If nOpc == 3 .Or. lCont 
	AADD(aCampos,{"ZC1_XOK"       ,"C",TamSX3("ZC1_XOK")[1],0})
	AADD(aCampos,{"ZC1_FILIAL"    ,"C",TamSX3("ZC1_FILIAL")[1],0})
	AADD(aCampos,{"ZC1_CODIGO"    ,"C",TamSX3("ZC1_CODIGO"  )[1],0})
	AADD(aCampos,{"ZC1_LOCCTR"    ,"C",TamSX3("ZC1_LOCCTR"  )[1],0})
	AADD(aCampos,{"ZC1_RAZSOC"    ,"C",TamSX3("ZC1_RAZSOC"  )[1],0})

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

	@15,10 CHECKBOX oChk VAR lCheck PROMPT "Selecionar Todos" SIZE 60,007 PIXEL OF oPanel ON CLICK U_CADK11Inv(lCheck) 

	@15,250 button "Concluir" size 45,11 pixel of oPanel action {||U_CK11ZR8(),If(lConcilia,oDlg:end(),lConcilia := .F.)}

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

EndIf

Return .T.

/*/{Protheus.doc} CK11ZR8
Chamada de processamento de locais de contrato
@author André Brito
@since 12/11/2020
@version 1.0
@type function
/*/

User Function CK11ZR8()

FWMsgRun(,{|| U_CADK11PRC() },,"Processando locais de contrato, aguarde..." )

Return


/*/{Protheus.doc} CADK11PRC
Processa locais de contrato
@author André Brito
@since 12/11/2020
@version 1.0
@type function
/*/

User Function CADK11PRC()

Local aArea     := GetArea()
Local lRet      := .F.
Local nx        := 0
Local oModel    := FWModelActive()
Local oView 	:= FwViewActive()
Local oAux      := oModel:GetModel( 'ZCM001_' )
Local cCodigo   := oModel:GetValue('ZCM001_','ZCM_CODIGO')
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
EndIf

oAux:SetValue('ZCM_CODIGO', cCodigo )

oModel:lModify := .T.

If !Empty(oView)
	oView:Refresh()
EndIf

RestArea(aArea)

Return lRet

/*/{Protheus.doc} CADK11Disp
Funcao executada ao Marcar/Desmarcar um registro.  

@author André Brito
@since 14/06/2019
@version P12
/*/

User Function CADK11Disp(cMark) 

Local cMarca := cMark

RecLock("cArqTrb",.F.) 

If Marked("ZC1_XOK")    

	cArqTrb->ZC1_XOK := cMarca  
	
Else 

	cArqTrb->ZC1_XOK :=  "" 

EndIf

MSUNLOCK() 

oMark:oBrowse:Refresh() 

Return 

/*/{Protheus.doc} CAK11GRV
Gravação tabela ZR8 - Amarração Locais de Contrato
@author André Brito
@since 12/11/2020
@version 1.0
@type function
/*/

User Function CAK11GRV()

Local aArea       := GetArea()
Local nx          := 0
Local oModel      := FWModelActive()
Local oView 	  := FwViewActive()
Local oAux        := oModel:GetModel( 'ZCM001_' )
Local cCodigo     := oModel:GetValue('ZCM001_','ZCM_CODIGO')

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

oAux:SetValue('ZCM_CODIGO', cCodigo )

oModel:lModify := .T.

If !Empty(oView)
	oView:Refresh()
EndIf

RestArea(aArea)

Return

/*/{Protheus.doc} CADK11Inv
Função que realiza a marcação/desmarcação de todos os registros da tabela temporária

@author André Brito
@since 14/06/2019
@version P12
/*/

User Function CADK11Inv(lCheck)

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

/*/{Protheus.doc} CADK11Inv
Exclui locais na alteração de amarração de contrato
@author André Brito
@since 14/06/2019
@version P12
/*/

Static Function CAK11EXC(cCodigo)

Local aArea   := GetArea()
Local cTab    := ""

cTab:= GetNextAlias()
	
BeginSql Alias cTab				
	SELECT R_E_C_N_O_ AS ZR8REC FROM %TABLE:ZR8% 
	WHERE ZR8_CODIGO=%exp:cCodigo%
	AND D_E_L_E_T_='' ORDER BY ZR8REC									
EndSql

//(cTab)->(dbSelectArea((cTab)))                    
(cTab)->(dbGoTop())      
                         	
While (cTab)->(!EOF())
	
	ZR8->(DBGOTO((cTab)->ZR8REC))
	RecLock("ZR8",.F.)
	DbDelete()
	MsUnlock()

	(cTab)->(DbSkip())

EndDo

(cTab)->(dbCloseArea())

RestArea(aArea)

Return



/*/{Protheus.doc} CADK11Inv
Exclui locais na alteração de amarração de contrato
@author André Brito
@since 14/06/2019
@version P12
/*/

User Function CAK11ZC1EX(cCodigo)

Local aArea   := GetArea()
Local cTab    := ""

cTab:= GetNextAlias()
	
BeginSql Alias cTab				
	SELECT R_E_C_N_O_ AS ZC1REC FROM %TABLE:ZC1% 
	WHERE ZC1_CODIGO=%exp:cCodigo%
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

User Function CADK11CON(oModel)

Local oModel      := FWModelActive()
Local oView 	  := FwViewActive()
Local oAux        := oModel:GetModel( 'ZCM001_' )
Local nOpc        := oModel:GetOperation()
Local cCodigo     := oModel:GetValue('ZCM001_','ZCM_CODIGO')
Local lCont       := .T.

If nOpc == 4

	U_CADK11LOC(lCont)
	
Else
	MsgInfo("Rotina disponível apenas na opção de alteração!","Cad. Locais")
EndIf

oAux:SetValue('ZCM_CODIGO', cCodigo )

oModel:lModify := .T.

If !Empty(oView)
	oView:ValidField("ZCM001_","ZCM_CODIGO",fWFldGet('ZCM_CODIGO'),.T.)
	oView:Refresh()
EndIf

Return

User Function CADK11VISU()

SetFunName("CCADK19")

U_CCADK19(ZCM->ZCM_CODIGO)

SetFunName("CCADK11")

Return

User Function CADK11EXC()

Local aArea   := GetArea()
Local cCodigo := Alltrim(ZCM->ZCM_CODIGO)
Local cTab    := GetNextAlias()

If MsgYesNo("Deseja realmente excluir o contrato e seus locais!?", "Exclusão")
	BeginSql Alias cTab				
		SELECT R_E_C_N_O_ AS ZCMREC  FROM %TABLE:ZCM% 
		WHERE ZCM_CODIGO=%exp:cCodigo%
		AND D_E_L_E_T_=''									
	EndSql

	(cTab)->(dbSelectArea((cTab)))                    
	(cTab)->(dbGoTop())      
								
	While (cTab)->(!EOF())
		
		dbGoto((cTab)->ZCMREC) 	
		RecLock("ZCM",.F.)
		ZCM->(DbDelete())
		MsUnlock()

		(cTab)->(DbSkip())

	EndDo

	(cTab)->(dbCloseArea())

	CAK11EXC(cCodigo)

	U_CAK11ZC1EX(cCodigo)

EndIf

RestArea(aArea)

Return .T.

User Function CADK11ATU(aLocais)

Local aArea := GetArea()
Local nx    := 1

DbSelectArea("ZC1") 
DbGotop()
ZC1->(dbSetOrder(1))    

For nx := 1 To Len(aLocais)

	IF ZC1->(dbSeek(aLocais[nx][2] + aLocais[nx][3] + aLocais[nx][4] ))
		
		RecLock("ZC1",.F.)
				
			ZC1->ZC1_XOK        := aLocais[nx][1]

		MsUnLock()

	EndIf
Next

RestArea(aArea)

Return
