#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADK13
Rotina de fechamento de caixa
@author  	Carlos Henrique
@since     	21/03/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCADK13()

Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZCF")
oBrowse:SetDescription("Fechamento de caixa")
oBrowse:AddLegend("ZCF_FECHAM!='1'", "BR_AMARELO" , "Pendente")
oBrowse:AddLegend("ZCF_FECHAM=='1'", "BR_VERMELHO", "Fechado")
oBrowse:SetFilterDefault("ZCF_TIPO<>'CRD'")
oBrowse:Activate()

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definio do menu
@author  	Carlos Henrique
@since     	21/03/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CCADK13" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Fechamento" ACTION "U_CCK13FEC"      OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Relatório" ACTION "U_CRELK03"      OPERATION 6 ACCESS 0

Return(aRotina)

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definio do MODEL
@author  	Carlos Henrique
@since     	21/03/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()
Local oStruZCF := FWFormStruct(1, "ZCF")
Local oModel   := MPFormModel():New( 'CCK13MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZCFMASTER", /*cOwner*/, oStruZCF)
oModel:SetPrimaryKey({"ZCF_FILIAL","ZCF_RDR","ZCF_TIPO","ZCF_NUM","ZCF_PREFIX","ZCF_PARCEL"})                                                                                                     
oModel:SetDescription("Fechamento de caixa")

Return oModel

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definio do VIEW
@author  	Carlos Henrique
@since     	21/03/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()
Local oView    := FWFormView():New()
Local oStruZCF := FWFormStruct( 2, "ZCF")
Local oModel   := FWLoadModel("CCADK13")

oView:SetModel(oModel)
oView:AddField("VIEW", oStruZCF, "ZCFMASTER")

oView:CreateHorizontalBox("TELA", 100)
oView:SetOwnerView("VIEW", "TELA")

oView:EnableTitleView('VIEW','Fechamento de caixa' )

Return oView

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK13FEC
Rotina de fechamento CNI x titulo
@author  	Carlos Henrique
@since     	21/03/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCK13FEC()
Local _cRDR   := SUBSTR(DTOS(DATE()),3,6)
Local aFrmPg  := {"Direto","Centralizado","Outras Contrib."} 
Local aParam  := {}
Local nFrmPg  := 0
Local cTab	  := ""

aAdd(aParam,{1,"RDR",_cRDR,"","","","",50,.T.}) 
aAdd(aParam,{2,"Forma de Pagamento",,aFrmPg,50,"",.F.})

if ParamBox(aParam,"Rotina de fechamento")
	
	IF MV_PAR02=="Direto"	 
		nFrmPg  := 1
	ELSEIF MV_PAR02=="Centralizado"
		nFrmPg  := 2
	ELSE
		nFrmPg  := 3
	ENDIF	 	

	cTab := GetNextAlias()
	BeginSql alias cTab
		SELECT ZCF_PREFIX
			,ZCF_NUM
			,ZCF_TIPO
			,ZCF_PARCEL
			,ZCG_BANCO
			,ZCG_AGENCI
			,ZCG_CONTA
			,ZCF_DTMOVI
			,ZCF_JUROS
			,ZCF_DESCON
			,(ZCF_BA+ZCF_CI) AS VLRREC
			,ZCF.R_E_C_N_O_ AS RECZCF
			,ZCF_RDR
			,ZCF_REGIST
			,ZCF_CODCTR
			,ZCF_LOCCTR
		FROM %table:ZCF% ZCF
		INNER JOIN %table:ZCG% ZCG ON ZCG_FILIAL='    '
			AND ZCG_REGIST=ZCF_REGIST
			AND ZCG.D_E_L_E_T_=''
		WHERE ZCF_TIPO<>'CRD'
		AND ZCF_RDR=%exp:MV_PAR01%
		AND ZCF_FORPGT=%exp:nFrmPg%
		AND ZCF_FECHAM!='1'
		AND ZCF.D_E_L_E_T_=''
		ORDER BY ZCF_RDR, ZCF_REGIST, ZCF_CODCTR, ZCF_LOCCTR
	EndSql
	
	// Não alterar o ORDER BY da query acima, porque é utilizado na gravação do recibo (U_CCK12INC)

	TCSETFIELD(cTab,"ZCF_DTMOVI","D")

	(cTab)->(DbGoTop())
	if (cTab)->(Eof())

		MsgAlert("Nenhum movimento encontrado! "+CRLF+" RDR: " + MV_PAR01)

	else

		if MsgYesNo("Confirma o fechamento do RDR: " + MV_PAR01 +"?")
			
			FWMsgRun(,{|| CCK13BXA(cTab) }, "Aguarde...", "Realizando o fechamento.") 

			MsgInfo("Processo finalizado")

		endif
	endif

	(cTab)->(DbCloseArea())

endif

Return

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK13BXA
Rotina de baixa de titulos com crédito
@author  	Carlos Henrique
@since     	21/03/2020
@version  	P.12
@return   	Nenhum
@type function
/*/
//---------------------------------------------------------------------------------------
Static Function CCK13BXA(cTab)

Local nI
Local cNumRecibo

Local cChvRec := ""
Local aRecibo := {}
Local aBaixa  := {}
Local cHist	  := "BAIXA CNI"

Private lMsErroAuto    := .F.
Private lMsHelpAuto    := .T.
Private lAutoErrNoFile := .T. 

dbselectarea("ZCF")

(cTab)->(DbGoTop())
while (cTab)->(!Eof())
	ZCF->(dbgoto((cTab)->RECZCF))

	if ZCF->(!Eof())
		lMsErroAuto    := .F.
		lMsHelpAuto    := .T.
		lAutoErrNoFile := .T. 

		aBaixa:={{"E1_PREFIXO" ,(cTab)->ZCF_PREFIX  ,Nil},;
				{"E1_NUM"      ,(cTab)->ZCF_NUM     ,Nil},;
				{"E1_TIPO"     ,(cTab)->ZCF_TIPO	,Nil},;
				{"E1_PARCELA"  ,(cTab)->ZCF_PARCEL	,Nil},;
				{"AUTMOTBX"    ,"NOR"          		,Nil},;
				{"AUTBANCO"    ,(cTab)->ZCG_BANCO   ,Nil},;
				{"AUTAGENCIA"  ,(cTab)->ZCG_AGENCI  ,Nil},;
				{"AUTCONTA"    ,(cTab)->ZCG_CONTA 	,Nil},;
				{"AUTDTBAIXA"  ,(cTab)->ZCF_DTMOVI  ,Nil},;
				{"AUTDTCREDITO",(cTab)->ZCF_DTMOVI	,Nil},;
				{"AUTHIST"     ,cHist  		   		,Nil},;
				{"AUTJUROS"    ,(cTab)->ZCF_JUROS   ,Nil,.T.},;
				{"AUTDESCONT"  ,(cTab)->ZCF_DESCON  ,Nil,.T.},;
				{"AUTVALREC"   ,(cTab)->VLRREC+(cTab)->ZCF_JUROS-(cTab)->ZCF_DESCON ,Nil}}
		
		MSExecAuto({|x,y| Fina070(x,y)},aBaixa,3) 

		IF lMsErroAuto
			RECLOCK("ZCF",.F.)
				ZCF->ZCF_FECHAM:= "2"
				ZCF->ZCF_LOG:= U_CAJERRO(GetAutoGRLog())
			MSUNLOCK()
		ELSE
			RECLOCK("ZCF",.F.)
				ZCF->ZCF_FECHAM:= "1"	
			MSUNLOCK()
			//Tratamento para baixa parcial
if "BAIXA CNI"$SE5->E5_HISTOR
	IF  SE5->E5_VALOR < SE1->E1_VALOR
		U_MANUTSX6()
		_bco := "CI_CAN" + SE5->E5_BANCO 
		_InstCan := SUPERGETMV(_bco,.F.,"35")
			DBSELECTAREA("FI2")
			RECLOCK("FI2",.T.)
				FI2_FILIAL   := xFilial("FI2")
				FI2_OCORR    := _InstCan
				FI2_DESCOC   := ""    
				FI2_PREFIX   := SE1->E1_PREFIXO
				FI2_TITULO   := SE1->E1_NUM
				FI2_PARCEL   := SE1->E1_PARCELA
				FI2_TIPO     := SE1->E1_TIPO
				FI2_CODCLI   := SE1->E1_CLIENTE
				FI2_LOJCLI   := SE1->E1_LOJA
				FI2_CODFOR   := ""
				FI2_LOJFOR   := ""
				FI2_GERADO   := "2"
				FI2_NUMBOR   := SE1->E1_NUMBOR
				FI2_CARTEI   := SE1->E1_SITUACA
				FI2_DTGER    := DDATABASE
				FI2_DTOCOR   := SE5->E5_DATA 
			MSUNLOCK()
			DBSELECTAREA("SE1")
	ENDIF
ENDIF 



			// até aqui
			// Tratamento para gravar o recibo
			if (cTab)->ZCF_TIPO <> "PBA"
				if !Empty(cChvRec) .and. cChvRec <> (cTab)->ZCF_RDR + (cTab)->ZCF_REGIST + (cTab)->ZCF_CODCTR + (cTab)->ZCF_LOCCTR
					for nI = 1 to Len(aRecibo)
						ZCF->(dbgoto(aRecibo[nI][1]))
						if nI == 1
							// Incluir movimento para impressão do recibo de pagamento
							cNumRecibo := U_CCK12INC( ZCF->ZCF_REGIST,;
													ZCF->ZCF_RDR,;
													ZCF->ZCF_CODCTR,;
													ZCF->ZCF_LOCCTR,;
													ZCF->ZCF_DTMOVI,;
													(ZCF->ZCF_BA + ZCF->ZCF_CI) )
						endif
						RECLOCK("ZCF",.F.)
							ZCF->ZCF_RECIBO := cNumRecibo
						MSUNLOCK()
					next
					aRecibo := {}
					cChvRec := (cTab)->ZCF_RDR + (cTab)->ZCF_REGIST + (cTab)->ZCF_CODCTR + (cTab)->ZCF_LOCCTR
				endif
				aadd(aRecibo,{(cTab)->RECZCF})
			endif
		ENDIF	
		
	ENDIF

	if Empty(cChvRec) .and. (cTab)->ZCF_TIPO <> "PBA"
		cChvRec := (cTab)->ZCF_RDR + (cTab)->ZCF_REGIST + (cTab)->ZCF_CODCTR + (cTab)->ZCF_LOCCTR
	endif

(cTab)->(DbSkip())
enddo

// Tratamento para gravar o recibo
if Len(aRecibo) > 0
	for nI = 1 to Len(aRecibo)
		ZCF->(dbgoto(aRecibo[nI][1]))
		if nI == 1
			// Incluir movimento para impressão do recibo de pagamento
			cNumRecibo := U_CCK12INC( ZCF->ZCF_REGIST,;
										ZCF->ZCF_RDR,;
										ZCF->ZCF_CODCTR,;
										ZCF->ZCF_LOCCTR,;
										ZCF->ZCF_DTMOVI,;
										(ZCF->ZCF_BA + ZCF->ZCF_CI) )
		endif
		RECLOCK("ZCF",.F.)
			ZCF->ZCF_RECIBO := cNumRecibo
		MSUNLOCK()
	next
endif

Return

User Function MANUTSX6

Local cTexto		:= "Código do banco para motivo de cancelamento"
Private cConteudo	:= "CI_CAN" + SE5->E5_BANCO 
Private cDescr		:= ""
If ! SX6->( dbSeek(xFilial("SX6")+cConteudo) )
	Reclock("SX6",.T.)
	SX6->X6_FIL			:= Space(2)
	SX6->X6_VAR			:= cConteudo
	SX6->X6_DESCRIC	:= Substr(cTexto,1,Len(SX6->X6_DESCRIC))
	SX6->X6_DESC1		:= ""
	SX6->X6_DESC2		:= ""
	SX6->X6_CONTEUD	:= "35"
	SX6->X6_PROPRI		:= "U" //Indica que foi criado por usuario
	SX6->X6_TIPO        := "C"
	SX6->( MsUnlock() )
Endif

RETURN()
