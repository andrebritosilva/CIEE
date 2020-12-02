#Include 'Protheus.ch'
#Include 'Fwmvcdef.ch'
#include 'parmtype.ch'
#include "MsOle.Ch"

#Define	oleWFormatPDF	"17" 

/*/{Protheus.doc} CCADK12
Impressão de Recibos
@author danilo.grodzicki
@since 11/06/2020
@version 12.1.25
@type user function
/*/
User Function CCADK12()

	Local oBrowse := Nil

	oBrowse := FwMBrowse():New()
	oBrowse:SetAlias('ZCR')
	oBrowse:SetDescription('Impressão de Recibos')
	oBrowse:AddLegend("ZCR_STATUS == '1'", "RED"  , "Pendênte de Impressão")
	oBrowse:AddLegend("ZCR_STATUS == '2'", "GREEN", "Impresso")
	oBrowse:Activate()

Return

/*/{Protheus.doc} MenuDef
Impressão de Recibos
@author danilo.grodzicki
@since 11/06/2020
@version 12.1.25
@type static function
/*/
Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'      ACTION 'VIEWDEF.CCADK12' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Legenda'         ACTION 'U_CCK12LEG()'    OPERATION 6 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir Recibo' ACTION 'U_CCK12PAR()'    OPERATION 8 ACCESS 0

Return(aRotina)

/*/{Protheus.doc} ModelDef
Impressão de Recibos
@author danilo.grodzicki
@since 11/06/2020
@version 12.1.25
@type static function
/*/
Static Function ModelDef()

	Local oModel   := Nil
	Local oStruZCR := FWFormStruct(1,'ZCR',/*bAvalCampo*/,/*lViewUsado*/)

	oModel := MPFormModel():New('ZCR001MO',/*bPreValidacao*/,{ |oModel| ValModelo( oModel ) }/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )

	oModel:AddFields('ZCRMASTER',/*cOwner*/,oStruZCR,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/)
	oModel:SetDescription('Impressão de Recibos')

	oModel:SetPrimaryKey({})

Return(oModel)

/*/{Protheus.doc} ViewDef
Impressão de Recibos
@author danilo.grodzicki
@since 11/06/2020
@version 12.1.25
@type static function
/*/
Static Function ViewDef()

	Local oView    := Nil
	Local oModel   := FWLoadModel('CCADK12')
	Local oStruZCR := FWFormStruct(2,'ZCR')

	oView := FWFormView():New()

	oView:SetModel(oModel)
	oView:AddField('VIEW_ZCR', oStruZCR, 'ZCRMASTER')

	oView:CreateHorizontalBox('TELA', 100)
	oView:SetOwnerView('VIEW_ZCR', 'TELA')

Return(oView)

/*/{Protheus.doc} CCK12LEG
Legenda da impressão de recibos
@author danilo.grodzicki
@since 11/06/2020
@version 12.1.25
@type user function
/*/
User Function CCK12LEG()

	BrwLegenda("Status Impressão Recibo", "Legenda", {;
		{"BR_VERMELHO", OemToAnsi("Pendente de Impressão")},;
		{"BR_VERDE"   , OemToAnsi("Impresso")            }})

Return Nil

/*/{Protheus.doc} ValModelo
Impressão de Recibos
@author danilo.grodzicki
@since 11/06/2020
@version 12.1.25
@type static function
/*/
Static Function ValModelo(oModel)

//Local nOperation := oModel:GetOperation()
//Local oModelAtv  := FWModelActive()

Return(.T.)

/*/{Protheus.doc} ZCR001MO
Impressão de Recibos
@author danilo.grodzicki
@since 11/06/2020
@version 12.1.25
@type user function
/*/
User Function ZCR001MO()

	Local oObj
	Local cIdPonto
	Local cIdModel
	Local aParam := PARAMIXB
	//Local oModelAtv  := FWModelActive()

	If aParam <> Nil
		oObj     := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]
	endif

Return(.T.)

/*/{Protheus.doc} CCK12PAR
Parâmetros para imprimir o Recibo
@author danilo.grodzicki
@since 15/06/2020
@version 12.1.25
@type user function
/*/
User Function CCK12PAR()

	Local oDlg
	Local oOk     := LoadBitmap( GetResources(), "LBOK" )
	Local oNo     := LoadBitmap( GetResources(), "LBNO" )
	Local aVetor  := {}
	Local aParam  := {}
	Local aParRet := {}

	Private cTab
	Private oLbx1

	aAdd(aParam,{1,"Data Baixa de"   ,CtoD("") ,"","","","",50,.F.})
	aAdd(aParam,{1,"Data Baixa até"  ,CtoD("") ,"","","","",50,.F.})
	aAdd(aParam,{1,"Número do Recibo",space(06),"","","","",50,.F.})

	if ParamBox(aParam,"Rotina de impressão de Recibo",@aParRet)

		cTab := GetNextAlias()
		BeginSql alias cTab
		SELECT ZCR.ZCR_DTBAIX AS DTBAIXA,
				ZCR.ZCR_NUMSEQ  AS NUMERO,
				ZCR.ZCR_CONTRA  AS CONTRATO,
				ZCR.ZCR_LOCCON  AS LOCAL,
				ZCR.ZCR_RAZSOC  AS RAZSOC,
				ZCR.ZCR_VALOR   AS VALOR,
				ZCR.R_E_C_N_O_  AS RECNO
		FROM %table:ZCR% ZCR
		WHERE ZCR.ZCR_FILIAL = %xFilial:ZCR%
			AND ((ZCR.ZCR_DTBAIX BETWEEN %exp:DtoS(aParRet[1])% AND %exp:DtoS(aParRet[2])%) OR ZCR.ZCR_NUMSEQ = %exp:aParRet[3]%)
			AND ZCR.D_E_L_E_T_= ''
		ORDER BY ZCR.ZCR_DTBAIX
		EndSql

		(cTab)->(DbGoTop())
		if (cTab)->(Eof())

			MsgStop("Não foram encontrados recibos para os parâmetros informados","ATENÇÃO")
			(cTab)->(DbCloseArea())

		else

			while (cTab)->(!Eof())
				aadd(aVetor, {.T., StoD((cTab)->DTBAIXA), (cTab)->NUMERO, (cTab)->CONTRATO, (cTab)->LOCAL, (cTab)->RAZSOC, (cTab)->VALOR, (cTab)->RECNO})
				(cTab)->(DbSkip())
			enddo
			(cTab)->(DbCloseArea())

			DEFINE MSDIALOG oDlg TITLE "Rotina de impressão de Recibo" FROM 31,58 TO 300,778 OF oDlg PIXEL

			@ 05,05 LISTBOX oLbx1 FIELDS HEADER " ","Dt. Baixa", "Número", "Id Contrato", "Loc Contrato", "Razão Social", "Valor" SIZE 345, 85 OF oDlg PIXEL
			oLbx1:SetArray(aVetor)

			oLbx1:bLine := {|| {Iif(;
				aVetor[oLbx1:nAt,1],oOk,oNo),;
				aVetor[oLbx1:nAt,2],;
				aVetor[oLbx1:nAt,3],;
				aVetor[oLbx1:nAt,4],;
				aVetor[oLbx1:nAt,5],;
				aVetor[oLbx1:nAt,6],;
				aVetor[oLbx1:nAt,7]}}

			oLbx1:BlDblClick := {|| aVetor[oLbx1:nAt, 1] := !aVetor[oLbx1:nAt, 1], VerTodos( aVetor ), oLbx1:Refresh(), oLbx1:Refresh()}

			@ 94, 264 BUTTON "Marcar"   SIZE 25 ,12 ACTION ( CCK12MKT(aVetor)                                                               , oLbx1:Refresh(.T.) ) Of oDlg PIXEL
			@ 94, 292 BUTTON "Imprimir" SIZE 25 ,12 ACTION ( FWMsgRun(,{|| U_CCK12IMP(aVetor) }, "Aguarde...", "Imprimindo o(s) Recibo(s)."), oDlg:End()         ) Of oDlg PIXEL
			@ 94, 320 BUTTON "Cancelar" SIZE 25 ,12 ACTION ( oDlg:End()                                                                                          ) Of oDlg PIXEL

			ACTIVATE MSDIALOG oDlg CENTERED
		endif
	endif

Return Nil

/*/{Protheus.doc} VerTodos
Rotina de liberação de folha 
@type  Function
@author danilo.grodzicki
@since 15/06/2020
@version version
/*/
Static Function VerTodos( _aVetor )

	Local lTTrue := .T.
	Local nI     := 0

	For nI := 1 To Len( _aVetor )
		lTTrue := IIf( !_aVetor[nI][1], .F., lTTrue )
	Next nI

	oLbx1:Refresh()

Return Nil

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK12MKT
Marcar todos
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function CCK12MKT(_aVetor)

	Local nCnt:= 0

	For nCnt:=1 to Len(_aVetor)
		If _aVetor[nCnt,1]
			_aVetor[nCnt,1] := .F.
		Else
			_aVetor[nCnt,1] := .T.
		EndIf
	Next nCnt

Return

/*/{Protheus.doc} CCK12IMP
Imprimir o Recibo
@author danilo.grodzicki
@since 11/06/2020
@version 12.1.25
@type user function
/*/
User Function CCK12IMP(aVetor)

	Local nI
	Local nT
	Local cMes
	Local cTab
	Local cTipoEmpr
	Local lImprimiu  := .F.
	Local aReferente := {}
	Local cTipoCont  := space(01)
	Local cPathDot   := AllTrim(GetMV("CI_MODRECI",.T.,"\modelo_recibo\modelo_de_recibo.dotm"))
	Local cPathTmDot := AllTrim(GetMV("CI_DIRMODE",.T.,"c:\spool\modelo_de_recibo.dotm"))
	Local cPathTmp   := Left(cPathTmDot,9)
	Local cPict      := ""	//	14/07/20, Mário A. Cavenaghi, mascara do documento
	Local nSoma      := 0	//	14/07/20, Mário A. Cavenaghi, soma dos Títulos

	Private	hWord

	ZC0->(DbSetOrder(01))
	ZC1->(DbSetOrder(01))
	ZCG->(DbSetOrder(06))

	if !File(cPathDot)
		MsgStop("Não foi encontrado o modelo do recibo.","ATENÇÃO")
		Return Nil
	else
		// verifica se existe o diretório spool, se não existir cria o diretório
		if !ExistDir(cPathTmp)
			MakeDir(cPathTmp)
		endif
		// Copio o modelo do word para o diretório temporário
		if !CpyS2T( cPathDot, cPathTmp, .T. )
			MsgStop("Não foi possível copiar o modelo do recibo.","ATENÇÃO")
			Return Nil
		endif
	endif

	//  Conecta ao word
	hWord := OLE_CreateLink()

	for nI = 1 to Len(aVetor)

		if !aVetor[nI][1]
			loop
		endif

		OLE_NewFile(hWord, cPathTmDot )

		ZCR->(DbGoTo(aVetor[nI][8]))

		// Impressão do Recibo
		ZC0->(DbSeek(xFilial("ZC0")+ZCR->ZCR_CONTRA))
		ZC1->(DbSeek(xFilial("ZC1")+ZCR->ZCR_CONTRA+ZCR->ZCR_LOCCON))
		ZCG->(DbSeek(xFilial("ZCG")+ZCR->ZCR_REGIST))

		if ZC0->ZC0_TIPCON == "1"
			cTipoCont := "Estágio"
		elseif ZC0->ZC0_TIPCON == "2"
			cTipoCont := "Aprendiz"
		endif

		if ZC0->ZC0_TIPCON == "2"  // Aprendiz
			if ZC0->ZC0_TIPAPR == "1"
				cTipoCont += " Capacitador"
			elseif ZC0->ZC0_TIPAPR == "2"
				cTipoCont += " Empregador"
			endif
		endif

		cTab := GetNextAlias()
		BeginSql alias cTab
		SELECT ZCF.ZCF_PREFIX,
				ZCF.ZCF_NUM,
				ZCF.ZCF_PARCEL,
				ZCF.ZCF_TIPO,
				SE1.E1_VENCREA,
				SE1.E1_VALOR,
				SE1.E1_NUMBCO
		FROM %table:ZCF% ZCF, %table:SE1% SE1
		WHERE ZCF_FILIAL = %xfilial:ZCF%
			AND ZCF_RECIBO = %exp:ZCR->ZCR_NUMSEQ%
			AND SE1.E1_FILIAL = %xfilial:SE1%
			AND SE1.E1_PREFIXO = ZCF.ZCF_PREFIX
			AND SE1.E1_NUM = ZCF.ZCF_NUM
			AND SE1.E1_PARCELA = ZCF.ZCF_PARCEL
			AND SE1.E1_TIPO = ZCF.ZCF_TIPO
			AND ZCF.%notDel%
			AND SE1.%notDel%
		EndSql
		TCSETFIELD(cTab,"E1_VENCREA","D")

		aReferente := {}
		nSoma := 0
		if (cTab)->(Eof())
			aadd(aReferente, {;
				"ITENS DO RECIBO NÃO LOCALIZADO",;  // Receita
				" ",;                               // Referência
				" ",;                               // Valor
				" "})                               // Complemento
		else
			while (cTab)->(!Eof())
				aadd(aReferente, {;
					cTipoCont + " - " + AllTrim(ZC0->ZC0_PRGAPE),;                                                   // Receita
					Subs(DtoC((cTab)->E1_VENCREA),4,3) + Str(Year((cTab)->E1_VENCREA),4),;                           // Referência
					AllTrim(TransForm((cTab)->E1_VALOR, "@E 9,999,999,999,999.99")),;                                 // Valor
					"Num. Título: " + AllTrim((cTab)->ZCF_NUM) + " - Nosso Número: " + AllTrim((cTab)->E1_NUMBCO)})  // Complemento
				nSoma += (cTab)->E1_VALOR
				(cTab)->(DbSkip())
			enddo
		endif
		(cTab)->(DbCloseArea())

		if     ZC0->ZC0_TIPEMP == "1"
			cTipoEmpr := "Privada"
		elseif ZC0->ZC0_TIPEMP == "2"
			cTipoEmpr := "Publica"
		elseif ZC0->ZC0_TIPEMP == "3"
			cTipoEmpr := "Mista"
		else
			cTipoEmpr := " "
		endif

		if     Month(dDataBase) == 1
			cMes := "Janeiro"
		elseif Month(dDataBase) == 2
			cMes := "Fevereiro"
		elseif Month(dDataBase) == 3
			cMes := "Março"
		elseif Month(dDataBase) == 4
			cMes := "Abril"
		elseif Month(dDataBase) == 5
			cMes := "Maio"
		elseif Month(dDataBase) == 6
			cMes := "Junho"
		elseif Month(dDataBase) == 7
			cMes := "Julho"
		elseif Month(dDataBase) == 8
			cMes := "Agosto"
		elseif Month(dDataBase) == 9
			cMes := "Setembro"
		elseif Month(dDataBase) == 10
			cMes := "Outubro"
		elseif Month(dDataBase) == 11
			cMes := "Novembro"
		elseif Month(dDataBase) == 12
			cMes := "Dezembro"
		endif

		cPict := Iif(Len(Alltrim(ZC1->ZC1_DOCLOC)) < 14, "@R 999.999.999-99", "@R 99.999.999/9999-99")
		OLE_SetDocumentVar(hWord, "numero"       , ZCR->ZCR_NUMSEQ                                          )
		OLE_SetDocumentVar(hWord, "valor"        , AllTrim(TransForm(nSoma,"@E 99,999,999,999.99"))         )
		OLE_SetDocumentVar(hWord, "valor_extenso", AllTrim(Extenso(nSoma))                                  )
		OLE_SetDocumentVar(hWord, "contrato"     , AllTrim(ZCR->ZCR_CONTRA) + "*" + AllTrim(ZCR->ZCR_LOCCON))
		OLE_SetDocumentVar(hWord, "razao_social" , AllTrim(ZCR->ZCR_RAZSOC)                                 )
		OLE_SetDocumentVar(hWord, "cnpj"         , AllTrim(TransForm(ZC1->ZC1_DOCLOC, cPict)) + " * "       )
		OLE_SetDocumentVar(hWord, "tipo_empresa" , cTipoEmpr                                                )
		OLE_SetDocumentVar(hWord, "endereco"     , AllTrim(ZC1->ZC1_ENDLOC) + "," + AllTrim(ZC1->ZC1_NUMLOC))
		OLE_SetDocumentVar(hWord, "cep"          , AllTrim(TransForm(ZC1->ZC1_CEPLOC,"@R 99999-999"))       )
		OLE_SetDocumentVar(hWord, "municipio"    , AllTrim(ZC1->ZC1_CIDLOC)                                 )
		OLE_SetDocumentVar(hWord, "uf"           , AllTrim(ZC1->ZC1_ESTLOC)                                 )

		OLE_SetDocumentVar(hWord, 'nroitens', str(Len(aReferente)))  // Quantidade de itens que será utilizado na macro
		for nT = 1 to Len(aReferente)
			OLE_SetDocumentVar(hWord, "receita"     + AllTrim(Str(nT)), aReferente[nT,1] )
			OLE_SetDocumentVar(hWord, "referencia"  + AllTrim(Str(nT)), aReferente[nT,2] )
			OLE_SetDocumentVar(hWord, "valor_ref"   + AllTrim(Str(nT)), aReferente[nT,3] )
			OLE_SetDocumentVar(hWord, "complemento" + AllTrim(Str(nT)), aReferente[nT,4] )
		next
		OLE_ExecuteMacro(hWord,"tabitens")

		OLE_SetDocumentVar(hWord, "banco"     , ZCG->ZCG_BANCO                                           )
		OLE_SetDocumentVar(hWord, "agencia"   , AllTrim(ZCG->ZCG_AGENCI)                                 )
		OLE_SetDocumentVar(hWord, "conta"     , AllTrim(ZCG->ZCG_CONTA)                                  )
		OLE_SetDocumentVar(hWord, "valor_rec" , AllTrim(TransForm(ZCG->ZCG_VALOR,"@E 99,999,999,999.99")))
		OLE_SetDocumentVar(hWord, "data_baixa", DtoC(ZCG->ZCG_EMISSA)                                    )

		OLE_SetDocumentVar(hWord, "dia"       , StrZero(Day(dDataBase),2)                                )
		OLE_SetDocumentVar(hWord, "mes"       , cMes                                                     )
		OLE_SetDocumentVar(hWord, "ano"       , Str(Year(dDataBase),4)                                   )

		// Atualizando as variaveis do documento do Word
		OLE_UpdateFields(hWord)

		// Salva o documento Word no formato PDF
		OLE_SaveAsFile(hWord, cPathTmp + "Recibo_" + ZCR->ZCR_NUMSEQ,,, .T., oleWFormatPDF)
		
		if RecLock("ZCR",.F.)
			ZCR->ZCR_STATUS := "2"
			ZCR->ZCR_DTIMPR := dDataBase
			ZCR->ZCR_HRIMPR := Time()
			ZCR->ZCR_USIMPR := UsrRetName(RetCodUsr())
			ZCR->(MsUnLock())
		endif

		lImprimiu := .T.

		OLE_CloseFile( hWord )
	next

	//  Fecha o Word e corta o link
	OLE_CloseLink( hWord )

	if lImprimiu
		fErase(cPathTmDot)	//	Apaga o Modelo
		MsgInfo("O(s) recibo(s) foi(ram) salvo(s) no diretório " + cPathTmp + ".","ATENÇÃO")
	endif

Return Nil

/*/{Protheus.doc} CCK12INC
Incluir Recibo
@author danilo.grodzicki
@since 11/06/2020
@version 12.1.25
@parâmetros: cRegistro  = campo ZCG_REGIST
             cRDR       = campo ZCF_RDR
             cContrato  = campo ZCF_CODCTR
			    cLocContra = campo ZCF_LOCCTR
			    dDtBaixa   = campo ZCF_DTMOVI
             nValor     = valor do depósito identificado (ZCF_BA + ZCF_CI)
@type user function
/*/
User Function CCK12INC(cRegistro, cRDR, cContrato, cLocContra, dDtBaixa, nValor)

	Local cNumSeq
	Local aArea := GetArea()

	cContrato  := Padr(AllTrim(cContrato),TamSX3("ZC1_CODIGO")[1]," ")
	cLocContra := Padr(AllTrim(cLocContra),TamSX3("ZC1_LOCCTR")[1]," ")

	ZC1->(DbSetOrder(01))
	ZC1->(DbSeek(xFilial("ZC1")+cContrato+cLocContra))

	ZCR->(DbSetOrder(01))
	cNumSeq := GETSXENUM("ZCR","ZCR_NUMSEQ")
	ConfirmSX8()

	if RecLock("ZCR",.T.)
		ZCR->ZCR_FILIAL := xFilial("ZCR")
		ZCR->ZCR_NUMSEQ := cNumSeq
		ZCR->ZCR_VALOR  := nValor
		ZCR->ZCR_CONTRA := cContrato
		ZCR->ZCR_LOCCON := cLocContra
		ZCR->ZCR_RAZSOC := ZC1->ZC1_RAZSOC
		ZCR->ZCR_REGIST := cRegistro
		ZCR->ZCR_DTBAIX := dDtBaixa
		ZCR->ZCR_RDR    := cRDR
		ZCR->ZCR_STATUS := "1"
		ZCR->(MsUnLock())
	endif

	RestArea(aArea)

Return(cNumSeq)
